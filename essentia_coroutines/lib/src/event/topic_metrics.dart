/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
