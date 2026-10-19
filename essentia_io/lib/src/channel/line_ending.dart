/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Which line endings a line reader accepts.
enum LineEnding {
  /// A line ends with LF or CR LF, as HTTP and most text formats say.
  defaultEnding,

  /// A line ends with LF, CR LF or a CR alone.
  lenient,
}
