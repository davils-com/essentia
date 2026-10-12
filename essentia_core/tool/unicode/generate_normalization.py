#
# Copyright (c) 2026 Davils GmbH
# All rights reserved.
#
# This software is the property of Davils GmbH.
# Unauthorized copying, modification, distribution, or use of this code,
# in whole or in part, is strictly prohibited without prior written permission.
#

"""Generates the Unicode normalization tables of Essentia and their test corpus.

The data comes from the `unicodedata` module of the Python that runs this
script, so the Unicode version of the tables is the one that Python ships.

Run from the repository root:

    python3 tool/unicode/generate_normalization.py
    python3 tool/unicode/generate_normalization.py --check

`--check` writes nothing and fails when a generated file is out of date.
"""

import random
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_FILE = ROOT / "lib/src/text/internal/unicode_normalization_data.dart"
CORPUS_FILE = ROOT / "test/text/unicode_normalization_corpus.dart"

HEADER = """/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */
"""

S_BASE, L_BASE, V_BASE, T_BASE = 0xAC00, 0x1100, 0x1161, 0x11A7
L_COUNT, V_COUNT, T_COUNT = 19, 21, 28
S_COUNT = L_COUNT * V_COUNT * T_COUNT
MAX_CODE_POINT = 0x10FFFF


def is_hangul_syllable(code_point):
    """Whether the code point is a precomposed Hangul syllable."""
    return S_BASE <= code_point < S_BASE + S_COUNT


def is_surrogate(code_point):
    """Whether the code point is a surrogate, which a string cannot hold alone."""
    return 0xD800 <= code_point <= 0xDFFF


def canonical_decompositions():
    """Maps every code point to its canonical decomposition mapping.

    Hangul syllables are left out: they decompose algorithmically.
    """
    result = {}
    for code_point in range(MAX_CODE_POINT + 1):
        if is_hangul_syllable(code_point) or is_surrogate(code_point):
            continue
        mapping = unicodedata.decomposition(chr(code_point))
        if not mapping or mapping.startswith("<"):
            continue
        parts = [int(part, 16) for part in mapping.split()]
        assert 1 <= len(parts) <= 2, hex(code_point)
        result[code_point] = parts
    return result


def combining_classes():
    """Maps every code point with a non-zero canonical combining class to it."""
    result = {}
    for code_point in range(MAX_CODE_POINT + 1):
        if is_surrogate(code_point):
            continue
        combining_class = unicodedata.combining(chr(code_point))
        if combining_class:
            result[code_point] = combining_class
    return result


def primary_composites(decompositions, classes):
    """The composition pairs: (first, second) -> primary composite.

    A pair comes from every canonical two code point decomposition whose
    composite is not excluded from composition: no singleton, no non-starter
    decomposition and no entry of the composition exclusion table. Python's
    own NFC confirms every pair.
    """
    result = {}
    for code_point, parts in decompositions.items():
        if len(parts) != 2:
            continue
        composite = chr(code_point)
        excluded = unicodedata.normalize("NFC", composite) != composite
        if classes.get(code_point, 0) or classes.get(parts[0], 0) or excluded:
            continue
        pair = chr(parts[0]) + chr(parts[1])
        assert unicodedata.normalize("NFC", pair) == composite, hex(code_point)
        result[(parts[0], parts[1])] = code_point
    return result


def nfc_quick_check(pairs):
    """Maps every code point whose NFC quick check is not Yes to 1 (Maybe) or 2 (No)."""
    result = {}
    for _, second in pairs:
        result[second] = 1
    for code_point in range(V_BASE, V_BASE + V_COUNT):
        result[code_point] = 1
    for code_point in range(T_BASE + 1, T_BASE + T_COUNT):
        result[code_point] = 1
    for code_point in range(MAX_CODE_POINT + 1):
        if is_surrogate(code_point):
            continue
        character = chr(code_point)
        if unicodedata.normalize("NFC", character) != character:
            assert code_point not in result, hex(code_point)
            result[code_point] = 2
    return result


def ranges(values):
    """Groups a code point -> value map into (start, end, value) runs."""
    result = []
    for code_point in sorted(values):
        value = values[code_point]
        if result and result[-1][1] == code_point - 1 and result[-1][2] == value:
            result[-1] = (result[-1][0], code_point, value)
            continue
        result.append((code_point, code_point, value))
    return result


def string_constant(records, per_line):
    """Writes records of fixed width as adjacent Dart string literals."""
    lines = []
    for index in range(0, len(records), per_line):
        lines.append("    '" + "".join(records[index : index + per_line]) + "'")
    return "\n".join(lines) + ";\n"


def data_source(decompositions, pairs, classes, quick_check):
    """The Dart source of the generated tables."""
    decomposition_records = [
        f"{code_point:06X}{parts[0]:06X}{(parts[1] if len(parts) == 2 else 0):06X}"
        for code_point, parts in sorted(decompositions.items())
    ]
    composition_records = [
        f"{first:06X}{second:06X}{composite:06X}"
        for (first, second), composite in sorted(pairs.items())
    ]
    class_records = [
        f"{start:06X}{end:06X}{value:02X}" for start, end, value in ranges(classes)
    ]
    quick_check_records = [
        f"{start:06X}{end:06X}{value:X}" for start, end, value in ranges(quick_check)
    ]
    version = unicodedata.unidata_version
    return (
        HEADER
        + f"""
/// The Unicode {version} character data of the normalization forms,
/// generated by `tool/unicode/generate_normalization.py` from Python's
/// `unicodedata`. Do not edit.
///
/// Every table is a run of fixed width records of upper case hexadecimal
/// fields, sorted by their first field.
@internal
library;

import 'package:meta/meta.dart';

/// The version of the Unicode character database the tables come from.
const unicodeNormalizationVersion = '{version}';

/// The number of canonical decomposition mappings in
/// [canonicalDecompositionTable].
const canonicalDecompositionCount = {len(decomposition_records)};

/// The canonical decomposition mapping of every code point that has one,
/// Hangul syllables aside: 18 characters per record, the code point, the
/// first and the second code point of its mapping, six digits each, the
/// second `000000` for a singleton.
const canonicalDecompositionTable =
{string_constant(decomposition_records, 4)}
/// The number of composition pairs in [canonicalCompositionTable].
const canonicalCompositionCount = {len(composition_records)};

/// The primary composites, Hangul syllables aside: 18 characters per record,
/// the first and the second code point of a pair and the composite they
/// form, six digits each, sorted by the pair.
const canonicalCompositionTable =
{string_constant(composition_records, 4)}
/// The number of ranges in [combiningClassTable].
const combiningClassCount = {len(class_records)};

/// The canonical combining class of every code point whose class is not 0:
/// 14 characters per record, the first and the last code point of a range,
/// six digits each, and the class of the range, two digits.
const combiningClassTable =
{string_constant(class_records, 5)}
/// The number of ranges in [nfcQuickCheckTable].
const nfcQuickCheckCount = {len(quick_check_records)};

/// The NFC quick check of every code point for which it is not Yes: 13
/// characters per record, the first and the last code point of a range,
/// six digits each, and one digit, 1 for Maybe and 2 for No.
const nfcQuickCheckTable =
{string_constant(quick_check_records, 5)}"""
    )


def hex_sequence(text):
    """The code points of text as hexadecimal numbers joined by commas."""
    return ",".join(f"{ord(character):X}" for character in text)


def corpus_case(text):
    """One corpus case: source, NFC and NFD, an empty field repeating the previous one."""
    nfc = unicodedata.normalize("NFC", text)
    nfd = unicodedata.normalize("NFD", text)
    fields = [hex_sequence(text)]
    fields.append("" if nfc == text else hex_sequence(nfc))
    fields.append("" if nfd == nfc else hex_sequence(nfd))
    return ";".join(fields)


def corpus_texts(decompositions, classes, pairs):
    """The texts of the corpus: every decomposable character, every mark, Hangul and random mixes."""
    texts = [chr(code_point) for code_point in sorted(decompositions)]
    texts += ["A" + chr(code_point) + "́" for code_point in sorted(classes)]
    texts += [
        "가",
        "힣",
        "각",
        "가",
        "히",
        "각",
        "힣",
        "가ᆧ",
        "가ᇃ",
        "각",
        "가ᆧ",
        "각ᆨ",
        "ᄀ가",
        "ᄀᅶ",
        "ᄓᅡ",
        "ჿᅡ",
        "ᄀᅠ",
        "ᄀ́ᅡ",
        "가́ᆨ",
        "힣ᆨ",
        "가̀ᆨ",
        "ᅡ",
        "ᆨ",
        "ᄀ",
        "ą́",
        "ą́",
        "ą́",
        "ą́",
        "ậ",
        "ậ",
        "ậ́",
        "é́",
        "e̅́",
        "é̕",
        "é̕",
        "ୋ",
        "େ̀ା",
        "क़",
        "क़",
        "Å",
        "Ω",
        "̈́",
        "ཱི",
        "ཱི",
        "\U0001D15E",
        "\U0001D160",
        "\U0001D157\U0001D165",
        "\U0001D158\U0001D165\U0001D16E",
        "\U00011099\U000110BA",
        "\U0001109A",
        "\U0002F800",
        "אִַָ",
        "à֮́̕",
        "Ạ̊",
        "ẛ̣",
        "q̣̇",
        "ḍ̇",
        "Ḍ̇",
        "Ḍ̇",
        "Ḉ",
        "Ḉ",
    ]
    rng = random.Random(20261010)
    pool_bases = [chr(code_point) for code_point in range(0x41, 0x5B)] + [
        chr(first) for first, _ in pairs
    ]
    pool_marks = [chr(code_point) for code_point in sorted(classes)]
    pool_seconds = sorted({chr(second) for _, second in pairs})
    pool_decomposable = [chr(code_point) for code_point in sorted(decompositions)]
    pool_hangul = (
        [chr(L_BASE + index) for index in range(L_COUNT)]
        + [chr(V_BASE + index) for index in range(V_COUNT)]
        + [chr(T_BASE + index) for index in range(T_COUNT)]
        + [chr(S_BASE + rng.randrange(S_COUNT)) for _ in range(40)]
    )
    pool_plain = ["a", " ", "中", "\U0001F600", "\U0001D400", "̀"]
    pools = [
        pool_bases,
        pool_marks,
        pool_seconds,
        pool_seconds,
        pool_decomposable,
        pool_hangul,
        pool_plain,
    ]
    for _ in range(1200):
        length = rng.randrange(2, 7)
        texts.append("".join(rng.choice(rng.choice(pools)) for _ in range(length)))
    unique = []
    seen = set()
    for text in texts:
        if text not in seen:
            seen.add(text)
            unique.append(text)
    return unique


def corpus_source(texts):
    """The Dart source of the test corpus."""
    joined = "|".join(corpus_case(text) for text in texts)
    chunks = [joined[index : index + 72] for index in range(0, len(joined), 72)]
    body = "\n".join(f"    '{chunk}'" for chunk in chunks)
    version = unicodedata.unidata_version
    return (
        HEADER
        + f"""
/// The number of cases in [unicodeNormalizationCorpus].
const unicodeNormalizationCorpusSize = {len(texts)};

/// Normalization cases checked against Python's `unicodedata` of Unicode
/// {version}, generated by `tool/unicode/generate_normalization.py`. Do not
/// edit.
///
/// The cases are separated by `|`; a case is the source, its NFC and its NFD,
/// separated by `;`, each a sequence of hexadecimal code points separated by
/// `,`. An empty NFC is the source, an empty NFD the NFC.
const unicodeNormalizationCorpus =
{body};
"""
    )


def main(arguments):
    """Generates the files, or checks them with `--check`."""
    decompositions = canonical_decompositions()
    classes = combining_classes()
    pairs = primary_composites(decompositions, classes)
    quick_check = nfc_quick_check(pairs)
    outputs = {
        DATA_FILE: data_source(decompositions, pairs, classes, quick_check),
        CORPUS_FILE: corpus_source(corpus_texts(decompositions, classes, pairs)),
    }
    check = "--check" in arguments
    stale = []
    for path, source in outputs.items():
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != source:
                stale.append(path)
            continue
        path.write_text(source, encoding="utf-8")
    for path in stale:
        print(f"Out of date: {path.relative_to(ROOT)}", file=sys.stderr)
    print(
        f"Unicode {unicodedata.unidata_version}: {len(decompositions)} decompositions, "
        f"{len(pairs)} compositions, {len(ranges(classes))} combining class ranges, "
        f"{len(ranges(quick_check))} quick check ranges"
    )
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
