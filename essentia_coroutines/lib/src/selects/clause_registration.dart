/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/selects/select_implementation.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// One clause of a running select: how it registers, what it selected
/// with, and what it has to undo once the select is over.
@internal
final class ClauseRegistration<R> implements SelectInstance {
  /// Creates the registration of a clause of [_select], registered by
  /// [_register] and finished by [_complete].
  ClauseRegistration(this._select, this._register, this._complete);

  /// The select the clause belongs to.
  final SelectImplementation<R> _select;

  /// Registers the clause.
  final void Function(SelectInstance select) _register;

  /// Turns what the clause selected with into the result of the select.
  final FutureOr<R> Function(Object? result) _complete;

  /// What to undo once the select is over.
  final _handles = <Disposable>[];

  /// What the clause selected with, `null` until it won.
  ({Object? result})? _selected;

  /// See [SelectInstance.owner].
  @override
  Object get owner => _select;

  /// Registers the clause with the select.
  void register() => _register(this);

  /// See [SelectInstance.trySelect].
  @override
  bool trySelect(Object? result, {void Function()? onCancellation}) {
    if (_select.isOver) {
      return false;
    }
    _selected = (result: result);
    _select.selected(this, onCancellation);
    return true;
  }

  /// See [SelectInstance.disposeOnCompletion].
  @override
  void disposeOnCompletion(Disposable handle) {
    if (_select.isOver) {
      handle.dispose();
      return;
    }
    _handles.add(handle);
  }

  /// Undoes the registration.
  void dispose() {
    final handles = List<Disposable>.of(_handles);
    _handles.clear();
    for (final handle in handles) {
      handle.dispose();
    }
  }

  /// Runs the block of the clause with what it selected.
  ///
  /// Returns the result of the block.
  ///
  /// Throws the failure the clause selected with, or what the block throws.
  FutureOr<R> complete() => _complete(_selected?.result);
}
