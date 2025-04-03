import 'package:adhd_tracker/providers.dart/mood_chart_provider.dart';
import 'package:adhd_tracker/providers.dart/symptom_chart_provider.dart';
import 'package:adhd_tracker/ui/representation/mood/mood_chart.dart';
import 'package:adhd_tracker/ui/representation/symptom/symptom_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MoodStatsProvider()..fetchMoodData(),
        ),
        ChangeNotifierProvider(
          create: (_) => SeverityStatsProvider()..fetchSeverityData(),
        ),
      ],
      child: const AnalyticsView(),
    );
  }
}

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String selectedChart = 'mood';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: _buildChartSelector(),
        ),
      ),
      body: Column(
        children: [
          _buildTimeRangeSelector(),
          Expanded(
            child: selectedChart == 'mood' 
              ? _buildMoodAnalytics() 
              : _buildSymptomAnalytics(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SegmentedButton<String>(
        selected: {selectedChart},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            selectedChart = newSelection.first;
          });
        },
        segments: const [
          ButtonSegment<String>(
            value: 'mood',
            label: Text('Mood'),
            icon: Icon(Icons.mood),
          ),
          ButtonSegment<String>(
            value: 'symptoms',
            label: Text('Symptoms'),
            icon: Icon(Icons.healing),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Consumer2<MoodStatsProvider, SeverityStatsProvider>(
      builder: (context, moodProvider, severityProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Weekly'),
                      selected: moodProvider.selectedRange == 'week',
                      onSelected: (selected) {
                        if (selected) {
                          moodProvider.setRange('week');
                          severityProvider.setRange('week');
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Monthly'),
                      selected: moodProvider.selectedRange == 'month',
                      onSelected: (selected) {
                        if (selected) {
                          moodProvider.setRange('month');
                          severityProvider.setRange('month');
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: moodProvider.selectedRange == 'custom',
                      onSelected: (selected) {
                        if (selected) {
                          moodProvider.setRange('custom');
                          severityProvider.setRange('custom');
                        }
                      },
                    ),
                  ],
                ),
                if (moodProvider.selectedRange == 'custom')
                  _buildMonthPicker(moodProvider, severityProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker(
    MoodStatsProvider moodProvider,
    SeverityStatsProvider severityProvider,
  ) {
    final DateTime now = DateTime.now();
    final List<DateTime> months = List.generate(
      12,
      (index) => DateTime(now.year, now.month - index),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Month',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: moodProvider.selectedMonth,
            items: months.map((DateTime date) {
              final value = DateFormat('yyyy-MM').format(date);
              return DropdownMenuItem(
                value: value,
                child: Text(DateFormat('MMMM yyyy').format(date)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                moodProvider.setMonth(value);
                severityProvider.setMonth(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAnalytics() {
    return Consumer<MoodStatsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorView(context, provider.error!);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchMoodData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Mood Trends',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectedRange == 'month'
                                  ? DateFormat('MMMM yyyy')
                                      .format(DateTime.now())
                                  : 'Daily Mood Pattern',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MoodChart(moodData: provider.moodsByDay),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Mood Distribution',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frequency of Moods',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MoodDistributionChart(
                              moodTotals: provider.moodTotals,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomAnalytics() {
    return Consumer<SeverityStatsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorView(context, provider.error!);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSeverityData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Symptom Severity Trends',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectedRange == 'month'
                                  ? DateFormat('MMMM yyyy')
                                      .format(DateTime.now())
                                  : 'Daily Severity Pattern',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SeverityChart(severityData: provider.severityByDay),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Severity Distribution',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frequency of Severity Levels',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SeverityDistributionChart(
                              severityTotals: provider.severityTotals,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (selectedChart == 'mood') {
                context.read<MoodStatsProvider>().fetchMoodData();
              } else {
                context.read<SeverityStatsProvider>().fetchSeverityData();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}