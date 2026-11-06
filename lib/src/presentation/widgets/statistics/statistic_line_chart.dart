import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';

class StatisticLineChart extends StatefulWidget {
  const StatisticLineChart({super.key, required this.series});

  final StatisticSeries series;

  @override
  State<StatisticLineChart> createState() => _StatisticLineChartState();
}

class _StatisticLineChartState extends State<StatisticLineChart> {
  int? _selectedIndex;

  String _format(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

  void _select(double x, double width) {
    if (width <= 0 || widget.series.values.isEmpty) return;
    final index = ((x / width).clamp(0.0, 1.0) *
            (widget.series.values.length - 1))
        .round();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final colors = Theme.of(context).colorScheme;
    final index = _selectedIndex;
    return Semantics(
      label: 'Wykres: ${series.title}, jednostka ${series.unit}. Dane przykładowe z 60 sekund.',
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(series.maximum)),
                      Text(_format((series.minimum + series.maximum) / 2)),
                      Text(_format(series.minimum)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            _select(details.localPosition.dx, constraints.maxWidth),
                        onHorizontalDragUpdate: (details) =>
                            _select(details.localPosition.dx, constraints.maxWidth),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _LineChartPainter(
                            series: series,
                            selectedIndex: index,
                            lineColor: colors.primary,
                            gridColor: colors.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 42, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('-60 s'), Text('-30 s'), Text('teraz')],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            index == null
                ? 'Dotknij wykresu, aby zobaczyć wartość'
                : '${-60 + (index * 60 / (series.values.length - 1)).round()} s · ${_format(series.values[index])} ${series.unit}',
            key: ValueKey('chart-reading-${series.title}'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.series,
    required this.selectedIndex,
    required this.lineColor,
    required this.gridColor,
  });

  final StatisticSeries series;
  final int? selectedIndex;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.values.length < 2 || series.maximum <= series.minimum) return;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset point(int index) => Offset(
          size.width * index / (series.values.length - 1),
          size.height *
              (1 - ((series.values[index] - series.minimum) /
                      (series.maximum - series.minimum)).clamp(0.0, 1.0)),
        );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < series.values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = lineColor.withValues(alpha: 0.08));
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    if (selectedIndex != null) {
      final selected = point(selectedIndex!);
      canvas.drawLine(
        Offset(selected.dx, 0),
        Offset(selected.dx, size.height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(selected, 5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
