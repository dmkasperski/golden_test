import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';

/// How [ListDetailLayout] arranges its panes.
enum ListDetailPanes {
  /// The list alone; the detail opens as a page of its own.
  single,

  /// The list and the detail side by side, on a wide screen.
  side,

  /// The list and the detail on either side of a fold from top to bottom, on
  /// a foldable half open like a book.
  book,

  /// The detail above and the list below a fold across the middle, on a
  /// foldable half open like a laptop.
  laptop,
}

/// Shows a list with its detail next to it when the screen has room for both,
/// and splits them at the fold of a foldable held half open.
///
/// It sees the fold only when the platform reports it in
/// [MediaQueryData.displayFeatures]. On iPhone Duo that takes a plugin, such
/// as `foldable`; Flutter itself reports no fold on iOS.
///
/// The fold's bounds are in the coordinates of the whole screen, so the
/// layout expects to fill the screen, as a screen-level widget does.
class ListDetailLayout extends StatelessWidget {
  const ListDetailLayout({super.key, required this.list, required this.detail});

  /// The narrowest screen that shows the list and the detail side by side.
  static const double minSideBySideWidth = 600;

  /// The width of the list when the panes are side by side on a flat screen.
  static const double listWidth = 360;

  final Widget list;
  final Widget detail;

  /// The arrangement for the screen in [context].
  static ListDetailPanes panesOf(BuildContext context) {
    final Rect? fold = _halfOpenFold(context);
    if (fold != null) {
      return fold.height >= fold.width
          ? ListDetailPanes.book
          : ListDetailPanes.laptop;
    }
    return MediaQuery.sizeOf(context).width >= minSideBySideWidth
        ? ListDetailPanes.side
        : ListDetailPanes.single;
  }

  /// A fold or hinge, half open, from one edge of the screen to the other.
  static Rect? _halfOpenFold(BuildContext context) {
    final Rect screen = Offset.zero & MediaQuery.sizeOf(context);
    for (final DisplayFeature feature in MediaQuery.displayFeaturesOf(
      context,
    )) {
      final Rect bounds = feature.bounds;
      // A hinge always splits the screen; a fold only while half open, since
      // lying flat it is one even surface.
      final bool splits = switch (feature.type) {
        DisplayFeatureType.hinge => true,
        DisplayFeatureType.fold =>
          feature.state == DisplayFeatureState.postureHalfOpened,
        _ => false,
      };
      final bool vertical =
          bounds.top <= screen.top &&
          bounds.bottom >= screen.bottom &&
          bounds.left > screen.left &&
          bounds.right < screen.right;
      final bool horizontal =
          bounds.left <= screen.left &&
          bounds.right >= screen.right &&
          bounds.top > screen.top &&
          bounds.bottom < screen.bottom;
      if (splits && (vertical || horizontal)) {
        return bounds;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    switch (panesOf(context)) {
      case ListDetailPanes.single:
        return list;
      case ListDetailPanes.side:
        return Row(
          children: [
            SizedBox(width: listWidth, child: _pane(list, removeRight: true)),
            const VerticalDivider(width: 1),
            Expanded(child: _pane(detail, removeLeft: true)),
          ],
        );
      case ListDetailPanes.book:
        final Rect fold = _halfOpenFold(context)!;
        return Row(
          children: [
            SizedBox(width: fold.left, child: _pane(list, removeRight: true)),
            SizedBox(width: fold.width),
            Expanded(child: _pane(detail, removeLeft: true)),
          ],
        );
      case ListDetailPanes.laptop:
        // The content faces the user above the fold; the controls lie flat
        // below it, where the keyboard opens too.
        final Rect fold = _halfOpenFold(context)!;
        return Column(
          children: [
            SizedBox(
              height: fold.top,
              child: _pane(detail, removeBottom: true),
            ),
            SizedBox(height: fold.height),
            Expanded(child: _pane(list, removeTop: true)),
          ],
        );
    }
  }

  /// A pane keeps only the padding of the edges of the screen it touches, and
  /// shows its own snackbars. Without a messenger of its own, a snackbar shows
  /// in every Scaffold that is not inside another one, so in both panes.
  Widget _pane(
    Widget child, {
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) => Builder(
    builder: (context) => MediaQuery.removeViewInsets(
      context: context,
      removeBottom: removeBottom,
      child: Builder(
        builder: (context) => MediaQuery.removePadding(
          context: context,
          removeLeft: removeLeft,
          removeTop: removeTop,
          removeRight: removeRight,
          removeBottom: removeBottom,
          child: ScaffoldMessenger(child: child),
        ),
      ),
    ),
  );
}

/// The `anchorPoint` of a dialog or sheet that shows content: on a foldable
/// half open, it opens above a fold across the middle, and on the trailing
/// side of a fold from top to bottom.
///
/// Without an anchor it opens on the side nearest the top leading corner.
Offset contentAnchorOf(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return switch (Directionality.of(context)) {
    TextDirection.ltr => Offset(size.width, 0),
    TextDirection.rtl => Offset.zero,
  };
}

/// The `anchorPoint` of a dialog or sheet with controls, such as a reply
/// form: on a foldable half open, it opens below a fold across the middle,
/// where the device lies flat, and on the trailing side of a fold from top to
/// bottom.
Offset controlsAnchorOf(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return switch (Directionality.of(context)) {
    TextDirection.ltr => Offset(size.width, size.height),
    TextDirection.rtl => Offset(0, size.height),
  };
}
