/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/number/byte_size.dart';
import 'package:essentia/src/number/byte_size_units.dart';
import 'package:test/test.dart';

/// Texts and the number of bytes each one means.
const _read = <String, int>{
  '0': 0,
  '4096': 4096,
  '512B': 512,
  '1KiB': 1024,
  '1kB': 1000,
  '1KB': 1000,
  '16MiB': 16777216,
  '16mib': 16777216,
  '10MB': 10000000,
  '1.5GiB': 1610612736,
  '2TiB': 2199023255552,
  '1PiB': 1125899906842624,
  '3PB': 3000000000000000,
  ' 16 MiB ': 16777216,
  '0.5KiB': 512,
  '9007199254740991': 9007199254740991,
};

/// Texts that are not a size.
const _refused = <String>[
  '',
  ' ',
  'B',
  'KiB',
  '-1',
  '-1KiB',
  '+5',
  '0x10',
  '1e3',
  '1.5',
  '0.3B',
  '1.1KiB',
  '16 XB',
  '8PiB',
  '9007199254740992',
  '99999999999999999999999',
  'NaNB',
  'InfinityB',
];

/// Covers reading, rendering and comparing sizes.
void main() {
  for (final MapEntry<String, int>(:key, :value) in _read.entries) {
    test('reads "$key"', () {
      final ByteSize size = ByteSize.parse(key);

      expect(size.bytes, value);
    });
  }

  for (final String text in _refused) {
    test('refuses "$text"', () {
      final ByteSize? size = ByteSize.tryParse(text);

      expect(size, isNull);
    });
  }

  test('a refusal does not quote the text', () {
    const text = 'secret-token';

    expect(
      () => ByteSize.parse(text),
      throwsA(
        isA<FormatException>().having(
          (failure) => failure.message,
          'message',
          isNot(contains(text)),
        ),
      ),
    );
  });

  test('renders the largest binary unit that holds the size exactly', () {
    expect(16.mebibytes.toString(), '16MiB');
    expect(const ByteSize(1536).toString(), '1536B');
    expect(1.gibibytes.toString(), '1GiB');
    expect(2048.kibibytes.toString(), '2MiB');
    expect(ByteSize.zero.toString(), '0B');
    expect(10.megabytes.toString(), '10000000B');
  });

  test('reads back what it renders', () {
    for (final size in <ByteSize>[
      ByteSize.zero,
      const ByteSize(1),
      const ByteSize(1536),
      3.kibibytes,
      7.mebibytes,
      5.gibibytes,
      4.tebibytes,
      9.terabytes,
      const ByteSize(ByteSize.maxBytes),
    ]) {
      expect(ByteSize.parse(size.toString()), size);
    }
  });

  test('the units multiply as their names say', () {
    expect(1.kilobytes.bytes, 1000);
    expect(1.megabytes.bytes, 1000000);
    expect(1.gigabytes.bytes, 1000000000);
    expect(1.terabytes.bytes, 1000000000000);
    expect(1.kibibytes.bytes, 1024);
    expect(1.tebibytes.bytes, 1099511627776);
  });

  test('sizes compare and equal by their bytes', () {
    final ByteSize small = 1.kibibytes;
    final ByteSize large = 1.mebibytes;

    expect(small < large, isTrue);
    expect(small <= large, isTrue);
    expect(large > small, isTrue);
    expect(large >= small, isTrue);
    expect(small >= small, isTrue);
    expect(small.compareTo(large), lessThan(0));
    expect(const ByteSize(1024), 1.kibibytes);
    expect(const ByteSize(1024).hashCode, 1.kibibytes.hashCode);
    expect(small == large, isFalse);
  });
}
