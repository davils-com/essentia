/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something that assembles a value of type [T] from what a configuration
/// block set on it.
///
/// A builder is mutable and short-lived: it exists for the duration of one
/// block, and the value it produces is immutable. Most builders want
/// `ValidatingBuilder` instead, which adds validation to this contract.
abstract interface class Builder<T> {
  /// Produces the value.
  ///
  /// Returns the built value.
  T build();
}
