import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/alerts_repository.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/devices_repository.dart';
import '../../core/api/zones_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/error_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/alert.dart';
import '../../models/device.dart';
import '../../models/zone.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/list_state_views.dart';
import '../../widgets/status_badge.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _alertsRepo = AlertsRepository();
  final _zonesRepo = ZonesRepository();
  final _devicesRepo = DevicesRepository();

  String? _zoneFilter;
  String? _deviceFilter;
  String? _statusFilter;

  List<Zone> _zones = const [];
  List<Device> _devices = const [];
  late Future<List<Alert>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final zones = await _zonesRepo.fetchZones();
      final devices = await _devicesRepo.fetchDevices();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _devices = devices;
      });
    } on ApiException {
      // Filters degrade to id-only chips (below) if this fails; the main
      // alerts list has its own error/retry path and is what matters here.
    }
  }

  Future<List<Alert>> _load() async {
    try {
      return await _alertsRepo.fetchAlerts(
        zoneId: _zoneFilter,
        deviceId: _deviceFilter,
        status: _statusFilter,
      );
    } on ApiException catch (e) {
      if (e.isAuthError && mounted) {
        await context.read<AuthProvider>().forceLogoutOnSessionExpired();
      }
      rethrow;
    }
  }

  void _applyFilters() {
    setState(() => _future = _load());
  }

  bool get _hasActiveFilters => _zoneFilter != null || _deviceFilter != null || _statusFilter != null;

  String _zoneName(String id) => _zones.firstWhere((z) => z.id == id, orElse: () => Zone(id: id, name: id, ownerId: '', createdAt: DateTime.now())).name;

  String _deviceName(String id) => _devices.firstWhere((d) => d.id == id, orElse: () => Device(id: id, name: id, zoneId: '', createdAt: DateTime.now())).name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _FilterBar(
          zones: _zones,
          devices: _devices,
          zoneFilter: _zoneFilter,
          deviceFilter: _deviceFilter,
          statusFilter: _statusFilter,
          hasActiveFilters: _hasActiveFilters,
          onZoneChanged: (v) {
            setState(() => _zoneFilter = v);
            _applyFilters();
          },
          onDeviceChanged: (v) {
            setState(() => _deviceFilter = v);
            _applyFilters();
          },
          onStatusChanged: (v) {
            setState(() => _statusFilter = v);
            _applyFilters();
          },
          onClear: () {
            setState(() {
              _zoneFilter = null;
              _deviceFilter = null;
              _statusFilter = null;
            });
            _applyFilters();
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _applyFilters();
              await _future.catchError((_) => <Alert>[]);
            },
            color: AppColors.accent,
            child: FutureBuilder<List<Alert>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListLoadingView(label: l10n.loading);
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException
                      ? l10n.messageFor((snapshot.error as ApiException).kind)
                      : l10n.t('alertsErrorFetch');
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ListErrorView(message: message, retryLabel: l10n.retry, onRetry: _applyFilters),
                    ),
                  );
                }
                final alerts = snapshot.data ?? const [];
                if (alerts.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ListEmptyView(
                        icon: Icons.notifications_none,
                        heading: l10n.t('alertsEmptyHeading'),
                        body: _hasActiveFilters ? l10n.t('alertsFilteredEmpty') : l10n.t('alertsEmptyBody'),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _AlertCard(
                      alert: alert,
                      zoneName: _zoneName(alert.zoneId),
                      deviceName: _deviceName(alert.deviceId),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.zones,
    required this.devices,
    required this.zoneFilter,
    required this.deviceFilter,
    required this.statusFilter,
    required this.hasActiveFilters,
    required this.onZoneChanged,
    required this.onDeviceChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final List<Zone> zones;
  final List<Device> devices;
  final String? zoneFilter;
  final String? deviceFilter;
  final String? statusFilter;
  final bool hasActiveFilters;
  final ValueChanged<String?> onZoneChanged;
  final ValueChanged<String?> onDeviceChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterDropdown<String>(
              label: l10n.t('filterZone'),
              value: zoneFilter,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('filterAll'))),
                for (final z in zones) DropdownMenuItem(value: z.id, child: Text(z.name)),
              ],
              onChanged: onZoneChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterDropdown<String>(
              label: l10n.t('filterDevice'),
              value: deviceFilter,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('filterAll'))),
                for (final d in devices) DropdownMenuItem(value: d.id, child: Text(d.name)),
              ],
              onChanged: onDeviceChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterDropdown<String>(
              label: l10n.t('filterStatus'),
              value: statusFilter,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('filterAll'))),
                DropdownMenuItem(value: 'active', child: Text(l10n.t('statusActive'))),
                DropdownMenuItem(value: 'resolved', child: Text(l10n.t('statusResolved'))),
              ],
              onChanged: onStatusChanged,
            ),
            if (hasActiveFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: AppSpacing.minTouchTarget,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.t('clearFilters')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: SizedBox(
        height: AppSpacing.minTouchTarget,
        child: DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              hint: Text(label, style: const TextStyle(fontSize: 14)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.zoneName, required this.deviceName});

  final Alert alert;
  final String zoneName;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = DateFormat.yMMMd(l10n.locale.toLanguageTag()).add_Hm();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SeverityBadge(severity: alert.severityLevel),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  alert.status == 'active' ? l10n.t('statusActive') : l10n.t('statusResolved'),
                  style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  formatter.format(alert.createdAt),
                  style: TextStyle(color: AppColors.ink.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16, color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$zoneName · $deviceName',
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
