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
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isMobile = size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: size.height -
                            130, // Account for SafeArea and padding
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 16),
                          _buildPeriodSelector(),
                          const SizedBox(height: 20),
                          _buildStatsSummary(),
                          const SizedBox(height: 16),
                          _buildStatsCards(isLandscape, isMobile),
                          const SizedBox(height: 24),
                          _buildLightScoreCard(context, isMobile),
                          const SizedBox(height: 24),
                          _buildTipsCard(context),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.visibility, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eye Health Report',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _formatDateTime(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor your eye health and lighting conditions',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'This Week', 'This Month'].map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.7),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
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

  Widget _buildStatsSummary() {
    final goodPercentage = _stats['timeAboveThreshold'].toStringAsFixed(0);
    final averageLux = _stats['averageLux'].toStringAsFixed(0);

    String message;
    IconData icon;
    Color color;

    if (_stats['timeAboveThreshold'] >= 70) {
      message = 'Great! Your eyes are well-protected';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (_stats['timeAboveThreshold'] >= 50) {
      message = 'Good, but room for improvement';
      icon = Icons.info;
      color = Colors.amber;
    } else {
      message = 'Your eyes need better lighting!';
      icon = Icons.warning;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$goodPercentage% of time in good light • Average: $averageLux lux',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isLandscape, bool isMobile) {
    final cards = [
      _statsCard(
        'Light Quality',
        '${_stats['timeAboveThreshold'].toStringAsFixed(0)}%',
        Icons.wb_sunny_outlined,
        Colors.amber,
        'Good light conditions',
      ),
      _statsCard(
        'Average',
        '${_stats['averageLux'].toStringAsFixed(0)} lux',
        Icons.lightbulb_outline,
        Colors.blue,
        'Average light level',
      ),
      _statsCard(
        'Light Range',
        '${_stats['minLux'].toStringAsFixed(0)}-${_stats['maxLux'].toStringAsFixed(0)}',
        Icons.compare_arrows,
        Colors.purple,
        'Minimum to maximum',
      ),
      _statsCard(
        'Poor Light',
        '${_stats['timeBelowThreshold'].toStringAsFixed(0)}%',
        Icons.warning_amber_outlined,
        Colors.red,
        'Time in poor lighting',
      ),
    ];

    // For landscape on tablets or desktops, show in a grid
    if (isLandscape && !isMobile) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: cards,
      );
    }

    // For mobile or portrait mode, use a horizontal list
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(width: 155, child: cards[index]),
        ),
      ),
    );
  }

  Widget _statsCard(String title, String value, IconData icon, Color color,
      String description) {
    String emoji;
    switch (title) {
      case 'Light Quality':
        emoji = '📊';
        break;
      case 'Average':
        emoji = '💡';
        break;
      case 'Light Range':
        emoji = '📏';
        break;
      case 'Poor Light':
        emoji = '⚠️';
        break;
      default:
        emoji = '🔍';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.15)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightScoreCard(BuildContext context, bool isMobile) {
    if (_recentReadings.isEmpty) {
      return _noDataCard();
    }

    // Calculate min and max for the chart
    double minLux = double.infinity;
    double maxLux = 0;

    for (var reading in _recentReadings) {
      if (reading.luxValue < minLux) minLux = reading.luxValue;
      if (reading.luxValue > maxLux) maxLux = reading.luxValue;
    }

    minLux = minLux == double.infinity ? 0 : minLux;

    // Determine an overall light score
    double goodLightPercentage = _stats['timeAboveThreshold'];
    String scoreText;
    String scoreEmoji;
    Color scoreColor;
    String advice;

    if (goodLightPercentage >= 80) {
      scoreText = 'Excellent!';
      scoreEmoji = '🤩';
      scoreColor = Colors.green;
      advice = 'Your eyes are getting great lighting!';
    } else if (goodLightPercentage >= 60) {
      scoreText = 'Good';
      scoreEmoji = '😊';
      scoreColor = Colors.lightGreen;
      advice = 'Your lighting is good most of the time';
    } else if (goodLightPercentage >= 40) {
      scoreText = 'Fair';
      scoreEmoji = '😐';
      scoreColor = Colors.amber;
      advice = 'Try to improve your lighting conditions';
    } else {
      scoreText = 'Poor';
      scoreEmoji = '😟';
      scoreColor = Colors.red;
      advice = 'Your eyes need much better lighting!';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Eye Health Score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scoreEmoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      advice,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLightIndicator(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            '${_recentReadings.length} readings collected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_recentReadings.length >= 2) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip('Min: ${minLux.toStringAsFixed(0)} lux',
                      Icons.arrow_downward),
                  _infoChip('Max: ${maxLux.toStringAsFixed(0)} lux',
                      Icons.arrow_upward),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip(
                      'First: ${_formatTime(_recentReadings.first.timestamp)}',
                      Icons.play_arrow),
                  _infoChip(
                      'Last: ${_formatTime(_recentReadings.last.timestamp)}',
                      Icons.stop),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLightIndicator() {
    return Column(
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.red,
                Colors.orange,
                Colors.lightGreen,
                Colors.green,
                Colors.yellow,
                Colors.red,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Too Dark',
                style: TextStyle(fontSize: 10, color: Colors.red),
                overflow: TextOverflow.ellipsis),
            Text('Perfect',
                style: TextStyle(fontSize: 10, color: Colors.green),
                overflow: TextOverflow.ellipsis),
            Text('Too Bright',
                style: TextStyle(fontSize: 10, color: Colors.red),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ],
    );
  }

  Widget _infoChip(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Tips for Healthy Eyes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Maintain proper lighting - not too dim or bright',
                Icons.lightbulb_outline),
            _buildTipItem(
                'Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds',
                Icons.timer),
            _buildTipItem(
                'Keep screens at arm\'s length away', Icons.phonelink),
            _buildTipItem(
                'Blink regularly when using digital devices', Icons.visibility),
            _buildTipItem('Adjust screen brightness to match surroundings',
                Icons.brightness_6),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noDataCard() {
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No light data collected yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep using the app to see your eye health statistics',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;

    return '$month $day, $year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
