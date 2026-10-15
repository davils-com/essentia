/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/brotli/brotli_bit_mark.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_bit_reader.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_block_category.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_codes.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_damaged.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_decoder_stage.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_dictionary.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_input_needed.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_prefix_code.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_tables.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_transforms.dart';
import 'package:meta/meta.dart';

/// Decodes a Brotli stream, RFC 7932, from the chunks added to it.
///
/// The decoder takes small steps: a header, a command, up to
/// [_literalsPerStep] literals, a distance, a copy. A step that runs out
/// of bytes goes back to where it began, and is taken again once more
/// bytes are added, so the decoder is a plain synchronous reader that
/// still decodes a stream as it arrives. What a step wrote stays in the
/// ring buffer, beyond the window behind the bytes handed on, so going
/// back never loses a byte a later distance refers to.
@internal
final class BrotliStreamDecoder {
  /// The most literals one step decodes.
  static const _literalsPerStep = 256;

  /// How many decoded bytes are gathered before they are handed on.
  static const _chunkSize = 16384;

  /// How far the ring buffer reaches beyond the window.
  static const _ringSlack = 65536;

  /// The first size of the ring buffer.
  static const _initialRing = 65536;

  /// The bits that are read.
  final _reader = BrotliBitReader();

  /// The decoded chunks not handed on yet.
  final _output = <Uint8List>[];

  /// What is read next.
  BrotliDecoderStage _stage = BrotliDecoderStage.streamHeader;

  /// The window: the farthest a distance reaches back.
  var _windowSize = 0;

  /// The size the ring buffer grows to at most.
  var _maxRing = 0;

  /// The decoded bytes, of which the last [_windowSize] count.
  var _ring = Uint8List(0);

  /// Where the next byte goes in [_ring].
  var _ringPosition = 0;

  /// How many bytes were decoded.
  var _total = 0;

  /// How many decoded bytes were handed on.
  var _emitted = 0;

  /// The last byte decoded.
  var _last = 0;

  /// The byte decoded before [_last].
  var _beforeLast = 0;

  /// Whether the current meta-block is the last one.
  var _isLast = false;

  /// How many bytes of the current meta-block are still to come.
  var _metaRemaining = 0;

  /// The literal blocks of the current meta-block.
  BrotliBlockCategory? _literals;

  /// The insert-and-copy blocks of the current meta-block.
  BrotliBlockCategory? _commands;

  /// The distance blocks of the current meta-block.
  BrotliBlockCategory? _distances;

  /// The context mode of each literal block type.
  var _contextModes = Uint8List(0);

  /// The literal context map.
  var _literalMap = Uint8List(0);

  /// The distance context map.
  var _distanceMap = Uint8List(0);

  /// The literal prefix codes.
  var _literalCodes = <BrotliPrefixCode>[];

  /// The insert-and-copy prefix codes.
  var _commandCodes = <BrotliPrefixCode>[];

  /// The distance prefix codes.
  var _distanceCodes = <BrotliPrefixCode>[];

  /// NPOSTFIX of the current meta-block.
  var _postfixBits = 0;

  /// NDIRECT of the current meta-block.
  var _directCodes = 0;

  /// The literals the current command still inserts.
  var _insertRemaining = 0;

  /// The copy length of the current command.
  var _copyLength = 0;

  /// Whether the current command reuses the last distance implicitly.
  var _implicitDistance = false;

  /// The bytes the current copy still writes.
  var _copyRemaining = 0;

  /// The distance of the current copy.
  var _copyDistance = 0;

  /// The last distance.
  var _distance0 = 4;

  /// The second to last distance.
  var _distance1 = 11;

  /// The third to last distance.
  var _distance2 = 15;

  /// The fourth to last distance.
  var _distance3 = 16;

  /// [_ringPosition] as [_save] kept it.
  var _savedRingPosition = 0;

  /// [_total] as [_save] kept it.
  var _savedTotal = 0;

  /// [_last] as [_save] kept it.
  var _savedLast = 0;

  /// [_beforeLast] as [_save] kept it.
  var _savedBeforeLast = 0;

  /// [_metaRemaining] as [_save] kept it.
  var _savedMetaRemaining = 0;

  /// [_insertRemaining] as [_save] kept it.
  var _savedInsertRemaining = 0;

  /// Decodes [chunk], the next bytes of the stream.
  ///
  /// Returns the decoded bytes it completed, in chunks.
  ///
  /// Throws a [FormatException] for data that is not Brotli, is damaged or
  /// follows the end of the stream.
  List<Uint8List> add(List<int> chunk) {
    if (_stage == BrotliDecoderStage.done) {
      if (chunk.isNotEmpty) {
        throw const FormatException('The brotli data is followed by more data');
      }
      return const <Uint8List>[];
    }
    _reader.add(chunk);
    _run();
    return _drain();
  }

  /// Ends the stream.
  ///
  /// Returns the decoded bytes still held, in chunks.
  ///
  /// Throws a [FormatException] for a stream cut short.
  List<Uint8List> close() {
    _reader.close();
    _run();
    return _drain();
  }

  /// Takes steps until the stream ends or needs more bytes.
  void _run() {
    while (true) {
      final BrotliBitMark mark = _reader.mark();
      _save();
      try {
        if (!_step()) {
          return;
        }
      } on BrotliInputNeeded {
        _reader.reset(mark);
        _restore();
        return;
      }
      if (_total - _emitted >= _chunkSize) {
        _emit();
      }
    }
  }

  /// Takes the step of [_stage].
  ///
  /// Returns whether there was one, `false` once the stream ended.
  bool _step() {
    switch (_stage) {
      case BrotliDecoderStage.streamHeader:
        _readStreamHeader();
      case BrotliDecoderStage.metaBlockHeader:
        _readMetaBlockHeader();
      case BrotliDecoderStage.metadata:
        _skipMetadata();
      case BrotliDecoderStage.uncompressed:
        _copyUncompressed();
      case BrotliDecoderStage.command:
        _readCommand();
      case BrotliDecoderStage.literals:
        _readLiterals();
      case BrotliDecoderStage.distance:
        _readDistance();
      case BrotliDecoderStage.copy:
        _copy();
      case BrotliDecoderStage.done:
        return false;
    }
    return true;
  }

  /// Reads the size of the window, RFC 7932 section 9.1.
  void _readStreamHeader() {
    final int windowBits = _readWindowBits();
    _windowSize = (1 << windowBits) - 16;
    _maxRing = (1 << windowBits) + _ringSlack;
    _ring = Uint8List(_initialRing < _maxRing ? _initialRing : _maxRing);
    _stage = BrotliDecoderStage.metaBlockHeader;
  }

  /// Reads WBITS, RFC 7932 section 9.1.
  ///
  /// Returns it, 10 to 24.
  int _readWindowBits() {
    if (_reader.readBits(1) == 0) {
      return 16;
    }
    final int high = _reader.readBits(3);
    if (high != 0) {
      return 17 + high;
    }
    final int low = _reader.readBits(3);
    if (low == 1) {
      brotliDamaged('its window size is not valid');
    }
    return low == 0 ? 17 : 8 + low;
  }

  /// Reads the header of a meta-block, RFC 7932 section 9.2.
  void _readMetaBlockHeader() {
    final isLast = _reader.readBits(1) == 1;
    if (isLast && _reader.readBits(1) == 1) {
      _finish();
      return;
    }
    final int nibbles = _reader.readBits(2) + 4;
    if (nibbles == 7) {
      _readMetadataHeader(isLast);
      return;
    }
    var length = 0;
    for (var nibble = 0; nibble < nibbles; nibble += 1) {
      final int value = _reader.readBits(4);
      if (nibble == nibbles - 1 && nibbles > 4 && value == 0) {
        brotliDamaged('a meta-block length has a needless nibble');
      }
      length |= value << (4 * nibble);
    }
    length += 1;
    if (!isLast && _reader.readBits(1) == 1) {
      _reader.alignToByte();
      _isLast = false;
      _metaRemaining = length;
      _stage = BrotliDecoderStage.uncompressed;
      return;
    }
    _readCompressedHeader(isLast, length);
  }

  /// Reads the header of a metadata block, RFC 7932 section 9.2.
  void _readMetadataHeader(bool isLast) {
    if (_reader.readBits(1) != 0) {
      brotliDamaged('a reserved bit is set');
    }
    final int bytes = _reader.readBits(2);
    var length = 0;
    for (var index = 0; index < bytes; index += 1) {
      final int value = _reader.readBits(8);
      if (index == bytes - 1 && bytes > 1 && value == 0) {
        brotliDamaged('a metadata length has a needless byte');
      }
      length |= value << (8 * index);
    }
    _reader.alignToByte();
    _isLast = isLast;
    _metaRemaining = bytes == 0 ? 0 : length + 1;
    _stage = BrotliDecoderStage.metadata;
  }

  /// Reads the rest of the header of a compressed meta-block of [length]
  /// bytes, RFC 7932 section 9.2.
  void _readCompressedHeader(bool isLast, int length) {
    final literals = BrotliBlockCategory.read(_reader);
    final commands = BrotliBlockCategory.read(_reader);
    final distances = BrotliBlockCategory.read(_reader);
    final int postfixBits = _reader.readBits(2);
    final int directCodes = _reader.readBits(4) << postfixBits;
    final contextModes = Uint8List(literals.count);
    for (var type = 0; type < literals.count; type += 1) {
      contextModes[type] = _reader.readBits(2);
    }
    final int literalTrees = readBrotliCount(_reader);
    final Uint8List literalMap = literalTrees < 2
        ? Uint8List(64 * literals.count)
        : readBrotliContextMap(_reader, 64 * literals.count, literalTrees);
    final int distanceTrees = readBrotliCount(_reader);
    final Uint8List distanceMap = distanceTrees < 2
        ? Uint8List(4 * distances.count)
        : readBrotliContextMap(_reader, 4 * distances.count, distanceTrees);
    final literalCodes = <BrotliPrefixCode>[
      for (var tree = 0; tree < literalTrees; tree += 1)
        readBrotliPrefixCode(_reader, 256),
    ];
    final commandCodes = <BrotliPrefixCode>[
      for (var tree = 0; tree < commands.count; tree += 1)
        readBrotliPrefixCode(_reader, 704),
    ];
    final int distanceAlphabet = 16 + directCodes + (48 << postfixBits);
    final distanceCodes = <BrotliPrefixCode>[
      for (var tree = 0; tree < distanceTrees; tree += 1)
        readBrotliPrefixCode(_reader, distanceAlphabet),
    ];
    _literals = literals;
    _commands = commands;
    _distances = distances;
    _postfixBits = postfixBits;
    _directCodes = directCodes;
    _contextModes = contextModes;
    _literalMap = literalMap;
    _distanceMap = distanceMap;
    _literalCodes = literalCodes;
    _commandCodes = commandCodes;
    _distanceCodes = distanceCodes;
    _isLast = isLast;
    _metaRemaining = length;
    _stage = BrotliDecoderStage.command;
  }

  /// Skips the bytes of a metadata block that are there.
  void _skipMetadata() {
    if (_metaRemaining == 0) {
      _endMetaBlock();
      return;
    }
    int count = _reader.alignedBytes;
    if (count == 0) {
      _reader.readAlignedByte();
    }
    if (count > _metaRemaining) {
      count = _metaRemaining;
    }
    for (var index = 0; index < count; index += 1) {
      _reader.readAlignedByte();
    }
    _metaRemaining -= count;
  }

  /// Copies the bytes of an uncompressed meta-block that are there.
  void _copyUncompressed() {
    if (_metaRemaining == 0) {
      _endMetaBlock();
      return;
    }
    int count = _reader.alignedBytes;
    if (count == 0) {
      _reader.readAlignedByte();
    }
    if (count > _metaRemaining) {
      count = _metaRemaining;
    }
    for (var index = 0; index < count; index += 1) {
      if (_total - _emitted >= _chunkSize) {
        _emit();
      }
      _put(_reader.readAlignedByte());
    }
    _metaRemaining -= count;
  }

  /// Reads the insert-and-copy length of the next command, RFC 7932
  /// section 5, or ends the meta-block.
  void _readCommand() {
    if (_metaRemaining == 0) {
      _endMetaBlock();
      return;
    }
    final BrotliBlockCategory commands = _commands!..next(_reader);
    final int symbol = _commandCodes[commands.type].read(_reader);
    final int cell = symbol >> 6;
    final int insertCode = brotliCellInsert[cell] + ((symbol >> 3) & 7);
    final int copyCode = brotliCellCopy[cell] + (symbol & 7);
    final int insert =
        brotliInsertBase[insertCode] +
        _reader.readBits(brotliInsertExtra[insertCode]);
    final int copy =
        brotliCopyBase[copyCode] + _reader.readBits(brotliCopyExtra[copyCode]);
    if (insert > _metaRemaining) {
      brotliDamaged('a command inserts more than its meta-block holds');
    }
    _insertRemaining = insert;
    _copyLength = copy;
    _implicitDistance = cell < 2;
    _stage = BrotliDecoderStage.literals;
  }

  /// Reads up to [_literalsPerStep] literals of the current command, RFC
  /// 7932 section 7.
  void _readLiterals() {
    final BrotliBlockCategory literals = _literals!;
    var count = 0;
    while (_insertRemaining > 0 && count < _literalsPerStep) {
      literals.next(_reader);
      final int context = _context(_contextModes[literals.type]);
      final BrotliPrefixCode code =
          _literalCodes[_literalMap[(literals.type << 6) + context]];
      _put(code.read(_reader));
      _insertRemaining -= 1;
      _metaRemaining -= 1;
      count += 1;
    }
    if (_insertRemaining > 0) {
      return;
    }
    _stage = _metaRemaining == 0
        ? BrotliDecoderStage.command
        : BrotliDecoderStage.distance;
  }

  /// The context of the next literal in [mode], RFC 7932 section 7.1.
  ///
  /// Returns it, 0 to 63.
  int _context(int mode) {
    if (mode == 0) {
      return _last & 0x3F;
    }
    if (mode == 1) {
      return _last >> 2;
    }
    if (mode == 2) {
      return brotliLut0[_last] | brotliLut1[_beforeLast];
    }
    return (brotliLut2[_last] << 3) | brotliLut2[_beforeLast];
  }

  /// Reads the distance of the current command, RFC 7932 section 4, and
  /// writes a dictionary word or prepares the copy.
  void _readDistance() {
    var code = 0;
    if (!_implicitDistance) {
      final BrotliBlockCategory distances = _distances!..next(_reader);
      final int context = _copyLength > 4 ? 3 : _copyLength - 2;
      code = _distanceCodes[_distanceMap[(distances.type << 2) + context]].read(
        _reader,
      );
    }
    final int distance = _distanceOf(code);
    final int reach = _total < _windowSize ? _total : _windowSize;
    if (distance > reach) {
      _writeWord(distance - reach - 1);
      _stage = BrotliDecoderStage.command;
      return;
    }
    if (_copyLength > _metaRemaining) {
      brotliDamaged('a copy is longer than its meta-block holds');
    }
    if (code != 0) {
      _distance3 = _distance2;
      _distance2 = _distance1;
      _distance1 = _distance0;
      _distance0 = distance;
    }
    _copyRemaining = _copyLength;
    _copyDistance = distance;
    _stage = BrotliDecoderStage.copy;
  }

  /// The distance distance [code] stands for, reading its extra bits.
  ///
  /// Returns it.
  ///
  /// Throws a [FormatException] for a distance that is not positive.
  int _distanceOf(int code) {
    if (code < 16) {
      final int distance = _lastDistance(code);
      if (distance <= 0) {
        brotliDamaged('a distance is not positive');
      }
      return distance;
    }
    if (code < 16 + _directCodes) {
      return code - 15;
    }
    final int index = code - _directCodes - 16;
    final int extraBits = 1 + (index >> (_postfixBits + 1));
    final int high = index >> _postfixBits;
    final int low = index & ((1 << _postfixBits) - 1);
    final int offset = ((2 + (high & 1)) << extraBits) - 4;
    return ((offset + _reader.readBits(extraBits)) << _postfixBits) +
        low +
        _directCodes +
        1;
  }

  /// The distance a special distance [code], 0 to 15, stands for, RFC 7932
  /// section 4.
  ///
  /// Returns it, which may not be positive.
  int _lastDistance(int code) {
    if (code < 4) {
      return <int>[_distance0, _distance1, _distance2, _distance3][code];
    }
    final int base = code < 10 ? _distance0 : _distance1;
    final int step = ((code - 4) % 6 >> 1) + 1;
    return (code - 4).isEven ? base - step : base + step;
  }

  /// Writes the dictionary word [wordId] of the copy length refers to, RFC
  /// 7932 section 8.
  ///
  /// Throws a [FormatException] for a length or transformation the
  /// dictionary does not have, or a word longer than the meta-block holds.
  void _writeWord(int wordId) {
    final int length = _copyLength;
    if (length < 4 || length > 24) {
      brotliDamaged('a dictionary word has a length the dictionary lacks');
    }
    final int indexBits = brotliDictionaryIndexBits[length];
    final int transform = wordId >> indexBits;
    if (transform >= brotliTransformCount) {
      brotliDamaged('a dictionary word has a transformation that is none');
    }
    final int index = wordId & ((1 << indexBits) - 1);
    final Uint8List word = brotliTransformWord(
      brotliDictionary,
      brotliDictionaryOffset[length] + index * length,
      length,
      transform,
    );
    if (word.length > _metaRemaining) {
      brotliDamaged('a dictionary word is longer than its meta-block holds');
    }
    word.forEach(_put);
    _metaRemaining -= word.length;
  }

  /// Copies the bytes of the current copy, handing them on as they come.
  void _copy() {
    int source = _ringPosition - _copyDistance;
    if (source < 0) {
      source += _ring.length;
    }
    while (_copyRemaining > 0) {
      if (_total - _emitted >= _chunkSize) {
        _emit();
      }
      final int byte = _ring[source];
      _put(byte);
      source += 1;
      if (source == _ring.length) {
        source = 0;
      }
      _copyRemaining -= 1;
      _metaRemaining -= 1;
    }
    _stage = BrotliDecoderStage.command;
  }

  /// Ends the current meta-block.
  void _endMetaBlock() {
    if (_isLast) {
      _finish();
      return;
    }
    _stage = BrotliDecoderStage.metaBlockHeader;
  }

  /// Ends the stream after its last meta-block.
  ///
  /// Throws a [FormatException] when padding bits are set or data follows.
  void _finish() {
    _reader.alignToByte();
    if (_reader.hasData) {
      throw const FormatException('The brotli data is followed by more data');
    }
    _stage = BrotliDecoderStage.done;
  }

  /// Writes [byte] as the next decoded byte.
  void _put(int byte) {
    if (_ringPosition == _ring.length) {
      _wrapOrGrow();
    }
    _ring[_ringPosition] = byte;
    _ringPosition += 1;
    _total += 1;
    _beforeLast = _last;
    _last = byte;
  }

  /// Grows the full ring buffer up to [_maxRing], or wraps it around.
  void _wrapOrGrow() {
    if (_ring.length == _maxRing) {
      _ringPosition = 0;
      return;
    }
    final int grown = _ring.length * 2 < _maxRing ? _ring.length * 2 : _maxRing;
    _ring = Uint8List(grown)..setRange(0, _ring.length, _ring);
  }

  /// Hands on the decoded bytes not handed on yet.
  void _emit() {
    final int count = _total - _emitted;
    if (count == 0) {
      return;
    }
    final chunk = Uint8List(count);
    final int start = _ringPosition - count;
    if (start >= 0) {
      chunk.setRange(0, count, _ring, start);
    }
    if (start < 0) {
      chunk
        ..setRange(0, -start, _ring, _ring.length + start)
        ..setRange(-start, count, _ring);
    }
    _output.add(chunk);
    _emitted = _total;
  }

  /// Takes what was decoded so far.
  ///
  /// Returns the chunks.
  List<Uint8List> _drain() {
    _emit();
    final chunks = List<Uint8List>.of(_output);
    _output.clear();
    return chunks;
  }

  /// Keeps what a step may change before it fails, for [_restore].
  void _save() {
    _savedRingPosition = _ringPosition;
    _savedTotal = _total;
    _savedLast = _last;
    _savedBeforeLast = _beforeLast;
    _savedMetaRemaining = _metaRemaining;
    _savedInsertRemaining = _insertRemaining;
    _literals?.save();
    _commands?.save();
    _distances?.save();
  }

  /// Goes back to what [_save] kept.
  void _restore() {
    _ringPosition = _savedRingPosition;
    _total = _savedTotal;
    _last = _savedLast;
    _beforeLast = _savedBeforeLast;
    _metaRemaining = _savedMetaRemaining;
    _insertRemaining = _savedInsertRemaining;
    _literals?.restore();
    _commands?.restore();
    _distances?.restore();
  }
}
