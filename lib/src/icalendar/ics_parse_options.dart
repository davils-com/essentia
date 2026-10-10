/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// How strictly `IcsCodec.decode` reads a file.
@immutable
final class IcsParseOptions {
  /// Strict unless [lenient].
  const IcsParseOptions({this.lenient = false});

  /// Whether to read past problems and report them as warnings instead of
  /// refusing the file: lines that are no content lines, components left
  /// open, values that cannot be read, a missing `UID`, and floating times
  /// in a file that names its zone in `X-WR-TIMEZONE`.
  final bool lenient;

  /// Whether [other] reads as strictly.
  @override
  bool operator ==(Object other) =>
      other is IcsParseOptions && other.lenient == lenient;

  /// A hash of the options.
  @override
  int get hashCode => lenient.hashCode;
}
