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

import 'package:essentia_core/src/arguments/parameter_info.dart';
import 'package:essentia_core/src/arguments/parameter_violation_codes.dart';
import 'package:essentia_core/src/arguments/value_origin.dart';
import 'package:essentia_core/src/lang/causal.dart';
import 'package:essentia_core/src/validation/severity.dart';
import 'package:essentia_core/src/validation/violation.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:essentia_core/src/validation/violation_path.dart';
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
///
/// A violation is a report, not a value: members are matched on by type or
/// by [code], and compared by identity. Its [ValueOrigin], by contrast, is a
/// value and compares by content.
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
///
/// A bundle of short flags is one token and is read as one decision, so a
/// bundle with an undeclared letter in it is refused whole: [token] is that
/// letter, [bundle] is the token it was part of, and nothing in the bundle
/// is applied - not even the declared letters before it.
final class UnknownArgument extends ParameterViolation {
  /// Creates the violation for [token], with the closest declared name as
  /// [suggestion], and the [bundle] of short flags it was part of.
  @internal
  const UnknownArgument(this.token, this.suggestion, {this.bundle});

  /// The token as it appeared on the command line, or the one undeclared
  /// letter of a bundle.
  final String token;

  /// The closest declared name, or `null` when nothing was close enough.
  final String? suggestion;

  /// The bundle of short flags [token] was part of, or `null` when it stood
  /// on its own.
  final String? bundle;

  /// The [token].
  @override
  ViolationPath get path => ViolationPath.of(token);

  /// [ParameterViolationCodes.unknownArgument].
  @override
  ViolationCode get code => ParameterViolationCodes.unknownArgument;

  /// That the token is unknown, and what was probably meant or which
  /// bundle was not applied because of it.
  @override
  String get message {
    final String? enclosing = bundle;
    if (enclosing != null) {
      return 'is not a known parameter, so nothing in $enclosing was applied';
    }
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
final class ConversionFailure extends ParameterViolation implements Causal {
  /// Creates the violation for [value] of [parameter] from [origin],
  /// rejected for [reason], with what the converter threw as [cause].
  @internal
  const ConversionFailure(
    this.parameter,
    this.origin,
    this.value,
    this.reason, {
    this.cause,
  });

  /// The parameter the value was resolved for.
  final ParameterInfo parameter;

  /// Where the value came from.
  final ValueOrigin origin;

  /// The offending value, already masked when the parameter is sensitive.
  final String value;

  /// What the converter expected.
  final String reason;

  /// What the converter threw, kept for diagnosis and never rendered.
  ///
  /// A converter's own exception is not written for this report and may
  /// quote the value it rejected, which is why only [reason] reaches
  /// [message]. `null` when the violation was created without one.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

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
///
/// The rule wrote [detail], and Essentia cannot mask a string somebody else
/// composed - a rule on a sensitive parameter that says
/// `it.fail("'$value' is not a valid token")` would put the secret in the
/// report. So for a parameter declared sensitive, [message] is a fixed
/// sentence and [detail] is not rendered. The code still travels, so a
/// program can still match on what went wrong, and [detail] stays
/// reachable for a caller who deliberately wants it.
final class ValidationFailure extends ParameterViolation {
  /// Creates the violation of [parameter] with the value from [origin],
  /// which the rule described as [detail].
  @internal
  const ValidationFailure(
    this.parameter,
    this.origin,
    this.detail, {
    this.code = ParameterViolationCodes.validationFailed,
    this.severity = Severity.error,
  });

  /// What a sensitive parameter's failed rule is reported as.
  static const _withheldDetail =
      'failed validation - the detail is withheld because the parameter is '
      'sensitive';

  /// The parameter the value was resolved for.
  final ParameterInfo parameter;

  /// Where the value came from.
  final ValueOrigin origin;

  /// What the rule reported, verbatim.
  ///
  /// Rendered only for a parameter that is not sensitive.
  final String detail;

  /// What the rule said, or a fixed sentence when the parameter is
  /// sensitive.
  @override
  String get message {
    if (parameter.isSensitive) {
      return _withheldDetail;
    }
    return detail;
  }

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

/// A value source threw while being asked for a value.
///
/// Reported under the source's name rather than as a bad value, because
/// nothing about the arguments has to be wrong for it to happen. The
/// exception itself is kept in [cause] and not rendered: a transport
/// error's message is not written for this report.
final class SourceUnavailable extends ParameterViolation implements Causal {
  /// Creates the violation for [parameter], which the source [sourceName]
  /// failed to read with [cause].
  @internal
  const SourceUnavailable(this.parameter, this.sourceName, this.cause);

  /// The parameter the source was asked about.
  final ParameterInfo parameter;

  /// The name of the source that failed.
  final String sourceName;

  /// What the source threw, kept for diagnosis and never rendered.
  @override
  final Object cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// The parameter's primary name and the source: `--token (from vault)`.
  @override
  ViolationPath get path =>
      ViolationPath.of(ExternalOrigin(sourceName).label(parameter));

  /// [ParameterViolationCodes.sourceUnavailable].
  @override
  ViolationCode get code => ParameterViolationCodes.sourceUnavailable;

  /// That the value could not be read because the source failed.
  @override
  String get message => 'could not be read, because the source failed';
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
