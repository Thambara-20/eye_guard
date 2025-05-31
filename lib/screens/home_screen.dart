import 'dart:async';
import 'package:flutter/material.dart';
import '../services/light_monitor_service.dart';
import '../services/storage_service.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Current Light Level',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),
              _buildLightMeter(),
              const SizedBox(height: 40),
              _buildStatusIndicator(),
              const SizedBox(height: 40),
              _buildInfoCard(),
              const Spacer(),
              _buildControlButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightMeter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          width: 200,
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
          height: 180,
          width: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor.withOpacity(0.2),
          ),
        ),
        Container(
          height: 150,
          width: 150,
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
                  _currentLuxValue.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'lux',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
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
}
