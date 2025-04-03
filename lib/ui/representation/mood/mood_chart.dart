import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class MoodChart extends StatelessWidget {
  final Map<String, List<double>> moodData;
  
  const MoodChart({Key? key, required this.moodData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> dates = moodData.keys.toList()..sort();
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < dates.length; i++) {
      if (moodData[dates[i]]!.isNotEmpty) {
        double avgMood = moodData[dates[i]]!.reduce((a, b) => a + b) / 
                        moodData[dates[i]]!.length;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: avgMood,
                color: getMoodColor(avgMood.round()),
                width: 16,
              ),
            ],
          ),
        );
      }
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 3,
          minY: 1,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final moodEmojis = {1: "😊", 2: "😐", 3: "😢"};
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(moodEmojis[value.toInt()] ?? ''),
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
    );
  }

  Color getMoodColor(int moodValue) {
    switch (moodValue) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFFFFA726);
      case 3:
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference >= 7) {
      // Monthly view
      if (date.day == 1) {
        return DateFormat('MMM d').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    } else {
      // Weekly view
      return DateFormat('MMM d').format(date);
    }
  }
}

class MoodDistributionChart extends StatelessWidget {
  final Map<int, int> moodTotals;
  
  const MoodDistributionChart({Key? key, required this.moodTotals}) : super(key: key);

  Color getMoodColor(int moodValue) {
    switch (moodValue) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFFFFA726);
      case 3:
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (moodTotals.values.isEmpty ? 0 : 
                 moodTotals.values.reduce((a, b) => a > b ? a : b)).toDouble(),
          barGroups: [1, 2, 3].map((mood) {
            return BarChartGroupData(
              x: mood,
              barRods: [
                BarChartRodData(
                  toY: (moodTotals[mood] ?? 0).toDouble(),
                  color: getMoodColor(mood),
                  width: 16,
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final moodEmojis = {1: "😊", 2: "😐", 3: "😢"};
                  return Text(moodEmojis[value.toInt()] ?? '');
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