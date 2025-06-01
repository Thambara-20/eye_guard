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
            '${_stats['minLux'].toStringAsFixed(0)}-${_stats['maxLux'].toStringAsFixed(0)}',
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
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified chart replacement
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

    for (var reading in _recentReadings) {
      if (reading.luxValue < minLux) minLux = reading.luxValue;
      if (reading.luxValue > maxLux) maxLux = reading.luxValue;
    }

    minLux = minLux == double.infinity ? 0 : minLux;

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Light Readings Over Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_recentReadings.length >= 2) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'Latest: ${_recentReadings.last.luxValue.toStringAsFixed(1)} lux'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.yellow,
                                    Colors.green
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Text('Too Dark',
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Flexible(
                            flex: 1,
                            child: Text('Perfect',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.green),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Flexible(
                            flex: 1,
                            child: Text('Too Bright',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Min: ${minLux.toStringAsFixed(1)} | Max: ${maxLux.toStringAsFixed(1)}',
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      Text('${_recentReadings.length} readings recorded',
                          overflow: TextOverflow.ellipsis),
                      Flexible(
                        child: Text(
                            'First: ${_recentReadings.first.timestamp.toString().substring(0, 16)}',
                            overflow: TextOverflow.ellipsis),
                      ),
                      Flexible(
                        child: Text(
                            'Last: ${_recentReadings.last.timestamp.toString().substring(0, 16)}',
                            overflow: TextOverflow.ellipsis),
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
}
