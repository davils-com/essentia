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

import 'package:essentia_core/src/arguments/argument_lexer.dart';
import 'package:essentia_core/src/arguments/cardinality.dart';
import 'package:essentia_core/src/arguments/declared_parameter.dart';
import 'package:essentia_core/src/arguments/host_system.dart';
import 'package:essentia_core/src/arguments/lex_result.dart';
import 'package:essentia_core/src/arguments/masking.dart';
import 'package:essentia_core/src/arguments/parameter.dart';
import 'package:essentia_core/src/arguments/parameter_declarations.dart';
import 'package:essentia_core/src/arguments/parameter_draft.dart';
import 'package:essentia_core/src/arguments/parameter_exception.dart';
import 'package:essentia_core/src/arguments/parameter_info.dart';
import 'package:essentia_core/src/arguments/parameter_snapshot.dart';
import 'package:essentia_core/src/arguments/parameter_spec.dart';
import 'package:essentia_core/src/arguments/parameter_violation.dart';
import 'package:essentia_core/src/arguments/parameters_not_loaded_error.dart';
import 'package:essentia_core/src/arguments/resolver.dart';
import 'package:essentia_core/src/arguments/unknown_argument_policy.dart';
import 'package:essentia_core/src/arguments/usage_renderer.dart';
import 'package:essentia_core/src/arguments/value_origin.dart';
import 'package:essentia_core/src/arguments/value_source.dart';
import 'package:essentia_core/src/validation/violation.dart';
import 'package:meta/meta.dart';

/// The parameters a program is started with.
///
/// A schema extends this class, declares one final field per parameter,
/// initialised with [parameter] or [flag], and lists them in [declared].
/// Declaring is separate from reading: [load] resolves every declared
/// parameter in one pass, and from then on each one is an ordinary immutable
/// value read through [Parameter.value].
///
/// ```dart
/// final class AppParameters extends Parameters {
///   AppParameters() : super(environmentPrefix: 'APP') {
///     exclusive(<Parameter<Object?>>[json, yaml]);
///   }
///
///   final Parameter<int> port =
///       parameter(<String>['--port', '-p']).integer().required();
///   final Parameter<String> dataDir =
///       parameter(<String>['--data-dir']).path(mustExist: true).required();
///   final Parameter<String> dbPassword =
///       parameter(<String>['--db-password']).sensitive().required();
///   final Parameter<List<String>> tags =
///       parameter(<String>['--tag']).multiple();
///   final Parameter<bool> dryRun = flag(<String>['--dry-run']);
///   final Parameter<bool> json = flag(<String>['--json']);
///   final Parameter<bool> yaml = flag(<String>['--yaml']);
///
///   @override
///   List<Parameter<Object?>> get declared => <Parameter<Object?>>[
///     port, dataDir, dbPassword, tags, dryRun, json, yaml,
///   ];
/// }
///
/// void main(List<String> argv) {
///   final parameters = AppParameters()..load(argv);
///   logger.info(parameters.describe());
///   startServer(parameters.port.value);
/// }
/// ```
///
/// A schema lists its parameters once in [declared], and the schema
/// registers that list as it is constructed. The order of the list is the
/// order of the usage listing, and a parameter missing from it fails loudly
/// when it is read.
///
/// Reading a parameter costs a list access. Nothing about it converts,
/// validates or waits, which is why [load] is the only place that has to be
/// called at a particular time.
///
/// A schema is loaded once. A second [load] or [loadFrom] is refused
/// whether it comes after the first or while an asynchronous [loadFrom] is
/// still waiting for a source; a load that failed may be retried.
///
/// Each parameter's environment variable belongs to that parameter alone.
/// Two parameters that would read the same variable - whether named with
/// `env` or derived, so that `--data-dir` and `--data_dir` would both read
/// `APP_DATA_DIR` - are refused when the schema registers its parameters,
/// as is a variable name no shell could export. Registering happens in the
/// constructor, so a schema that is wrong cannot be constructed at all.
abstract class Parameters {
  /// Creates a schema.
  ///
  /// [_environmentPrefix] derives an environment variable for each parameter,
  /// so that `--data-dir` falls back to `APP_DATA_DIR`. Parameters opt out
  /// with `noEnv` and override it with `env`. Without a prefix only
  /// parameters with an explicit variable have an environment fallback.
  /// [_unknownArguments] decides what happens to arguments the schema does
  /// not declare.
  ///
  /// The constructor registers the parameters of [declared], which every
  /// final field of the subclass has been initialised for by then.
  ///
  /// Throws an [ArgumentError] if a parameter of [declared] was not created
  /// by [parameter] or [flag], is listed twice or by another schema, shares
  /// a name or an environment variable with another one, or reads a
  /// malformed environment variable.
  Parameters({
    this._environmentPrefix,
    this._unknownArguments = UnknownArgumentPolicy.reject,
  }) {
    _registered();
  }

  /// The prefix environment variables are derived with, or `null`.
  final String? _environmentPrefix;

  /// What happens to arguments the schema does not declare.
  final UnknownArgumentPolicy _unknownArguments;

  /// The groups of which at most one parameter may be given.
  final _exclusive = <List<Parameter<Object?>>>[];

  /// The parameters that need others, and the ones they need.
  final _requirements = <(Parameter<Object?>, List<Parameter<Object?>>)>[];

  /// The position of every registered parameter.
  final _ordinals = Map<Parameter<Object?>, int>.identity();

  /// The registered parameters, once [declared] was read.
  List<ParameterSpec>? _specs;

  /// What the load resolved, once it ran.
  ParameterSnapshot? _snapshot;

  /// Whether a load is running or has succeeded, which is what refuses a
  /// second one.
  var _loadStarted = false;

  /// What a well-formed environment variable name looks like.
  static final _variableName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// Every parameter of the schema, in the order of the usage listing.
  ///
  /// Read once, while the schema is constructed.
  @protected
  List<Parameter<Object?>> get declared;

  /// Whether [load] has run.
  bool get isLoaded => _snapshot != null;

  /// The arguments that followed the `--` terminator, untouched.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded.
  List<String> get rest => _requireSnapshot('rest').rest;

  /// The arguments that matched no declared parameter.
  ///
  /// This is always empty under [UnknownArgumentPolicy.reject], since an
  /// undeclared argument is a violation there.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded.
  List<String> get unknown => _requireSnapshot('unknown').unknown;

  /// Everything the load reported that did not stop it.
  ///
  /// A deprecated parameter that was given ends up here, as does a rule
  /// that reported through `warn` rather than `fail`.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded.
  List<Violation> get warnings => _requireSnapshot('warnings').warnings;

  /// Declares that at most one of [parameters] may be given.
  @protected
  void exclusive(List<Parameter<Object?>> parameters) {
    _exclusive.add(List<Parameter<Object?>>.unmodifiable(parameters));
  }

  /// Declares that [parameter] may only be given together with every one of
  /// [required].
  @protected
  void requires(
    Parameter<Object?> parameter,
    List<Parameter<Object?>> required,
  ) {
    _requirements.add((
      parameter,
      List<Parameter<Object?>>.unmodifiable(required),
    ));
  }

  /// Resolves every declared parameter from [argv], [environment] and the
  /// declared defaults.
  ///
  /// Precedence is command line, then environment, then default. Values
  /// from the environment go through the same conversion and validation as
  /// those from the command line, and a problem with one is reported under
  /// the name of the variable it came from. [environment] defaults to the
  /// environment of the process.
  ///
  /// Throws a [ParameterException] carrying every problem found if anything
  /// about the arguments is wrong, a [StateError] if the schema was already
  /// loaded or is being loaded, and an [ArgumentError] if the schema itself
  /// is wrong.
  void load(List<String> argv, {Map<String, String>? environment}) {
    final List<ParameterSpec> specs = _beginLoad();
    try {
      final LexResult lexed = ArgumentLexer(specs, _unknownArguments).lex(argv);
      _finish(
        specs,
        lexed,
        _environmentValues(specs, lexed, environment ?? hostEnvironment()),
        const <ParameterViolation>[],
      );
    } finally {
      _loadStarted = _snapshot != null;
    }
  }

  /// Resolves every declared parameter like [load], additionally consulting
  /// [sources] for anything the command line and the environment did not
  /// supply.
  ///
  /// Precedence is command line, then environment, then each source in the
  /// order given, then the default. This one is asynchronous because a
  /// source may have to reach somewhere slow; the resolution itself is the
  /// same work [load] does. A source that throws an [Exception] is reported
  /// as [SourceUnavailable] for the parameter it was asked about, and the
  /// sources after it are still asked.
  ///
  /// Throws what [load] throws.
  Future<void> loadFrom(
    List<String> argv,
    List<ValueSource> sources, {
    Map<String, String>? environment,
  }) async {
    final List<ParameterSpec> specs = _beginLoad();
    try {
      final LexResult lexed = ArgumentLexer(specs, _unknownArguments).lex(argv);
      final Map<int, (String, ValueOrigin)> external = _environmentValues(
        specs,
        lexed,
        environment ?? hostEnvironment(),
      );
      final failures = <ParameterViolation>[];
      for (final source in sources) {
        for (final spec in specs) {
          final bool resolved =
              lexed.occurrences.containsKey(spec.ordinal) ||
              external.containsKey(spec.ordinal);
          if (resolved) {
            continue;
          }
          final String? raw = await _readFrom(source, spec, failures);
          if (raw != null) {
            external[spec.ordinal] = (raw, ExternalOrigin(source.name));
          }
        }
      }
      _finish(specs, lexed, external, failures);
    } finally {
      _loadStarted = _snapshot != null;
    }
  }

  /// Renders the listing of supported parameters.
  ///
  /// This is what a failed load appends to its report, and what a program
  /// prints when it wants to show what it accepts.
  ///
  /// Returns the listing, without a trailing newline.
  String usage() => renderUsage(_registered());

  /// Renders the resolved values together with where each one came from.
  ///
  /// Sensitive parameters are masked, which is what makes this safe to
  /// write to a startup log.
  ///
  /// Returns the rendered values, without a trailing newline.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded.
  String describe() =>
      renderValues(_registered(), _requireSnapshot('describe()'));

  /// The resolved value of [parameter].
  ///
  /// Returns the value.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded,
  /// and a [StateError] if [parameter] is not one of [declared].
  @internal
  Object? valueOf(Parameter<Object?> parameter) {
    final String name = _nameOf(parameter);
    final ParameterSnapshot snapshot =
        _snapshot ?? (throw ParametersNotLoadedError('Parameter "$name"'));
    final int ordinal =
        _ordinals[parameter] ??
        (throw StateError(
          'Parameter "$name" is not listed in the declared parameters of '
          'its schema, so it was never loaded',
        ));
    return snapshot.valueAt(ordinal);
  }

  /// Checks that the schema can be loaded, and marks the load as started.
  ///
  /// Returns the registered parameters.
  ///
  /// Throws a [StateError] if it was loaded already or is being loaded, and
  /// an [ArgumentError] if a group names a parameter that is not declared.
  List<ParameterSpec> _beginLoad() {
    if (_loadStarted) {
      throw StateError(
        'This schema was already loaded, or is being loaded. Construct a new '
        'instance instead of loading twice.',
      );
    }
    final List<ParameterSpec> specs = _registered();
    final Iterable<Parameter<Object?>> references = <Parameter<Object?>>[
      for (final group in _exclusive) ...group,
      for (final (parameter, required)
          in _requirements) ...<Parameter<Object?>>[parameter, ...required],
    ];
    final List<String> missing = <String>{
      for (final reference in references)
        if (!_ordinals.containsKey(reference)) _nameOf(reference),
    }.toList();
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'The schema declares a parameter group naming '
        '${missing.map((name) => '"$name"').join(', ')}, which is not a '
        'declared parameter. Group members are parameters listed in declared.',
      );
    }
    _loadStarted = true;
    return specs;
  }

  /// Asks [source] for the value of [spec], recording a failure of the
  /// source in [failures] instead of letting it end the load.
  ///
  /// Returns the value, or `null` when the source has none or failed.
  static Future<String?> _readFrom(
    ValueSource source,
    ParameterSpec spec,
    List<ParameterViolation> failures,
  ) async {
    try {
      return await source.read(spec.info);
    } on Exception catch (cause) {
      failures.add(SourceUnavailable(spec.info, source.name, cause));
      return null;
    }
  }

  /// Resolves what was lexed, reporting the [sourceFailures] alongside, and
  /// stores the snapshot.
  ///
  /// Throws a [ParameterException] if anything is wrong.
  void _finish(
    List<ParameterSpec> specs,
    LexResult lexed,
    Map<int, (String, ValueOrigin)> external,
    List<ParameterViolation> sourceFailures,
  ) {
    final resolver = Resolver(
      specs,
      <List<int>>[
        for (final group in _exclusive)
          <int>[for (final member in group) _ordinals[member]!],
      ],
      <(int, List<int>)>[
        for (final (parameter, required) in _requirements)
          (
            _ordinals[parameter]!,
            <int>[for (final member in required) _ordinals[member]!],
          ),
      ],
    );
    final (ParameterSnapshot? snapshot, List<ParameterViolation> violations) =
        resolver.resolve(lexed, external, sourceFailures);
    if (snapshot == null) {
      throw ParameterException(violations, usage());
    }
    _snapshot = snapshot;
  }

  /// Reads the environment value of every parameter the command line did
  /// not supply.
  ///
  /// Returns the values by ordinal.
  Map<int, (String, ValueOrigin)> _environmentValues(
    List<ParameterSpec> specs,
    LexResult lexed,
    Map<String, String> environment,
  ) => <int, (String, ValueOrigin)>{
    for (final spec in specs)
      if (!lexed.occurrences.containsKey(spec.ordinal))
        if (spec.info.environmentVariable case final String variable)
          if (environment[variable] case final String raw)
            spec.ordinal: (raw, EnvironmentOrigin(variable)),
  };

  /// Registers the parameters of [declared], once.
  ///
  /// Returns the registered parameters.
  ///
  /// Throws an [ArgumentError] if a parameter was not created by
  /// [parameter] or [flag], is listed twice or by another schema, shares a
  /// name or an environment variable with another one, or reads a malformed
  /// environment variable.
  List<ParameterSpec> _registered() {
    final List<ParameterSpec>? registered = _specs;
    if (registered != null) {
      return registered;
    }
    final specs = <ParameterSpec>[];
    final claimed = <String>{};
    final claimedVariables = <String, String>{};
    for (final Parameter<Object?> parameter in declared) {
      final ParameterSpec spec = _specFor(parameter, specs.length);
      for (final String name in spec.matchableNames()) {
        if (!claimed.add(name)) {
          throw ArgumentError(
            'Parameter name "$name" is declared more than once',
          );
        }
      }
      _claimVariable(spec.info, claimedVariables);
      _ordinals[parameter] = spec.ordinal;
      if (parameter is DeclaredParameter<Object?>) {
        parameter.declareOn(this);
      }
      specs.add(spec);
    }
    return _specs = List<ParameterSpec>.unmodifiable(specs);
  }

  /// Claims the environment variable of [info] in [claimed], which maps
  /// every variable claimed so far to the primary name of its parameter.
  ///
  /// Throws an [ArgumentError] if the variable is not a well-formed name or
  /// another parameter reads it already.
  static void _claimVariable(ParameterInfo info, Map<String, String> claimed) {
    final String? variable = info.environmentVariable;
    if (variable == null) {
      return;
    }
    if (!_variableName.hasMatch(variable)) {
      throw ArgumentError(
        'Parameter "${info.primaryName}" reads the environment variable '
        '"$variable", which is not a well-formed variable name',
      );
    }
    final String? previous = claimed[variable];
    if (previous != null) {
      throw ArgumentError(
        'Parameters "$previous" and "${info.primaryName}" both read the '
        'environment variable "$variable". A variable belongs to one '
        'parameter; use env() or noEnv() to separate them.',
      );
    }
    claimed[variable] = info.primaryName;
  }

  /// Builds the spec of [parameter] at [ordinal].
  ///
  /// Returns the spec.
  ///
  /// Throws an [ArgumentError] if the parameter was not created by
  /// [parameter] or [flag], another schema lists it, or it was listed
  /// already.
  ParameterSpec _specFor(Parameter<Object?> parameter, int ordinal) {
    if (parameter is! DeclaredParameter<Object?>) {
      throw ArgumentError(
        'A declared parameter was not created by parameter() or flag()',
      );
    }
    final Parameters? owner = parameter.schema;
    if (owner != null && !identical(owner, this)) {
      throw ArgumentError(
        'Parameter "${_nameOf(parameter)}" is declared by another schema. '
        'A parameter belongs to one schema; declare it on each schema.',
      );
    }
    if (_ordinals.containsKey(parameter)) {
      throw ArgumentError(
        'Parameter "${_nameOf(parameter)}" is listed twice in declared',
      );
    }
    final ParameterDraft draft = parameter.draft;
    final Cardinality cardinality = parameter.cardinality;
    final Object? defaultValue = parameter.defaultValue;
    return ParameterSpec(
      info: ParameterInfo(
        names: draft.names,
        environmentVariable: _environmentVariableFor(draft),
        typeName: draft.typeName,
        isRequired: cardinality == Cardinality.required,
        isSensitive: draft.isSensitive,
        acceptsMultiple: cardinality == Cardinality.multiple,
        isFlag: draft.isFlag,
        defaultDisplay: _defaultDisplayFor(draft, defaultValue),
        description: draft.description,
        deprecation: draft.deprecation,
      ),
      ordinal: ordinal,
      cardinality: cardinality,
      converter: draft.converter,
      constraint: draft.constraint,
      validators: draft.validators,
      defaultValue: defaultValue,
      splitDelimiter: draft.splitDelimiter,
      isNegatable: draft.isNegatable,
      collect: parameter.collect,
    );
  }

  /// The environment variable [draft] falls back to.
  ///
  /// Returns the variable named explicitly, else the one derived from the
  /// prefix and the first long name, else `null`.
  String? _environmentVariableFor(ParameterDraft draft) {
    if (!draft.environmentEnabled) {
      return null;
    }
    final String? explicit = draft.environmentVariable;
    if (explicit != null) {
      return explicit;
    }
    final String? prefix = _environmentPrefix;
    if (prefix == null) {
      return null;
    }
    final Iterable<String> longNames = draft.names.where(
      (name) => name.startsWith('--'),
    );
    if (longNames.isEmpty) {
      return null;
    }
    final String body = longNames.first
        .substring(2)
        .replaceAll('-', '_')
        .toUpperCase();
    final String trimmed = prefix.replaceFirst(RegExp(r'_+$'), '');
    return '${trimmed}_$body';
  }

  /// Renders [defaultValue] for the usage listing.
  ///
  /// Returns the rendered default, or `null` when there is nothing worth
  /// showing.
  String? _defaultDisplayFor(ParameterDraft draft, Object? defaultValue) {
    if (defaultValue == null) {
      return null;
    }
    if (draft.isFlag && defaultValue == false) {
      return null;
    }
    if (defaultValue is List<Object?> && defaultValue.isEmpty) {
      return null;
    }
    if (draft.isSensitive) {
      return mask;
    }
    return '$defaultValue';
  }

  /// The snapshot, which [subject] needs.
  ///
  /// Returns the snapshot.
  ///
  /// Throws a [ParametersNotLoadedError] if the schema has not been loaded.
  ParameterSnapshot _requireSnapshot(String subject) =>
      _snapshot ?? (throw ParametersNotLoadedError(subject));

  /// The name [parameter] is reported under.
  ///
  /// Returns its first name, or a placeholder for a foreign parameter.
  static String _nameOf(Parameter<Object?> parameter) {
    if (parameter is DeclaredParameter<Object?>) {
      return parameter.draft.names.first;
    }
    return 'a parameter of another schema';
  }
}
