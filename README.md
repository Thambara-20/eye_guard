# Eye Guard - Protect Your Eyes With Good Lighting

Eye Guard is a Flutter application that monitors ambient light and device distance to help protect your eyes while reading, studying, or using digital devices.

## Features

- **Light Level Monitoring**: Monitors ambient light to ensure you're using your device in proper lighting conditions
- **Device Distance Detection**: Ensures you maintain a safe distance from your device
- **Child-Friendly Interface**: Uses emojis and simple language to make eye health accessible to all ages
- **Notifications**: Sends alerts when lighting is poor or when you're too close to the screen
- **Statistics**: Tracks your light exposure over time with easy-to-understand charts
- **Customizable Thresholds**: Adjust settings to your personal preference or environment

## Smart Sensor Adaptability

Eye Guard now intelligently adapts to different device capabilities:

- **Full Sensor Mode**: Uses your device's ambient light and proximity sensors for accurate readings
- **Partial Sensor Mode**: If only some sensors are available, combines real readings with simulated data
- **Simulation Mode**: On devices without sensors, uses realistic simulated data to provide the eye health experience

The app will automatically notify you which mode it's operating in and continue to provide useful eye health guidance regardless of your device's capabilities.

## Requirements

Eye Guard is compatible with a wide range of Android devices. The app works best on devices with:

- Ambient light sensor (for light measurements)
- Proximity sensor (for distance measurements)

However, the app will work on all devices, adapting its functionality as needed.

## Permissions

The app requires the following permissions:

- **Body Sensors**: To access the ambient light and proximity sensors
- **Notifications**: To send alerts about poor lighting conditions
- **Foreground Service**: To continue monitoring in the background

## Getting Started

1. Launch the app
2. Allow the requested permissions
3. Keep the app open while reading or studying
4. Check the statistics page to see your eye health habits over time
5. Adjust the threshold in settings to match your preferences

## Troubleshooting

If you encounter sensor errors:

1. Make sure you've granted all necessary permissions
2. Check if your device has the required sensors
3. The app will automatically switch to simulation mode if necessary

## Privacy

All data is stored locally on your device and is never shared with external servers.
