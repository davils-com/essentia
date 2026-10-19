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

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

import 'form_slot.dart';

/// A value that arrived without a builder and states its own invariants.
@immutable
final class WorkspaceForm implements Validatable {
  /// Creates the form, defaulting every part to something valid.
  const WorkspaceForm({
    this.name = 'staging',
    this.owner = 'nils',
    this.slots = const <FormSlot>[FormSlot('first', 1)],
  });

  /// The code of the warning about too many slots.
  static const tooManySlots = ViolationCode('test.workspace.too-many-slots');

  /// The name of the workspace.
  final String name;

  /// Who owns the workspace.
  final String owner;

  /// The slots of the workspace.
  final List<FormSlot> slots;

  /// States what is wrong with the form.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('must not be blank', property: 'name');
    }
    if (owner.trim().isEmpty) {
      scope.fail('must not be blank', property: 'owner');
    }
    scope.each('slots', slots, (it, slot) {
      if (slot.size < 1) {
        it.fail('must be at least 1', property: 'size');
      }
    });
    if (slots.length > 2) {
      scope.warn(
        'more than two slots is unusual',
        property: 'slots',
        code: tooManySlots,
      );
    }
  }
}
