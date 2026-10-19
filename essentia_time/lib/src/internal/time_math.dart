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

/// The integer quotient of [dividend] by a positive [divisor], rounded
/// towards negative infinity.
int floorDiv(int dividend, int divisor) =>
    (dividend - dividend % divisor) ~/ divisor;

/// The remainder of [dividend] by a positive [divisor], never negative.
int floorMod(int dividend, int divisor) => dividend % divisor;

/// The number of nanoseconds in a second.
const nanosPerSecond = 1000000000;

/// The number of seconds in a day.
const secondsPerDay = 86400;

/// The number of nanoseconds in a day, exact on every platform.
const nanosPerDay = 86400000000000;
