/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/cardinality.dart';
import 'package:essentia/src/arguments/conversion_exception.dart';
import 'package:essentia/src/arguments/lex_result.dart';
import 'package:essentia/src/arguments/masking.dart';
import 'package:essentia/src/arguments/parameter_snapshot.dart';
import 'package:essentia/src/arguments/parameter_spec.dart';
import 'package:essentia/src/arguments/parameter_violation.dart';
import 'package:essentia/src/arguments/parameter_violation_codes.dart';
import 'package:essentia/src/arguments/raw_occurrence.dart';
import 'package:essentia/src/arguments/value_origin.dart';
import 'package:essentia/src/validation/severity.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:essentia/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// Stands for a value that could not be used, distinct from `null`.
final _noValue = Object();

/// Turns what the command line, the environment and the value sources
/// supplied into one value per parameter, collecting every problem on the
/// way.
@internal
final class Resolver {
  /// Creates a resolver for [_specs], checking the mutually exclusive
  /// [_exclusiveGroups] and the [_dependencies], all by ordinal.
  const Resolver(this._specs, this._exclusiveGroups, this._dependencies);

  /// The registered parameters, by ordinal.
  final List<ParameterSpec> _specs;

  /// The groups of parameters of which at most one may be given.
  final List<List<int>> _exclusiveGroups;

  /// The parameters that need others, and the ones they need.
  final List<(int, List<int>)> _dependencies;

  /// Resolves every parameter from [lexed] and the values of [external],
  /// which the environment and the value sources supplied by ordinal,
  /// reporting the [sourceFailures] of sources that could not answer
  /// alongside.
  ///
  /// Returns the snapshot, or `null` when any error was found, together
  /// with every violation.
  (ParameterSnapshot?, List<ParameterViolation>) resolve(
    LexResult lexed,
    Map<int, (String, ValueOrigin)> external, [
    List<ParameterViolation> sourceFailures = const <ParameterViolation>[],
  ]) {
    final violations = <ParameterViolation>[
      ...lexed.violations,
      ...sourceFailures,
    ];
    final values = List<Object?>.filled(_specs.length, null);
    final origins = List<ValueOrigin?>.filled(_specs.length, null);
    final provided = List<bool>.filled(_specs.length, false);
    for (final ParameterSpec spec in _specs) {
      final List<RawOccurrence> occurrences =
          lexed.occurrences[spec.ordinal] ?? const <RawOccurrence>[];
      final (String, ValueOrigin)? fallback = external[spec.ordinal];
      final bool wasGiven = occurrences.isNotEmpty || fallback != null;
      provided[spec.ordinal] = wasGiven;
      final String? advice = spec.info.deprecation;
      if (wasGiven && advice != null) {
        violations.add(DeprecatedParameter(spec.info, advice));
      }
      final (Object? value, ValueOrigin? origin) = _resolveSlot(
        spec,
        occurrences,
        fallback,
        violations,
      );
      values[spec.ordinal] = value;
      origins[spec.ordinal] = origin;
    }
    violations.addAll(_checkGroups(provided));
    final bool failed = violations.any(
      (violation) => violation.severity == Severity.error,
    );
    if (failed) {
      return (null, violations);
    }
    final snapshot = ParameterSnapshot(
      values,
      origins,
      lexed.rest,
      lexed.unknown,
      List<Violation>.of(violations),
    );
    return (snapshot, violations);
  }

  /// Resolves the value of [spec] from its [occurrences], else from its
  /// [fallback], else from what the parameter does when it is absent.
  ///
  /// Returns the value and where it came from.
  (Object?, ValueOrigin?) _resolveSlot(
    ParameterSpec spec,
    List<RawOccurrence> occurrences,
    (String, ValueOrigin)? fallback,
    List<ParameterViolation> violations,
  ) {
    if (occurrences.isNotEmpty) {
      return _convertAll(
        spec,
        occurrences.map((occurrence) => occurrence.raw).toList(),
        ValueOrigin.commandLine,
        violations,
      );
    }
    if (fallback != null) {
      final (String raw, ValueOrigin origin) = fallback;
      return _convertAll(spec, <String>[raw], origin, violations);
    }
    return _absent(spec, violations);
  }

  /// Resolves [spec], which no source supplied.
  ///
  /// Returns its default, an empty value, or nothing after reporting it as
  /// missing.
  (Object?, ValueOrigin?) _absent(
    ParameterSpec spec,
    List<ParameterViolation> violations,
  ) {
    switch (spec.cardinality) {
      case Cardinality.required:
        violations.add(MissingRequiredParameter(spec.info));
        return (null, null);
      case Cardinality.defaulted:
        final Object? checked = _admitDefault(
          spec,
          spec.defaultValue,
          violations,
        );
        if (identical(checked, _noValue)) {
          return (null, null);
        }
        return (checked, ValueOrigin.defaulted);
      case Cardinality.multiple:
        return (_defaultElements(spec, violations), ValueOrigin.defaulted);
      case Cardinality.optional:
        return (null, null);
    }
  }

  /// Checks every element of the default list of [spec].
  ///
  /// Returns the usable elements.
  List<Object?> _defaultElements(
    ParameterSpec spec,
    List<ParameterViolation> violations,
  ) {
    final Object? declared = spec.defaultValue;
    if (declared is! List<Object?>) {
      return spec.collect(const <Object?>[]);
    }
    return spec.collect(
      <Object?>[
        for (final Object? element in declared)
          _admitDefault(spec, element, violations),
      ].where((element) => !identical(element, _noValue)).toList(),
    );
  }

  /// Converts every one of [raws] that came from [origin].
  ///
  /// Returns the value, a list for a parameter that collects, and its
  /// origin.
  (Object?, ValueOrigin?) _convertAll(
    ParameterSpec spec,
    List<String> raws,
    ValueOrigin origin,
    List<ParameterViolation> violations,
  ) {
    final collects = spec.cardinality == Cardinality.multiple;
    if (!collects && raws.length > 1) {
      violations.add(RepeatedParameter(spec.info, raws.length));
    }
    final List<Object?> usable = <Object?>[
      for (final String piece in _splitPieces(spec, raws))
        _convertOne(spec, piece, origin, violations),
    ].where((value) => !identical(value, _noValue)).toList();
    if (collects) {
      return (spec.collect(usable), origin);
    }
    return (usable.isEmpty ? null : usable.first, origin);
  }

  /// Splits each of [raws] on the delimiter of [spec], if it has one.
  ///
  /// An empty piece, from a trailing delimiter or two in a row, is dropped
  /// rather than handed to the converter.
  ///
  /// Returns the pieces.
  List<String> _splitPieces(ParameterSpec spec, List<String> raws) {
    final String? delimiter = spec.splitDelimiter;
    if (delimiter == null) {
      return raws;
    }
    return <String>[
      for (final raw in raws)
        ...raw.split(delimiter).where((piece) => piece.isNotEmpty),
    ];
  }

  /// Converts and checks [raw].
  ///
  /// A converter that throws an [Exception] other than a
  /// [ConversionException] is reported with a generic reason, because its
  /// own message is not written for the report and may quote the value.
  ///
  /// Returns the value, or the marker of an unusable one.
  Object? _convertOne(
    ParameterSpec spec,
    String raw,
    ValueOrigin origin,
    List<ParameterViolation> violations,
  ) {
    final Object? converted;
    try {
      converted = spec.converter(raw);
    } on ConversionException catch (failure) {
      violations.add(
        _conversionFailure(spec, origin, raw, failure.message, failure),
      );
      return _noValue;
    } on Exception catch (failure) {
      violations.add(
        _conversionFailure(
          spec,
          origin,
          raw,
          'could not be read as ${spec.info.typeName}',
          failure,
        ),
      );
      return _noValue;
    }
    final Object? admitted = _constrain(
      spec,
      converted,
      raw,
      origin,
      violations,
    );
    if (identical(admitted, _noValue)) {
      return _noValue;
    }
    return _validate(spec, admitted, origin, violations);
  }

  /// Holds the declared default [value] of [spec] to the constraint of its
  /// conversion and to its rules, as if it had been given.
  ///
  /// Returns the value, or the marker of an unusable one.
  Object? _admitDefault(
    ParameterSpec spec,
    Object? value,
    List<ParameterViolation> violations,
  ) {
    final Object? admitted = _constrain(
      spec,
      value,
      '$value',
      ValueOrigin.defaulted,
      violations,
    );
    if (identical(admitted, _noValue)) {
      return _noValue;
    }
    return _validate(spec, admitted, ValueOrigin.defaulted, violations);
  }

  /// Runs the constraint of [spec] on [value], which is reported as
  /// [rendered] if it is refused.
  ///
  /// Returns the value, or the marker of an unusable one.
  Object? _constrain(
    ParameterSpec spec,
    Object? value,
    String rendered,
    ValueOrigin origin,
    List<ParameterViolation> violations,
  ) {
    final void Function(Object? value)? constraint = spec.constraint;
    if (constraint == null) {
      return value;
    }
    try {
      constraint(value);
    } on ConversionException catch (failure) {
      violations.add(
        _conversionFailure(spec, origin, rendered, failure.message, failure),
      );
      return _noValue;
    }
    return value;
  }

  /// Reports that [raw] of [spec] from [origin] could not be used for
  /// [reason], because of [cause].
  ///
  /// Returns the violation, with the value masked when the parameter is
  /// sensitive.
  ConversionFailure _conversionFailure(
    ParameterSpec spec,
    ValueOrigin origin,
    String raw,
    String reason,
    Object cause,
  ) => ConversionFailure(
    spec.info,
    origin,
    spec.info.isSensitive ? mask : raw,
    reason,
    cause: cause,
  );

  /// Runs every rule of [spec] on [value].
  ///
  /// Returns the value, or the marker of an unusable one when a rule
  /// reported an error.
  Object? _validate(
    ParameterSpec spec,
    Object? value,
    ValueOrigin origin,
    List<ParameterViolation> violations,
  ) {
    if (spec.validators.isEmpty) {
      return value;
    }
    final scope = ValidationScope(
      ViolationPath.root,
      ParameterViolationCodes.validationFailed,
    );
    for (final void Function(ValidationScope scope, Object? value) rule
        in spec.validators) {
      rule(scope, value);
    }
    final List<Violation> reported = scope.violations();
    for (final failure in reported) {
      violations.add(
        ValidationFailure(
          spec.info,
          origin,
          failure.message,
          code: failure.code,
          severity: failure.severity,
        ),
      );
    }
    final bool failed = reported.any(
      (failure) => failure.severity == Severity.error,
    );
    if (failed) {
      return _noValue;
    }
    return value;
  }

  /// Checks the groups and dependencies against what was [provided].
  ///
  /// Returns the violations.
  List<ParameterViolation> _checkGroups(List<bool> provided) {
    final violations = <ParameterViolation>[];
    for (final List<int> group in _exclusiveGroups) {
      final List<int> given = group
          .where((ordinal) => provided[ordinal])
          .toList();
      if (given.length > 1) {
        violations.add(
          MutuallyExclusiveParameters([
            for (final ordinal in given) _specs[ordinal].info,
          ]),
        );
      }
    }
    for (final (int subject, List<int> requires) in _dependencies) {
      if (!provided[subject]) {
        continue;
      }
      final List<int> missing = requires
          .where((ordinal) => !provided[ordinal])
          .toList();
      if (missing.isNotEmpty) {
        violations.add(
          MissingDependency(_specs[subject].info, [
            for (final ordinal in missing) _specs[ordinal].info,
          ]),
        );
      }
    }
    return violations;
  }
}
