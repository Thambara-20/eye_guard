import 'package:flutter/material.dart';

class EyeHealthSummaryWidget extends StatelessWidget {
  final int dailyExposureMinutes;
  final int poorLightingPercentage;
  final String overallStatus;
  final IconData statusIcon;
  final Color statusColor;

  const EyeHealthSummaryWidget({
    super.key,
    required this.dailyExposureMinutes,
    required this.poorLightingPercentage,
    required this.overallStatus,
    required this.statusIcon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icons.health_and_safety,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Eye Health Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  context,
                  'Screen Time',
                  '$dailyExposureMinutes min',
                  Icons.timer_outlined,
                  dailyExposureMinutes > 180 ? Colors.orange : Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Poor Light',
                  '$poorLightingPercentage%',
                  Icons.lightbulb_outline,
                  poorLightingPercentage > 30 ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSuggestion(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getSuggestion() {
    if (poorLightingPercentage > 50) {
      return "Consider improving your lighting environment to reduce eye strain.";
    } else if (dailyExposureMinutes > 240) {
      return "Take more frequent breaks from screen time using the 20-20-20 rule.";
    } else if (dailyExposureMinutes > 180) {
      return "Your screen time is moderate. Remember to blink regularly and look away occasionally.";
    } else {
      return "You're maintaining a healthy balance. Keep it up!";
    }
  }
}
