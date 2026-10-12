/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// The declaration of a parameter accumulated so far, with its type erased.
///
/// Every builder step returns a new builder around a new draft, so a
/// builder held somewhere is never changed by a later step.
@internal
@immutable
final class ParameterDraft {
  /// Creates the draft of a parameter answering to [names].
  const ParameterDraft({
    required this.names,
    required this.converter,
    required this.typeName,
    required this.isFlag,
    this.constraint,
    this.validators = const <void Function(ValidationScope, Object?)>[],
    this.environmentVariable,
    this.environmentEnabled = true,
    this.isSensitive = false,
    this.description,
    this.splitDelimiter,
    this.isNegatable = false,
    this.deprecation,
  });

  /// Every name the parameter answers to, including the dashes.
  final List<String> names;

  /// Turns raw text into the declared type.
  final Object? Function(String raw) converter;

  /// The name of the declared type, for the usage listing.
  final String typeName;

  /// The check the conversion installed, or `null`.
  ///
  /// It runs on a converted value and on a declared default alike, and
  /// throws a `ConversionException` for one it refuses. This is what holds a
  /// default to `choice` or `path(mustExist: true)`.
  final void Function(Object? value)? constraint;

  /// The rules the converted value has to satisfy.
  final List<void Function(ValidationScope scope, Object? value)> validators;

  /// The environment variable named explicitly, or `null`.
  final String? environmentVariable;

  /// Whether the parameter falls back to the environment at all.
  final bool environmentEnabled;

  /// Whether the value is masked wherever Essentia renders it.
  final bool isSensitive;

  /// The explanation for the usage listing, or `null`.
  final String? description;

  /// What one occurrence is split on, or `null` to keep it whole.
  final String? splitDelimiter;

  /// Whether the parameter is a flag.
  final bool isFlag;

  /// Whether the flag also answers to its `--no-` names.
  final bool isNegatable;

  /// What to use instead, or `null` when the parameter is not deprecated.
  final String? deprecation;

  /// Returns this draft with [rule] added to its validators.
  ParameterDraft withValidator(
    void Function(ValidationScope scope, Object? value) rule,
  ) => _copy(
    validators: List<void Function(ValidationScope, Object?)>.unmodifiable(
      <void Function(ValidationScope, Object?)>[...validators, rule],
    ),
  );

  /// Returns this draft masked wherever Essentia renders it.
  ParameterDraft asSensitive() => _copy(isSensitive: true);

  /// Returns this draft falling back to the environment [variable].
  ParameterDraft withEnvironment(String variable) =>
      _copy(environmentVariable: variable, environmentEnabled: true);

  /// Returns this draft without any environment fallback.
  ParameterDraft withoutEnvironment() => ParameterDraft(
    names: names,
    converter: converter,
    typeName: typeName,
    isFlag: isFlag,
    constraint: constraint,
    validators: validators,
    environmentEnabled: false,
    isSensitive: isSensitive,
    description: description,
    splitDelimiter: splitDelimiter,
    isNegatable: isNegatable,
    deprecation: deprecation,
  );

  /// Returns this draft explained by [text] in the usage listing.
  ParameterDraft withDescription(String text) => _copy(description: text);

  /// Returns this draft splitting each occurrence on [delimiter].
  ///
  /// Throws an [ArgumentError] if [delimiter] is empty, which would split
  /// between every character.
  ParameterDraft withSplit(String delimiter) {
    if (delimiter.isEmpty) {
      throw ArgumentError.value(
        delimiter,
        'delimiter',
        'A split delimiter must not be empty; a parameter that takes one '
            'value per occurrence is multiple() rather than split("")',
      );
    }
    return _copy(splitDelimiter: delimiter);
  }

  /// Returns this draft answering to its `--no-` names as well.
  ParameterDraft asNegatable() => _copy(isNegatable: true);

  /// Returns this draft marked deprecated, pointing at [advice].
  ParameterDraft asDeprecated(String advice) => _copy(deprecation: advice);

  /// Returns this draft converting with [newConverter] to the type named
  /// [newTypeName], checking each value with [newConstraint].
  ///
  /// The constraint of the previous type is dropped, since it was written
  /// against that type.
  ///
  /// Throws a [StateError] if validation was already declared, since a rule
  /// written against the previous type cannot apply to the new one.
  ParameterDraft retyped(
    String newTypeName,
    Object? Function(String raw) newConverter, [
    void Function(Object? value)? newConstraint,
  ]) {
    if (validators.isNotEmpty) {
      throw StateError(
        'Parameter ${names.first} declares validation before its type is '
        'fixed. Move validate() after the conversion.',
      );
    }
    return ParameterDraft(
      names: names,
      converter: newConverter,
      typeName: newTypeName,
      isFlag: isFlag,
      constraint: newConstraint,
      environmentVariable: environmentVariable,
      environmentEnabled: environmentEnabled,
      isSensitive: isSensitive,
      description: description,
      splitDelimiter: splitDelimiter,
      isNegatable: isNegatable,
      deprecation: deprecation,
    );
  }

  /// Returns this draft with the given values replaced.
  ParameterDraft _copy({
    List<void Function(ValidationScope, Object?)>? validators,
    String? environmentVariable,
    bool? environmentEnabled,
    bool? isSensitive,
    String? description,
    String? splitDelimiter,
    bool? isNegatable,
    String? deprecation,
  }) => ParameterDraft(
    names: names,
    converter: converter,
    typeName: typeName,
    isFlag: isFlag,
    constraint: constraint,
    validators: validators ?? this.validators,
    environmentVariable: environmentVariable ?? this.environmentVariable,
    environmentEnabled: environmentEnabled ?? this.environmentEnabled,
    isSensitive: isSensitive ?? this.isSensitive,
    description: description ?? this.description,
    splitDelimiter: splitDelimiter ?? this.splitDelimiter,
    isNegatable: isNegatable ?? this.isNegatable,
    deprecation: deprecation ?? this.deprecation,
  );
}
