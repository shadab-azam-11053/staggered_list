import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:staggered_list/staggered/rendering/sliver_staggered_grid.dart';
import 'package:staggered_list/staggered/rendering/sliver_variable_size_box_adaptor.dart';

/// A sliver that places multiple box children in a two dimensional arrangement.
/// [RenderSliverGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
class RenderSliverStaggeredGrid extends RenderSliverVariableSizeBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose size and
  /// position are determined by a delegate.
  /// The [configuration] and [childManager] arguments must not be null.
  RenderSliverStaggeredGrid({
    required RenderSliverVariableSizeBoxChildManager childManager,
    required SliverStaggeredGridDelegate gridDelegate,
  })  : _gridDelegate = gridDelegate,
        _pageSizeToViewportOffsets =
            HashMap<double, SplayTreeMap<int, _ViewportOffsets?>>(),
        super(childManager: childManager);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverVariableSizeBoxAdaptorParentData) {
      final data = SliverVariableSizeBoxAdaptorParentData();
      // By default we will keep it true.
      //data.keepAlive = true;
      child.parentData = data;
    }
  }

  /// The delegate that controls the configuration of the staggered grid.
  SliverStaggeredGridDelegate get gridDelegate => _gridDelegate;
  SliverStaggeredGridDelegate _gridDelegate;
  set gridDelegate(SliverStaggeredGridDelegate value) {
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  final HashMap<double, SplayTreeMap<int, _ViewportOffsets?>>
      _pageSizeToViewportOffsets;

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    bool reachedEnd = false;
    double trailingScrollOffset = 0;
    double leadingScrollOffset = double.infinity;
    bool visible = false;
    int firstIndex = 0;
    int lastIndex = 0;

    final configuration = _gridDelegate.getConfiguration(constraints);

    final pageSize = configuration.mainAxisOffsetsCacheSize *
        constraints.viewportMainAxisExtent;
    if (pageSize == 0.0) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }
    final pageIndex = scrollOffset ~/ pageSize;
    assert(pageIndex >= 0);

    // If the viewport is resized, we keep the in memory the old offsets caches. (Useful if only the orientation changes multiple times).
    final viewportOffsets = _pageSizeToViewportOffsets.putIfAbsent(
        pageSize, () => SplayTreeMap<int, _ViewportOffsets?>());

    _ViewportOffsets? viewportOffset;
    if (viewportOffsets.isEmpty) {
      viewportOffset =
          _ViewportOffsets(configuration.generateMainAxisOffsets(), pageSize);
      viewportOffsets[0] = viewportOffset;
    } else {
      final smallestKey = viewportOffsets.lastKeyBefore(pageIndex + 1);
      viewportOffset = viewportOffsets[smallestKey!];
    }
    // A staggered grid always have to layout the child from the zero-index based one to the last visible.
    final mainAxisOffsets = viewportOffset!.mainAxisOffsets.toList();
    final visibleIndices = HashSet<int>();
    // Iterate through all children while they can be visible.
    for (var index = viewportOffset.firstChildIndex;
        mainAxisOffsets.any((o) => o <= targetEndScrollOffset);
        index++) {
      SliverStaggeredGridGeometry? geometry =
          getSliverStaggeredGeometry(index, configuration, mainAxisOffsets);
      if (geometry == null) {
        // There are either no children, or we are past the end of all our children.
        reachedEnd = true;
        break;
      }

      final bool hasTrailingScrollOffset = geometry.hasTrailingScrollOffset;
      RenderBox? child;
      if (!hasTrailingScrollOffset) {
        // Layout the child to compute its tailingScrollOffset.
        final constraints =
            BoxConstraints.tightFor(width: geometry.crossAxisExtent);
        child = addAndLayoutChild(index, constraints, parentUsesSize: true);
        geometry = geometry.copyWith(mainAxisExtent: paintExtentOf(child!));
      }

      if (!visible &&
          targetEndScrollOffset >= geometry.scrollOffset &&
          scrollOffset <= geometry.trailingScrollOffset) {
        visible = true;
        leadingScrollOffset = geometry.scrollOffset;
        firstIndex = index;
      }

      if (visible && hasTrailingScrollOffset) {
        child =
            addAndLayoutChild(index, geometry.getBoxConstraints(constraints));
      }

      if (child != null) {
        final childParentData =
            child.parentData! as SliverVariableSizeBoxAdaptorParentData;
        childParentData.layoutOffset = geometry.scrollOffset;
        childParentData.crossAxisOffset = geometry.crossAxisOffset;
        assert(childParentData.index == index);
      }

      if (visible && indices.contains(index)) {
        visibleIndices.add(index);
      }

      if (geometry.trailingScrollOffset >=
          viewportOffset!.trailingScrollOffset) {
        final nextPageIndex = viewportOffset.pageIndex + 1;
        final nextViewportOffset = _ViewportOffsets(mainAxisOffsets,
            (nextPageIndex + 1) * pageSize, nextPageIndex, index);
        viewportOffsets[nextPageIndex] = nextViewportOffset;
        viewportOffset = nextViewportOffset;
      }

      final double endOffset =
          geometry.trailingScrollOffset + configuration.mainAxisSpacing;
      for (var i = 0; i < geometry.crossAxisCellCount; i++) {
        mainAxisOffsets[i + geometry.blockIndex] = endOffset;
      }

      trailingScrollOffset = mainAxisOffsets.reduce(math.max);
      lastIndex = index;
    }

    if (!visible) {
      if (scrollOffset > viewportOffset!.trailingScrollOffset) {
        // We are outside the bounds, we have to correct the scroll.
        final viewportOffsetScrollOffset = pageSize * viewportOffset.pageIndex;
        final correction = viewportOffsetScrollOffset - scrollOffset;
        geometry = SliverGeometry(
          scrollOffsetCorrection: correction,
        );
      } else {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
      }
      return;
    }

    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = trailingScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          trailingScrollOffset - leadingScrollOffset);
    }

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: trailingScrollOffset > targetEndScrollOffset ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a child.
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  static SliverStaggeredGridGeometry? getSliverStaggeredGeometry(int index,
      StaggeredGridConfiguration configuration, List<double> offsets) {
    final tile = configuration.getStaggeredTile(index);
    if (tile == null) {
      return null;
    }

    final block = _findFirstAvailableBlockWithCrossAxisCount(
        tile.crossAxisCellCount, offsets);

    final scrollOffset = block.minOffset;
    var blockIndex = block.index;
    if (configuration.reverseCrossAxis) {
      blockIndex =
          configuration.crossAxisCount - tile.crossAxisCellCount - blockIndex;
    }
    final crossAxisOffset = blockIndex * configuration.cellStride;
    final geometry = SliverStaggeredGridGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: tile.mainAxisExtent,
      crossAxisExtent: configuration.cellStride * tile.crossAxisCellCount -
          configuration.crossAxisSpacing,
      crossAxisCellCount: tile.crossAxisCellCount,
      blockIndex: block.index,
    );
    return geometry;
  }

  /// Finds the first available block with at least the specified [crossAxisCount] in the [offsets] staggered.
  static _Block _findFirstAvailableBlockWithCrossAxisCount(
      int crossAxisCount, List<double> offsets) {
    return _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
        crossAxisCount, List.from(offsets));
  }

  /// Finds the first available block with at least the specified [crossAxisCount].
  static _Block _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
      int crossAxisCount, List<double> offsets) {
    final block = _findFirstAvailableBlock(offsets);
    if (block.crossAxisCount < crossAxisCount) {
      // Not enough space for the specified cross axis count.
      // We have to fill this block and try again.
      for (var i = 0; i < block.crossAxisCount; ++i) {
        offsets[i + block.index] = block.maxOffset;
      }
      return _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
          crossAxisCount, offsets);
    } else {
      return block;
    }
  }

  /// Finds the first available block for the specified [offsets] staggered.
  static _Block _findFirstAvailableBlock(List<double> offsets) {
    int index = 0;
    double minBlockOffset = double.infinity;
    double maxBlockOffset = double.infinity;
    int crossAxisCount = 1;
    bool contiguous = false;

    // We have to use the _nearEqual function because of floating-point arithmetic.
    // Ex: 0.1 + 0.2 = 0.30000000000000004 and not 0.3.

    for (var i = index; i < offsets.length; ++i) {
      final offset = offsets[i];
      if (offset < minBlockOffset && !_nearEqual(offset, minBlockOffset)) {
        index = i;
        maxBlockOffset = minBlockOffset;
        minBlockOffset = offset;
        crossAxisCount = 1;
        contiguous = true;
      } else if (_nearEqual(offset, minBlockOffset) && contiguous) {
        crossAxisCount++;
      } else if (offset < maxBlockOffset &&
          offset > minBlockOffset &&
          !_nearEqual(offset, minBlockOffset)) {
        contiguous = false;
        maxBlockOffset = offset;
      } else {
        contiguous = false;
      }
    }

    return _Block(index, crossAxisCount, minBlockOffset, maxBlockOffset);
  }
}

const double _epsilon = 0.0001;

bool _nearEqual(double d1, double d2) {
  return (d1 - d2).abs() < _epsilon;
}

class _ViewportOffsets {
  _ViewportOffsets(
    List<double> mainAxisOffsets,
    this.trailingScrollOffset, [
    this.pageIndex = 0,
    this.firstChildIndex = 0,
  ]) : mainAxisOffsets = mainAxisOffsets.toList();

  final int pageIndex;

  final int firstChildIndex;

  final double trailingScrollOffset;

  final List<double> mainAxisOffsets;
}

class _Block {
  const _Block(this.index, this.crossAxisCount, this.minOffset, this.maxOffset);
  final int index;
  final int crossAxisCount;
  final double minOffset;
  final double maxOffset;
}
