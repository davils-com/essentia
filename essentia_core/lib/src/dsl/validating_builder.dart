/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/dsl/builder.dart';
import 'package:essentia_core/src/validation/validatable.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/validation_report.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:essentia_core/src/validation/violation.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:essentia_core/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// A builder whose value of type [T] states its own invariants.
///
/// The three parts of the pattern are the builder, the immutable
/// [Validatable] it assembles, and a function taking a configuration block
/// that ties them together, the way a Kotlin DSL takes a lambda with a
/// receiver:
///
/// ```dart
/// final class LoggingBuilder extends ValidatingBuilder<LoggingData> {
///   final List<SinkData> _sinks = <SinkData>[];
///   LogLevel level = LogLevel.info;
///
///   void console([void Function(ConsoleSinkBuilder it)? block]) {
///     collect(_sinks, ConsoleSinkBuilder(), 'sinks', block ?? (_) {});
///   }
///
///   @override
///   LoggingData assemble() => LoggingData(level, List.unmodifiable(_sinks));
/// }
///
/// LoggingData logging(void Function(LoggingBuilder it) block) =>
///     LoggingBuilder().apply(block).build();
///
/// final LoggingData config = logging((it) {
///   it.level = LogLevel.debug;
///   it.console((it) => it.colored = true);
/// });
/// ```
///
/// A nested block does **not** fail on its own. [nested] and [collect] hand
/// the inner builder's violations up to the outer one with the path they
/// sit at, so a configuration with three problems spread over three levels
/// reports all three at once. Anything that validated a nested block by
/// calling [build] on it would report the first and hide the rest.
abstract class ValidatingBuilder<T extends Validatable> implements Builder<T> {
  /// The violations nested builders handed up, already under their paths.
  final _adopted = <Violation>[];

  /// How many elements each collected property holds so far, which is the
  /// index the next one reports under.
  final _declared = <String, int>{};

  /// What is being built, used in the headline of the report.
  @protected
  String get subject => 'configuration';

  /// Puts together what the block configured, without checking any of it.
  ///
  /// Every check belongs in [Validatable.validate] on the assembled type.
  /// This method must not throw and must have no side effects, because it
  /// may run more than once: [validate] and [build] each assemble.
  ///
  /// Returns the assembled value.
  @protected
  T assemble();

  /// Assembles and validates the value.
  ///
  /// Returns the value.
  ///
  /// Throws a [ValidationException] carrying every problem found, nested
  /// ones included, when anything makes the value unusable.
  @nonVirtual
  @override
  T build() {
    final ({ValidationReport report, T value}) evaluation = evaluate();
    if (!evaluation.report.isValid) {
      throw ValidationException(evaluation.report);
    }
    return evaluation.value;
  }

  /// Assembles and validates, returning what was found instead of throwing.
  ///
  /// This is the same work [build] does, for callers that would rather
  /// inspect the report than catch an exception.
  ///
  /// Returns the report, valid or not.
  ValidationReport validate() => evaluate().report;

  /// Configures [builder] with [block] and assembles it as the value of
  /// [property].
  ///
  /// Its violations are taken over under [property] rather than thrown.
  ///
  /// Returns the nested value, or `null` when it is unusable, in which case
  /// the reasons are already part of this builder's report.
  @protected
  D? nested<D extends Validatable, B extends ValidatingBuilder<D>>(
    B builder,
    String property,
    void Function(B it) block,
  ) => _nestedAt(builder, ViolationPath.of(property), block);

  /// Configures [builder] with [block] and adds what it assembles to
  /// [target], the list behind [property].
  ///
  /// Each call reports under the next index of [property], so the third
  /// collected element reports as `property[2]`. An unusable element is not
  /// added; its violations are taken over instead.
  @protected
  void collect<D extends Validatable, B extends ValidatingBuilder<D>>(
    List<D> target,
    B builder,
    String property,
    void Function(B it) block,
  ) {
    final int index = _declared[property] ?? 0;
    _declared[property] = index + 1;
    final ViolationPath path = ViolationPath.of(property).index(index);
    final D? value = _nestedAt(builder, path, block);
    if (value == null) {
      return;
    }
    target.add(value);
  }

  /// Takes over [violations] found elsewhere, reporting them under [path].
  @protected
  void adopt(List<Violation> violations, ViolationPath path) {
    final scope = ValidationScope(ViolationPath.root, ViolationCode.invalid)
      ..include(violations, path);
    _adopted.addAll(scope.violations());
  }

  /// Assembles the value and validates it together with everything adopted
  /// from nested builders.
  ///
  /// Returns the value and its report.
  @protected
  ({T value, ValidationReport report}) evaluate() {
    final T value = assemble();
    final scope = ValidationScope(ViolationPath.root, ViolationCode.invalid)
      ..include(_adopted);
    value.validate(scope);
    return (
      value: value,
      report: ValidationReport(subject, scope.violations()),
    );
  }

  /// Configures [builder] with [block], evaluates it and adopts its
  /// violations under [path].
  ///
  /// Returns the nested value, or `null` when it is unusable.
  D? _nestedAt<D extends Validatable, B extends ValidatingBuilder<D>>(
    B builder,
    ViolationPath path,
    void Function(B it) block,
  ) {
    block(builder);
    final ({ValidationReport report, D value}) evaluation = builder.evaluate();
    final List<Violation> violations = evaluation.report.violations;
    if (violations.isNotEmpty) {
      adopt(violations, path);
    }
    if (!evaluation.report.isValid) {
      return null;
    }
    return evaluation.value;
  }
}
