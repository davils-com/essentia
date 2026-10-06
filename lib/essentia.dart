/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The Davils application runtime core for Dart.
///
/// Validation that reports every problem at once, validating configuration
/// builders, an in-process event bus, layering contracts, RFC 9562
/// identifiers and platform detection. Program
/// parameters need `dart:io` and live in `package:essentia/arguments.dart`.
library;

export 'src/architecture/data_source.dart';
export 'src/architecture/data_transfer_object.dart';
export 'src/architecture/data_transfer_objects.dart';
export 'src/architecture/domain_model.dart';
export 'src/architecture/mapper.dart';
export 'src/architecture/repository.dart';
export 'src/architecture/use_case.dart';
export 'src/architecture/use_case_without_input.dart';
export 'src/dsl/builder.dart';
export 'src/dsl/validating_builder.dart';
export 'src/event/bus_state.dart';
export 'src/event/consumer_group.dart';
export 'src/event/drop_reason.dart';
export 'src/event/event.dart';
export 'src/event/event_bus.dart';
export 'src/event/event_bus_builder.dart';
export 'src/event/event_bus_data.dart';
export 'src/event/event_envelope.dart';
export 'src/event/event_error_handler.dart';
export 'src/event/event_handler.dart';
export 'src/event/event_headers.dart';
export 'src/event/event_interceptor.dart';
export 'src/event/event_listener.dart';
export 'src/event/event_subscription.dart';
export 'src/event/event_topic.dart';
export 'src/event/event_topic_builder.dart';
export 'src/event/event_topic_data.dart';
export 'src/event/event_violation_codes.dart';
export 'src/event/overflow_policy.dart';
export 'src/event/topic_key.dart';
export 'src/event/topic_metrics.dart';
export 'src/event/topic_not_declared_error.dart';
export 'src/event/topic_type_mismatch_error.dart';
export 'src/identity/uuid.dart';
export 'src/identity/uuid_version.dart';
export 'src/lifecycle/disposable.dart';
export 'src/lifecycle/disposable_async.dart';
export 'src/platform/architecture.dart';
export 'src/platform/operating_system.dart';
export 'src/platform/platform.dart';
export 'src/scope/scope_functions.dart';
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
