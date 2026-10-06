/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/parameter_info.dart';
import 'package:essentia/src/arguments/parameter_violation_codes.dart';
import 'package:essentia/src/arguments/value_origin.dart';
import 'package:essentia/src/validation/severity.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:essentia/src/validation/violation_code.dart';
import 'package:essentia/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// One reason why loading the parameters failed.
///
/// Loading never stops at the first problem. Every violation found in one
/// pass is collected and reported together through a `ParameterException`,
/// because a caller who has three parameters wrong should learn that once
/// rather than three runs in a row.
///
/// This is a closed domain: the set of things that can go wrong is fixed by
/// the loader, and a `switch` over it is exhaustive by design. It is at the
/// same time an ordinary [Violation], so a parameter problem and a
/// configuration problem render the same way and are matched on the same
/// way.
///
/// For a parameter, [path] is where the reader has to go and fix
/// something, which is not always the parameter itself: a value that
/// arrived through `APP_PORT` is reported as `APP_PORT`.
@immutable
sealed class ParameterViolation implements Violation {
  /// Creates a violation.
  const ParameterViolation();

  /// An error, unless the violation says otherwise.
  @override
  Severity get severity => Severity.error;
}

/// A required parameter had no value in any source.
final class MissingRequiredParameter extends ParameterViolation {
  /// Creates the violation for the missing [parameter].
  @internal
  const MissingRequiredParameter(this.parameter);

  /// The parameter that is missing.
  final ParameterInfo parameter;

  /// The parameter's primary name.
  @override
  ViolationPath get path => ViolationPath.of(parameter.primaryName);

  /// [ParameterViolationCodes.missingRequired].
  @override
  ViolationCode get code => ParameterViolationCodes.missingRequired;

  /// That the parameter is required, and the variable that was not set
  /// either.
  @override
  String get message {
    final String? variable = parameter.environmentVariable;
    if (variable == null) {
      return 'is required but was not given';
    }
    return 'is required but was not given, and $variable is not set';
  }
}

/// A parameter that takes a value was the last token, leaving nothing for
/// it to consume.
final class MissingParameterValue extends ParameterViolation {
  /// Creates the violation for [parameter], named as [token].
  @internal
  const MissingParameterValue(this.parameter, this.token);

  /// The parameter that expected a value.
  final ParameterInfo parameter;

  /// The token as it appeared on the command line.
  final String token;

  /// The [token].
  @override
  ViolationPath get path => ViolationPath.of(token);

  /// [ParameterViolationCodes.missingValue].
  @override
  ViolationCode get code => ParameterViolationCodes.missingValue;

  /// What type of value was expected.
  @override
  String get message =>
      'expects a value of type ${parameter.typeName} but none followed';
}

/// A token was passed that matches no declared parameter.
final class UnknownArgument extends ParameterViolation {
  /// Creates the violation for [token], with the closest declared name as
  /// [suggestion].
  @internal
  const UnknownArgument(this.token, this.suggestion);

  /// The token as it appeared on the command line.
  final String token;

  /// The closest declared name, or `null` when nothing was close enough.
  final String? suggestion;

  /// The [token].
  @override
  ViolationPath get path => ViolationPath.of(token);

  /// [ParameterViolationCodes.unknownArgument].
  @override
  ViolationCode get code => ParameterViolationCodes.unknownArgument;

  /// That the token is unknown, and what was probably meant.
  @override
  String get message {
    final String? candidate = suggestion;
    if (candidate == null) {
      return 'is not a known parameter';
    }
    return 'is not a known parameter - did you mean $candidate?';
  }
}

/// A token could not be read as a parameter at all, independently of which
/// are declared.
///
/// Only the name part of the token is carried. Anything written after an
/// `=` is a value of a parameter that was not identified, so Essentia
/// cannot know whether it is a port or an API key, and reports the name
/// alone.
final class MalformedArgument extends ParameterViolation {
  /// Creates the violation for [token], malformed for [reason].
  @internal
  const MalformedArgument(this.token, this.reason);

  /// The name part of the token, with anything after an `=` removed.
  final String token;

  /// What is malformed about it.
  final String reason;

  /// The [token].
  @override
  ViolationPath get path => ViolationPath.of(token);

  /// [ParameterViolationCodes.malformedArgument].
  @override
  ViolationCode get code => ParameterViolationCodes.malformedArgument;

  /// The [reason].
  @override
  String get message => reason;
}

/// A token that is not a parameter name appeared where a parameter was
/// expected.
///
/// Reported by position, and never by content. A bare token is a value,
/// and the parameter it was meant for is by definition not known, so
/// Essentia cannot tell whether it is a path, a port or the API key whose
/// parameter name was mistyped by one character. A program that really
/// does take positional arguments declares
/// `UnknownArgumentPolicy.collect` and gets them handed back instead.
final class StrayValue extends ParameterViolation {
  /// Creates the violation for the argument at [position].
  @internal
  const StrayValue(this.position);

  /// Which of the arguments it was, counting the first as one.
  final int position;

  /// `argument <position>`.
  @override
  ViolationPath get path => ViolationPath.of('argument $position');

  /// [ParameterViolationCodes.strayValue].
  @override
  ViolationCode get code => ParameterViolationCodes.strayValue;

  /// That the value belongs to no parameter.
  @override
  String get message => 'is a value with no parameter to belong to';
}

/// A value was present but its converter rejected it.
final class ConversionFailure extends ParameterViolation {
  /// Creates the violation for [value] of [parameter] from [origin],
  /// rejected for [reason].
  @internal
  const ConversionFailure(this.parameter, this.origin, this.value, this.reason);

  /// The parameter the value was resolved for.
  final ParameterInfo parameter;

  /// Where the value came from.
  final ValueOrigin origin;

  /// The offending value, already masked when the parameter is sensitive.
  final String value;

  /// What the converter expected.
  final String reason;

  /// Where the value came from.
  @override
  ViolationPath get path => ViolationPath.of(origin.label(parameter));

  /// [ParameterViolationCodes.conversionFailed].
  @override
  ViolationCode get code => ParameterViolationCodes.conversionFailed;

  /// The value and what was expected of it.
  @override
  String get message => "'$value' $reason";
}

/// A value converted cleanly but failed a validation rule declared for the
/// parameter.
final class ValidationFailure extends ParameterViolation {
  /// Creates the violation of [parameter] with the value from [origin].
  @internal
  const ValidationFailure(
    this.parameter,
    this.origin,
    this.message, {
    this.code = ParameterViolationCodes.validationFailed,
    this.severity = Severity.error,
  });

  /// The parameter the value was resolved for.
  final ParameterInfo parameter;

  /// Where the value came from.
  final ValueOrigin origin;

  /// What the rule said.
  @override
  final String message;

  /// The code the rule reported under.
  @override
  final ViolationCode code;

  /// The severity the rule reported with.
  @override
  final Severity severity;

  /// Where the value came from.
  @override
  ViolationPath get path => ViolationPath.of(origin.label(parameter));
}

/// A single-valued parameter was passed more than once.
///
/// Reported rather than letting the last occurrence win silently, because
/// a repeated parameter is nearly always a mistake in a script that
/// assembled the arguments.
final class RepeatedParameter extends ParameterViolation {
  /// Creates the violation for [parameter], given [occurrences] times.
  @internal
  const RepeatedParameter(this.parameter, this.occurrences);

  /// The parameter that was repeated.
  final ParameterInfo parameter;

  /// How many times it appeared.
  final int occurrences;

  /// The parameter's primary name.
  @override
  ViolationPath get path => ViolationPath.of(parameter.primaryName);

  /// [ParameterViolationCodes.repeated].
  @override
  ViolationCode get code => ParameterViolationCodes.repeated;

  /// How often the parameter was given.
  @override
  String get message =>
      'was given $occurrences times but accepts a single value';
}

/// Parameters declared as mutually exclusive were given together.
final class MutuallyExclusiveParameters extends ParameterViolation {
  /// Creates the violation for the clashing [parameters].
  @internal
  MutuallyExclusiveParameters(List<ParameterInfo> parameters)
    : parameters = List<ParameterInfo>.unmodifiable(parameters);

  /// The parameters that clashed.
  final List<ParameterInfo> parameters;

  /// The primary names of the clashing parameters.
  @override
  ViolationPath get path => ViolationPath.of(
    parameters.map((parameter) => parameter.primaryName).join(', '),
  );

  /// [ParameterViolationCodes.mutuallyExclusive].
  @override
  ViolationCode get code => ParameterViolationCodes.mutuallyExclusive;

  /// That the parameters cannot be combined.
  @override
  String get message => 'cannot be used together';
}

/// A parameter was given without another one it depends on.
final class MissingDependency extends ParameterViolation {
  /// Creates the violation for [parameter], given without [missing].
  @internal
  MissingDependency(this.parameter, List<ParameterInfo> missing)
    : missing = List<ParameterInfo>.unmodifiable(missing);

  /// The parameter that was given.
  final ParameterInfo parameter;

  /// The parameters it requires that were absent.
  final List<ParameterInfo> missing;

  /// The parameter's primary name.
  @override
  ViolationPath get path => ViolationPath.of(parameter.primaryName);

  /// [ParameterViolationCodes.missingDependency].
  @override
  ViolationCode get code => ParameterViolationCodes.missingDependency;

  /// What the parameter requires.
  @override
  String get message =>
      'requires ${missing.map((info) => info.primaryName).join(', ')}';
}

/// A parameter that is still honoured but should no longer be used was
/// given.
///
/// This is the one violation that is a warning: the value is used and
/// loading succeeds.
final class DeprecatedParameter extends ParameterViolation {
  /// Creates the warning for [parameter], pointing at [advice].
  @internal
  const DeprecatedParameter(this.parameter, this.advice);

  /// The parameter that was given.
  final ParameterInfo parameter;

  /// What to use instead, empty when there is nothing to point at.
  final String advice;

  /// The parameter's primary name.
  @override
  ViolationPath get path => ViolationPath.of(parameter.primaryName);

  /// [ParameterViolationCodes.deprecated].
  @override
  ViolationCode get code => ParameterViolationCodes.deprecated;

  /// Always [Severity.warning].
  @override
  Severity get severity => Severity.warning;

  /// That the parameter is deprecated, and what to use instead.
  @override
  String get message {
    if (advice.isEmpty) {
      return 'is deprecated';
    }
    return 'is deprecated: $advice';
  }
}
