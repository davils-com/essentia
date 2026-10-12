/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
