/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
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
