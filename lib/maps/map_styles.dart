/* The common styles of the geographical maps: one style per stroke layer,
   one style per point layer, and the settings bundle of a map ( layers,
   points, label thresholds, frame ).
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';

class StrokeStyle {
  final Color color;
  final double width;
  final Color? fill;
  final List<double>? dashes;
  final bool closes; // polygon layer: the closing edge is drawn
  const StrokeStyle(this.color, this.width,
      {this.fill, this.dashes, this.closes = false});
}

class PointStyle {
  final Color color;
  final double radius;
  final double? minZoom; // visible beyond this zoom ( scale )
  const PointStyle(this.color, this.radius, {this.minZoom});
}

class MapSettings {
  final Map<String, StrokeStyle> layers;
  final Map<String, PointStyle> points;
  final Map<String, double> labelsMinZoom; // labels visible beyond this zoom
  final Rect bounds; // initial frame, in plane units
  const MapSettings(
      this.layers, this.points, this.labelsMinZoom, this.bounds);
}