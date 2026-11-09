import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';

class StatisticLineChart extends StatefulWidget {
  const StatisticLineChart({
    super.key,
    required this.series,
    this.height = 170,
  });

  final StatisticSeries series;
  final double height;

  @override
  State<StatisticLineChart> createState() => _StatisticLineChartState();
}

class _StatisticLineChartState extends State<StatisticLineChart> {
  double? _selectedSeconds;

  String _format(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final colors = Theme.of(context).colorScheme;
    final times = series.secondsAgo.length == series.values.length
        ? series.secondsAgo
        : List.generate(
            series.values.length,
            (i) => series.values.length < 2
                ? 0.0
                : -60 + i * 60 / (series.values.length - 1),
          );
    int? index;
    if (_selectedSeconds != null && times.isNotEmpty) {
      index = 0;
      for (var i = 1; i < times.length; i++) {
        if ((times[i] - _selectedSeconds!).abs() <
            (times[index!] - _selectedSeconds!).abs()) {
          index = i;
        }
      }
    }
    final value = index == null ? null : series.values[index];
    final hasData = series.values.any((value) => value != null);
    final reading = index != null
        ? '${times[index].round()} s · ${value == null ? 'Brak danych' : '${_format(value)} ${series.unit}'}'
        : hasData
        ? 'Dotknij wykresu, aby zobaczyć wartość'
        : 'Brak danych';
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final axisStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(fontSize: 11);
    final axisWidth = 42 * textScale;
    return Semantics(
      label:
          'Wykres: ${series.title}, jednostka ${series.unit}. Ostatnie 60 sekund.',
      child: Column(
        children: [
          SizedBox(
            height: widget.height * textScale,
            child: Row(
              children: [
                SizedBox(
                  width: axisWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(series.maximum), style: axisStyle),
                      Text(
                        _format((series.minimum + series.maximum) / 2),
                        style: axisStyle,
                      ),
                      Text(_format(series.minimum), style: axisStyle),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        void select(double x) {
                          if (constraints.maxWidth <= 0 || times.isEmpty) {
                            return;
                          }
                          setState(
                            () => _selectedSeconds =
                                -60 +
                                60 * (x / constraints.maxWidth).clamp(0, 1),
                          );
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) =>
                              select(details.localPosition.dx),
                          onHorizontalDragUpdate: (details) =>
                              select(details.localPosition.dx),
                          child: CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _LineChartPainter(
                              series: series,
                              times: times,
                              selectedIndex: index,
                              lineColor: colors.primary,
                              gridColor: colors.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: axisWidth, top: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('-60 s', style: axisStyle),
                Text('-30 s', style: axisStyle),
                Text('teraz', style: axisStyle),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reading,
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
    required this.times,
    required this.selectedIndex,
    required this.lineColor,
    required this.gridColor,
  });

  final StatisticSeries series;
  final List<double> times;
  final int? selectedIndex;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.maximum <= series.minimum) return;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }
    Offset point(int i) => Offset(
      size.width * ((times[i] + 60) / 60).clamp(0, 1),
      size.height *
          (1 -
              ((series.values[i]! - series.minimum) /
                      (series.maximum - series.minimum))
                  .clamp(0, 1)),
    );
    final line = Path();
    var connected = false;
    for (var i = 0; i < series.values.length; i++) {
      if (series.values[i] == null) {
        connected = false;
        continue;
      }
      final p = point(i);
      if (connected && (times[i] - times[i - 1]) <= 3) {
        line.lineTo(p.dx, p.dy);
      } else {
        line.moveTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 2, Paint()..color = lineColor);
      connected = true;
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final selected = selectedIndex;
    if (selected != null && series.values[selected] != null) {
      final p = point(selected);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
