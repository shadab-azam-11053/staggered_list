import 'dart:collection';

import 'package:staggered_list/staggered/rendering/render_sliver_staggered_grid.dart';
import 'package:staggered_list/staggered/rendering/sliver_staggered_grid.dart';
import 'package:staggered_list/staggered/rendering/sliver_variable_size_box_adaptor.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A base class for sliver that have multiple variable size box children.
///
/// Helps subclasses build their children lazily using a [SliverVariableSizeChildDelegate].
abstract class SliverVariableSizeBoxAdaptorWidget
    extends SliverWithKeepAliveWidget {
  /// Initializes fields for subclasses.
  const SliverVariableSizeBoxAdaptorWidget({
    Key? key,
    required this.delegate,
    this.addAutomaticKeepAlives = true,
  }) : super(key: key);

  /// Whether to add keepAlives to children
  final bool addAutomaticKeepAlives;

  /// The delegate that provides the children for this widget.
  ///
  /// The children are constructed lazily using this widget to avoid creating
  /// more children than are visible through the [Viewport].
  ///
  /// See also:
  ///
  ///  * [SliverChildBuilderDelegate] and [SliverChildListDelegate], which are
  ///    commonly used subclasses of [SliverChildDelegate] that use a builder
  ///    callback and an explicit child staggered, respectively.
  final SliverChildDelegate delegate;

  @override
  SliverVariableSizeBoxAdaptorElement createElement() =>
      SliverVariableSizeBoxAdaptorElement(
        this,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
      );

  /// Returns an estimate of the max scroll extent for all the children.
  ///
  /// Subclasses should override this function if they have additional
  /// information about their max scroll extent.
  ///
  /// This is used by [SliverMultiBoxAdaptorElement] to implement part of the
  /// [RenderSliverBoxChildManager] API.
  ///
  /// The default implementation defers to [delegate] via its
  /// [SliverChildDelegate.estimateMaxScrollOffset] method.
  double? estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }
}

/// An element that lazily builds children for a [SliverVariableSizeBoxAdaptorWidget].
///
/// Implements [RenderSliverVariableSizeBoxChildManager], which lets this element manage
/// the children of subclasses of [RenderSliverVariableSizeBoxAdaptor].
class SliverVariableSizeBoxAdaptorElement extends RenderObjectElement
    implements RenderSliverVariableSizeBoxChildManager {
  /// Creates an element that lazily builds children for the given widget.
  SliverVariableSizeBoxAdaptorElement(SliverVariableSizeBoxAdaptorWidget widget,
      {this.addAutomaticKeepAlives = true})
      : super(widget);

  /// Whether to add keepAlives to children
  final bool addAutomaticKeepAlives;

  @override
  SliverVariableSizeBoxAdaptorWidget get widget =>
      super.widget as SliverVariableSizeBoxAdaptorWidget;

  @override
  RenderSliverVariableSizeBoxAdaptor get renderObject =>
      super.renderObject as RenderSliverVariableSizeBoxAdaptor;

  // We inflate widgets at two different times:
  //  1. When we ourselves are told to rebuild (see performRebuild).
  //  2. When our render object needs a child (see createChild).
  // In both cases, we cache the results of calling into our delegate to get the widget,
  // so that if we do case 2 later, we don't call the builder again.
  // Any time we do case 1, though, we reset the cache.

  final Map<int, Widget?> _childWidgets = HashMap<int, Widget?>();
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  Widget? _build(int index) {
    return _childWidgets.putIfAbsent(
        index, () => widget.delegate.build(this, index));
  }

  @override
  void createChild(int index) {
    assert(_currentlyUpdatingChildIndex == null);
    owner!.buildScope(this, () {
      Element? newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  double? _extrapolateMaxScrollOffset(
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  ) {
    final int? childCount = widget.delegate.estimatedChildCount;
    if (childCount == null) {
      return double.infinity;
    }
    if (lastIndex == childCount - 1) {
      return trailingScrollOffset;
    }
    final int reifiedCount = lastIndex! - firstIndex! + 1;
    final double averageExtent =
        (trailingScrollOffset! - leadingScrollOffset!) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return widget.estimateMaxScrollOffset(
          constraints,
          firstIndex!,
          lastIndex!,
          leadingScrollOffset!,
          trailingScrollOffset!,
        ) ??
        _extrapolateMaxScrollOffset(
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
        )!;
  }

  @override
  int get childCount => widget.delegate.estimatedChildCount ?? 0;

  @override
  void didStartLayout() {
    assert(debugAssertChildListLocked());
  }

  @override
  void didFinishLayout() {
    assert(debugAssertChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    widget.delegate.didFinishLayout(firstIndex, lastIndex);
  }

  int? _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final childParentData =
        child.parentData! as SliverVariableSizeBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  bool _didUnderflow = false;

  @override
  void setDidUnderflow(bool value) {
    _didUnderflow = value;
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, int slot) {
    assert(_currentlyUpdatingChildIndex == slot);
    renderObject[_currentlyUpdatingChildIndex!] = child;
    assert(() {
      final childParentData =
          child.parentData! as SliverVariableSizeBoxAdaptorParentData;
      assert(slot == childParentData.index);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(
    covariant RenderObject child,
    covariant Object? oldSlot,
    covariant Object? newSlot,
  ) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(
    covariant RenderObject child,
    covariant Object? slot,
  ) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(_currentlyUpdatingChildIndex!);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // The toList() is to make a copy so that the underlying staggered can be modified by
    // the visitor:
    _childElements.values.toList().forEach(visitor);
  }

  @override
  void removeChild(RenderBox child) {
    // TODO: implement removeChild
  }
}

/// A sliver that places multiple box children in a two dimensional arrangement.
///
/// [SliverStaggeredGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// The main axis direction of a grid is the direction in which it scrolls; the
/// cross axis direction is the orthogonal direction.
///

///
///  * [SliverList], which places its children in a linear array.
///  * [SliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype staggered item instead of a pixel value to define
///    the main axis extent of each item.
class SliverStaggeredGrid extends SliverVariableSizeBoxAdaptorWidget {
  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement.
  const SliverStaggeredGrid({
    Key? key,
    required SliverChildDelegate delegate,
    required this.gridDelegate,
    bool addAutomaticKeepAlives = true,
  }) : super(
          key: key,
          delegate: delegate,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
        );

  /// The delegate that controls the size and position of the children.
  final SliverStaggeredGridDelegate gridDelegate;

  @override
  RenderSliverStaggeredGrid createRenderObject(BuildContext context) {
    final element = context as SliverVariableSizeBoxAdaptorElement;
    return RenderSliverStaggeredGrid(
        childManager: element, gridDelegate: gridDelegate);
  }
}
