/* The floating box of the app: every sheet of the settings, the
   shortcuts and the map menus opens in the same detached box, rounded
   and shaded, away from the edges of the screen instead of glued to
   the bottom edge and cut by it; the box floats at the center of the
   window height, the arrival fades with a short slide on an
   easeOutCubic curve, softer than the plain linear rise of the modal
   bottom sheet. Every number of the template sits in the settings
   below, one place to adapt the whole application.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';

/* the template of the floating boxes: the margins, the maximal size,
   the radius, the shading and the speed of the animation live here,
   the rest of the application calls showFloatingBox and inherits
   every change */
class FloatingBoxTheme {
  final EdgeInsets margins;
  final double maxWidth, radius, elevation, grow;
  final Duration duration;
  final Curve curve, reverseCurve;
  final Offset rise;
  const FloatingBoxTheme({
    this.margins = const EdgeInsets.fromLTRB(24, 24, 24, 24),
    this.maxWidth = 520,
    this.radius = 16,
    this.elevation = 6,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.rise = const Offset(0, 0.05),
    this.grow = 0.97,
  });
}

const floatingBoxTheme = FloatingBoxTheme();

Future<T?> showFloatingBox<T>(
    {required BuildContext context, required WidgetBuilder builder,
    FloatingBoxTheme box = floatingBoxTheme}) {
  final theme = Theme.of(context);
  final maxHeight = MediaQuery.of(context).size.height -
      box.margins.top -
      box.margins.bottom;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: box.duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      /* the fade, the small rise and the gentle scale share one curve,
         the box seems to float up into its place instead of sliding
         on a rail; the scale keeps the transform on the compositor,
         the raster cache of the content never rebuilds per tick */
      final curved = CurvedAnimation(
          parent: animation,
          curve: box.curve,
          reverseCurve: box.reverseCurve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: box.rise, end: Offset.zero)
              .animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: box.grow, end: 1.0).animate(curved),
          /* the box floats at the center of the window height, the
             edges of the screen cut nothing */
          child: Center(
            child: Padding(
              padding: box.margins,
              child: Material(
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: box.elevation,
                borderRadius: BorderRadius.circular(box.radius),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: box.maxWidth, maxHeight: maxHeight),
                  child: child,
                ),
              ),
            ),
          ),
          ),
        ),
      );
    },
  );
}