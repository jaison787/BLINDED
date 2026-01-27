import 'package:flutter/material.dart';
import '../../../models/detected_object.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectedObject> objects;
  final Size? imageSize;

  const DetectionOverlay({
    Key? key,
    required this.objects,
    this.imageSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DetectionPainter(objects, imageSize),
      child: Container(),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size? imageSize;

  DetectionPainter(this.objects, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null) return;
    
    for (var obj in objects) {
      _drawBoundingBox(canvas, size, obj);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, DetectedObject obj) {
    // Determine scaling factors. 
    // Image comes in YUV format (usu. landscape 720x480)
    // Screen is in Portrait (usu. 400x800)
    // Since images are rotated by ML Kit logic, we need to match that.
    
    // We assume the preview is "Cover" or "Fill" - for MVP we'll use simple ratio
    final double scaleX = size.width / imageSize!.height;
    final double scaleY = size.height / imageSize!.width;

    // Choose color based on distance
    Color boxColor;
    double strokeWidth;
    
    if (obj.isCritical) {
      boxColor = Colors.red;
      strokeWidth = 4.0;
    } else if (obj.isWarning) {
      boxColor = Colors.orange;
      strokeWidth = 3.0;
    } else {
      boxColor = Colors.green;
      strokeWidth = 2.0;
    }

    // Draw bounding box (scaled)
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTRB(
      obj.boundingBox.left * scaleX,
      obj.boundingBox.top * scaleY,
      obj.boundingBox.right * scaleX,
      obj.boundingBox.bottom * scaleY,
    );

    canvas.drawRect(rect, paint);

    // Draw label background
    final textSpan = TextSpan(
      text: '${obj.label} (${obj.distance.toStringAsFixed(1)}m)',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw label above bounding box
    final labelOffset = Offset(
      rect.left,
      rect.top - textPainter.height - 4,
    );

    // Draw background for text
    final bgRect = Rect.fromLTWH(
      labelOffset.dx,
      labelOffset.dy,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = boxColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRect(bgRect, bgPaint);

    // Draw text
    textPainter.paint(canvas, labelOffset + const Offset(4, 2));

    // Draw distance indicator (circle at center)
    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy),
      8,
      Paint()..color = boxColor,
    );
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return true; // Always repaint for live stream
  }
}
