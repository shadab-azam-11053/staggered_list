import 'dart:collection';

import 'package:flutter/rendering.dart';

/// Generic mixin for render objects with a staggered of children.
///
/// Provides a child model for a render object subclass that stores children
/// in a HashMap.
mixin TileContainerRenderObjectMixin<ChildType extends RenderObject,
    ParentDataType extends ParentData> on RenderObject {
  final SplayTreeMap<int, ChildType> _childRenderObjects =
      SplayTreeMap<int, ChildType>();

  /// The number of children.
  int get childCount => _childRenderObjects.length;

  Iterable<ChildType> get children => _childRenderObjects.values;

  Iterable<int> get indices => _childRenderObjects.keys;

  /// Checks whether the given render object has the correct [runtimeType] to be
  /// a child of this render object.
  ///
  /// Does nothing if assertions are disabled.
  ///
  /// Always returns true.
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw FlutterError(
            'A $runtimeType expected a child of type $ChildType but received a '
            'child of type ${child.runtimeType}.\n'
            'RenderObjects expect specific types of children because they '
            'coordinate with their children during layout and paint. For '
            'example, a RenderSliver cannot be the child of a RenderBox because '
            'a RenderSliver does not understand the RenderBox layout protocol.\n'
            '\n'
            'The $runtimeType that expected a $ChildType child was created by:\n'
            '  $debugCreator\n'
            '\n'
            'The ${child.runtimeType} that did not match the expected child type '
            'was created by:\n'
            '  ${child.debugCreator}\n');
      }
      return true;
    }());
    return true;
  }

  ChildType? operator [](int index) => _childRenderObjects[index];

  void operator []=(int index, ChildType child) {
    if (index < 0) {
      throw ArgumentError(index);
    }

    adoptChild(child);
    _childRenderObjects[index] = child;
  }

  void forEachChild(void Function(ChildType child) f) {
    _childRenderObjects.values.forEach(f);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _childRenderObjects.values.forEach(visitor);
  }
}
