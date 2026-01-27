enum InstructionPriority { critical, high, medium, low, info }

enum Direction { forward, left, right, stop, turnAround }

class NavigationInstruction {
  final String message;
  final InstructionPriority priority;
  final Direction direction;

  NavigationInstruction({
    required this.message,
    required this.priority,
    required this.direction,
  });

  bool get requiresVibration =>
      priority == InstructionPriority.critical ||
      priority == InstructionPriority.high ||
      priority == InstructionPriority.medium;
}
