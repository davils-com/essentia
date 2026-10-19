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

import 'dart:io';

import 'package:essentia_io/essentia_io.dart';

/// Writes a number and a text into a buffer and reads them back.
void main() {
  final buffer = Buffer()
    ..writeInt(42)
    ..writeString('hello');
  final int number = buffer.readInt();
  final String text = buffer.readString();

  stdout
    ..writeln(number)
    ..writeln(text);
}
