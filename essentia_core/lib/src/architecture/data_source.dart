/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The edge of the program, where data is read from or written to something
/// the program does not own: a database, a file, an HTTP API, the keychain.
///
/// A data source speaks the vocabulary of whatever is on the other side of
/// it and nothing else. It hands back rows, documents, response bodies and
/// the `DataTransferObject` instances built from them, never a
/// `DomainModel`, because turning one into the other is the job of the
/// layer above it. It is also the only layer allowed to fail for reasons
/// the domain has no word for, such as a socket that closed or a file that
/// is not there, which is exactly why it is worth naming as its own layer.
///
/// ```dart
/// abstract interface class WorkspaceDataSource implements DataSource {
///   Future<List<WorkspaceDto>> findAll();
///   Future<bool> upsert(WorkspaceDto workspace);
/// }
/// ```
///
/// Declare the interface in terms of the store and implement it once per
/// store. The interface is what a `Repository` is written against and what
/// a test replaces.
///
/// ## Why this one has no type parameter
///
/// A `Repository` names the `DomainModel` it serves. A data source has no
/// equivalent: one hands back a transport shape, the next a scalar, the
/// next runs a transaction for the others and hands back nothing at all. A
/// parameter that fits the first would be a fiction on the other two.
///
/// Implementing this interface adds nothing to a type. The marker names the
/// layer a type belongs to and stops there; it hands out no logger and
/// enrols the type in no container.
abstract interface class DataSource {}
