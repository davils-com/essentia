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

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'bundle_parameters.dart';
import 'failure_of.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests that a bundle of short flags is read as one decision.
void main() {
  group('a bundle with an undeclared letter, when unknown arguments are '
      'rejected', () {
    test('is reported by the letter and the bundle it was in', () {
      final UnknownArgument violation = singleViolation<UnknownArgument>(
        failureOf(
          () =>
              BundleParameters().load(<String>['-axc'], environment: _nothing),
        ),
      );

      expect(violation.token, '-x');
      expect(violation.bundle, '-axc');
      expect(
        violation.message,
        'is not a known parameter, so nothing in -axc was applied',
      );
    });

    test('is reported even when the undeclared letter comes first', () {
      final UnknownArgument violation = singleViolation<UnknownArgument>(
        failureOf(
          () =>
              BundleParameters().load(<String>['-xac'], environment: _nothing),
        ),
      );

      expect(violation.token, '-x');
      expect(violation.bundle, '-xac');
    });
  });

  group('a bundle with an undeclared letter, when unknown arguments are '
      'collected', () {
    test('applies none of its letters', () {
      final parameters = BundleParameters(UnknownArgumentPolicy.collect)
        ..load(<String>['-axc'], environment: _nothing);

      expect(parameters.all.value, isFalse);
      expect(parameters.colour.value, isFalse);
    });

    test('is collected as the token that was passed', () {
      final parameters = BundleParameters(UnknownArgumentPolicy.collect)
        ..load(<String>['-axc'], environment: _nothing);

      expect(parameters.unknown, <String>['-axc']);
    });
  });

  group('a bundle of declared letters', () {
    test('applies every one of them', () {
      final parameters = BundleParameters()
        ..load(<String>['-ac'], environment: _nothing);

      expect(parameters.all.value, isTrue);
      expect(parameters.colour.value, isTrue);
    });

    test('may end in a parameter whose value is attached', () {
      final parameters = BundleParameters()
        ..load(<String>['-ap8080'], environment: _nothing);

      expect(parameters.all.value, isTrue);
      expect(parameters.port.value, 8080);
    });

    test('treats what follows a value-taking letter as its value, not as '
        'more letters', () {
      singleViolation<ConversionFailure>(
        failureOf(
          () => BundleParameters().load(<String>[
            '-apxyz',
          ], environment: _nothing),
        ),
      );
    });

    test('may end in a flag whose value is attached', () {
      final parameters = BundleParameters()
        ..load(<String>['-ac=false'], environment: _nothing);

      expect(parameters.all.value, isTrue);
      expect(parameters.colour.value, isFalse);
    });
  });

  test('a single undeclared short name is reported without a bundle', () {
    final UnknownArgument violation = singleViolation<UnknownArgument>(
      failureOf(
        () => BundleParameters().load(<String>['-x'], environment: _nothing),
      ),
    );

    expect(violation.bundle, isNull);
    expect(violation.message, 'is not a known parameter');
  });
}
