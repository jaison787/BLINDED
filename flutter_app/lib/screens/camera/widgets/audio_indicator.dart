import 'package:flutter/material.dart';
import '../../../models/navigation_instruction.dart';
import '../../../core/theme/app_theme.dart';

class AudioIndicator extends StatelessWidget {
  final NavigationInstruction? instruction;

  const AudioIndicator({
    Key? key,
    this.instruction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (instruction == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(instruction!.priority),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority Icon
            Icon(
              _getIconForPriority(instruction!.priority),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),

            // Instruction Message
            Text(
              instruction!.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Direction Indicator
            _buildDirectionIndicator(instruction!.direction),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(InstructionPriority priority) {
    switch (priority) {
      case InstructionPriority.critical:
        return AppTheme.criticalColor;
      case InstructionPriority.high:
        return AppTheme.errorColor;
      case InstructionPriority.medium:
        return AppTheme.warningColor;
      case InstructionPriority.low:
        return AppTheme.primaryColor;
      case InstructionPriority.info:
        return AppTheme.surfaceColor;
    }
  }

  IconData _getIconForPriority(InstructionPriority priority) {
    switch (priority) {
      case InstructionPriority.critical:
        return Icons.error;
      case InstructionPriority.high:
        return Icons.warning;
      case InstructionPriority.medium:
        return Icons.info;
      case InstructionPriority.low:
        return Icons.navigation;
      case InstructionPriority.info:
        return Icons.info_outline;
    }
  }

  Widget _buildDirectionIndicator(Direction direction) {
    IconData icon;
    String text;

    switch (direction) {
      case Direction.forward:
        icon = Icons.arrow_upward;
        text = 'Move Forward';
        break;
      case Direction.left:
        icon = Icons.arrow_back;
        text = 'Turn Left';
        break;
      case Direction.right:
        icon = Icons.arrow_forward;
        text = 'Turn Right';
        break;
      case Direction.stop:
        icon = Icons.stop;
        text = 'Stop';
        break;
      case Direction.turnAround:
        icon = Icons.u_turn_left;
        text = 'Turn Around';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}