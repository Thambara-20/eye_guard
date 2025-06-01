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
  bool _showingSensorWarning = false;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
    _startMonitoring();

    // Refresh light value every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLightValue();
      _checkSensors();
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
      _lightStatus = 'Needs More Light';
      _statusColor = Colors.orange;
    } else if (luxValue < _threshold * 2) {
      _lightStatus = 'Perfect Light';
      _statusColor = Colors.green;
    } else {
      _lightStatus = 'Too Bright';
      _statusColor = Colors.purple;
    }
  }

  void _checkSensors() {
    final bool lightSensorAvailable =
        widget.monitorService.isLightSensorAvailable;
    final bool proximitySensorAvailable =
        widget.monitorService.isProximitySensorAvailable;

    if (!lightSensorAvailable || !proximitySensorAvailable) {
      if (!_showingSensorWarning) {
        _showingSensorWarning = true;

        // Show a sensor unavailable message
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Some sensors unavailable - using simulated data'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } else {
      _showingSensorWarning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool lightsEnabled = widget.monitorService.isLightSensorAvailable;
    final bool proximityEnabled =
        widget.monitorService.isProximitySensorAvailable;
    final bool inSimulationMode = !lightsEnabled || !proximityEnabled;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // Make the screen scrollable to handle small screens
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 12 : 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.visibility, color: Colors.blue, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Eye Guardian',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                    ),
                  ],
                ),
                Text(
                  'Protecting your eyes from bad light',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (inSimulationMode) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Simulation Mode',
                          style:
                              TextStyle(color: Colors.amber[900], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildLightMeter(),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildStatusIndicator(),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildInfoCard(),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildControlButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLightMeter() {
    // Determine emoji and color based on light level
    String emoji;
    String message;

    if (_currentLuxValue < _threshold * 0.5) {
      emoji = '😟';
      message = 'Too dark for your eyes!';
    } else if (_currentLuxValue < _threshold) {
      emoji = '😐';
      message = 'Need more light!';
    } else if (_currentLuxValue < _threshold * 2) {
      emoji = '😊';
      message = 'Perfect for your eyes!';
    } else {
      emoji = '😎';
      message = 'Bit too bright!';
    }

    // Calculate sizes based on available width
    final screenWidth = MediaQuery.of(context).size.width;
    final maxSize = screenWidth < 360 ? 170.0 : 200.0;
    final innerSize = maxSize - 20;
    final centerSize = maxSize - 50;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: maxSize,
          width: maxSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: _statusColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Container(
          height: innerSize,
          width: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor.withOpacity(0.2),
          ),
        ),
        Container(
          height: centerSize,
          width: centerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: screenWidth < 360 ? 36 : 40),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 360 ? 12 : 14,
                  ),
                ),
                Text(
                  '${_currentLuxValue.toStringAsFixed(0)} lux',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: screenWidth < 360 ? 10 : 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    // Define the tip based on current light status - using more concise text
    String tip;
    if (_lightStatus == 'Too Dark') {
      tip = 'Turn on more lights or move to a brighter area';
    } else if (_lightStatus == 'Needs More Light') {
      tip = 'A bit more light would help your eyes';
    } else if (_lightStatus == 'Perfect Light') {
      tip = 'Great lighting for your eyes!';
    } else {
      tip = 'Consider reducing brightness a little';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _statusColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                _lightStatus == 'Perfect Light'
                    ? Icons.check_circle
                    : Icons.lightbulb,
                color: _statusColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lightStatus,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final bool lightsEnabled = widget.monitorService.isLightSensorAvailable;
    final bool proximityEnabled =
        widget.monitorService.isProximitySensorAvailable;
    final bool inSimulationMode = !lightsEnabled || !proximityEnabled;

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
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Did You Know?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Good lighting helps your eyes stay healthy!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Recommended: ${_threshold.toInt()} lux',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (inSimulationMode) ...[
              const SizedBox(height: 12),
              _buildSensorStatusSection(lightsEnabled, proximityEnabled),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusSection(bool lightsEnabled, bool proximityEnabled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Sensor Status:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    lightsEnabled ? Icons.check_circle : Icons.error_outline,
                    color: lightsEnabled ? Colors.green : Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text('Light', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Icon(
                    proximityEnabled ? Icons.check_circle : Icons.error_outline,
                    color: proximityEnabled ? Colors.green : Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text('Distance', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          if (!lightsEnabled || !proximityEnabled) ...[
            const SizedBox(height: 4),
            const Text(
              'Using estimated values',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    final bool isMonitoring = widget.monitorService.isMonitoring;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMonitoring
              ? [Colors.orangeAccent, Colors.redAccent]
              : [Colors.lightBlue, Colors.blueAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isMonitoring
                ? Colors.redAccent.withOpacity(0.3)
                : Colors.blueAccent.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
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
          color: Colors.white,
        ),
        label: Text(
          widget.monitorService.isMonitoring
              ? 'Stop Watching My Eyes'
              : 'Start Watching My Eyes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
