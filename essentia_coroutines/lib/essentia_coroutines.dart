/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Kotlin's coroutines for Dart: structured concurrency with jobs, scopes
/// and dispatchers, channels, select, hot flows on Dart's `Stream`, stream
/// operators, fair locks and an in-process event bus built on them.
library;

export 'src/channels/buffer_overflow.dart';
export 'src/channels/channel.dart';
export 'src/channels/channel_closed.dart';
export 'src/channels/channel_result.dart';
export 'src/channels/channel_streams.dart';
export 'src/channels/closed_receive_channel_exception.dart';
export 'src/channels/closed_send_channel_exception.dart';
export 'src/channels/produce.dart';
export 'src/channels/producer_await.dart';
export 'src/channels/producer_scope.dart';
export 'src/channels/receive_channel.dart';
export 'src/channels/send_channel.dart';
export 'src/channels/stream_produce_in.dart';
export 'src/context/abstract_coroutine_context_element.dart';
export 'src/context/coroutine_context.dart';
export 'src/context/coroutine_context_access.dart';
export 'src/context/coroutine_context_element.dart';
export 'src/context/coroutine_context_key.dart';
export 'src/context/coroutine_context_zone.dart'
    show currentCoroutineContext, runWithContext;
export 'src/context/coroutine_name.dart';
export 'src/continuation/cancellable_continuation.dart';
export 'src/continuation/suspension.dart';
export 'src/coroutine/coroutine_scope_builders.dart';
export 'src/coroutine/coroutine_start.dart';
export 'src/deferred/await_all.dart';
export 'src/deferred/completable_deferred.dart';
export 'src/deferred/deferred.dart';
export 'src/deferred/future_as_deferred.dart';
export 'src/dispatcher/coroutine_dispatcher.dart';
export 'src/dispatcher/dispatchers.dart';
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
export 'src/exception/cancellation_exception.dart';
export 'src/exception/coroutine_exception_handler.dart';
export 'src/exception/exception_handling.dart';
export 'src/exception/suppressed_exceptions.dart' show suppressedExceptionsOf;
export 'src/flow/flow_collector.dart';
export 'src/flow/mutable_shared_flow.dart';
export 'src/flow/mutable_state_flow.dart';
export 'src/flow/mutable_state_flow_update.dart';
export 'src/flow/shared_flow.dart';
export 'src/flow/sharing_command.dart';
export 'src/flow/sharing_started.dart';
export 'src/flow/state_flow.dart';
export 'src/flow/stream_sharing.dart';
export 'src/isolate/isolate_body_not_sendable_error.dart';
export 'src/isolate/isolate_transferable.dart';
export 'src/job/completable_job.dart';
export 'src/job/completion_handler.dart';
export 'src/job/completion_handler_exception.dart';
export 'src/job/job.dart';
export 'src/job/job_cancellation_exception.dart';
export 'src/job/job_operations.dart';
export 'src/job/join_all.dart';
export 'src/job/non_cancellable.dart';
export 'src/job/supervisor_job.dart';
export 'src/principal/principal_context.dart';
export 'src/principal/principal_element.dart';
export 'src/principal/principal_missing_exception.dart';
export 'src/scheduler/scheduled_task.dart';
export 'src/scheduler/scheduler.dart';
export 'src/scheduler/system_scheduler.dart';
export 'src/scope/coroutine_scope.dart';
export 'src/scope/global_scope.dart';
export 'src/scope/scoping.dart';
export 'src/selects/deferred_select_clauses.dart';
export 'src/selects/job_select_clauses.dart';
export 'src/selects/select.dart';
export 'src/selects/select_builder.dart';
export 'src/selects/select_builder_clauses.dart';
export 'src/selects/select_clause.dart';
export 'src/stream/combine_latest.dart' show combine;
export 'src/stream/stream_accumulation.dart';
export 'src/stream/stream_buffering.dart';
export 'src/stream/stream_cancellation.dart';
export 'src/stream/stream_collection.dart';
export 'src/stream/stream_combination.dart';
export 'src/stream/stream_distinctness.dart';
export 'src/stream/stream_lifecycle.dart';
export 'src/stream/stream_mapping.dart';
export 'src/stream/stream_recovery.dart';
export 'src/stream/stream_timing.dart';
export 'src/sync/mutex.dart';
export 'src/sync/semaphore.dart';
export 'src/testing/test_scheduler.dart';
export 'src/timeout/future_timeout.dart';
export 'src/timeout/timeout_cancellation_exception.dart';
export 'src/timeout/timeouts.dart';
