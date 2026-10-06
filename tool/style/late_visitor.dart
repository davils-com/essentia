/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:inspectra/style.dart';

/// Finds the `late` modifier of fields, top level and local variables.
final class LateVisitor extends RecursiveAstVisitor<void> {
  /// Creates a visitor reporting to [reporter].
  LateVisitor(this.reporter);

  /// Receives the violations.
  final StyleReporter reporter;

  /// Reports the `late` of a variable declaration.
  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final Token? keyword = node.lateKeyword;
    if (keyword != null) {
      reporter.reportAt(
        keyword,
        'No late: initialise the variable where it is declared, in an '
        'initialiser list, or make the deferred value explicit.',
      );
    }
    super.visitVariableDeclarationList(node);
  }
}
