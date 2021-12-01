import 'package:staggered_list/staggered/rendering/sliver_staggered_grid.dart';
import 'package:staggered_list/staggered/widgets/sliver.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A scrollable, 2D array of widgets with variable sizes.
/// The main axis direction of a grid is the direction in which it scrolls (the
/// [scrollDirection]).
/// To create a grid with a large (or infinite) number of children, use the
/// [SliverStaggeredGridDelegateWithFixedCrossAxisCount] for the [gridDelegate].
/// You can also use the [StaggeredGridView.countBuilder]
/// To create a linear array of children, use a [ListView].
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
/// Here are two brief snippets showing a [StaggeredGridView] and its equivalent using
/// *  [CustomScrollView]:
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [ListView], which is scrollable, linear staggered of widgets.
///  * [PageView], which is a scrolling staggered of child widgets that are each the
///    size of the viewport.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [SliverStaggeredGridDelegateWithFixedCrossAxisCount], which creates a
///    layout with a fixed number of tiles in the cross axis.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class StaggeredGridView extends BoxScrollView {
  /// Creates a scrollable, 2D array of widgets of variable sizes with a fixed
  /// number of tiles in the cross axis that are created on demand.
  /// This constructor is appropriate for grid views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Uses a [SliverStaggeredGridDelegateWithFixedCrossAxisCount] as the
  /// [gridDelegate].
  ///
  ///  Providing a non-null [itemCount] improves the ability of the
  /// [SliverStaggeredGridDelegate] to estimate the maximum scroll extent.
  ///
  /// [itemBuilder] and [staggeredTileBuilder] will be called only with
  /// indices greater than or equal to
  /// zero and less than [itemCount].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverVariableSizeChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverVariableSizeChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  StaggeredGridView.countBuilder({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required int crossAxisCount,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedStaggeredTileBuilder staggeredTileBuilder,
    int? itemCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    this.addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    String? restorationId,
  })  : gridDelegate = SliverStaggeredGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileBuilder: staggeredTileBuilder,
          staggeredTileCount: itemCount,
        ),
        childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
        ),
        super(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          restorationId: restorationId,
        );

  /// A delegate that controls the layout of the children within the
  /// [StaggeredGridView].
  ///
  /// The [StaggeredGridView] and [StaggeredGridView.custom] constructors let you specify this
  /// delegate explicitly. The other constructors create a [gridDelegate]
  /// implicitly.
  final SliverStaggeredGridDelegate gridDelegate;

  /// A delegate that provides the children for the [StaggeredGridView].
  ///
  /// The [StaggeredGridView.custom] constructor lets you specify this delegate
  /// explicitly. The other constructors create a [childrenDelegate] that wraps
  /// the given child staggered.
  final SliverChildDelegate childrenDelegate;

  /// Whether to add keepAlives to children
  final bool addAutomaticKeepAlives;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverStaggeredGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
    );
  }
}
