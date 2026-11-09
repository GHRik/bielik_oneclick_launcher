import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';

const _historySeconds = StatisticSeries.historySeconds;

class StatisticLineChart extends StatefulWidget {
  const StatisticLineChart({
    super.key,
    required this.series,
    this.height = 170,
    this.selectedSeconds,
    this.onTimeSelected,
  });

  final StatisticSeries series;
  final double height;
  final double? selectedSeconds;
  final ValueChanged<double>? onTimeSelected;

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
                : -_historySeconds +
                      i * _historySeconds / (series.values.length - 1),
          );
    final selectedSeconds = widget.onTimeSelected == null
        ? _selectedSeconds
        : widget.selectedSeconds;
    int? index;
    if (selectedSeconds != null &&
        selectedSeconds >= -_historySeconds &&
        times.isNotEmpty) {
      index = 0;
      for (var i = 1; i < times.length; i++) {
        if ((times[i] - selectedSeconds).abs() <
            (times[index!] - selectedSeconds).abs()) {
          index = i;
        }
      }
    }
    final value = index == null ? null : series.values[index];
    final hasData = series.values.any((value) => value != null);
    final reading = index != null
        ? '${times[index].round()} s · ${_format(value ?? 0)} ${series.unit}'
        : hasData
        ? 'Dotknij wykresu'
        : '0 ${series.unit}';
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final axisStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontSize: 11,
          height: 1.2,
        );
    final axisWidth = 42 * textScale;
    return Semantics(
      label:
          'Wykres: ${series.title}, jednostka ${series.unit}. Ostatnie $_historySeconds sekund.',
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
                          final seconds =
                              -_historySeconds +
                              _historySeconds.toDouble() *
                                  (x / constraints.maxWidth).clamp(0.0, 1.0);
                          final onSelected = widget.onTimeSelected;
                          if (onSelected != null) {
                            onSelected(seconds);
                          } else {
                            setState(() => _selectedSeconds = seconds);
                          }
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
                              selectedSeconds: selectedSeconds,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labels = [
                  '-${_historySeconds ~/ 60} min',
                  '-${_historySeconds ~/ 120} min',
                  'teraz',
                ];
                final painters = [
                  for (final label in labels)
                    TextPainter(
                      text: TextSpan(text: label, style: axisStyle),
                      textDirection: TextDirection.ltr,
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(),
                ];
                final showMiddle =
                    constraints.maxWidth >=
                    painters[1].width +
                        2 *
                            (painters[0].width > painters[2].width
                                ? painters[0].width
                                : painters[2].width) +
                        16;
                final height = painters
                    .map((p) => p.height)
                    .reduce((a, b) => a > b ? a : b);
                for (final painter in painters) {
                  painter.dispose();
                }
                return SizedBox(
                  width: double.infinity,
                  height: height,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(labels[0], style: axisStyle),
                      ),
                      if (showMiddle)
                        Align(
                          alignment: Alignment.center,
                          child: Text(labels[1], style: axisStyle),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(labels[2], style: axisStyle),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30 * textScale,
            child: Center(
              child: Text(
                reading,
                key: ValueKey('chart-reading-${series.title}'),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 11, height: 1.2),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
    required this.selectedSeconds,
    required this.lineColor,
    required this.gridColor,
  });

  final StatisticSeries series;
  final List<double> times;
  final int? selectedIndex;
  final double? selectedSeconds;
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
      size.width * ((times[i] + _historySeconds) / _historySeconds).clamp(0, 1),
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
    final seconds = selectedSeconds;
    if (seconds != null && seconds >= -_historySeconds && seconds <= 0) {
      final x = size.width * ((seconds + _historySeconds) / _historySeconds);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
    final selected = selectedIndex;
    if (selected != null && series.values[selected] != null) {
      final p = point(selected);
      canvas.drawCircle(p, 5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.selectedSeconds != selectedSeconds ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
