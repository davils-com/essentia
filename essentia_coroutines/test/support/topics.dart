/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

import 'audit_event.dart';
import 'user_event.dart';

/// The topic of user events.
final users = TopicKey<UserEvent>('users');

/// The topic of audit records.
final audit = TopicKey<AuditEvent>('audit');
