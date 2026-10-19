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

/// One thing the application does, expressed as the function it is: it
/// takes an input of type [I] and produces an output of type [O].
///
/// A use case takes what it needs, does the work, and hands back the
/// answer. Everything else about it, which repositories it holds, whether
/// it caches, whether it talks to three services or none, is its own
/// business and does not appear in the type.
///
/// ```dart
/// final class RenameWorkspace implements UseCase<RenameInput, Workspace> {
///   const RenameWorkspace(this._workspaces);
///
///   final WorkspaceRepository _workspaces;
///
///   @override
///   Future<Workspace> call(RenameInput input) =>
///       _workspaces.rename(input.id, input.name);
/// }
///
/// final Workspace renamed = await renameWorkspace(RenameInput(id, 'Staging'));
/// ```
///
/// The input is a single parameter rather than a parameter list, because a
/// use case gains parameters over its life and a named input type absorbs
/// that without breaking a call site or silently swapping two arguments of
/// the same type.
///
/// Invocation is asynchronous, because application behaviour reaches
/// storage, the network or the clock. A use case that needs no input is a
/// use case of `void` and is run with `invoke()`.
///
/// ## The one layer with no bound on it
///
/// A use case may consult two repositories or none, and what it hands back
/// is as often a `bool` as a domain value. What holds the layer in place
/// instead is the direction of the dependencies: a use case takes
/// repositories; nothing takes a use case. A use case that has a
/// `DataSource` or a `DataTransferObject` in its signature has reached
/// past the layer that exists to keep those out of it.
abstract interface class UseCase<I, O> {
  /// Runs the use case with [input].
  ///
  /// Returns what it produced.
  Future<O> call(I input);
}
