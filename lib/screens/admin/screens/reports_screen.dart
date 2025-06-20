import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedReportType;
  String? _selectedBatch;
  String? _selectedTimeRange;

  final List<String> _reportTypes = [
    'Attendance Report',
    'Fee Collection Report',
    'Student Performance',
    'Teacher Performance',
  ];

  final List<String> _batches = [
    'All Batches',
    'Morning Batch',
    'Afternoon Batch',
    'Evening Batch',
  ];

  final List<String> _timeRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      prefixIcon: Icon(Icons.bar_chart),
                    ),
                    items: _reportTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReportType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: _batches.map((batch) {
                      return DropdownMenuItem(
                        value: batch,
                        child: Text(batch),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBatch = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeRange,
                    decoration: const InputDecoration(
                      labelText: 'Time Range',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: _timeRanges.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(range),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeRange = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedReportType != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Summary Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth > 600 
                                    ? (constraints.maxWidth - 16) / 2 
                                    : constraints.maxWidth,
                                child: _buildSummaryCard(
                                  'Total Students',
                                  '150',
                                  Icons.people,
                                  AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth > 600 
                                    ? (constraints.maxWidth - 16) / 2 
                                    : constraints.maxWidth,
                                child: _buildSummaryCard(
                                  'Average Attendance',
                                  '85%',
                                  Icons.calendar_today,
                                  AppTheme.successColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Chart
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Trend',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: constraints.maxWidth > 600 ? 300 : 200,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: const FlTitlesData(show: false),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: [
                                              const FlSpot(0, 3),
                                              const FlSpot(2.6, 2),
                                              const FlSpot(4.9, 5),
                                              const FlSpot(6.8, 3.1),
                                              const FlSpot(8, 4),
                                              const FlSpot(9.5, 3),
                                              const FlSpot(11, 4),
                                            ],
                                            isCurved: true,
                                            color: AppTheme.primaryColor,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Detailed Report
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detailed Report',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildReportTable(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Present')),
          DataColumn(label: Text('Absent')),
          DataColumn(label: Text('Percentage')),
        ],
        rows: List.generate(
          7,
          (index) => DataRow(
            cells: [
              DataCell(Text('${DateTime.now().subtract(Duration(days: index)).day}/${DateTime.now().subtract(Duration(days: index)).month}')),
              DataCell(Text('${15 + index}')),
              DataCell(Text('${5 - index}')),
              DataCell(Text('${(15 + index) * 100 ~/ 20}%')),
            ],
          ),
        ),
      ),
    );
  }
} 