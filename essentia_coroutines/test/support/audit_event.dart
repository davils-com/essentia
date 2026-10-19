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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:meta/meta.dart';

/// Something worth auditing, the second payload type of the event tests.
@immutable
final class AuditEvent implements Event {
  /// Creates the audit record of [action].
  const AuditEvent(this.action);

  /// What was done.
  final String action;

  /// Two records are equal when their actions are.
  @override
  bool operator ==(Object other) =>
      other is AuditEvent && action == other.action;

  /// The hash of the action.
  @override
  int get hashCode => action.hashCode;

  /// Renders the record with its field.
  @override
  String toString() => 'AuditEvent(action=$action)';
}
