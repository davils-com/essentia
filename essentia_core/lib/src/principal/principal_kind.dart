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

/// What sort of caller a `Principal` names.
///
/// An audit trail and an access rule treat a person, a service account and
/// the process itself differently, and without this they could only guess
/// from the id.
///
/// There is deliberately no `anonymous`. A caller nobody established is an
/// absent principal - `currentPrincipal()` answering `null` - and a constant
/// for it would compare unequal to every real kind exactly as a known one
/// does, so code could not tell "definitely not a user" from "nobody said".
/// The same reasoning keeps `unknown` out of `Platform`.
enum PrincipalKind {
  /// A person, established by a login or a token issued to them.
  user,

  /// Another program: a service account, a client credential, a peer in a
  /// service mesh.
  service,

  /// This process itself, doing work nobody asked for from outside: a
  /// scheduled job, a migration, a startup task. Name it rather than leave
  /// the zone empty, so an audit record says the system did it instead of
  /// saying nothing.
  system,
}
