import 'package:flutter/material.dart';

class EyeCareTipsWidget extends StatefulWidget {
  const EyeCareTipsWidget({super.key});

  @override
  State<EyeCareTipsWidget> createState() => _EyeCareTipsWidgetState();
}

class _EyeCareTipsWidgetState extends State<EyeCareTipsWidget> {
  final List<Map<String, dynamic>> _eyeCareTips = [
    {
      'title': '20-20-20 Rule',
      'description':
          'Every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain.',
      'icon': Icons.timer,
    },
    {
      'title': 'Adjust Screen Brightness',
      'description':
          'Ensure your screen brightness matches your ambient lighting to reduce strain.',
      'icon': Icons.brightness_6,
    },
    {
      'title': 'Blink Regularly',
      'description':
          'Remember to blink frequently when using digital devices to keep your eyes moist.',
      'icon': Icons.remove_red_eye,
    },
    {
      'title': 'Screen Distance',
      'description':
          'Keep your screen about arm\'s length (20-24 inches) away from your eyes.',
      'icon': Icons.straighten,
    },
    {
      'title': 'Regular Eye Exams',
      'description':
          'Schedule regular eye check-ups to catch and address vision problems early.',
      'icon': Icons.medical_services,
    },
  ];

  int _currentTipIndex = 0;

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _eyeCareTips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTip = _eyeCareTips[_currentTipIndex];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Eye Care Tip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.refresh),
                  color: Colors.grey[600],
                  onPressed: _nextTip,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    currentTip['icon'],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTip['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentTip['description'],
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
          ],
        ),
      ),
    );
  }
}
