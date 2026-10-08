import 'package:flutter/material.dart';

import '../../core/utils/currency_utils.dart';
import '../../data/models/expense.dart';

class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({super.key, required this.data});

  final List<DailyTotal> data;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.data.fold<int>(
      0,
      (max, item) => max > item.amount ? max : item.amount,
    );

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _BarsPainter(
                data: widget.data,
                maxAmount: maxAmount,
                progress: _controller.value,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        Row(
          children: widget.data
              .map(
                (item) => Expanded(
                  child: Center(
                    child: Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][
                        item.date.weekday - 1
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Peak: ${formatVnd(maxAmount)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.data,
    required this.maxAmount,
    required this.progress,
    required this.color,
  });

  final List<DailyTotal> data;
  final int maxAmount;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxAmount == 0) {
      return;
    }

    final slotWidth = size.width / data.length;

    for (var index = 0; index < data.length; index++) {
      final barHeight =
          (size.height - 20) * data[index].amount / maxAmount * progress;
      final barWidth = slotWidth * 0.55;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            index * slotWidth + (slotWidth - barWidth) / 2,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(10),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldPainter) {
    return oldPainter.progress != progress ||
        oldPainter.data != data ||
        oldPainter.maxAmount != maxAmount ||
        oldPainter.color != color;
  }
}