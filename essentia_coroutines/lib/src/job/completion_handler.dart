/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a job calls once it completes, Kotlin's `CompletionHandler`.
///
/// [cause] is `null` when the job completed normally, a
/// `CancellationException` when it was cancelled, and the failure when it
/// failed.
typedef CompletionHandler = void Function(Object? cause);
