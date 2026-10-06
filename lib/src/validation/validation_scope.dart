/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/reported_violation.dart';
import 'package:essentia/src/validation/severity.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:essentia/src/validation/violation_code.dart';
import 'package:essentia/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// Where a rule says what is wrong.
///
/// A rule reports through [fail] or [warn] and returns normally. It must
/// never throw: throwing on the spot abandons every remaining rule and
/// reduces the report to whatever happened to be checked first. Reporting
/// several times in one block is not only allowed but the point; each call
/// becomes its own entry.
///
/// Every scope carries a path prefix, so a rule only ever names the property
/// it is about. [at] and [each] descend into that path, which is how a
/// nested object reports as `sinks[2].queueSize` without knowing it is
/// nested.
///
/// ```dart
/// @override
/// void validate(ValidationScope scope) {
///   if (sinks.isEmpty) {
///     scope.fail('at least one sink must be configured', property: 'sinks');
///   }
///   scope.each('sinks', sinks, (scope, sink) => sink.validate(scope));
/// }
/// ```
final class ValidationScope {
  /// Creates a scope reporting under [_prefix], with [_defaultCode] for
  /// every report that names no code of its own.
  @internal
  ValidationScope(this._prefix, this._defaultCode);

  /// The path everything reported here sits under.
  final ViolationPath _prefix;

  /// The code of a report that names none.
  final ViolationCode _defaultCode;

  /// What was reported so far, in order.
  final _collected = <Violation>[];

  /// Reports an error.
  ///
  /// [message] says what is wrong, phrased to follow the path:
  /// `"must not be empty"`. [property] names the property at fault, or is
  /// left out when the object as a whole is wrong. [code] is the stable
  /// identifier of this kind of problem.
  void fail(String message, {String? property, ViolationCode? code}) {
    _record(property, code, Severity.error, message);
  }

  /// Reports a warning, which does not stop the result from being produced.
  ///
  /// [message] says what is worth saying, [property] names the property
  /// concerned or is left out for the object as a whole, and [code] is the
  /// stable identifier of this kind of problem.
  void warn(String message, {String? property, ViolationCode? code}) {
    _record(property, code, Severity.warning, message);
  }

  /// Validates something under [property], so that everything [block]
  /// reports is reported under that name.
  void at(String property, void Function(ValidationScope it) block) {
    _descend(_prefix.name(property), block);
  }

  /// Validates every element of [items] under `property[index]`, handing
  /// [block] the scope of the element and the element itself.
  void each<T>(
    String property,
    Iterable<T> items,
    void Function(ValidationScope it, T item) block,
  ) {
    var index = 0;
    for (final item in items) {
      final ViolationPath path = _prefix.name(property).index(index);
      _descend(path, (scope) => block(scope, item));
      index++;
    }
  }

  /// Takes over [violations] that were produced elsewhere, reporting them
  /// under [under], relative to this scope.
  ///
  /// This is what makes a nested validation part of the enclosing one
  /// instead of a failure of its own. The violations are re-reported under
  /// the combined path, so a caller's own violation type does not survive
  /// being nested; the shared shape does.
  void include(
    List<Violation> violations, [
    ViolationPath under = ViolationPath.root,
  ]) {
    final ViolationPath base = _prefix + under;
    for (final violation in violations) {
      _collected.add(
        ReportedViolation(
          base + violation.path,
          violation.code,
          violation.severity,
          violation.message,
        ),
      );
    }
  }

  /// Everything reported here so far.
  ///
  /// Returns an unmodifiable copy, in the order it was reported.
  @internal
  List<Violation> violations() => List<Violation>.unmodifiable(_collected);

  /// Runs [block] in a scope under [path] and takes over what it reported.
  void _descend(ViolationPath path, void Function(ValidationScope it) block) {
    final nested = ValidationScope(path, _defaultCode);
    block(nested);
    _collected.addAll(nested._collected);
  }

  /// Records a violation of [severity] about [property], or about the
  /// object as a whole when it is `null`.
  void _record(
    String? property,
    ViolationCode? code,
    Severity severity,
    String message,
  ) {
    final ViolationPath path = property == null
        ? _prefix
        : _prefix.name(property);
    _collected.add(
      ReportedViolation(path, code ?? _defaultCode, severity, message),
    );
  }
}
