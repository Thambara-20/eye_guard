import 'dart:async';
import 'package:flutter/material.dart';
import '../services/light_monitor_service.dart';
import '../models/light_reading.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  final LightMonitorService monitorService;
  final StorageService storageService;

  const StatsScreen({
    super.key,
    required this.monitorService,
    required this.storageService,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _stats = {
    'averageLux': 0.0,
    'timeBelowThreshold': 0.0,
    'timeAboveThreshold': 0.0,
    'minLux': 0.0,
    'maxLux': 0.0,
  };
  List<LightReading> _recentReadings = [];
  Timer? _refreshTimer;
  String _selectedPeriod = 'Today';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Refresh data periodically
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load stats
    final stats = await widget.monitorService.getLightStats();

    // Load readings for chart
    final DateTime now = DateTime.now();
    DateTime startTime;

    switch (_selectedPeriod) {
      case 'Today':
        startTime = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startTime = now.subtract(const Duration(days: 7));
        break;
      case 'This Month':
        startTime = DateTime(now.year, now.month, 1);
        break;
      default:
        startTime = DateTime(now.year, now.month, now.day);
    }

    final readings =
        await widget.storageService.getReadingsInRange(startTime, now);

    if (mounted) {
      setState(() {
        _stats = stats;
        _recentReadings = readings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Light Exposure Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    Text(
                      'Light Level History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildSimpleChart(),
                    const SizedBox(height: 16),
                    const Text(
                        'Optimal light levels help reduce eye strain and improve focus.'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Today', 'This Week', 'This Month'].map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _statsCard(
            'Average',
            '${_stats['averageLux'].toStringAsFixed(1)} lux',
            Icons.wb_sunny,
            Colors.amber,
          ),
          _statsCard(
            'Good Light',
            '${_stats['timeAboveThreshold'].toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.green,
          ),
          _statsCard(
            'Poor Light',
            '${_stats['timeBelowThreshold'].toStringAsFixed(1)}%',
            Icons.warning,
            Colors.red,
          ),
          _statsCard(
            'Range',
            '${_stats['minLux'].toStringAsFixed(0)} - ${_stats['maxLux'].toStringAsFixed(0)} lux',
            Icons.compare_arrows,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _statsCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced chart implementation
  Widget _buildSimpleChart() {
    if (_recentReadings.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No data available for this period'),
        ),
      );
    }

    // Calculate min and max for the chart
    double minLux = double.infinity;
    double maxLux = 0;
    int goodLightCount = 0;
    int badLightCount = 0;
    final threshold = _stats['averageLux'] *
        0.7; // Use 70% of average as threshold for simplicity

    for (var reading in _recentReadings) {
      if (reading.luxValue < minLux) minLux = reading.luxValue;
      if (reading.luxValue > maxLux) maxLux = reading.luxValue;
      if (reading.luxValue >= threshold) {
        goodLightCount++;
      } else {
        badLightCount++;
      }
    }

    minLux = minLux == double.infinity ? 0 : minLux;

    // Calculate good light percentage for the pie chart
    final goodLightPercentage = _recentReadings.isEmpty
        ? 0
        : (goodLightCount / _recentReadings.length * 100).toInt();

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Light Exposure Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_recentReadings.length} readings',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (_recentReadings.length >= 2) ...[
                Expanded(
                  child: Column(
                    children: [
                      // Time period indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _recentReadings.first.timestamp
                                .toString()
                                .substring(0, 16),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            _recentReadings.last.timestamp
                                .toString()
                                .substring(0, 16),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Visualization section
                      Expanded(
                        child: Row(
                          children: [
                            // Left side - Pie chart
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: CircularProgressIndicator(
                                          value: goodLightPercentage / 100,
                                          strokeWidth: 10,
                                          backgroundColor:
                                              Colors.red.withOpacity(0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Colors.green),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$goodLightPercentage%',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Good Light',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem('Good', Colors.green),
                                      const SizedBox(width: 16),
                                      _buildLegendItem('Poor', Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right side - Stats and recommendations
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatRow('Latest',
                                      '${_recentReadings.last.luxValue.toStringAsFixed(0)} lux'),
                                  const SizedBox(height: 8),
                                  _buildStatRow('Average',
                                      '${_stats['averageLux'].toStringAsFixed(0)} lux'),
                                  const SizedBox(height: 8),
                                  _buildStatRow('Range',
                                      '${minLux.toStringAsFixed(0)}-${maxLux.toStringAsFixed(0)} lux'),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: goodLightPercentage >= 70
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      goodLightPercentage >= 70
                                          ? 'Great job maintaining good lighting!'
                                          : 'Try to improve your lighting conditions',
                                      style: TextStyle(
                                        color: goodLightPercentage >= 70
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text('Not enough data to display chart'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
