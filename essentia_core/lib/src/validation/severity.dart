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

/// How much weight a violation carries.
enum Severity {
  /// Something worth saying that does not stop anything.
  ///
  /// A report containing only warnings is still valid, and the object it
  /// describes is still built. Warnings are for what is legal but probably
  /// not meant: a deprecated parameter that is still honoured, a setting
  /// that will be expensive in production.
  warning,

  /// Something that makes the result unusable.
  ///
  /// A single error invalidates the whole report; the object is not built
  /// and nothing partially configured escapes.
  error,
}
