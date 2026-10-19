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
