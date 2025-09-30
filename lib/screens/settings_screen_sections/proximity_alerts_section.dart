import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../services/localization_service.dart';
import '../../services/proximity_alert_service.dart';
import '../../dev_config.dart';

/// Settings section for proximity alerts configuration
/// Follows brutalist principles: simple, explicit UI that matches existing patterns
class ProximityAlertsSection extends StatefulWidget {
  const ProximityAlertsSection({super.key});

  @override
  State<ProximityAlertsSection> createState() => _ProximityAlertsSectionState();
}

class _ProximityAlertsSectionState extends State<ProximityAlertsSection> {
  late final TextEditingController _distanceController;
  bool _notificationsEnabled = false;
  bool _checkingPermissions = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _distanceController = TextEditingController(
      text: appState.proximityAlertDistance.toString(),
    );
    _checkNotificationPermissions();
  }
  
  Future<void> _checkNotificationPermissions() async {
    setState(() {
      _checkingPermissions = true;
    });
    
    final enabled = await ProximityAlertService().areNotificationsEnabled();
    
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _checkingPermissions = false;
      });
    }
  }
  
  Future<void> _requestNotificationPermissions() async {
    setState(() {
      _checkingPermissions = true;
    });
    
    final enabled = await ProximityAlertService().requestNotificationPermissions();
    
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _checkingPermissions = false;
      });
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _updateDistance(AppState appState) {
    final text = _distanceController.text.trim();
    final distance = int.tryParse(text);
    if (distance != null) {
      appState.setProximityAlertDistance(distance);
    } else {
      // Reset to current value if invalid
      _distanceController.text = appState.proximityAlertDistance.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proximity Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Enable/disable toggle
            SwitchListTile(
              title: const Text('Enable proximity alerts'),
              subtitle: Text(
                'Get notified when approaching surveillance devices\n'
                'Uses extra battery for continuous location monitoring\n'
                '${_notificationsEnabled ? "✓ Notifications enabled" : "⚠ Notifications disabled"}',
                style: const TextStyle(fontSize: 12),
              ),
              value: appState.proximityAlertsEnabled,
              onChanged: (enabled) {
                appState.setProximityAlertsEnabled(enabled);
                if (enabled && !_notificationsEnabled) {
                  // Automatically try to request permissions when enabling
                  _requestNotificationPermissions();
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Notification permissions section (only show when proximity alerts are enabled)
            if (appState.proximityAlertsEnabled && !_notificationsEnabled && !_checkingPermissions) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_off, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Notification permission required',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Push notifications are disabled. You\'ll only see in-app alerts and won\'t be notified when the app is in background.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _requestNotificationPermissions,
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Enable Notifications'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Loading indicator
            if (_checkingPermissions) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Checking permissions...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
            
            // Distance setting (only show when enabled)
            if (appState.proximityAlertsEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Alert distance: '),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _updateDistance(appState),
                      onEditingComplete: () => _updateDistance(appState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('meters'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Range: $kProximityAlertMinDistance-$kProximityAlertMaxDistance meters (default: $kProximityAlertDefaultDistance)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}