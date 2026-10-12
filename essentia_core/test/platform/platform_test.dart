/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Product names a runtime reports, and the system each one means.
const _operatingSystems = <String, OperatingSystem>{
  'Linux': OperatingSystem.linux,
  'linux': OperatingSystem.linux,
  'Windows 11': OperatingSystem.windows,
  'Windows Server 2022': OperatingSystem.windows,
  'Mac OS X': OperatingSystem.macos,
  'macOS': OperatingSystem.macos,
  'Darwin': OperatingSystem.macos,
  'iOS': OperatingSystem.ios,
  'ios': OperatingSystem.ios,
  'iPadOS': OperatingSystem.ios,
  'iPhone OS': OperatingSystem.ios,
};

/// Spellings a toolchain emits, and the architecture each one means.
const _architectures = <String, Architecture>{
  'amd64': Architecture.x64,
  'x86_64': Architecture.x64,
  'x86-64': Architecture.x64,
  'x64': Architecture.x64,
  'em64t': Architecture.x64,
  'aarch64': Architecture.aarch64,
  'aarch_64': Architecture.aarch64,
  'arm64': Architecture.aarch64,
};

/// Systems that are not Linux, however Unix-like they are.
const _notLinux = <String>[
  'FreeBSD',
  'OpenBSD',
  'SunOS',
  'Solaris',
  'AIX',
  'HP-UX',
];

/// Architectures that are 32-bit.
const _notSixtyFourBit = <String>[
  'arm',
  'armv7l',
  'armv6',
  'i386',
  'i686',
  'x86',
];

/// Architectures nothing is published for.
const _notPublishedFor = <String>[
  'sparcv9',
  'ppc64',
  'ppc64le',
  'riscv64',
  's390x',
];

/// Tests the table that maps what a runtime reports to a platform,
/// exhaustively rather than on whatever machine runs the test.
void main() {
  group('an operating system is recognised from a product name', () {
    for (final MapEntry<String, OperatingSystem> entry
        in _operatingSystems.entries) {
      test("'${entry.key}' is ${entry.value.identifier}", () {
        expect(OperatingSystem.resolve(entry.key), entry.value);
      });
    }
  });

  group('a system Essentia cannot name is absent, not guessed at', () {
    for (final String reported in _notLinux) {
      test("'$reported' does not resolve", () {
        expect(OperatingSystem.resolve(reported), isNull);
      });
    }

    test('an empty name does not resolve', () {
      expect(OperatingSystem.resolve(''), isNull);
      expect(OperatingSystem.resolve('   '), isNull);
    });
  });

  group('an architecture is recognised from every spelling a toolchain '
      'emits', () {
    for (final MapEntry<String, Architecture> entry in _architectures.entries) {
      test("'${entry.key}' is ${entry.value.identifier}", () {
        expect(Architecture.resolve(entry.key), entry.value);
      });
    }
  });

  group('a 32-bit machine never resolves to a 64-bit build', () {
    for (final String reported in _notSixtyFourBit) {
      test("'$reported' does not resolve", () {
        expect(Architecture.resolve(reported), isNull);
      });
    }
  });

  group('an architecture nothing is published for is absent, not guessed '
      'at', () {
    for (final String reported in _notPublishedFor) {
      test("'$reported' does not resolve", () {
        expect(Architecture.resolve(reported), isNull);
      });
    }

    test('an empty architecture does not resolve', () {
      expect(Architecture.resolve(''), isNull);
      expect(Architecture.resolve('   '), isNull);
    });
  });

  test('what a runtime pads or capitalises is still understood', () {
    expect(Platform.of('  LINUX  ', '  AMD64  ')?.identifier, 'linux-x86_64');
    expect(Platform.of('linux', 'X86_64')?.identifier, 'linux-x86_64');
  });

  test('either half being unrecognised leaves no platform', () {
    expect(Platform.of('Solaris', 'amd64'), isNull);
    expect(Platform.of('Linux', 'armv7l'), isNull);
    expect(Platform.of('', 'amd64'), isNull);
    expect(Platform.of('Linux', ''), isNull);
  });

  test('the halves resolve separately, so a report can say which one it did '
      'not know', () {
    expect(OperatingSystem.resolve('Solaris'), isNull);
    expect(Architecture.resolve('amd64'), isNotNull);
  });

  test('the identifier is what names a directory of binaries', () {
    expect(Platform.of('Windows 11', 'amd64')?.identifier, 'windows-x86_64');
    expect(Platform.of('Mac OS X', 'arm64')?.identifier, 'macos-aarch64');
    expect(Platform.of('Linux', 'aarch64').toString(), 'linux-aarch64');
  });

  test('two ways of spelling one machine are one value', () {
    final Platform? one = Platform.of('Linux', 'amd64');
    final Platform? same = Platform.of('linux', 'x86_64');
    final Platform? other = Platform.of('Linux', 'aarch64');

    expect(one, same);
    expect(one.hashCode, same.hashCode);
    expect(one, isNot(equals(other)));
  });

  group('the predicates answer without a caller comparing enums', () {
    test('Windows is Windows and is not Unix', () {
      final Platform? windows = Platform.of('Windows 11', 'amd64');

      expect(windows, isNotNull);
      expect(windows?.isWindows, isTrue);
      expect(windows?.isLinux, isFalse);
      expect(windows?.isUnix, isFalse);
    });

    test('Linux and macOS are both Unix', () {
      expect(Platform.of('Linux', 'amd64')?.isUnix, isTrue);
      expect(Platform.of('Darwin', 'arm64')?.isUnix, isTrue);
      expect(Platform.of('Darwin', 'arm64')?.isMacos, isTrue);
    });

    test('every system says for itself whether it is Unix', () {
      expect(OperatingSystem.linux.isUnix, isTrue);
      expect(OperatingSystem.macos.isUnix, isTrue);
      expect(OperatingSystem.windows.isUnix, isFalse);
      expect(OperatingSystem.android.isUnix, isTrue);
      expect(OperatingSystem.ios.isUnix, isTrue);
      expect(OperatingSystem.web.isUnix, isFalse);
    });
  });

  group('Android is not Linux and the web is not a machine', () {
    test('Android resolves to itself rather than to Linux', () {
      final Platform? android = Platform.of('Android', 'aarch64');

      expect(android, isNotNull);
      expect(android?.isAndroid, isTrue);
      expect(android?.isLinux, isFalse);
      expect(android?.identifier, 'android-aarch64');
    });

    test('iOS resolves to itself rather than to macOS', () {
      final Platform? ios = Platform.of('iOS', 'arm64');

      expect(ios, isNotNull);
      expect(ios?.isIos, isTrue);
      expect(ios?.isMacos, isFalse);
      expect(ios?.isUnix, isTrue);
      expect(ios?.identifier, 'ios-aarch64');
    });

    test('the simulator on an Intel Mac is iOS on x86_64', () {
      expect(Platform.of('ios', 'x64')?.identifier, 'ios-x86_64');
    });

    test('a runtime reporting Darwin still resolves to macOS', () {
      expect(Platform.of('Darwin', 'arm64')?.isIos, isFalse);
    });

    test('a runtime reporting Linux still resolves to Linux', () {
      expect(Platform.of('Linux', 'aarch64')?.isAndroid, isFalse);
    });

    test('the web has one architecture and it is not a processor', () {
      final Platform? web = Platform.of('web', 'wasm');

      expect(web, isNotNull);
      expect(web?.isWeb, isTrue);
      expect(web?.isUnix, isFalse);
      expect(web?.identifier, 'web-wasm');
    });

    test('every spelling of WebAssembly is one architecture', () {
      expect(Architecture.resolve('wasm'), Architecture.wasm);
      expect(Architecture.resolve('wasm32'), Architecture.wasm);
      expect(Architecture.resolve('wasm64'), Architecture.wasm);
    });
  });

  group('the table can be enumerated, not only resolved', () {
    test('every operating system is paired with every architecture', () {
      final int pairs =
          OperatingSystem.values.length * Architecture.values.length;

      expect(Platform.entries, hasLength(pairs));
    });

    test('every machine the table resolves is one of the entries', () {
      for (final String osName in _operatingSystems.keys) {
        for (final String osArch in _architectures.keys) {
          final Platform? resolved = Platform.of(osName, osArch);

          expect(resolved, isNotNull, reason: '$osName $osArch');
          expect(Platform.entries, contains(resolved));
        }
      }
    });

    test('the identifiers are the identifiers of the entries, and none of '
        'them repeats', () {
      final List<String> rendered = Platform.entries
          .map((platform) => platform.identifier)
          .toList();

      expect(Platform.identifiers, rendered.toSet());
      expect(Platform.identifiers, hasLength(rendered.length));
    });

    test('a misspelt identifier is absent, which is the question the set '
        'exists to answer', () {
      expect(Platform.identifiers, contains('linux-x86_64'));
      expect(Platform.identifiers, isNot(contains('linux-x86-64')));
      expect(Platform.identifiers, isNot(contains('linux-x64')));
    });

    test('it is a cross product, so it holds a pair nobody builds for', () {
      expect(Platform.identifiers, contains('windows-wasm'));
    });

    test('the set refuses to be cleared and still names every platform', () {
      expect(Platform.identifiers.clear, throwsUnsupportedError);

      expect(Platform.identifiers, hasLength(Platform.entries.length));
      expect(Platform.identifiers, contains('linux-x86_64'));
    });

    test('the set refuses a name Essentia does not resolve', () {
      expect(
        () => Platform.identifiers.add('solaris-sparc'),
        throwsUnsupportedError,
      );

      expect(Platform.identifiers, isNot(contains('solaris-sparc')));
    });

    test('the entries refuse to be changed', () {
      expect(Platform.entries.clear, throwsUnsupportedError);

      expect(Platform.entries, isNotEmpty);
    });
  });

  test('the current machine is read once and held', () {
    expect(Platform.current(), Platform.current());
  });
}
