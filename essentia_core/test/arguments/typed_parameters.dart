/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'colour.dart';

/// A schema with one parameter per conversion Essentia ships, and one the
/// schema converts itself.
final class TypedParameters extends Parameters {
  /// An integer.
  final Parameter<int?> count = parameter(<String>['--count']).integer();

  /// An integer beyond the 32-bit range.
  final Parameter<int?> size = parameter(<String>['--size']).integer();

  /// A decimal number.
  final Parameter<double?> ratio = parameter(<String>['--ratio']).decimal();

  /// A boolean written out.
  final Parameter<bool?> enabled = parameter(<String>['--enabled']).boolean();

  /// An enum constant.
  final Parameter<Colour?> colour = parameter(<String>['--colour'])
      .enumeration(Colour.values);

  /// An application mode.
  final Parameter<ApplicationMode?> mode = parameter(<String>['--mode'])
      .applicationMode();

  /// A duration.
  final Parameter<Duration?> timeout = parameter(<String>['--timeout'])
      .duration();

  /// A URI.
  final Parameter<Uri?> endpoint = parameter(<String>['--endpoint']).uri();

  /// One of two declared choices.
  final Parameter<String?> level = parameter(<String>['--level'])
      .choice(<String>['low', 'high']);

  /// Values split on commas.
  final Parameter<List<String>> tags = parameter(<String>['--tags']).split(',');

  /// A path that is not checked.
  final Parameter<String?> directory = parameter(<String>['--directory'])
      .path();

  /// An identifier the schema converts with a converter of its own.
  final Parameter<String?> identifier = parameter(<String>['--id'])
      .convert<String>('identifier', (raw) {
        if (!raw.startsWith('id-')) {
          throw const ConversionException("must start with 'id-'");
        }
        return raw.substring('id-'.length);
      });

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    count,
    size,
    ratio,
    enabled,
    colour,
    mode,
    timeout,
    endpoint,
    level,
    tags,
    directory,
    identifier,
  ];
}
