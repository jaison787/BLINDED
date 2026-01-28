import '../models/detected_object.dart';
import '../models/navigation_instruction.dart';

class DetectionFilter {
  /// Filter and prioritize objects for navigation guidance
  static List<DetectedObject> filterForNavigation(List<DetectedObject> objects) {
    // Priority levels for different object types
    final priorities = <String, int>{
      'Stairs': 10,      // Critical safety
      'Door': 9,         // Primary navigation target
      'Person': 8,       // Collision avoidance
      'Chair': 5,
      'Table': 5,
      'Couch': 4,
      'Bed': 4,
      'Obstacle': 3,
    };
    
    // Filter objects
    final filtered = objects.where((obj) {
      // Include objects that are:
      // 1. Close enough to matter (< 5 meters)
      // 2. High enough confidence (> 40%)
      // 3. In relevant zones (front/center)
      return obj.distance < 5.0 && 
             obj.confidence > 0.4 &&
             _isRelevantZone(obj.zone);
    }).toList();
    
    // Sort by priority, then by distance
    filtered.sort((a, b) {
      final priorityA = priorities[a.label] ?? 1;
      final priorityB = priorities[b.label] ?? 1;
      
      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA);
      }
      return a.distance.compareTo(b.distance);
    });
    
    // Return top 3 most important
    return filtered.take(3).toList();
  }
  
  /// Check if zone is relevant for navigation
  static bool _isRelevantZone(ObjectZone zone) {
    // Exclude top corners (usually ceiling/irrelevant)
    return zone != ObjectZone.topLeft && zone != ObjectZone.topRight;
  }
  
  /// Create navigation instruction from detected object
  static NavigationInstruction createInstruction(DetectedObject obj) {
    // CRITICAL: Stairs or very close obstacles
    if (obj.label == 'Stairs' || obj.isCritical) {
      return NavigationInstruction(
        message: _getCriticalMessage(obj),
        priority: InstructionPriority.critical,
        direction: Direction.stop,
      );
    }
    
    // HIGH: Doors
    if (obj.label == 'Door') {
      final positionText = _getPositionText(obj.zone);
      final direction = _getDirectionFromZone(obj.zone);
      
      return NavigationInstruction(
        message: 'Door $positionText, ${obj.distance.toStringAsFixed(1)} meters',
        priority: InstructionPriority.high,
        direction: direction,
      );
    }
    
    // MEDIUM: Warning distance obstacles
    if (obj.isWarning) {
      return NavigationInstruction(
        message: '${obj.label} ${_getPositionText(obj.zone)}, ${obj.distance.toStringAsFixed(1)} meters',
        priority: InstructionPriority.medium,
        direction: _getAvoidanceDirection(obj.zone),
      );
    }
    
    // LOW/INFO: Far objects
    return NavigationInstruction(
      message: '${obj.label} ${_getPositionText(obj.zone)}',
      priority: InstructionPriority.low,
      direction: Direction.forward,
    );
  }
  
  static String _getCriticalMessage(DetectedObject obj) {
    if (obj.label == 'Stairs') {
      return 'STAIRS AHEAD! Stop immediately. ${obj.distance.toStringAsFixed(1)} meters.';
    }
    return 'OBSTACLE! ${obj.label} very close, ${obj.distance.toStringAsFixed(1)} meters. STOP!';
  }
  
  static String _getPositionText(ObjectZone zone) {
    switch (zone) {
      case ObjectZone.topLeft:
      case ObjectZone.centerLeft:
      case ObjectZone.bottomLeft:
        return 'on your left';
      case ObjectZone.topRight:
      case ObjectZone.centerRight:
      case ObjectZone.bottomRight:
        return 'on your right';
      case ObjectZone.topCenter:
        return 'above';
      case ObjectZone.bottomCenter:
        return 'below';
      default:
        return 'ahead';
    }
  }
  
  static Direction _getDirectionFromZone(ObjectZone zone) {
    // For doors, suggest direction to face them
    switch (zone) {
      case ObjectZone.centerLeft:
      case ObjectZone.bottomLeft:
        return Direction.left;
      case ObjectZone.centerRight:
      case ObjectZone.bottomRight:
        return Direction.right;
      default:
        return Direction.forward;
    }
  }
  
  static Direction _getAvoidanceDirection(ObjectZone zone) {
    // For obstacles, suggest direction to avoid them
    switch (zone) {
      case ObjectZone.centerLeft:
      case ObjectZone.bottomLeft:
        return Direction.right; // Avoid by going right
      case ObjectZone.centerRight:
      case ObjectZone.bottomRight:
        return Direction.left; // Avoid by going left
      default:
        return Direction.stop; // Object ahead - stop or assess
    }
  }
  
  /// Combine multiple detections into single instruction
  static NavigationInstruction? createCombinedInstruction(List<DetectedObject> objects) {
    if (objects.isEmpty) return null;
    
    final filtered = filterForNavigation(objects);
    if (filtered.isEmpty) return null;
    
    // Return instruction for highest priority object
    return createInstruction(filtered.first);
  }
}