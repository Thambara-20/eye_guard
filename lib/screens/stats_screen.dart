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
                    Row(
                      children: [
                        const Icon(Icons.bar_chart,
                            color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Your Eye Health Report',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      'See how well your eyes have been protected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    const Text(
                      'Light Level History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSimpleChart(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Good lighting helps you read better, feel better, and protects your eyes!',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    String emoji = '';
    if (title == 'Average')
      emoji = '📊';
    else if (title == 'Good Light')
      emoji = '👍';
    else if (title == 'Poor Light')
      emoji = '👎';
    else if (title == 'Range') emoji = '📏';

    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.15)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
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
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
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
          ],
        ),
      ),
    );
  }

  // Simplified chart replacement with more visuals
  Widget _buildSimpleChart() {
    if (_recentReadings.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 40, color: Colors.grey),
              SizedBox(height: 16),
              Text('No light data collected yet'),
              Text('Keep monitoring to see your stats!',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    } // Calculate min and max for the chart
    double minLux = double.infinity;
    double maxLux = 0;

    for (var reading in _recentReadings) {
      if (reading.luxValue < minLux) minLux = reading.luxValue;
      if (reading.luxValue > maxLux) maxLux = reading.luxValue;
    }

    minLux = minLux == double.infinity ? 0 : minLux;

    // Determine an overall "score" based on % time in good light
    double goodLightPercentage = _stats['timeAboveThreshold'];
    String scoreText;
    String scoreEmoji;
    Color scoreColor;

    if (goodLightPercentage >= 80) {
      scoreText = 'Excellent!';
      scoreEmoji = '🤩';
      scoreColor = Colors.green;
    } else if (goodLightPercentage >= 60) {
      scoreText = 'Good!';
      scoreEmoji = '😊';
      scoreColor = Colors.lightGreen;
    } else if (goodLightPercentage >= 40) {
      scoreText = 'OK';
      scoreEmoji = '😐';
      scoreColor = Colors.amber;
    } else {
      scoreText = 'Needs Improvement';
      scoreEmoji = '😟';
      scoreColor = Colors.red;
    }

    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Light Score',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_recentReadings.length >= 2) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        scoreEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_recentReadings.length} readings collected',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.lightGreen,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
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
                          const Flexible(
                            flex: 1,
                            child: Text('Too Bright',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text('Not enough data to display your score yet'),
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
