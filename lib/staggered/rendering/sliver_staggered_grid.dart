import 'dart:collection';
import 'dart:math' as math;

import 'package:staggered_list/staggered/rendering/sliver_variable_size_box_adaptor.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Signature for a function that creates [StaggeredTile] for a given index.
typedef IndexedStaggeredTileBuilder = StaggeredTile? Function(int index);

/// Specifies how a staggered grid is configured.
@immutable
class StaggeredGridConfiguration {
  ///  Creates an object that holds the configuration of a staggered grid.
  const StaggeredGridConfiguration({
    required this.crossAxisCount,
    required this.staggeredTileBuilder,
    required this.cellExtent,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.reverseCrossAxis,
    required this.staggeredTileCount,
    this.mainAxisOffsetsCacheSize = 3,
  })  : assert(crossAxisCount > 0),
        assert(cellExtent >= 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(mainAxisOffsetsCacheSize > 0),
        cellStride = cellExtent + crossAxisSpacing;

  /// The maximum number of children in the cross axis.
  final int crossAxisCount;

  /// The number of pixels from the leading edge of one cell to the trailing
  /// edge of the same cell in both axis.
  final double cellExtent;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// Called to get the tile at the specified index for the
  /// [SliverGridStaggeredTileLayout].
  final IndexedStaggeredTileBuilder staggeredTileBuilder;

  /// The total number of tiles this delegate can provide.
  /// If null, the number of tiles is determined by the least index for which
  /// [builder] returns null.
  final int? staggeredTileCount;

  /// Whether the children should be placed in the opposite order of increasing
  /// coordinates in the cross axis.
  /// For example, if the cross axis is horizontal, the children are placed from
  /// left to right when [reverseCrossAxis] is false and from right to left when
  /// [reverseCrossAxis] is true.
  /// Typically set to the return value of [axisDirectionIsReversed] applied to
  /// the [SliverConstraints.crossAxisDirection].
  final bool reverseCrossAxis;

  final double cellStride;

  /// The number of pages necessary to cache a mainAxisOffsets value.
  final int mainAxisOffsetsCacheSize;

  List<double> generateMainAxisOffsets() =>
      List.generate(crossAxisCount, (i) => 0.0);

  /// Gets a normalized tile for the given index.
  StaggeredTile? getStaggeredTile(int index) {
    StaggeredTile? tile;
    if (staggeredTileCount == null || index < staggeredTileCount!) {
      // There is maybe a tile for this index.
      tile = _normalizeStaggeredTile(staggeredTileBuilder(index));
    }
    return tile;
  }

  /// Creates a staggered tile with the computed extent from the given tile.
  StaggeredTile? _normalizeStaggeredTile(StaggeredTile? staggeredTile) {
    if (staggeredTile == null) {
      return null;
    } else {
      final crossAxisCellCount =
          staggeredTile.crossAxisCellCount.clamp(0, crossAxisCount).toInt();
      if (staggeredTile.fitContent) {
        return StaggeredTile.fit(crossAxisCellCount);
      }
    }
  }
}

/// Describes the placement of a child in a [RenderSliverStaggeredGrid].
///  * [RenderSliverStaggeredGrid], which uses this class during its
///    [RenderSliverStaggeredGrid.performLayout] method.
@immutable
class SliverStaggeredGridGeometry {
  /// Creates an object that describes the placement of a child in a [RenderSliverStaggeredGrid].
  const SliverStaggeredGridGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
    required this.crossAxisCellCount,
    required this.blockIndex,
  });

  /// The scroll offset of the leading edge of the child relative to the leading
  /// edge of the parent.
  final double scrollOffset;

  /// The offset of the child in the non-scrolling axis.
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  final double crossAxisOffset;

  /// The extent of the child in the scrolling axis.
  /// If the scroll axis is vertical, this extent is the child's height. If the
  /// scroll axis is horizontal, this extent is the child's width.
  final double? mainAxisExtent;

  /// The extent of the child in the non-scrolling axis.
  /// If the scroll axis is vertical, this extent is the child's width. If the
  /// scroll axis is horizontal, this extent is the child's height.
  final double crossAxisExtent;

  final int crossAxisCellCount;

  final int blockIndex;

  bool get hasTrailingScrollOffset => mainAxisExtent != null;

  /// The scroll offset of the trailing edge of the child relative to the
  /// leading edge of the parent.
  double get trailingScrollOffset => scrollOffset + (mainAxisExtent ?? 0);

  SliverStaggeredGridGeometry copyWith({
    double? scrollOffset,
    double? crossAxisOffset,
    double? mainAxisExtent,
    double? crossAxisExtent,
    int? crossAxisCellCount,
    int? blockIndex,
  }) {
    return SliverStaggeredGridGeometry(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      crossAxisOffset: crossAxisOffset ?? this.crossAxisOffset,
      mainAxisExtent: mainAxisExtent ?? this.mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisCellCount: crossAxisCellCount ?? this.crossAxisCellCount,
      blockIndex: blockIndex ?? this.blockIndex,
    );
  }

  /// Returns a tight [BoxConstraints] that forces the child to have the
  /// required size.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent ?? 0.0,
      maxExtent: mainAxisExtent ?? double.infinity,
      crossAxisExtent: crossAxisExtent,
    );
  }
}

/// Creates staggered grid layouts.
/// This delegate creates grids with variable sized but equally spaced tiles.
///  * [RenderSliverStaggeredGrid], which can use this delegate to control the layout of
///    its tiles.
abstract class SliverStaggeredGridDelegate {
  /// Creates a delegate that makes staggered grid layouts
  /// All of the arguments must not be null. The [mainAxisSpacing] and
  /// [crossAxisSpacing] arguments must not be negative.
  const SliverStaggeredGridDelegate({
    required this.staggeredTileBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.staggeredTileCount,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0);

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// Called to get the tile at the specified index for the
  /// [RenderSliverStaggeredGrid].
  final IndexedStaggeredTileBuilder staggeredTileBuilder;

  /// The total number of tiles this delegate can provide.
  /// If null, the number of tiles is determined by the least index for which
  /// [builder] returns null.
  final int? staggeredTileCount;

  /// Returns information about the staggered grid configuration.
  StaggeredGridConfiguration getConfiguration(SliverConstraints constraints);

  /// Override this method to return true when the children need to be
  /// laid out.
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(SliverStaggeredGridDelegate oldDelegate) {
    return oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.staggeredTileCount != staggeredTileCount ||
        oldDelegate.staggeredTileBuilder != staggeredTileBuilder;
  }
}

/// Creates staggered grid layouts with a fixed number of cells in the cross axis.
/// For example, if the grid is vertical, this delegate will create a layout
/// with a fixed number of columns. If the grid is horizontal, this delegate
/// will create a layout with a fixed number of rows.
/// This delegate creates grids with variable sized but equally spaced tiles.
///  * [SliverStaggeredGridDelegate], which creates staggered grid layouts.
///  * [RenderSliverStaggeredGrid], which can use this delegate to control the layout of
///    its tiles.
class SliverStaggeredGridDelegateWithFixedCrossAxisCount
    extends SliverStaggeredGridDelegate {
  /// Creates a delegate that makes staggered grid layouts with a fixed number
  /// of tiles in the cross axis.
  /// All of the arguments must not be null. The [mainAxisSpacing] and
  /// [crossAxisSpacing] arguments must not be negative. The [crossAxisCount]
  /// argument must be greater than zero.
  const SliverStaggeredGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
    required IndexedStaggeredTileBuilder staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    int? staggeredTileCount,
  })  : assert(crossAxisCount > 0),
        super(
          staggeredTileBuilder: staggeredTileBuilder,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileCount: staggeredTileCount,
        );

  /// The number of children in the cross axis.
  final int crossAxisCount;

  @override
  StaggeredGridConfiguration getConfiguration(SliverConstraints constraints) {
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double cellExtent = usableCrossAxisExtent / crossAxisCount;
    return StaggeredGridConfiguration(
      crossAxisCount: crossAxisCount,
      staggeredTileBuilder: staggeredTileBuilder,
      staggeredTileCount: staggeredTileCount,
      cellExtent: cellExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }
}
