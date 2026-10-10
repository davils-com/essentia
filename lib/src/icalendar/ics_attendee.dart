/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_participation.dart';
import 'package:essentia/src/icalendar/ics_role.dart';
import 'package:essentia/src/icalendar/ics_user_type.dart';
import 'package:meta/meta.dart';

/// Someone or something invited to an entry, the `ATTENDEE` of RFC 5545.
@immutable
final class IcsAttendee {
  /// The attendee at [address], usually `mailto:` and an email address.
  IcsAttendee(
    this.address, {
    this.name,
    this.role,
    this.participation,
    this.userType,
    this.rsvp = false,
    List<String> delegatedTo = const <String>[],
    List<String> delegatedFrom = const <String>[],
    this.sentBy,
    List<String> members = const <String>[],
  }) : delegatedTo = List<String>.unmodifiable(delegatedTo),
       delegatedFrom = List<String>.unmodifiable(delegatedFrom),
       members = List<String>.unmodifiable(members);

  /// The calendar address, such as `mailto:ada@example.com`.
  final String address;

  /// The common name, `CN`.
  final String? name;

  /// The part the attendee plays, `ROLE`.
  final IcsRole? role;

  /// The answer to the invitation, `PARTSTAT`.
  final IcsParticipation? participation;

  /// The kind of attendee, `CUTYPE`.
  final IcsUserType? userType;

  /// Whether an answer is expected, `RSVP`.
  final bool rsvp;

  /// Whom the attendee handed on to, `DELEGATED-TO`.
  final List<String> delegatedTo;

  /// Who handed on to the attendee, `DELEGATED-FROM`.
  final List<String> delegatedFrom;

  /// Who acts for the attendee, `SENT-BY`.
  final String? sentBy;

  /// The groups the attendee belongs to, `MEMBER`.
  final List<String> members;

  /// The email address of [address] without its `mailto:`.
  String get email => address.toLowerCase().startsWith('mailto:')
      ? address.substring(7)
      : address;

  /// Whether [other] is the same attendee.
  @override
  bool operator ==(Object other) =>
      other is IcsAttendee && other.toString() == toString();

  /// A hash of the attendee.
  @override
  int get hashCode => toString().hashCode;

  /// Describes the attendee.
  @override
  String toString() =>
      'IcsAttendee($address, $name, $role, $participation, $userType, '
      '$rsvp, $delegatedTo, $delegatedFrom, $sentBy, $members)';
}
