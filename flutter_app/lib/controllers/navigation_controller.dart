import '../models/detected_object.dart';
import '../models/navigation_instruction.dart';
import '../core/utils/zone_analyzer.dart';

class NavigationController {
  NavigationInstruction analyzeAndNavigate(
      List<DetectedObject> objects, double imageWidth, double imageHeight) {
    if (objects.isEmpty) {
      return NavigationInstruction(
        message: "Path clear",
        priority: InstructionPriority.low,
        direction: Direction.forward,
      );
    }

    // Sort objects by distance (closest first)
    objects.sort((a, b) => a.distance.compareTo(b.distance));
    
    // Look for high-priority hazards first (Stairs)
    final stairs = objects.where((o) => o.label.toLowerCase().contains('stairs')).toList();
    if (stairs.isNotEmpty) {
      final closestStairs = stairs.first;
      if (closestStairs.distance < 3.0 && ZoneAnalyzer.isCenterZone(closestStairs.zone)) {
        return NavigationInstruction(
          message: "Caution! Stairs ahead. ${closestStairs.distance.toStringAsFixed(1)} meters.",
          priority: InstructionPriority.critical,
          direction: Direction.forward,
        );
      }
    }

    // Look for Doors
    final doors = objects.where((o) => o.label.toLowerCase().contains('door')).toList();
    if (doors.isNotEmpty) {
      final closestDoor = doors.first;
      if (closestDoor.distance < 7.0) {
        String side = ZoneAnalyzer.isLeftZone(closestDoor.zone) ? "on your left" 
                   : ZoneAnalyzer.isRightZone(closestDoor.zone) ? "on your right" 
                   : "ahead";
                   
        String msg = closestDoor.distance < 1.2
            ? "Door $side. Reach out." 
            : "Door $side, ${closestDoor.distance.toStringAsFixed(1)} meters.";
            
        return NavigationInstruction(
          message: msg,
          priority: closestDoor.distance < 1.0 ? InstructionPriority.critical : InstructionPriority.medium,
          direction: Direction.forward,
        );
      }
    }

    final closest = objects.first;

    // Side obstacles (very close awareness)
    if (closest.distance < 1.5) {
      if (ZoneAnalyzer.isLeftZone(closest.zone)) {
        return NavigationInstruction(
          message: "${closest.label} on your left.",
          priority: InstructionPriority.medium,
          direction: Direction.forward,
        );
      } else if (ZoneAnalyzer.isRightZone(closest.zone)) {
        return NavigationInstruction(
          message: "${closest.label} on your right.",
          priority: InstructionPriority.medium,
          direction: Direction.forward,
        );
      }
    }

    // Critical proximity check (< 1.2 meters)
    if (closest.distance < 1.2 && ZoneAnalyzer.isCenterZone(closest.zone)) {
      return NavigationInstruction(
        message: "Stop! ${closest.label} directly ahead.",
        priority: InstructionPriority.critical,
        direction: Direction.stop,
      );
    }

    // Warning proximity check (1.2-2.5 meters)
    if (closest.distance < 2.5 && ZoneAnalyzer.isCenterZone(closest.zone)) {
      return NavigationInstruction(
        message:
            "${closest.label} ahead, ${closest.distance.toStringAsFixed(1)} meters.",
        priority: InstructionPriority.high,
        direction: _suggestDetour(closest.zone),
      );
    }

    // Side obstacles (very close)
    if (closest.distance < 1.2) {
      if (ZoneAnalyzer.isLeftZone(closest.zone)) {
        return NavigationInstruction(
          message: "${closest.label} on your left.",
          priority: InstructionPriority.medium,
          direction: Direction.forward,
        );
      } else if (ZoneAnalyzer.isRightZone(closest.zone)) {
        return NavigationInstruction(
          message: "${closest.label} on your right.",
          priority: InstructionPriority.medium,
          direction: Direction.forward,
        );
      }
    }

    // If we have a far away door, we already handled it above.
    // Otherwise, default safe state
    return NavigationInstruction(
      message: "Path is clear.",
      priority: InstructionPriority.low,
      direction: Direction.forward,
    );
  }

  Direction _suggestDetour(ObjectZone obstacleZone) {
    // If obstacle is center or slightly left/right, suggest opposite
    if (ZoneAnalyzer.isLeftZone(obstacleZone)) return Direction.right;
    if (ZoneAnalyzer.isRightZone(obstacleZone)) return Direction.left;

    // If dead center, usually suggest right (standard convention) or random/based on other objects
    return Direction.right;
  }
}
