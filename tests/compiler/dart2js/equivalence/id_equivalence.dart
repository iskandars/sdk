// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

enum IdKind {
  element,
  cls,
  node,
  invoke,
  update,
  iterator,
  current,
  moveNext,
}

/// Id for a code point or element with type inference information.
abstract class Id {
  IdKind get kind;
  bool get isGlobal;

  /// Display name for this id.
  String get descriptor;
}

class IdValue {
  final Id id;
  final String value;

  const IdValue(this.id, this.value);

  @override
  int get hashCode => id.hashCode * 13 + value.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! IdValue) return false;
    return id == other.id && value == other.value;
  }

  @override
  String toString() => idToString(id, value);

  static String idToString(Id id, String value) {
    switch (id.kind) {
      case IdKind.element:
        ElementId elementId = id;
        return '$elementPrefix${elementId.name}:$value';
      case IdKind.cls:
        ClassId classId = id;
        return '$classPrefix${classId.name}:$value';
      case IdKind.node:
        return value;
      case IdKind.invoke:
        return '$invokePrefix$value';
      case IdKind.update:
        return '$updatePrefix$value';
      case IdKind.iterator:
        return '$iteratorPrefix$value';
      case IdKind.current:
        return '$currentPrefix$value';
      case IdKind.moveNext:
        return '$moveNextPrefix$value';
    }
    throw new UnsupportedError("Unexpected id kind: ${id.kind}");
  }

  static const String globalPrefix = "global#";
  static const String elementPrefix = "element: ";
  static const String classPrefix = "class: ";
  static const String invokePrefix = "invoke: ";
  static const String updatePrefix = "update: ";
  static const String iteratorPrefix = "iterator: ";
  static const String currentPrefix = "current: ";
  static const String moveNextPrefix = "moveNext: ";

  static IdValue decode(int offset, String text) {
    Id id;
    String expected;
    if (text.startsWith(elementPrefix)) {
      text = text.substring(elementPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid element id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new ElementId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(classPrefix)) {
      text = text.substring(classPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid class id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new ClassId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(invokePrefix)) {
      id = new NodeId(offset, IdKind.invoke);
      expected = text.substring(invokePrefix.length);
    } else if (text.startsWith(updatePrefix)) {
      id = new NodeId(offset, IdKind.update);
      expected = text.substring(updatePrefix.length);
    } else if (text.startsWith(iteratorPrefix)) {
      id = new NodeId(offset, IdKind.iterator);
      expected = text.substring(iteratorPrefix.length);
    } else if (text.startsWith(currentPrefix)) {
      id = new NodeId(offset, IdKind.current);
      expected = text.substring(currentPrefix.length);
    } else if (text.startsWith(moveNextPrefix)) {
      id = new NodeId(offset, IdKind.moveNext);
      expected = text.substring(moveNextPrefix.length);
    } else {
      id = new NodeId(offset, IdKind.node);
      expected = text;
    }
    // Remove newlines.
    expected = expected.replaceAll(new RegExp(r'\s*(\n\s*)+\s*'), '');
    return new IdValue(id, expected);
  }
}

/// Id for an member element.
class ElementId implements Id {
  final String className;
  final String memberName;
  @override
  final bool isGlobal;

  factory ElementId(String text, {bool isGlobal: false}) {
    int dotPos = text.indexOf('.');
    if (dotPos != -1) {
      return new ElementId.internal(text.substring(dotPos + 1),
          className: text.substring(0, dotPos), isGlobal: isGlobal);
    } else {
      return new ElementId.internal(text, isGlobal: isGlobal);
    }
  }

  ElementId.internal(this.memberName, {this.className, this.isGlobal: false});

  @override
  int get hashCode => className.hashCode * 13 + memberName.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ElementId) return false;
    return className == other.className && memberName == other.memberName;
  }

  @override
  IdKind get kind => IdKind.element;

  String get name => className != null ? '$className.$memberName' : memberName;

  @override
  String get descriptor => 'member $name';

  @override
  String toString() => 'element:$name';
}

/// Id for a class.
class ClassId implements Id {
  final String className;
  @override
  final bool isGlobal;

  ClassId(this.className, {this.isGlobal: false});

  @override
  int get hashCode => className.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ClassId) return false;
    return className == other.className;
  }

  @override
  IdKind get kind => IdKind.cls;

  String get name => className;

  @override
  String get descriptor => 'class $name';

  @override
  String toString() => 'class:$name';
}

/// Id for a code point with type inference information.
// TODO(johnniwinther): Create an [NodeId]-based equivalence with the kernel IR.
class NodeId implements Id {
  final int value;
  @override
  final IdKind kind;

  const NodeId(this.value, this.kind);

  @override
  bool get isGlobal => false;

  @override
  int get hashCode => value.hashCode * 13 + kind.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NodeId) return false;
    return value == other.value && kind == other.kind;
  }

  @override
  String get descriptor => 'offset $value ($kind)';

  @override
  String toString() => '$kind:$value';
}

class ActualData<T> {
  final Id id;
  final T value;
  final SourceSpan sourceSpan;
  final Object object;

  ActualData(this.id, this.value, this.sourceSpan, this.object);

  int get offset {
    if (id is NodeId) {
      NodeId nodeId = id;
      return nodeId.value;
    } else {
      return sourceSpan.begin;
    }
  }

  String get objectText {
    return 'object `${'$object'.replaceAll('\n', '')}` (${object.runtimeType})';
  }

  @override
  String toString() =>
      'ActualData(id=$id,value=$value,sourceSpan=$sourceSpan,object=$objectText)';
}

abstract class DataRegistry<T> {
  DiagnosticReporter get reporter;
  Map<Id, ActualData<T>> get actualMap;

  void registerValue(SourceSpan sourceSpan, Id id, T value, Object object) {
    if (actualMap.containsKey(id)) {
      ActualData<T> existingData = actualMap[id];
      reportHere(reporter, sourceSpan,
          "Duplicate id ${id}, value=$value, object=$object");
      reportHere(
          reporter,
          sourceSpan,
          "Duplicate id ${id}, value=${existingData.value}, "
          "object=${existingData.object}");
      Expect.fail("Duplicate id $id.");
    }
    if (value != null) {
      actualMap[id] = new ActualData<T>(id, value, sourceSpan, object);
    }
  }
}

/// Compute a canonical [Id] for kernel-based nodes.
Id computeEntityId(ir.Member node) {
  String className;
  if (node.enclosingClass != null) {
    className = node.enclosingClass.name;
  }
  String memberName = node.name.name;
  if (node is ir.Procedure && node.kind == ir.ProcedureKind.Setter) {
    memberName += '=';
  }
  return new ElementId.internal(memberName, className: className);
}

/// Abstract IR visitor for computing data corresponding to a node or element,
/// and record it with a generic [Id]
abstract class IrDataExtractor<T> extends ir.Visitor with DataRegistry<T> {
  @override
  final DiagnosticReporter reporter;
  @override
  final Map<Id, ActualData<T>> actualMap;

  /// Implement this to compute the data corresponding to [member].
  ///
  /// If `null` is returned, [member] has no associated data.
  T computeMemberValue(Id id, ir.Member member);

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  T computeNodeValue(Id id, ir.TreeNode node);

  IrDataExtractor(this.reporter, this.actualMap);

  void computeForMember(ir.Member member) {
    ElementId id = computeEntityId(member);
    if (id == null) return;
    T value = computeMemberValue(id, member);
    registerValue(computeSourceSpan(member), id, value, member);
  }

  void computeForNode(ir.TreeNode node, NodeId id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    registerValue(computeSourceSpan(node), id, value, node);
  }

  SourceSpan computeSourceSpan(ir.TreeNode node) {
    return computeSourceSpanFromTreeNode(node);
  }

  NodeId computeDefaultNodeId(ir.TreeNode node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on $node (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.node);
  }

  NodeId createInvokeId(ir.TreeNode node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.invoke);
  }

  NodeId createUpdateId(ir.TreeNode node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.update);
  }

  NodeId createIteratorId(ir.ForInStatement node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.iterator);
  }

  NodeId createCurrentId(ir.ForInStatement node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.current);
  }

  NodeId createMoveNextId(ir.ForInStatement node) {
    assert(node.fileOffset != ir.TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.moveNext);
  }

  NodeId createLabeledStatementId(ir.LabeledStatement node) =>
      computeDefaultNodeId(node.body);
  NodeId createLoopId(ir.TreeNode node) => computeDefaultNodeId(node);
  NodeId createGotoId(ir.TreeNode node) => computeDefaultNodeId(node);
  NodeId createSwitchId(ir.SwitchStatement node) => computeDefaultNodeId(node);
  NodeId createSwitchCaseId(ir.SwitchCase node) =>
      new NodeId(node.expressionOffsets.first, IdKind.node);

  void run(ir.Node root) {
    root.accept(this);
  }

  @override
  defaultNode(ir.Node node) {
    node.visitChildren(this);
  }

  @override
  defaultMember(ir.Member node) {
    super.defaultMember(node);
    computeForMember(node);
  }

  @override
  visitMethodInvocation(ir.MethodInvocation node) {
    ir.TreeNode receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      // This is an invocation of a named local function.
      computeForNode(node, createInvokeId(node.receiver));
      node.arguments.accept(this);
    } else if (node.name.name == '==' &&
        receiver is ir.VariableGet &&
        receiver.variable.name == null) {
      // This is a desugared `?.`.
    } else if (node.name.name == '[]') {
      computeForNode(node, computeDefaultNodeId(node));
      super.visitMethodInvocation(node);
    } else if (node.name.name == '[]=') {
      computeForNode(node, createUpdateId(node));
      super.visitMethodInvocation(node);
    } else {
      computeForNode(node, createInvokeId(node));
      super.visitMethodInvocation(node);
    }
  }

  @override
  visitLoadLibrary(ir.LoadLibrary node) {
    computeForNode(node, createInvokeId(node));
  }

  @override
  visitPropertyGet(ir.PropertyGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitPropertyGet(node);
  }

  @override
  visitVariableDeclaration(ir.VariableDeclaration node) {
    if (node.name != null && node.parent is! ir.FunctionDeclaration) {
      // Skip synthetic variables and function declaration variables.
      computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitVariableDeclaration(node);
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionDeclaration(node);
  }

  @override
  visitFunctionExpression(ir.FunctionExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionExpression(node);
  }

  @override
  visitVariableGet(ir.VariableGet node) {
    if (node.variable.name != null && !node.variable.isFieldFormal) {
      // Skip use of synthetic variables.
      computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitVariableGet(node);
  }

  @override
  visitPropertySet(ir.PropertySet node) {
    computeForNode(node, createUpdateId(node));
    super.visitPropertySet(node);
  }

  @override
  visitVariableSet(ir.VariableSet node) {
    if (node.variable.name != null) {
      // Skip use of synthetic variables.
      computeForNode(node, createUpdateId(node));
    }
    super.visitVariableSet(node);
  }

  @override
  visitDoStatement(ir.DoStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitDoStatement(node);
  }

  @override
  visitForStatement(ir.ForStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitForStatement(node);
  }

  @override
  visitForInStatement(ir.ForInStatement node) {
    computeForNode(node, createLoopId(node));
    computeForNode(node, createIteratorId(node));
    computeForNode(node, createCurrentId(node));
    computeForNode(node, createMoveNextId(node));
    super.visitForInStatement(node);
  }

  @override
  visitWhileStatement(ir.WhileStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitWhileStatement(node);
  }

  @override
  visitLabeledStatement(ir.LabeledStatement node) {
    if (!JumpVisitor.canBeBreakTarget(node.body) &&
        !JumpVisitor.canBeContinueTarget(node.parent)) {
      computeForNode(node, createLabeledStatementId(node));
    }
    super.visitLabeledStatement(node);
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitBreakStatement(node);
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    computeForNode(node, createSwitchId(node));
    super.visitSwitchStatement(node);
  }

  @override
  visitSwitchCase(ir.SwitchCase node) {
    if (node.expressionOffsets.isNotEmpty) {
      computeForNode(node, createSwitchCaseId(node));
    }
    super.visitSwitchCase(node);
  }

  @override
  visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitContinueSwitchStatement(node);
  }
}
