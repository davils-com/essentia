/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Who organises an entry, the `ORGANIZER` of RFC 5545.
@immutable
final class IcsOrganizer {
  /// The organiser at [address], with a common [name] and someone who
  /// acts for them, [sentBy].
  const IcsOrganizer(this.address, {this.name, this.sentBy});

  /// The calendar address, such as `mailto:ada@example.com`.
  final String address;

  /// The common name, `CN`.
  final String? name;

  /// Who acts for the organiser, `SENT-BY`.
  final String? sentBy;

  /// The email address of [address] without its `mailto:`.
  String get email => address.toLowerCase().startsWith('mailto:')
      ? address.substring(7)
      : address;

  /// Whether [other] is the same organiser.
  @override
  bool operator ==(Object other) =>
      other is IcsOrganizer &&
      other.address == address &&
      other.name == name &&
      other.sentBy == sentBy;

  /// A hash of the organiser.
  @override
  int get hashCode => Object.hash(address, name, sentBy);

  /// Describes the organiser.
  @override
  String toString() => 'IcsOrganizer($address, $name, $sentBy)';
}
