/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/brotli/brotli_dictionary_data.dart';
import 'package:meta/meta.dart';

/// The static dictionary of Brotli, RFC 7932 Appendix A, decoded the first
/// time a stream refers to it.
@internal
final Uint8List brotliDictionary = base64.decode(brotliDictionaryData);
