/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:essentia/essentia.dart' show EventEnvelope;
import 'package:essentia/src/event/bus_state.dart';
import 'package:essentia/src/event/consumer_group.dart';
import 'package:essentia/src/event/drop_reason.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_envelope.dart';
import 'package:essentia/src/event/event_error_handler.dart';
import 'package:essentia/src/event/event_handler.dart';
import 'package:essentia/src/event/event_headers.dart';
import 'package:essentia/src/event/event_subscription.dart';
import 'package:essentia/src/event/event_topic_data.dart';
import 'package:essentia/src/event/group_mailboxes.dart';
import 'package:essentia/src/event/handled_envelope.dart';
import 'package:essentia/src/event/next_waiter.dart';
import 'package:essentia/src/event/subscriber.dart';
import 'package:essentia/src/event/topic_metrics.dart';
import 'package:essentia/src/event/topic_partition.dart';
import 'package:essentia/src/identity/uuid.dart';
import 'package:essentia/src/lifecycle/disposable.dart';
import 'package:essentia/src/principal/principal.dart';
import 'package:essentia/src/principal/principal_context.dart';
import 'package:meta/meta.dart';

/// One named stream of events of type [T] on an `EventBus`.
///
/// ## What it guarantees
///
/// **Order, per key.** Every envelope published under the same key lands on
/// the same partition, and a partition is delivered by exactly one task, so
/// subscribers see those envelopes in the order they were published.
/// Envelopes under different keys are only ordered against each other on a
/// topic with a single partition.
///
/// **Parallelism, per partition.** Partitions bound how much of a consumer
/// group runs at once: a group holds one worker per partition. A single
/// subscriber handles envelopes one at a time whatever the partition count.
///
/// **At most once.** A topic is not durable. Nothing is written down,
/// nothing is retried, and an envelope published while nobody is subscribed
/// reaches nobody unless the topic replays.
///
/// **Nothing is lost quietly.** Every envelope the topic discards is
/// reported to the bus's listener with the reason. Under
/// `OverflowPolicy.suspend`, which is the default, nothing is discarded at
/// all: a publisher that can wait waits, and one that cannot is told it was
/// refused.
///
/// ## Getting one
///
/// Topics are declared through `eventBus` and resolved from the bus by
/// their key. They cannot be constructed and cannot be added to a running
/// bus.
final class EventTopic<T extends Event> implements Disposable {
  /// Starts the topic [_data] describes.
  @internal
  EventTopic(this._data) {
    _partitions = List<TopicPartition>.unmodifiable(
      List<TopicPartition>.generate(
        _data.partitions,
        (index) => TopicPartition(
          _data.bufferCapacity,
          _data.overflow,
          _report,
          (envelope) => _deliver(index, envelope),
        ),
      ),
    );
  }

  /// What this topic was declared to be.
  final EventTopicData<T> _data;

  /// The lanes envelopes are dispatched on.
  late final List<TopicPartition> _partitions;

  /// The broadcast subscribers attached right now.
  ///
  /// Copy-on-write: the list is never changed, only replaced, so a walk over
  /// it, even one that waits halfway through, is never disturbed by a
  /// subscriber attaching or detaching.
  var _subscribers = const <Subscriber>[];

  /// The consumer groups attached right now, replaced on every change like
  /// [_subscribers].
  var _groups = const <GroupMailboxes>[];

  /// The callers of [next] still waiting for their envelope, replaced on
  /// every change like [_subscribers].
  var _waiters = const <NextWaiter>[];

  /// The last envelopes delivered, which a new subscriber is handed first.
  final _replayCache = Queue<EventEnvelope<Event>>();

  /// How many envelopes the topic accepted.
  var _published = 0;

  /// How many times a consumer finished handling an envelope.
  var _delivered = 0;

  /// How many times a consumer threw.
  var _failed = 0;

  /// How many envelopes were never delivered.
  var _discarded = 0;

  /// Where the topic is in its life.
  BusState _lifecycle = BusState.running;

  /// The multiplier of FNV-1a.
  static const _fnvPrime = 0x01000193;

  /// The multiplier of the hash finaliser.
  static const _finaliserMultiplier = 0x85EBCA6B;

  /// The seed of the partition hash, chosen afresh for every topic.
  final int _partitionSeed = Random().nextInt(0xFFFFFFFF);

  /// How many subscriptions were given a generated name.
  var _anonymousConsumers = 0;

  /// The partition the next envelope without a key goes to.
  var _nextPartition = 0;

  /// This topic's name, unique on its bus.
  String get name => _data.name;

  /// The payload type this topic was declared to carry, which a bus checks a
  /// key against before resolving it.
  Type get eventType => _data.eventType;

  /// How many lanes this topic dispatches on.
  int get partitionCount => _data.partitions;

  /// Where this topic is in its life.
  BusState get state => _lifecycle;

  /// Whether an envelope published now would reach anybody.
  ///
  /// `true` while the topic is running and has a broadcast subscriber, a
  /// caller waiting in [next], a consumer group, or a replay cache that
  /// would hand the envelope to a subscriber attaching later.
  /// [subscriberCount] alone answers the first of those only.
  ///
  /// Meant to be asked before every publish by a publisher that would
  /// rather not build an event nobody receives. The answer is a moment: a
  /// subscriber can attach right after it, which is harmless for telemetry,
  /// which is what it is for.
  bool get hasConsumers {
    if (_lifecycle != BusState.running) {
      return false;
    }
    return _subscribers.isNotEmpty ||
        _waiters.isNotEmpty ||
        _groups.isNotEmpty ||
        _data.replay > 0;
  }

  /// How many broadcast subscribers are attached right now.
  ///
  /// A consumer group is one consumer however many workers it runs, and is
  /// not counted here.
  int get subscriberCount => _subscribers.length;

  /// What this topic has done so far, as of right now.
  ///
  /// Counters are kept whether or not anything is listening, so this
  /// answers without a listener having to be registered first.
  TopicMetrics get metrics => TopicMetrics(
    published: _published,
    delivered: _delivered,
    failed: _failed,
    dropped: _discarded,
    queueDepth: _partitions.fold(
      0,
      (depth, partition) => depth + partition.queueDepth,
    ),
    subscribers: _subscribers.length,
    groups: _groups.length,
  );

  /// Publishes [event], waiting for room if there is none.
  ///
  /// This is the publish to reach for. It applies backpressure rather than
  /// discarding, so a publisher that is faster than its subscribers is
  /// slowed down instead of quietly losing what it produced, whatever the
  /// overflow policy says, which governs only the publish that refuses to
  /// wait.
  ///
  /// [key] orders the envelope: envelopes sharing a key are delivered in
  /// publish order. [headers] travel beside the payload. When called while
  /// a consumer handles an envelope, the new envelope joins that chain: it
  /// takes that envelope's correlation identifier and names it as its cause.
  /// [causedBy] overrides that, and links a chain across a boundary the zone
  /// does not cross.
  ///
  /// The envelope records the principal the publishing code runs as, if
  /// there is one, as [EventEnvelope.principal]; [publishAs] states it
  /// explicitly instead.
  ///
  /// Returns the envelope that was published, or `null` if the topic was
  /// closed and refused it.
  ///
  /// Throws an [ArgumentError] if the topic requires a key and none was
  /// given.
  Future<EventEnvelope<T>?> publish(
    T event, {
    String? key,
    EventHeaders headers = EventHeaders.empty,
    EventEnvelope<Event>? causedBy,
  }) => publishAs(
    currentPrincipal(),
    event,
    key: key,
    headers: headers,
    causedBy: causedBy,
  );

  /// Publishes [event] on behalf of the explicitly named [principal],
  /// waiting for room if there is none.
  ///
  /// Everything else is as for [publish]. Use this where the publishing
  /// code does not run as the caller, such as a callback from a library
  /// that left the zone, or where the envelope must deliberately carry
  /// none: `null` publishes without a principal even inside a zone that has
  /// one.
  ///
  /// Returns the envelope that was published, or `null` if the topic was
  /// closed and refused it.
  ///
  /// Throws an [ArgumentError] if the topic requires a key and none was
  /// given.
  Future<EventEnvelope<T>?> publishAs(
    Principal? principal,
    T event, {
    String? key,
    EventHeaders headers = EventHeaders.empty,
    EventEnvelope<Event>? causedBy,
  }) async {
    final EventEnvelope<T>? envelope = _envelope(
      event,
      key,
      headers,
      causedBy,
      principal,
    );
    if (envelope == null) {
      return null;
    }
    final bool accepted = await _partitionFor(key).send(envelope);
    if (!accepted) {
      return null;
    }
    _accepted(envelope);
    return envelope;
  }

  /// Publishes [event] without ever waiting, applying the topic's overflow
  /// policy if there is no room.
  ///
  /// For a publisher that must not be slowed down by its subscribers: a UI
  /// event, a progress reading. The cost is that this can be refused, and
  /// the return value is the only thing that says so. [key], [headers] and
  /// [causedBy] mean what they mean for [publish], and like it this joins
  /// the chain of the envelope being handled.
  ///
  /// Returns the envelope that was published, or `null` if it was refused,
  /// in which case it has already been reported to the listener with the
  /// reason.
  ///
  /// Throws an [ArgumentError] if the topic requires a key and none was
  /// given.
  EventEnvelope<T>? tryPublish(
    T event, {
    String? key,
    EventHeaders headers = EventHeaders.empty,
    EventEnvelope<Event>? causedBy,
  }) => tryPublishAs(
    currentPrincipal(),
    event,
    key: key,
    headers: headers,
    causedBy: causedBy,
  );

  /// Publishes [event] on behalf of the explicitly named [principal],
  /// without ever waiting.
  ///
  /// Everything else is as for [tryPublish]; `null` publishes without a
  /// principal even inside a zone that has one.
  ///
  /// Returns the envelope that was published, or `null` if it was refused,
  /// in which case it has already been reported to the listener with the
  /// reason.
  ///
  /// Throws an [ArgumentError] if the topic requires a key and none was
  /// given.
  EventEnvelope<T>? tryPublishAs(
    Principal? principal,
    T event, {
    String? key,
    EventHeaders headers = EventHeaders.empty,
    EventEnvelope<Event>? causedBy,
  }) {
    final EventEnvelope<T>? envelope = _envelope(
      event,
      key,
      headers,
      causedBy,
      principal,
    );
    if (envelope == null) {
      return null;
    }
    if (!_partitionFor(key).offer(envelope)) {
      return null;
    }
    _accepted(envelope);
    return envelope;
  }

  /// Every envelope this topic delivers, as a stream.
  ///
  /// Each listener of the stream is a subscriber like any other and is
  /// replayed to on attaching. Prefer [subscribe] where the subscription
  /// has a lifetime of its own to manage; reach for this where the events
  /// are being combined with other streams. The stream closes once the
  /// topic does.
  ///
  /// Returns a stream that can be listened to any number of times.
  Stream<EventEnvelope<T>> events() =>
      Stream<EventEnvelope<T>>.multi((controller) {
        final EventSubscription subscription = subscribe(controller.add);
        controller.onCancel = subscription.cancel;
        unawaited(
          subscription.join().then<void>(
            (_) => controller.close(),
            onError: (Object error, StackTrace stackTrace) {
              controller
                ..addError(error, stackTrace)
                ..closeSync();
            },
          ),
        );
      });

  /// Runs [on] for every envelope, in publish order per key.
  ///
  /// A handler that throws does not end the subscription: the failure is
  /// reported and the next envelope is handled. [name] is what the
  /// subscription is reported under and defaults to a generated one;
  /// [onError] handles a failure of [on] and defaults to the topic's
  /// handler.
  ///
  /// Returns a handle on the subscription.
  EventSubscription subscribe(
    EventHandler<T> on, {
    String? name,
    EventErrorHandler? onError,
  }) => _attach(on, name, onError, (_) => true, once: false);

  /// Runs [on] for the envelopes that match [predicate].
  ///
  /// The predicate runs in the subscription's own task, so an envelope it
  /// rejects still counts as handed to this subscription. Filtering is about
  /// what the handler does, not about what the topic dispatches.
  ///
  /// Returns a handle on the subscription.
  EventSubscription subscribeWhere(
    bool Function(EventEnvelope<T> envelope) predicate,
    EventHandler<T> on, {
    String? name,
    EventErrorHandler? onError,
  }) => _attach(on, name, onError, predicate, once: false);

  /// Runs [on] for the envelopes whose payload is an [R], one variant of
  /// what the topic carries.
  ///
  /// What a sealed event hierarchy is for: a consumer that only cares about
  /// one variant says so once, and the payload arrives already narrowed. An
  /// [R] that is not a subtype of what the topic carries simply never
  /// matches.
  ///
  /// Returns a handle on the subscription.
  EventSubscription subscribeTo<R extends Event>(
    EventHandler<R> on, {
    String? name,
    EventErrorHandler? onError,
  }) => _attach(
    (envelope) => on(envelope.narrowed<R>()),
    name,
    onError,
    (envelope) => envelope.payload is R,
    once: false,
  );

  /// Runs [on] for the first envelope that matches [predicate], or the
  /// first one at all, and then stops.
  ///
  /// The subscription ends by itself once the handler has run, which makes
  /// [EventSubscription.join] a way to wait for that one delivery to have
  /// been handled.
  ///
  /// Returns a handle on the subscription.
  EventSubscription subscribeOnce(
    EventHandler<T> on, {
    bool Function(EventEnvelope<T> envelope)? predicate,
    String? name,
    EventErrorHandler? onError,
  }) => _attach(on, name, onError, predicate ?? (_) => true, once: true);

  /// Attaches the group [name], a set of workers that share this topic's
  /// envelopes out between them and run [on] for each.
  ///
  /// Each envelope reaches exactly one worker, which is what makes a group
  /// the way to *process* a topic rather than to watch it. The group runs
  /// one worker per partition, so its width is [partitionCount] and is
  /// decided by the topic. Envelopes sharing a key reach the same worker in
  /// publish order.
  ///
  /// A group cannot miss what is published immediately afterwards: its
  /// mailboxes exist from the moment this returns. A group is not replayed
  /// to; work already handed to somebody is not work for the group that
  /// just arrived. [onError] handles a failure of [on] and defaults to the
  /// topic's handler.
  ///
  /// A topic that is draining or closed takes no new group: attaching one
  /// there would hand back a handle over workers nothing will ever offer
  /// to, so it is refused instead.
  ///
  /// Returns a handle on the group.
  ///
  /// Throws a [StateError] if the topic is draining or closed.
  ConsumerGroup group(
    String name,
    EventHandler<T> on, {
    EventErrorHandler? onError,
  }) {
    if (_lifecycle != BusState.running) {
      throw StateError(
        'Topic "${_data.name}" is ${_lifecycle.name} and takes no new '
        'consumer group, so "$name" was not attached',
      );
    }
    final EventErrorHandler handle = onError ?? _data.onError;
    final mailboxes = GroupMailboxes(
      _data.partitions,
      _data.bufferCapacity,
      _report,
      (envelope) => _consume(envelope as EventEnvelope<T>, name, handle, on),
    );
    _groups = List<GroupMailboxes>.unmodifiable(<GroupMailboxes>[
      ..._groups,
      mailboxes,
    ]);
    return ConsumerGroup(name, mailboxes, () => _detachGroup(mailboxes));
  }

  /// Completes with the next envelope published that matches [predicate],
  /// or the next one at all.
  ///
  /// The next one, not the last one: this never sees the replay cache, so
  /// what comes back was published after this call.
  ///
  /// Returns the envelope.
  ///
  /// Throws a [StateError] if the topic closes before a matching envelope
  /// is delivered.
  Future<EventEnvelope<T>> next([
    bool Function(EventEnvelope<T> envelope)? predicate,
  ]) async {
    if (_lifecycle == BusState.closed) {
      throw StateError('Topic "$name" is closed');
    }
    final waiter = NextWaiter(
      (envelope) => predicate?.call(envelope as EventEnvelope<T>) ?? true,
    );
    _waiters = List<NextWaiter>.unmodifiable(<NextWaiter>[..._waiters, waiter]);
    final EventEnvelope<Event> envelope = await waiter.future;
    return envelope as EventEnvelope<T>;
  }

  /// Stops the topic at once, without delivering what it still holds.
  ///
  /// Everything buffered is reported to the listener as discarded,
  /// subscriptions and groups are stopped after the envelope they are
  /// handling, and every publication from now on is refused. Calling this
  /// again does nothing.
  @override
  void dispose() {
    if (_lifecycle == BusState.closed) {
      return;
    }
    _lifecycle = BusState.closed;
    for (final TopicPartition partition in _partitions) {
      partition.close();
    }
    for (final GroupMailboxes group in _groups) {
      group.close();
    }
    for (final TopicPartition partition in _partitions) {
      partition.disposeBuffered();
    }
    for (final GroupMailboxes group in _groups) {
      group
        ..disposeBuffered()
        ..cancel();
    }
    _stopConsumers();
  }

  /// Stops the topic after delivering everything it is still holding.
  ///
  /// Publications are refused from the moment this is called, and it then
  /// completes once every buffered envelope has been handed to the
  /// subscribers attached at that point and every group has handled what it
  /// was given. A subscriber is handed the last envelope but is not waited
  /// for while it handles it; join its subscription after this completes
  /// where that matters. Calling this again waits for the first call to
  /// finish.
  Future<void> drain() async {
    if (_lifecycle != BusState.running) {
      await _awaitSettled();
      return;
    }
    _lifecycle = BusState.draining;
    for (final TopicPartition partition in _partitions) {
      partition.close();
    }
    await _awaitSettled();
    _lifecycle = BusState.closed;
    _stopConsumers();
  }

  /// Completes once every partition is delivered and every group has
  /// handled what it holds.
  Future<void> _awaitSettled() async {
    await Future.wait(_partitions.map((partition) => partition.pump));
    for (final GroupMailboxes group in _groups) {
      group.close();
    }
    await Future.wait(_groups.map((group) => group.join()));
  }

  /// Cancels every subscription and fails every caller of [next].
  void _stopConsumers() {
    for (final Subscriber subscriber in _subscribers) {
      subscriber.cancel();
    }
    for (final NextWaiter waiter in _waiters) {
      waiter.abandon(
        StateError('Topic "$name" closed before a matching envelope arrived'),
      );
    }
    _waiters = const <NextWaiter>[];
  }

  /// Creates the envelope of [event], unless the topic no longer accepts
  /// publications.
  ///
  /// Returns the envelope, or `null` when the topic refused it, in which
  /// case it has been reported as discarded.
  ///
  /// Throws an [ArgumentError] if the topic requires a key and none was
  /// given.
  EventEnvelope<T>? _envelope(
    T event,
    String? key,
    EventHeaders headers,
    EventEnvelope<Event>? causedBy,
    Principal? principal,
  ) {
    if (_data.requiresKey && key == null) {
      throw ArgumentError.value(
        key,
        'key',
        'Topic "$name" requires every publication to carry a key',
      );
    }
    final EventEnvelope<Event>? cause = causedBy ?? handledEnvelope();
    final id = UuidV7.random();
    final envelope = EventEnvelope<T>(
      id: id,
      topic: name,
      key: key,
      correlationId: cause?.correlationId ?? id,
      causationId: cause?.id,
      headers: headers,
      payload: event,
      principal: principal,
    );
    if (_lifecycle == BusState.running) {
      return envelope;
    }
    _report(envelope, DropReason.closed);
    return null;
  }

  /// Hands [envelope], taken off [partition], to every group, every
  /// subscriber and every caller of [next] waiting for it.
  Future<void> _deliver(int partition, EventEnvelope<Event> envelope) async {
    _remember(envelope);
    final List<GroupMailboxes> groups = _groups;
    final List<Subscriber> subscribers = _subscribers;
    _wakeWaiters(envelope);
    for (final group in groups) {
      await group.offer(partition, envelope);
    }
    for (final subscriber in subscribers) {
      await subscriber.offer(envelope);
    }
  }

  /// Keeps [envelope] for the subscribers that attach later, if the topic
  /// replays.
  void _remember(EventEnvelope<Event> envelope) {
    if (_data.replay <= 0) {
      return;
    }
    _replayCache.add(envelope);
    while (_replayCache.length > _data.replay) {
      _replayCache.removeFirst();
    }
  }

  /// Completes every caller of [next] whose predicate [envelope] matches.
  void _wakeWaiters(EventEnvelope<Event> envelope) {
    final List<NextWaiter> waiting = _waiters;
    if (waiting.isEmpty) {
      return;
    }
    _waiters = List<NextWaiter>.unmodifiable(
      waiting.where((waiter) => !waiter.offer(envelope)),
    );
  }

  /// Takes [group] off the groups the topic sends to.
  void _detachGroup(GroupMailboxes group) {
    _groups = List<GroupMailboxes>.unmodifiable(
      _groups.where((attached) => !identical(attached, group)),
    );
  }

  /// Takes [subscriber] off the subscribers the topic sends to.
  void _detachSubscriber(Subscriber subscriber) {
    _subscribers = List<Subscriber>.unmodifiable(
      _subscribers.where((attached) => !identical(attached, subscriber)),
    );
  }

  /// Reports [envelope] as discarded for [reason].
  void _report(EventEnvelope<Event> envelope, DropReason reason) {
    _discarded++;
    _observe(() => _data.listener.onDropped(envelope, reason));
  }

  /// Counts and reports [envelope] as accepted.
  void _accepted(EventEnvelope<Event> envelope) {
    _published++;
    _observe(() => _data.listener.onPublished(envelope));
  }

  /// Runs a listener [notification], discarding anything it throws: there
  /// is nobody to report it to, and a publisher must not fail because a
  /// listener did.
  void _observe(void Function() notification) {
    try {
      notification();
    } on Object catch (_) {
      return;
    }
  }

  /// Picks the partition an envelope under [key] goes to: the same one for
  /// the same key, turn about without one.
  ///
  /// Returns the partition.
  TopicPartition _partitionFor(String? key) {
    if (_partitions.length == 1) {
      return _partitions.first;
    }
    if (key == null) {
      final int next = _nextPartition;
      _nextPartition = (next + 1) % _partitions.length;
      return _partitions[next];
    }
    final int spread = _spreadOf(key) & 0x7FFFFFFF;
    return _partitions[spread % _partitions.length];
  }

  /// Hashes [key] with a seed chosen afresh for this topic: FNV-1a over its
  /// code units, followed by a finaliser that spreads the bits.
  ///
  /// Which partition a key lands on is not part of the contract, and keys
  /// chosen to collide under `String.hashCode` do not all end up in one
  /// lane.
  ///
  /// Returns an unsigned 32-bit hash.
  int _spreadOf(String key) {
    int hash = _partitionSeed;
    for (final int codeUnit in key.codeUnits) {
      hash = _multiply32(hash ^ codeUnit, _fnvPrime);
    }
    hash = hash ^ (hash >>> 16);
    hash = _multiply32(hash, _finaliserMultiplier);
    return hash ^ (hash >>> 13);
  }

  /// Multiplies [left] and [right] modulo 2^32, exactly on every platform,
  /// the web included.
  ///
  /// Returns the unsigned 32-bit product.
  static int _multiply32(int left, int right) {
    final int leftLow = left & 0xFFFF;
    final int leftHigh = (left >>> 16) & 0xFFFF;
    final int rightLow = right & 0xFFFF;
    final int rightHigh = (right >>> 16) & 0xFFFF;
    final int cross = (leftHigh * rightLow + leftLow * rightHigh) & 0xFFFF;
    return (leftLow * rightLow + cross * 0x10000) & 0xFFFFFFFF;
  }

  /// Attaches a subscriber running [on] for the envelopes matching
  /// [predicate], ending after the first one when [once] is set.
  ///
  /// Returns a handle on the subscription.
  EventSubscription _attach(
    EventHandler<T> on,
    String? name,
    EventErrorHandler? onError,
    bool Function(EventEnvelope<T> envelope) predicate, {
    required bool once,
  }) {
    final String consumer = name ?? '${_data.name}#${_anonymousConsumers++}';
    final EventErrorHandler handle = onError ?? _data.onError;
    final subscriber = Subscriber(
      consumer,
      _data.replay,
      (envelope) async {
        final typed = envelope as EventEnvelope<T>;
        if (!predicate(typed)) {
          return false;
        }
        await _consume(typed, consumer, handle, on);
        return true;
      },
      _detachSubscriber,
      once: once,
    );
    if (_lifecycle == BusState.closed) {
      subscriber.refuse();
      return EventSubscription(subscriber);
    }
    _subscribers = List<Subscriber>.unmodifiable(<Subscriber>[
      ..._subscribers,
      subscriber,
    ]);
    subscriber.start(_replayCache);
    return EventSubscription(subscriber);
  }

  /// Runs [on] for [envelope] as the [consumer] it belongs to, wrapped in
  /// the topic's interceptors, counting and reporting the outcome and
  /// handing a failure to [onError].
  Future<void> _consume(
    EventEnvelope<T> envelope,
    String consumer,
    EventErrorHandler onError,
    EventHandler<T> on,
  ) async {
    try {
      await _asPublisher(
        envelope,
        () => handling(
          envelope,
          () => _proceed(0, envelope, consumer, () async {
            await on(envelope);
            _delivered++;
            _observe(() => _data.listener.onDelivered(envelope, consumer));
          }),
        ),
      );
    } on Object catch (failure, stackTrace) {
      _failed++;
      _observe(
        () => _data.listener.onFailed(envelope, consumer, failure, stackTrace),
      );
      await _observeAsync(() => onError(failure, stackTrace));
    }
  }

  /// Runs [body] as the principal that published [envelope], so that a
  /// consumer can ask who caused what it handles and anything it publishes
  /// carries the same caller on. An envelope without one leaves the
  /// consumer's own principal in place.
  ///
  /// Returns the future of [body].
  Future<void> _asPublisher(
    EventEnvelope<Event> envelope,
    Future<void> Function() body,
  ) {
    final Principal? principal = envelope.principal;
    if (principal == null) {
      return body();
    }
    return runAsPrincipal(principal, body);
  }

  /// Runs an error [handler], discarding anything it throws: the failure of
  /// the thing that reports failures has nowhere left to go, and the
  /// consumer carries on with its next envelope.
  Future<void> _observeAsync(FutureOr<void> Function() handler) async {
    try {
      await handler();
    } on Object catch (_) {
      return;
    }
  }

  /// Runs the interceptor at [index] around the rest of the chain, and
  /// [action] once every interceptor proceeded.
  Future<void> _proceed(
    int index,
    EventEnvelope<Event> envelope,
    String consumer,
    Future<void> Function() action,
  ) async {
    if (index == _data.interceptors.length) {
      await action();
      return;
    }
    await _data.interceptors[index](
      envelope,
      consumer,
      () => _proceed(index + 1, envelope, consumer, action),
    );
  }
}
