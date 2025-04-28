// lines to connect document previews

import 'package:flutter/material.dart';

class Line {
  final String sourceId;
  final String destinationId;

  Line(this.sourceId, this.destinationId);
}

class LinePainter extends CustomPainter {
  List<Line> lines;
  Map<String, Offset> positions; // map document IDs to their center positions
  LinePainter({required this.lines, required this.positions});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 108, 108, 108)
      ..strokeWidth = 6;
    for (var line in lines) {
      final sourcePos = positions[line.sourceId];
      final destPos = positions[line.destinationId];
      if (sourcePos != null && destPos != null) {
        canvas.drawLine(sourcePos, destPos, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) => true; // Simplified for clarity
}