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

/// Why an envelope was never delivered.
///
/// Essentia discards an envelope in exactly these cases and reports every
/// one of them to `EventListener.onDropped`. The reason is what tells apart
/// a topic that is too slow from one that was shut down under load, which
/// are the same symptom and different problems.
///
/// This is also the seam a retry or a dead-letter store attaches to. The
/// bus deliberately does neither: both are policy that belongs to a caller's
/// domain.
enum DropReason {
  /// The partition's buffer was full and the policy discarded this
  /// envelope.
  ///
  /// Under `OverflowPolicy.dropLatest` this is the envelope just published;
  /// under `OverflowPolicy.dropOldest` it is the one that had been waiting
  /// longest. Either way the topic is not keeping up with its publishers.
  overflow,

  /// The topic was already closed when the envelope was published.
  ///
  /// A publisher that outlives its bus. Normal during shutdown, a defect at
  /// any other time.
  closed,

  /// The envelope was still buffered when the topic was disposed without
  /// draining.
  ///
  /// Expected of an abrupt shutdown. Drain instead to deliver these.
  disposed,
}
