import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SeverityChart extends StatelessWidget {
  final Map<String, List<double>> severityData;
  
  const SeverityChart({Key? key, required this.severityData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> dates = severityData.keys.toList()..sort();
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < dates.length; i++) {
      if (severityData[dates[i]]!.isNotEmpty) {
        double avgSeverity = severityData[dates[i]]!.reduce((a, b) => a + b) / 
                           severityData[dates[i]]!.length;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: avgSeverity,
                color: getSeverityColor(avgSeverity.round()),
                width: 16,
              ),
            ],
          ),
        );
      }
    }

    return SizedBox(
      height: 300,
      child: Padding(
         padding: const EdgeInsets.only(left: 4.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 4,
            minY: 1,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                       reservedSize: 34,
                  getTitlesWidget: (value, meta) {
                    final severityLabels = {
                      1: "NA",
                      2: "Mild",
                      3: "Mod",
                      4: "Sev"
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        severityLabels[value.toInt()] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < dates.length) {
                      final date = DateTime.parse(dates[index]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: -45 * 3.14159 / 180,
                          child: Text(
                            DateFormat('d').format(date),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: dates.isNotEmpty,
                  getTitlesWidget: (value, meta) {
                    if (value == dates.length / 2) {
                      final date = DateTime.parse(dates.first);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          DateFormat('MMMM yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Color getSeverityColor(int severityValue) {
    switch (severityValue) {
      case 1: // Not at all
        return const Color(0xFF4CAF50);
      case 2: // Mild
        return const Color(0xFFFFA726);
      case 3: // Moderate
        return const Color(0xFFFF7043);
      case 4: // Severe
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }
}

class SeverityDistributionChart extends StatelessWidget {
  final Map<String, int> severityTotals;
  
  const SeverityDistributionChart({Key? key, required this.severityTotals}) : super(key: key);

  Color getSeverityColor(String severity) {
    switch (severity) {
      case 'Not at all':
        return const Color(0xFF4CAF50);
      case 'Mild':
        return const Color(0xFFFFA726);
      case 'Moderate':
        return const Color(0xFFFF7043);
      case 'Severe':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityOrder = ['Not at all', 'Mild', 'Moderate', 'Severe'];
    
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (severityTotals.values.isEmpty ? 0 : 
                 severityTotals.values.reduce((a, b) => a > b ? a : b)).toDouble(),
          barGroups: List.generate(severityOrder.length, (index) {
            final severity = severityOrder[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (severityTotals[severity] ?? 0).toDouble(),
                  color: getSeverityColor(severity),
                  width: 16,
                ),
              ],
            );
          }),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < severityOrder.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: -45 * 3.14159 / 180,
                        child: Text(
                          severityOrder[index].split(' ')[0],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}