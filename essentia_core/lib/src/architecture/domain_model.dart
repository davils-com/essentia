/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something the program is about, in the program's own words.
///
/// A domain model is what the rest of the application reasons with: a
/// workspace, a licence, a session. It is decided by the program rather than
/// by a schema, a table or a screen, which is what lets all three change
/// without reaching the code that means something.
///
/// ```dart
/// final class Workspace implements DomainModel {
///   const Workspace(this.id, this.name, {this.pinnedAt});
///
///   final WorkspaceId id;
///   final String name;
///   final DateTime? pinnedAt;
///
///   bool get isPinned => pinnedAt != null;
/// }
/// ```
///
/// ## Why it is a type at all
///
/// This is the anchor the rest of the layering contracts are pinned to. A
/// `DataTransferObject` must name the domain model it stands for, a
/// `Repository` must name the one it serves, and a `Mapper` is about
/// exactly one pairing of the two. None of those can be declared without a
/// domain model existing first, which is the point: the layer that most
/// often gets skipped, transport shapes handed straight to the screen, is
/// the one the type checker now asks for.
///
/// ## What belongs in one
///
/// Data and the things that are true of that data on its own: `isPinned`
/// above reads a field this type already has. Anything needing a
/// collaborator, such as loading, storing or calling, belongs to a
/// `Repository` or a `UseCase`.
///
/// A domain model that has invariants states them by also implementing
/// `Validatable`, which puts it in the same reporting model as everything
/// else Essentia validates. Implementing this adds nothing to a type: it
/// says which layer the type belongs to and stops there.
abstract interface class DomainModel {}
