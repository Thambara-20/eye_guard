import 'dart:async';
import 'package:flutter/material.dart';
import '../services/light_monitor_service.dart';
import '../services/storage_service.dart';
import '../widgets/eye_care_tips_widget.dart';
import '../widgets/eye_health_summary_widget.dart';

class HomeScreen extends StatefulWidget {
  final LightMonitorService monitorService;
  final StorageService storageService;

  const HomeScreen({
    super.key,
    required this.monitorService,
    required this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentLuxValue = 0;
  double _threshold = StorageService.defaultThreshold;
  String _lightStatus = 'Checking...';
  Color _statusColor = Colors.blue;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
    _startMonitoring();

    // Refresh light value every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLightValue();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadThreshold() async {
    final threshold = await widget.storageService.getLuxThreshold();
    setState(() {
      _threshold = threshold;
    });
  }

  Future<void> _startMonitoring() async {
    if (!widget.monitorService.isMonitoring) {
      final success = await widget.monitorService.startMonitoring();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Light sensor not available or permission denied'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
    _updateLightValue();
  }

  Future<void> _updateLightValue() async {
    final service = widget.monitorService;

    if (!service.isMonitoring) return;

    try {
      // Access the sensor service through a public method
      final lightValue = await service.getCurrentLightValue();

      if (mounted) {
        setState(() {
          _currentLuxValue = lightValue;
          _updateStatus(lightValue);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lightStatus = 'Sensor Error';
          _statusColor = Colors.red;
        });
      }
    }
  }

  void _updateStatus(double luxValue) {
    if (luxValue < _threshold * 0.5) {
      _lightStatus = 'Too Dark';
      _statusColor = Colors.red;
    } else if (luxValue < _threshold) {
      _lightStatus = 'Suboptimal';
      _statusColor = Colors.orange;
    } else if (luxValue < _threshold * 2) {
      _lightStatus = 'Good';
      _statusColor = Colors.green;
    } else {
      _lightStatus = 'Too Bright';
      _statusColor = Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Eye Guard',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 24), _buildLightMeter(),
                const SizedBox(height: 24),
                _buildEyeHealthSummary(),
                const SizedBox(height: 24),
                _buildEyeCareTipsWidget(),
                const SizedBox(height: 24),
                _buildControlButton(),
                const SizedBox(height: 20),
                _buildEyeHealthSummary(), // Add the eye health summary widget here
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLightMeter() {
    // Determine light quality text and color based on lux value
    String qualityText;
    Color qualityColor;
    String description;
    IconData iconData;

    if (_currentLuxValue < _threshold * 0.5) {
      qualityText = 'Too Dark';
      qualityColor = Colors.red;
      description =
          'This lighting can cause eye strain. Consider turning on more lights.';
      iconData = Icons.brightness_low;
    } else if (_currentLuxValue < _threshold) {
      qualityText = 'Suboptimal';
      qualityColor = Colors.orange;
      description =
          'Current lighting is below recommended levels for reading/working.';
      iconData = Icons.brightness_medium;
    } else if (_currentLuxValue < _threshold * 2) {
      qualityText = 'Good';
      qualityColor = Colors.green;
      description = 'Perfect lighting for current activity!';
      iconData = Icons.brightness_high;
    } else {
      qualityText = 'Too Bright';
      qualityColor = Colors.purple;
      description =
          'Lighting may be causing glare. Consider dimming lights or moving away from bright light sources.';
      iconData = Icons.brightness_7;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Light',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currentLuxValue.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'lux',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: qualityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        iconData,
                        color: qualityColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        qualityText,
                        style: TextStyle(
                          color: qualityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _calculateProgressValue(_currentLuxValue),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calculate progress value for light meter
  double _calculateProgressValue(double luxValue) {
    // Range from 0 to 1000+ lux
    if (luxValue <= 0) return 0.0;
    if (luxValue >= 1000) return 1.0;
    return luxValue / 1000;
  }

  Widget _buildStatusIndicator() {
    return Column(
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _lightStatus,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommended:'),
                Text(
                  '${_threshold.toInt()} lux',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'For reading and writing, 250-500 lux is recommended. '
              'For detailed tasks, aim for 500-1000 lux.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    return ElevatedButton.icon(
      onPressed: () {
        if (widget.monitorService.isMonitoring) {
          widget.monitorService.stopMonitoring();
        } else {
          _startMonitoring();
        }
        setState(() {});
      },
      icon: Icon(
        widget.monitorService.isMonitoring ? Icons.pause : Icons.play_arrow,
      ),
      label: Text(
        widget.monitorService.isMonitoring
            ? 'Stop Monitoring'
            : 'Start Monitoring',
      ),
    );
  }

  Widget _buildEyeCareTipsWidget() {
    return const EyeCareTipsWidget();
  }

  Widget _buildEyeHealthSummary() {
    // For a real application, you would calculate these values based on actual user data
    // Here we're using placeholders for demonstration
    int screenTimeMinutes = 120; // Sample value
    int poorLightingPercent = 25; // Sample value

    String status;
    IconData icon;
    Color color;

    if (poorLightingPercent > 50) {
      status = "Poor Light Environment";
      icon = Icons.warning;
      color = Colors.red;
    } else if (screenTimeMinutes > 240) {
      status = "Excessive Screen Time";
      icon = Icons.error_outline;
      color = Colors.orange;
    } else {
      status = "Good Eye Health";
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    return EyeHealthSummaryWidget(
      dailyExposureMinutes: screenTimeMinutes,
      poorLightingPercentage: poorLightingPercent,
      overallStatus: status,
      statusIcon: icon,
      statusColor: color,
    );
  }
}
