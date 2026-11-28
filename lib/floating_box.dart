/* The floating box of the app: every sheet of the settings, the
   shortcuts and the map menus opens in the same detached box, rounded
   and shaded, away from the bottom edge of the screen instead of
   glued to it and cut by it; the arrival fades with a short slide on
   an easeOutCubic curve, softer than the plain linear rise of the
   modal bottom sheet.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';

Future<T?> showFloatingBox<T>(BuildContext context, WidgetBuilder builder) {
  final theme = Theme.of(context);
  final maxHeight = MediaQuery.of(context).size.height - 48;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      /* the fade and the small rise share one curve, the box seems to
         float up into its place instead of sliding on a rail */
      final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(curved),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              /* the box keeps its distance from every edge, the
                 bottom of the screen no longer cuts through it */
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Material(
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: 520, maxHeight: maxHeight),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}