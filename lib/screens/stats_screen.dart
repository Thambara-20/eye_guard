import 'dart:async';
import 'dart:math' as math;
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
  double _luxThreshold = 300.0; // Default value, will be updated in _loadData

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

    // Get the current threshold setting
    _luxThreshold = await widget.storageService.getLuxThreshold();

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
<<<<<<< Updated upstream
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
=======
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildPeriodSelector(),
                      const SizedBox(height: 24),
                      _buildEyeHealthScore(),
                      const SizedBox(height: 24),
                      _buildLightingDetails(),
                      const SizedBox(height: 24),
                      _buildRecommendationsCard(),
                    ],
                  ),
>>>>>>> Stashed changes
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            Text(
              'Eye Health Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
            ),
          ],
        ),
        Text(
          'Your personalized eye health insights',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
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

<<<<<<< Updated upstream
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
=======
  Widget _buildEyeHealthScore() {
    // Calculate overall eye health score based on time in good lighting
    double goodLightPercentage = _stats['timeAboveThreshold'];

    String scoreText;
    String scoreDescription;
    Color scoreColor;
    double scoreValue = goodLightPercentage / 100; // Convert to 0-1 range

    if (goodLightPercentage >= 80) {
      scoreText = 'Excellent';
      scoreDescription =
          'You\'re doing great at maintaining healthy lighting conditions!';
      scoreColor = Colors.green;
    } else if (goodLightPercentage >= 60) {
      scoreText = 'Good';
      scoreDescription =
          'You mostly have good lighting but there\'s room for improvement.';
      scoreColor = Colors.lightGreen;
    } else if (goodLightPercentage >= 40) {
      scoreText = 'Fair';
      scoreDescription =
          'Your lighting conditions need attention to protect your eyes better.';
      scoreColor = Colors.amber;
    } else {
      scoreText = 'Poor';
      scoreDescription =
          'Your lighting conditions need significant improvement for eye health.';
      scoreColor = Colors.red;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
>>>>>>> Stashed changes
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
<<<<<<< Updated upstream
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
=======
                Icon(Icons.health_and_safety, color: scoreColor),
                const SizedBox(width: 8),
                const Text(
                  'Eye Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
>>>>>>> Stashed changes
                  ),
                ),
              ],
            ),
<<<<<<< Updated upstream
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
=======
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '${goodLightPercentage.toStringAsFixed(0)}% of time in good light',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularProgressIndicator(
                          value: scoreValue,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(scoreValue * 100).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
>>>>>>> Stashed changes
            ),
            const SizedBox(height: 16),
            Text(
              scoreDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
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
=======
  Widget _buildLightingDetails() {
    final avgLux = _stats['averageLux'];
    String lightLevelText;
    String lightLevelDescription;
    IconData lightIcon;
    Color lightColor;

    if (avgLux < 50) {
      lightLevelText = 'Very Low';
      lightLevelDescription = 'This is too dark for reading or detailed work';
      lightIcon = Icons.nights_stay;
      lightColor = Colors.indigo;
    } else if (avgLux < 200) {
      lightLevelText = 'Low';
      lightLevelDescription =
          'This is dim lighting, not ideal for long periods of reading';
      lightIcon = Icons.brightness_low;
      lightColor = Colors.purple;
    } else if (avgLux < _luxThreshold) {
      lightLevelText = 'Moderate';
      lightLevelDescription = 'Better lighting but still below optimal levels';
      lightIcon = Icons.brightness_medium;
      lightColor = Colors.amber;
    } else if (avgLux < 1000) {
      lightLevelText = 'Good';
      lightLevelDescription =
          'This is comfortable lighting for reading and most tasks';
      lightIcon = Icons.brightness_high;
      lightColor = Colors.green;
    } else {
      lightLevelText = 'Very Bright';
      lightLevelDescription =
          'Bright conditions, similar to outdoor indirect sunlight';
      lightIcon = Icons.brightness_7;
      lightColor = Colors.orange;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Lighting Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
                height: 20), // Light level details in a more responsive layout
            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5 - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Average Light Level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(lightIcon, color: lightColor, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              lightLevelText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: lightColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${avgLux.toStringAsFixed(0)} lux',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text('Not enough data to display chart'),
=======
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5 - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_luxThreshold.toStringAsFixed(0)}+ lux',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'for comfortable reading',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
>>>>>>> Stashed changes
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lightLevelDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildLightingRangeIndicator(),
            if (_recentReadings.isNotEmpty) ...[
              const SizedBox(
                  height:
                      28), // Increased to ensure enough space after the range indicators
              _buildLightHistoryChart(),
            ],
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
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
=======
  Widget _buildLightingRangeIndicator() {
    double minLux = _stats['minLux'];
    double maxLux = _stats['maxLux'];
    double avgLux = _stats['averageLux'];

    // Ensure we have valid values
    if (maxLux <= 0) maxLux = 1000;
    if (minLux < 0) minLux = 0;

    // Calculate positions on scale (0-1)
    double thresholdPosition = _luxThreshold / maxLux;
    if (thresholdPosition > 1) thresholdPosition = 1;

    double averagePosition = avgLux / maxLux;
    if (averagePosition > 1) averagePosition = 1;

    // Make sure the indicators don't overflow
    if (averagePosition < 0.05) averagePosition = 0.05;
    if (averagePosition > 0.95) averagePosition = 0.95;
    if (thresholdPosition < 0.05) thresholdPosition = 0.05;
    if (thresholdPosition > 0.95) thresholdPosition = 0.95;

    // Avoid overlap between avg and threshold indicators
    if ((averagePosition - thresholdPosition).abs() < 0.05) {
      if (averagePosition < thresholdPosition) {
        averagePosition = thresholdPosition - 0.05;
      } else {
        averagePosition = thresholdPosition + 0.05;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Light Range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
            height: 22), // Increased space to fully show the Target label
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.indigo,
                Colors.blue,
                Colors.green,
                Colors.amber,
                Colors.orange,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            // Calculate actual positions with padding
            final leftPadding = 10.0;
            final rightPadding = 10.0;
            final usableWidth =
                constraints.maxWidth - leftPadding - rightPadding;
            final thresholdPos = leftPadding + thresholdPosition * usableWidth;
            final avgPos = leftPadding + averagePosition * usableWidth;

            return Stack(
              children: [
                // Threshold indicator
                Positioned(
                  // Constrain position to prevent overflow
                  left: math.min(
                      math.max(thresholdPos, 15), constraints.maxWidth - 15),
                  top: 3, // Adjusted to be more visible with increased spacing
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Target',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ), // Average indicator (inline with the gradient bar)
                Positioned(
                  // Ensure indicator doesn't overflow by clamping its position
                  left: math.min(avgPos - 8, constraints.maxWidth - 16),
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        // Add space and label for average separately
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '= Average Light Level',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10), // Reduced spacing since we moved elements
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${minLux.toStringAsFixed(0)} lux',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                '${maxLux.toStringAsFixed(0)} lux',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
>>>>>>> Stashed changes
      ],
    );
  }

<<<<<<< Updated upstream
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
=======
  Widget _buildLightHistoryChart() {
    if (_recentReadings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group readings by hour to create a simplified chart
    final Map<int, List<double>> hourlyData = {};

    for (var reading in _recentReadings) {
      final hour = reading.timestamp.hour;
      if (hourlyData[hour] == null) {
        hourlyData[hour] = [];
      }
      hourlyData[hour]!.add(reading.luxValue);
    }

    // Calculate hourly averages
    final List<MapEntry<int, double>> hourlyAverages =
        hourlyData.entries.map((entry) {
      final hourSum = entry.value.reduce((a, b) => a + b);
      return MapEntry(entry.key, hourSum / entry.value.length);
    }).toList();

    // Sort by hour
    hourlyAverages.sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Light Levels By Hour',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: _buildSimplifiedChart(hourlyAverages),
>>>>>>> Stashed changes
        ),
      ],
    );
  }
<<<<<<< Updated upstream
=======

  Widget _buildSimplifiedChart(List<MapEntry<int, double>> hourlyData) {
    if (hourlyData.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height =
            constraints.maxHeight - 15; // Reserve space for labels
        final double chartHeight =
            height - 15; // Reserve more space for the threshold label
        final double barWidth =
            (width - 10) / 24 - 1; // Slightly smaller bars with spacing

        // Find the max value to scale the chart
        final double maxValue =
            hourlyData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        // Ensure max value is at least the threshold
        final double effectiveMaxValue =
            maxValue > _luxThreshold ? maxValue : _luxThreshold * 1.2;

        return Stack(
          children: [
            // Draw threshold line with label
            Positioned(
              left: 0,
              right: 0,
              top: chartHeight -
                  (chartHeight * _luxThreshold / effectiveMaxValue),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.green.withOpacity(0.7),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: Colors.green.withOpacity(0.2),
                    child: Text(
                      'Target',
                      style: TextStyle(fontSize: 9, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),

            // Draw bars
            Positioned(
              left: 5,
              right: 5,
              bottom: 15, // Space for hour labels
              height: chartHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (hour) {
                  // Find data for this hour
                  final data =
                      hourlyData.where((entry) => entry.key == hour).toList();

                  if (data.isEmpty) {
                    return Container(
                      width: barWidth,
                      height: 1,
                      color: Colors.grey.withOpacity(0.1),
                    );
                  }

                  final value = data[0].value;
                  final double barHeight =
                      (value / effectiveMaxValue) * chartHeight;
                  final bool isAboveThreshold = value >= _luxThreshold;

                  return Container(
                    width: barWidth,
                    height: barHeight.isNaN || barHeight <= 0 ? 1 : barHeight,
                    decoration: BoxDecoration(
                      color: isAboveThreshold ? Colors.blue : Colors.amber,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  );
                }),
              ),
            ),

            // Hour labels (bottom) - only show key hours to prevent overflow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show fewer hour labels to prevent overflow
                  Text('12AM',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Text('6AM',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Text('12PM',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Text('6PM',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Text('11PM',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationsCard() {
    // Determine recommendations based on stats
    List<Map<String, dynamic>> recommendations = [];

    double goodLightPercentage = _stats['timeAboveThreshold'];
    double avgLux = _stats['averageLux'];

    if (goodLightPercentage < 40) {
      recommendations.add({
        'icon': Icons.lightbulb_outline,
        'title': 'Improve Light Sources',
        'description':
            'Your environment is often too dark. Consider adding a desk lamp or increasing ambient lighting.'
      });
    }

    if (avgLux > 1000) {
      recommendations.add({
        'icon': Icons.wb_sunny,
        'title': 'Reduce Glare',
        'description':
            'Your environment sometimes has very bright light. Consider using curtains or repositioning your workspace to reduce direct light.'
      });
    }

    if (goodLightPercentage < 60) {
      recommendations.add({
        'icon': Icons.access_time,
        'title': 'Regular Light Checks',
        'description':
            'Set a reminder to check your lighting every few hours, especially as natural light changes throughout the day.'
      });
    }

    // Always include this general recommendation
    recommendations.add({
      'icon': Icons.visibility,
      'title': '20-20-20 Rule',
      'description':
          'Every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain.'
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Personalized Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => _buildRecommendationItem(
                  rec['icon'] as IconData,
                  rec['title'] as String,
                  rec['description'] as String,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
      IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
>>>>>>> Stashed changes
}
