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
import '../../widgets/search_field.dart';
import '../devices/devices_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _repository = ZonesRepository();
  late Future<List<Zone>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      color: AppColors.marca,
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
                child: ListErrorView(
                  message: message,
                  retryLabel: l10n.retry,
                  onRetry: _refresh,
                ),
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
          final q = _query.trim().toLowerCase();
          final visible = q.isEmpty
              ? zones
              : zones
                    .where(
                      (z) =>
                          z.name.toLowerCase().contains(q) ||
                          (z.location ?? '').toLowerCase().contains(q),
                    )
                    .toList();
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: visible.isEmpty ? 3 : visible.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SearchField(
                  controller: _searchController,
                  label: l10n.t('searchZonesHint'),
                  onChanged: (v) => setState(() => _query = v),
                );
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ResultCount(count: visible.length),
                );
              }
              if (visible.isEmpty) {
                return SizedBox(
                  height: 280,
                  child: ListEmptyView(
                    icon: Icons.search_off,
                    heading: l10n.t('zonesEmptyHeading'),
                    body: l10n.t('searchNoResults'),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ZoneCard(zone: visible[index - 2]),
              );
            },
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DevicesScreen(zoneId: zone.id, zoneName: zone.name),
            ),
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
                  color: AppColors.marca.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.map_outlined, color: AppColors.marca),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texto,
                      ),
                    ),
                    if (zone.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        zone.location!,
                        style: const TextStyle(
                          color: AppColors.textoMute,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textoMute),
            ],
          ),
        ),
      ),
    );
  }
}
