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

import 'package:meta/meta.dart';

/// What a relayed stream does with the events of its source, created once
/// for every listener.
///
/// `onData` receives every element of the source, `onDone` runs when the
/// source ends and `onCancel` when the listener cancels. Errors of the
/// source are always passed on unchanged.
@internal
typedef RelayHandlers<T> = ({
  void Function(T element) onData,
  void Function() onDone,
  void Function() onCancel,
});
