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

/// What a schema does with arguments it does not declare.
enum UnknownArgumentPolicy {
  /// An undeclared argument is a violation, reported with the closest
  /// declared name when there is one.
  ///
  /// This is the default, because the usual cause is a typo, and a program
  /// that silently ignores `--porrt=9090` starts on the wrong port instead
  /// of saying so.
  reject,

  /// An undeclared argument is collected into `Parameters.unknown` and
  /// loading continues.
  ///
  /// Use this when the program forwards arguments it does not own to
  /// something else.
  collect,
}
