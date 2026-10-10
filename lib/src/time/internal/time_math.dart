/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The integer quotient of [dividend] by a positive [divisor], rounded
/// towards negative infinity, as Kotlin's `floorDiv`.
int floorDiv(int dividend, int divisor) =>
    (dividend - dividend % divisor) ~/ divisor;

/// The remainder of [dividend] by a positive [divisor], never negative, as
/// Kotlin's `mod`.
int floorMod(int dividend, int divisor) => dividend % divisor;

/// The number of nanoseconds in a second.
const nanosPerSecond = 1000000000;

/// The number of seconds in a day.
const secondsPerDay = 86400;

/// The number of nanoseconds in a day, exact on every platform.
const nanosPerDay = 86400000000000;
