import 'package:flutter/material.dart';

// WOW tarzı CustomPainter - center-to-center drawing with dots
class LinePainter extends CustomPainter {
  final List<Offset> points;
  final double letterRadius;

  LinePainter(this.points, this.letterRadius);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // WOW tarzı çizgi çizimi - center to center
    final paint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Glow efekti
    final glowPaint = Paint()
      ..color = Colors.orange.shade400.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Nokta çizimi için
    final dotPaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.fill;

    // Tüm noktalar harf merkezleri
    final List<Offset> letterCenters = points;

    if (letterCenters.length < 2) return;

    // Her segment için ayrı çizgi çiz - edge to edge
    for (int i = 0; i < letterCenters.length - 1; i++) {
      final currentCenter = letterCenters[i];
      final nextCenter = letterCenters[i + 1];

      // Mevcut harfin kenar noktasını hesapla
      final startEdge = _getCircleEdgePoint(currentCenter, nextCenter);

      // Sonraki harfin kenar noktasını hesapla
      final endEdge = _getCircleEdgePoint(nextCenter, currentCenter);

      // Her segment için ayrı path oluştur - edge to edge
      final segmentPath = Path();
      segmentPath.moveTo(startEdge.dx, startEdge.dy);
      segmentPath.lineTo(endEdge.dx, endEdge.dy);

      // Segment'i çiz (glow ve ana çizgi)
      canvas.drawPath(segmentPath, glowPaint);
      canvas.drawPath(segmentPath, paint);
    }

    // Her harf için kenar noktasında dot çiz
    for (int i = 0; i < letterCenters.length; i++) {
      final currentCenter = letterCenters[i];
      final nextCenter = i + 1 < letterCenters.length
          ? letterCenters[i + 1]
          : null;
      final prevCenter = i > 0 ? letterCenters[i - 1] : null;

      // Nokta pozisyonunu hesapla - kenarda
      Offset dotPosition;
      if (i == 0 && nextCenter != null) {
        // İlk harf - sonraki harfe doğru kenar
        dotPosition = _getCircleEdgePoint(currentCenter, nextCenter);
      } else if (i == letterCenters.length - 1 && prevCenter != null) {
        // Son harf - önceki harfe doğru kenar
        dotPosition = _getCircleEdgePoint(currentCenter, prevCenter);
      } else if (prevCenter != null && nextCenter != null) {
        // Orta harfler - iki yöne de kenar hesapla ve ortalaması
        final edge1 = _getCircleEdgePoint(currentCenter, prevCenter);
        final edge2 = _getCircleEdgePoint(currentCenter, nextCenter);
        dotPosition = Offset(
          (edge1.dx + edge2.dx) / 2,
          (edge1.dy + edge2.dy) / 2,
        );
      } else {
        // Fallback - merkez nokta
        dotPosition = currentCenter;
      }

      canvas.drawCircle(dotPosition, 5.0, dotPaint);
    }
  }

  // Çember kenarındaki noktayı hesapla - normalized direction ile
  Offset _getCircleEdgePoint(Offset center, Offset target) {
    final direction = target - center;
    final distance = direction.distance;
    if (distance == 0) return center;

    final normalizedDirection = direction / distance;
    return center + normalizedDirection * letterRadius;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
