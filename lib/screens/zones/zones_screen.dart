import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/zones_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/error_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/zone.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/list_state_views.dart';
import '../devices/devices_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _repository = ZonesRepository();
  late Future<List<Zone>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Zone>> _load() async {
    try {
      return await _repository.fetchZones();
    } on ApiException catch (e) {
      if (e.isAuthError && mounted) {
        await context.read<AuthProvider>().forceLogoutOnSessionExpired();
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future.catchError((_) => <Zone>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.accent,
      child: FutureBuilder<List<Zone>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListLoadingView(label: l10n.loading);
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? l10n.messageFor((snapshot.error as ApiException).kind)
                : l10n.t('zonesErrorFetch');
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListErrorView(message: message, retryLabel: l10n.retry, onRetry: _refresh),
              ),
            );
          }
          final zones = snapshot.data ?? const [];
          if (zones.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListEmptyView(
                  icon: Icons.map_outlined,
                  heading: l10n.t('zonesEmptyHeading'),
                  body: l10n.t('zonesEmptyBody'),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: zones.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _ZoneCard(zone: zones[index]),
          );
        },
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DevicesScreen(zoneId: zone.id, zoneName: zone.name)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    if (zone.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        zone.location!,
                        style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6), fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
