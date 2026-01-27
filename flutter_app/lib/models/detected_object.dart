import 'dart:ui';

enum ObjectZone {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight
}

class DetectedObject {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final double distance;
  final ObjectZone zone;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.distance,
    required this.zone,
  });

  double get centerX => boundingBox.center.dx;
  double get centerY => boundingBox.center.dy;

  bool get isCritical => distance < 1.0;
  bool get isWarning => distance >= 1.0 && distance < 2.0;
}
