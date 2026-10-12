/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// What a topic has done, as of the moment it was asked.
///
/// A snapshot, not a live view: reading one costs nothing and holding one
/// shows what was true when it was taken. This is the answer for a health
/// endpoint or a scrape that runs on a timer, where registering a listener
/// to keep counters of its own would be a lot of machinery for a number
/// somebody wanted once a minute.
///
/// The counts are cumulative since the topic was created and never reset.
@immutable
final class TopicMetrics {
  /// Creates a snapshot of the counters of a topic.
  @internal
  const TopicMetrics({
    required this.published,
    required this.delivered,
    required this.failed,
    required this.dropped,
    required this.queueDepth,
    required this.subscribers,
    required this.groups,
  });

  /// How many envelopes the topic accepted.
  final int published;

  /// How many times a consumer finished handling one.
  ///
  /// Counted per consumer, so a topic with three subscribers counts three
  /// for one publication, which is what makes comparing it against
  /// [published] meaningful.
  final int delivered;

  /// How many times a consumer threw.
  final int failed;

  /// How many envelopes were never delivered to anybody.
  ///
  /// Anything above zero on a topic that is supposed to be lossless is the
  /// number to alert on.
  final int dropped;

  /// How many envelopes are waiting across every partition right now.
  ///
  /// Unlike the others this is a level rather than a count, and a level
  /// that keeps climbing is a topic whose consumers are slower than its
  /// publishers.
  final int queueDepth;

  /// How many broadcast subscribers are attached.
  final int subscribers;

  /// How many consumer groups are attached.
  final int groups;

  /// Renders every counter.
  @override
  String toString() =>
      'TopicMetrics(published=$published, delivered=$delivered, '
      'failed=$failed, dropped=$dropped, queueDepth=$queueDepth, '
      'subscribers=$subscribers, groups=$groups)';
}
