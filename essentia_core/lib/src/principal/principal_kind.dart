/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
