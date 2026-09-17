import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/devices_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/error_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/list_state_views.dart';
import '../../widgets/status_badge.dart';
import 'device_control_screen.dart';

/// Devices list. Used both as the "Devices" bottom-nav tab (no [zoneId],
/// shows every device the owner has) and pushed from a zone card
/// (scoped to that zone, with its own AppBar/back navigation).
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, this.zoneId, this.zoneName});

  final String? zoneId;
  final String? zoneName;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _repository = DevicesRepository();
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Device>> _load() async {
    try {
      return await _repository.fetchDevices(zoneId: widget.zoneId);
    } on ApiException catch (e) {
      if (e.isAuthError && mounted) {
        await context.read<AuthProvider>().forceLogoutOnSessionExpired();
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future.catchError((_) => <Device>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.marca,
      child: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListLoadingView(label: l10n.loading);
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? l10n.messageFor((snapshot.error as ApiException).kind)
                : l10n.t('devicesErrorFetch');
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListErrorView(message: message, retryLabel: l10n.retry, onRetry: _refresh),
              ),
            );
          }
          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListEmptyView(
                  icon: Icons.sensors_outlined,
                  heading: l10n.t('devicesEmptyHeading'),
                  body: l10n.t('devicesEmptyBody'),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: devices.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _DeviceCard(device: devices[index]),
          );
        },
      ),
    );

    if (widget.zoneId == null) return content;

    return Scaffold(
      appBar: AppBar(title: Text(widget.zoneName ?? l10n.devicesTitle)),
      body: content,
    );
  }
}

extension on AppLocalizations {
  String get devicesTitle => t('devicesTitle');
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = DateFormat.yMMMd(l10n.locale.toLanguageTag()).add_Hm();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeviceControlScreen(deviceId: device.id, deviceName: device.name),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto),
                  ),
                ),
                if (device.isOnline != null) OnlineStatusBadge(isOnline: device.isOnline!),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              device.lastReading != null
                  ? '${l10n.t('lastReading')}: ${device.lastReading!.sensorType} · ${device.lastReading!.displayValue} · ${formatter.format(device.lastReading!.recordedAt)}'
                  : l10n.t('noReadingYet'),
              style: AppTheme.dataText(),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
