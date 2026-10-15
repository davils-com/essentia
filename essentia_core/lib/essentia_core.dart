/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The core of Essentia, the Davils application runtime for Dart.
///
/// Validation that reports every problem at once, validating configuration
/// builders, program parameters, layering contracts, RFC 9562 identifiers,
/// semantic versions, principals, platform detection, a `Result` type,
/// Kotlin's `lazy`, byte strings and hexadecimal formats, gzip and CRC-32,
/// decimals, ranges, Kotlin's `Duration` extensions and Kotlin's standard
/// library extensions on Dart's own classes. It runs on every Dart
/// platform, the web and WebAssembly included; `file()` is offered where
/// `dart:io` is.
library;

export 'src/architecture/data_source.dart';
export 'src/architecture/data_transfer_object.dart';
export 'src/architecture/data_transfer_objects.dart';
export 'src/architecture/domain_model.dart';
export 'src/architecture/mapper.dart';
export 'src/architecture/repository.dart';
export 'src/architecture/use_case.dart';
export 'src/architecture/use_case_without_input.dart';
export 'src/arguments/application_mode.dart';
export 'src/arguments/conversion_exception.dart';
export 'src/arguments/converter.dart';
export 'src/arguments/defaulted_parameter_builder.dart';
export 'src/arguments/file_parameter_converters.dart'
    if (dart.library.js_interop) 'src/arguments/no_file_parameter_converters.dart';
export 'src/arguments/flag_builder.dart';
export 'src/arguments/multiple_parameter_builder.dart';
export 'src/arguments/parameter.dart';
export 'src/arguments/parameter_builder.dart';
export 'src/arguments/parameter_converters.dart';
export 'src/arguments/parameter_declarations.dart';
export 'src/arguments/parameter_exception.dart';
export 'src/arguments/parameter_info.dart';
export 'src/arguments/parameter_violation.dart';
export 'src/arguments/parameter_violation_codes.dart';
export 'src/arguments/parameters.dart';
export 'src/arguments/parameters_not_loaded_error.dart';
export 'src/arguments/required_parameter_builder.dart';
export 'src/arguments/unknown_argument_policy.dart';
export 'src/arguments/value_origin.dart';
export 'src/arguments/value_source.dart';
export 'src/arguments/version_parameter_converters.dart';
export 'src/bytes/adler32.dart';
export 'src/bytes/byte_list_content.dart';
export 'src/bytes/byte_list_hex.dart';
export 'src/bytes/byte_list_to_byte_string.dart';
export 'src/bytes/byte_string.dart';
export 'src/bytes/compression/brotli.dart';
export 'src/bytes/compression/deflate.dart';
export 'src/bytes/compression/gzip.dart';
export 'src/bytes/crc32.dart';
export 'src/bytes/hex_format.dart';
export 'src/bytes/hex_format_builder.dart';
export 'src/bytes/hex_format_dsl.dart';
export 'src/bytes/hex_parsing.dart';
export 'src/bytes/string_to_byte_string.dart';
export 'src/charset/charset.dart';
export 'src/charset/charsets.dart';
export 'src/charset/unsupported_charset_exception.dart';
export 'src/collection/attribute_key.dart';
export 'src/collection/attributes.dart';
export 'src/collection/case_insensitive_map.dart';
export 'src/collection/comparable_iterable_ordering.dart';
export 'src/collection/grouping.dart';
export 'src/collection/iterable_accumulation.dart';
export 'src/collection/iterable_aggregation.dart';
export 'src/collection/iterable_association.dart';
export 'src/collection/iterable_extremes.dart';
export 'src/collection/iterable_joining.dart';
export 'src/collection/iterable_null_elements.dart';
export 'src/collection/iterable_ordering.dart';
export 'src/collection/iterable_sampling.dart';
export 'src/collection/iterable_set_algebra.dart';
export 'src/collection/iterable_transformation.dart';
export 'src/collection/iterable_windowing.dart';
export 'src/collection/join_format.dart';
export 'src/collection/list_access.dart';
export 'src/collection/list_folding.dart';
export 'src/collection/list_mutation.dart';
export 'src/collection/list_slicing.dart';
export 'src/collection/map_access.dart';
export 'src/collection/map_composition.dart';
export 'src/collection/map_defaulting.dart';
export 'src/collection/map_query.dart';
export 'src/collection/map_transformation.dart';
export 'src/collection/map_with_default.dart';
export 'src/collection/nullable_iterable.dart';
export 'src/collection/nullable_list.dart';
export 'src/collection/nullable_map.dart';
export 'src/collection/record_iterable_unzip.dart';
export 'src/collection/set_algebra.dart';
export 'src/collection/window_remainder.dart';
export 'src/comparison/comparable_coercion.dart';
export 'src/comparison/comparator_chaining.dart';
export 'src/comparison/comparison_dsl.dart';
export 'src/dsl/builder.dart';
export 'src/dsl/validating_builder.dart';
export 'src/duration/decimal_duration_units.dart';
export 'src/duration/duration_arithmetic.dart';
export 'src/duration/duration_components.dart';
export 'src/duration/duration_parsing.dart';
export 'src/duration/duration_text.dart';
export 'src/duration/duration_units.dart';
export 'src/duration/readable_duration.dart';
export 'src/identity/uuid.dart';
export 'src/identity/uuid_version.dart';
export 'src/lang/causal.dart';
export 'src/lazy/lazy.dart';
export 'src/lazy/lazy_dsl.dart';
export 'src/lifecycle/disposable.dart';
export 'src/lifecycle/disposable_async.dart';
export 'src/number/byte_size.dart';
export 'src/number/byte_size_units.dart';
export 'src/number/decimal_value.dart';
export 'src/number/int_arithmetic.dart';
export 'src/number/rounding_mode.dart';
export 'src/platform/architecture.dart';
export 'src/platform/operating_system.dart';
export 'src/platform/platform.dart';
export 'src/principal/principal.dart';
export 'src/principal/principal_attributes.dart';
export 'src/principal/principal_builder.dart';
export 'src/principal/principal_kind.dart';
export 'src/principal/principal_violation_codes.dart';
export 'src/principal/principals.dart';
export 'src/range/closed_range.dart';
export 'src/range/comparable_range_building.dart';
export 'src/range/int_progression.dart';
export 'src/range/int_range_building.dart';
export 'src/range/open_end_range.dart';
export 'src/result/result.dart';
export 'src/result/result_async.dart';
export 'src/result/result_dsl.dart';
export 'src/result/result_flatten.dart';
export 'src/result/result_future.dart';
export 'src/result/result_iterable.dart';
export 'src/scope/scope_functions.dart';
export 'src/text/nullable_string.dart';
export 'src/text/string_affixes.dart';
export 'src/text/string_blankness.dart';
export 'src/text/string_case.dart';
export 'src/text/string_indentation.dart';
export 'src/text/string_runes.dart';
export 'src/text/string_search.dart';
export 'src/text/string_similarity.dart';
export 'src/text/string_slicing.dart';
export 'src/text/string_words.dart';
export 'src/text/unicode_normalization.dart';
export 'src/validation/path_segment.dart';
export 'src/validation/severity.dart';
export 'src/validation/validatable.dart';
export 'src/validation/validatable_checks.dart';
export 'src/validation/validation_exception.dart';
export 'src/validation/validation_report.dart';
export 'src/validation/validation_scope.dart';
export 'src/validation/violation.dart';
export 'src/validation/violation_code.dart';
export 'src/validation/violation_path.dart';
export 'src/version/pre_release_policy.dart';
export 'src/version/semantic_version.dart';
export 'src/version/semantic_version_range.dart';
export 'src/version/version_interval.dart';
export 'src/version/version_strings.dart';
export 'src/version/version_validations.dart';
export 'src/version/version_violation_codes.dart';
