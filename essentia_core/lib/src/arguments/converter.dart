/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Turns the raw text of an argument into the type [T] a parameter is
/// declared with.
///
/// A converter is applied to every value regardless of where it came from,
/// so a value read from an environment variable is subject to exactly the
/// same conversion as one passed on the command line.
///
/// Implementations signal a value they cannot handle by throwing a
/// `ConversionException` whose message does not quote the value; the
/// message becomes part of the report the caller sees. Any other
/// [Exception] is caught as well and reported the same way, so one careless
/// converter does not cut the report down to one problem - but with a
/// generic reason rather than its own message, because an arbitrary
/// exception's message is not written for this report and often quotes the
/// value it rejected. Throw a `ConversionException` to say why. An [Error]
/// is a defect in the converter and is not caught.
typedef Converter<T> = T Function(String raw);
