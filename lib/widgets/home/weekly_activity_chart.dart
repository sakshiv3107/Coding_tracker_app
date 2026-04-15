import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyActivityChart extends StatefulWidget {
  final List<double> values;
  final List<String> days;
  final Map<int, Map<String, int>> perPlatformData;

  const WeeklyActivityChart({
    super.key,
    required this.values,
    required this.days,
    required this.perPlatformData,
  });

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );

    _animations = List.generate(7, (index) {
      return Tween<double>(begin: 0, end: widget.values[index]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (index * 40) / 600,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double average = widget.values.isEmpty ? 0 : widget.values.reduce((a, b) => a + b) / widget.values.length;
    double maxVal = widget.values.fold(0, (max, e) => e > max ? e : max);
    if (maxVal < 20) maxVal = 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weekly Activity",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                _buildAverageLine(average, maxVal),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return BarChart(
                      BarChartData(
                        maxY: maxVal * 1.2,
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    widget.days[value.toInt()],
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) {
                          double val = _animations[i].value;
                          bool isEmpty = widget.values[i] == 0;
                          
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: isEmpty ? 20 : val,
                                color: isEmpty 
                                  ? Colors.grey.withOpacity(0.15) 
                                  : (i % 2 == 0 ? const Color(0xFFEF9F27) : const Color(0xFF7B68EE)),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                borderSide: isEmpty 
                                  ? BorderSide(color: Colors.grey.shade400, width: 1, style: BorderStyle.none) // Dashed border not directly supported in RodData, using ghost look
                                  : BorderSide.none,
                              ),
                            ],
                          );
                        }),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Theme.of(context).cardColor,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final data = widget.perPlatformData[groupIndex] ?? {};
                              return BarTooltipItem(
                                "${widget.days[groupIndex]}\nTotal: ${widget.values[groupIndex].toInt()}\n${data.entries.map((e) => "${e.key}: ${e.value}").join('\n')}",
                                GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageLine(double average, double maxVal) {
    return LayoutBuilder(builder: (context, constraints) {
      double yPos = 200 - (average / (maxVal * 1.2) * 200) - 20; // Adjusted for padding/titles
      if (yPos < 0) yPos = 0;
      
      return Positioned(
        top: yPos,
        left: 0,
        right: 0,
        child: Row(
          children: [
            Expanded(
              child: CustomPaint(
                painter: DashedLinePainter(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "avg",
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    });
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    var max = size.width;
    var dashWidth = 4;
    var dashSpace = 4;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


