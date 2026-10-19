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

import 'package:essentia_core/src/result/result.dart';
import 'package:essentia_core/src/result/result_async.dart';
import 'package:test/test.dart';

import 'probe_log.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// A future of a success carrying 7.
///
/// Returns the future.
Future<Result<int>> _seven() async => const Success<int>(7);

/// A future of a failure carrying [_bad].
///
/// Returns the future.
Future<Result<int>> _broken() async => const Failure<int>(_bad);

/// Covers [ResultAsync], the operations of a result on a future of a
/// result.
void main() {
  test('maps the value a future of a result carries', () async {
    final Result<String> mapped = await _seven().map((value) => '$value');

    expect(mapped, const Success<String>('7'));
  });

  test('maps the value a future of a result carries asynchronously', () async {
    final Result<String> mapped = await _seven().mapAsync(
      (value) async => '$value',
    );

    expect(mapped, const Success<String>('7'));
  });

  test('chains a future of a result into another result', () async {
    final Result<String> chained = await _seven().flatMap(
      (value) => Success<String>('$value'),
    );

    expect(chained, const Success<String>('7'));
  });

  test(
    'chains a future of a result into another result asynchronously',
    () async {
      final Result<String> chained = await _seven().flatMapAsync(
        (value) async => Success<String>('$value'),
      );

      expect(chained, const Success<String>('7'));
    },
  );

  test('replaces the error a future of a result carries', () async {
    final Result<int> relabelled = await _broken().mapError(
      (error, stackTrace) => StateError('$error'),
    );

    expect(relabelled.errorOrNull, isA<StateError>());
  });

  test('recovers the failure a future of a result carries', () async {
    final Result<int> recovered = await _broken().recover(
      (error, stackTrace) => 0,
    );

    expect(recovered, const Success<int>(0));
  });

  test('observes the value a future of a result carries', () async {
    final log = ProbeLog();

    await _seven().onSuccess((value) => log.record('$value'));

    expect(log.entries, ['7']);
  });

  test('observes the error a future of a result carries', () async {
    final log = ProbeLog();

    await _broken().onFailure((error, stackTrace) => log.record('$error'));

    expect(log.entries, ['$_bad']);
  });

  test('folds a future of a result into one value', () async {
    final String folded = await _seven().fold(
      onSuccess: (value) => 'value $value',
      onFailure: (error, stackTrace) => 'error $error',
    );

    expect(folded, 'value 7');
  });

  test('falls back when a future of a result carries a failure', () async {
    final int value = await _broken().getOrElse((error, stackTrace) => 0);

    expect(value, 0);
  });

  test('unwraps the value a future of a result carries', () async {
    final int value = await _seven().getOrThrow();

    expect(value, 7);
  });
}
