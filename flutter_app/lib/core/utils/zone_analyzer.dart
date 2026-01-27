import '../../models/detected_object.dart';

class ZoneAnalyzer {
  /// Determines which zone of the screen the object is in
  /// Screen is divided into 3x3 grid
  static ObjectZone getZone(
    double centerX,
    double centerY,
    double screenWidth,
    double screenHeight,
  ) {
    // Calculate thirds
    final horizontalThird = screenWidth / 3;
    final verticalThird = screenHeight / 3;

    // Determine horizontal position
    int horizontalZone;
    if (centerX < horizontalThird) {
      horizontalZone = 0; // Left
    } else if (centerX < horizontalThird * 2) {
      horizontalZone = 1; // Center
    } else {
      horizontalZone = 2; // Right
    }

    // Determine vertical position
    int verticalZone;
    if (centerY < verticalThird) {
      verticalZone = 0; // Top
    } else if (centerY < verticalThird * 2) {
      verticalZone = 1; // Center
    } else {
      verticalZone = 2; // Bottom
    }

    // Map to ObjectZone enum
    return _mapToZone(horizontalZone, verticalZone);
  }

  static ObjectZone _mapToZone(int horizontal, int vertical) {
    switch (vertical) {
      case 0: // Top
        switch (horizontal) {
          case 0:
            return ObjectZone.topLeft;
          case 1:
            return ObjectZone.topCenter;
          case 2:
            return ObjectZone.topRight;
        }
        break;
      case 1: // Center
        switch (horizontal) {
          case 0:
            return ObjectZone.centerLeft;
          case 1:
            return ObjectZone.center;
          case 2:
            return ObjectZone.centerRight;
        }
        break;
      case 2: // Bottom
        switch (horizontal) {
          case 0:
            return ObjectZone.bottomLeft;
          case 1:
            return ObjectZone.bottomCenter;
          case 2:
            return ObjectZone.bottomRight;
        }
        break;
    }
    return ObjectZone.center; // Default
  }

  /// Gets a human-readable description of the zone
  static String getZoneDescription(ObjectZone zone) {
    switch (zone) {
      case ObjectZone.topLeft:
        return "upper left";
      case ObjectZone.topCenter:
        return "ahead above";
      case ObjectZone.topRight:
        return "upper right";
      case ObjectZone.centerLeft:
        return "on your left";
      case ObjectZone.center:
        return "directly ahead";
      case ObjectZone.centerRight:
        return "on your right";
      case ObjectZone.bottomLeft:
        return "lower left";
      case ObjectZone.bottomCenter:
        return "below";
      case ObjectZone.bottomRight:
        return "lower right";
    }
  }

  /// Checks if zone is in the center column (most important for navigation)
  static bool isCenterZone(ObjectZone zone) {
    return zone == ObjectZone.topCenter ||
        zone == ObjectZone.center ||
        zone == ObjectZone.bottomCenter;
  }

  /// Checks if zone is on the left side
  static bool isLeftZone(ObjectZone zone) {
    return zone == ObjectZone.topLeft ||
        zone == ObjectZone.centerLeft ||
        zone == ObjectZone.bottomLeft;
  }

  /// Checks if zone is on the right side
  static bool isRightZone(ObjectZone zone) {
    return zone == ObjectZone.topRight ||
        zone == ObjectZone.centerRight ||
        zone == ObjectZone.bottomRight;
  }
}
