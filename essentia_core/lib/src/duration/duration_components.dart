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

/// A duration split into whole days, hours, minutes and seconds and the
/// microseconds of the last second.
///
/// What `Duration.toComponents` returns. Every component carries the sign
/// of the duration.
typedef DurationComponents = ({
  int days,
  int hours,
  int minutes,
  int seconds,
  int microseconds,
});
