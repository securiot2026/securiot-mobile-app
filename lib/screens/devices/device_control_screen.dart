import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/device_control_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/error_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/command_status.dart';
import '../../providers/auth_provider.dart';

const _feedPollInterval = Duration(seconds: 5);
const _commandStatusPollInterval = Duration(seconds: 1);
const _commandStatusPollTimeout = Duration(seconds: 10);
const _panTiltStep = 15.0;

/// Manual control + live feed + occupancy for one device.
///
/// CTRL-01/02/03: pan/tilt, light, buzzer, sent via
/// [DeviceControlRepository]. CTRL-05: every send starts a short poll of
/// the command's delivery status so the operator sees pending -> delivered
/// feedback rather than silence after pressing a button. FEED-02/05: the
/// live feed polls on its own timer and always shows a relative "updated
/// Xs ago" freshness label, never just the raw frame. EXTR-02: the zone
/// occupancy counter polls alongside the feed.
/// Resolves a user-facing message in the active language, so the text
/// follows a language switch instead of being frozen at failure time.
typedef _LocalizedMessage = String Function(AppLocalizations l10n);

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.repository,
  });

  final String deviceId;
  final String deviceName;

  /// Injectable for tests; the real [DeviceControlRepository] is created in
  /// `initState` when none is given.
  final DeviceControlRepository? repository;

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late final DeviceControlRepository _repository;

  Timer? _feedTimer;
  Timer? _freshnessTicker;
  LatestFrame? _frame;
  Occupancy? _occupancy;
  _LocalizedMessage? _feedError;
  bool _feedLoading = true;

  bool _lightOn = false;
  bool _buzzerOn = false;
  final Map<String, CommandDeliveryStatus> _actuatorStatus = {};

  /// D-07: localization key of the last manual-command failure, shown in the
  /// dismissible banner at the top of the screen.
  _LocalizedMessage? _commandError;

  /// Latest command sequence per actuator. A newer press supersedes an older
  /// one, so a stale failure never reverts or overrides the newer toggle.
  final Map<String, int> _commandSeq = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DeviceControlRepository();
    _pollFeed();
    _feedTimer = Timer.periodic(_feedPollInterval, (_) => _pollFeed());
    // Repaints the "updated Xs ago" label between feed polls, independent
    // of network activity.
    _freshnessTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _feedTimer?.cancel();
    _freshnessTicker?.cancel();
    super.dispose();
  }

  Future<void> _pollFeed() async {
    try {
      final frame = await _repository.getLatestFrame(widget.deviceId);
      if (!mounted) return;
      setState(() {
        _frame = frame;
        _feedError = null;
        _feedLoading = false;
      });
    } on ApiException catch (e) {
      if (e.isAuthError && mounted) {
        await context.read<AuthProvider>().forceLogoutOnSessionExpired();
        return;
      }
      if (!mounted) return;
      setState(() {
        _feedError = _feedErrorFor(e);
        _feedLoading = false;
      });
    }

    try {
      final occupancy = await _repository.getOccupancy(widget.deviceId);
      if (!mounted) return;
      setState(() => _occupancy = occupancy);
    } on ApiException {
      // Occupancy is supplementary to the feed — a failed poll here does
      // not block or blank the rest of the screen, it just skips this tick.
    }
  }

  /// D-07: distinguishes a missing edgeUrl, an unreachable Edge and a device
  /// that has not captured a frame yet (404) from a generic load error.
  _LocalizedMessage _feedErrorFor(ApiException e) {
    switch (e.kind) {
      case ApiErrorKind.edgeNotConfigured:
      case ApiErrorKind.edgeUnreachable:
        return (l10n) => l10n.messageFor(e.kind);
      default:
        final key = e.statusCode == 404 ? 'controlFeedNoFrameYet' : 'controlFeedLoadError';
        return (l10n) => l10n.t(key);
    }
  }

  _LocalizedMessage _commandErrorFor(ApiException e) {
    switch (e.kind) {
      case ApiErrorKind.edgeNotConfigured:
      case ApiErrorKind.edgeUnreachable:
      case ApiErrorKind.network:
        return (l10n) => l10n.messageFor(e.kind);
      default:
        return (l10n) => l10n.t('controlErrorCommandFailed');
    }
  }

  /// Sends one manual command. On failure the error banner is shown and
  /// [revert] returns the toggle to its previous position so the UI never
  /// keeps a state the device did not receive (D-07).
  Future<void> _sendCommand(
    String actuator,
    Future<void> Function() send, {
    VoidCallback? revert,
  }) async {
    final seq = (_commandSeq[actuator] ?? 0) + 1;
    _commandSeq[actuator] = seq;
    setState(() => _actuatorStatus[actuator] = CommandDeliveryStatus.pending);
    try {
      await send();
    } on ApiException catch (e) {
      if (e.isAuthError && mounted) {
        await context.read<AuthProvider>().forceLogoutOnSessionExpired();
        return;
      }
      if (!mounted) return;
      final current = _commandSeq[actuator] == seq;
      setState(() {
        if (current) {
          _actuatorStatus.remove(actuator);
          revert?.call();
        }
        _commandError = _commandErrorFor(e);
      });
      return;
    }
    _pollCommandStatus(actuator, seq, revert);
  }

  void _markNotDelivered(String actuator, VoidCallback? revert) {
    setState(() {
      _actuatorStatus.remove(actuator);
      _commandError = (l10n) => l10n.t('controlErrorCommandNotDelivered');
      revert?.call();
    });
  }

  Future<void> _pollCommandStatus(String actuator, int seq, VoidCallback? revert) async {
    // Counted polls instead of wall-clock time: same 10 s window, and the
    // loop stays deterministic under fake time in widget tests.
    final maxPolls =
        _commandStatusPollTimeout.inMilliseconds ~/ _commandStatusPollInterval.inMilliseconds;
    for (var attempt = 0; attempt < maxPolls; attempt++) {
      await Future.delayed(_commandStatusPollInterval);
      if (!mounted || _commandSeq[actuator] != seq) return;
      try {
        final status = await _repository.getCommandStatus(widget.deviceId, actuator);
        if (!mounted || _commandSeq[actuator] != seq) return;
        if (status == CommandDeliveryStatus.none) {
          // The Edge dropped the command (expired undelivered).
          _markNotDelivered(actuator, revert);
          return;
        }
        setState(() {
          _actuatorStatus[actuator] = status;
          if (status == CommandDeliveryStatus.delivered) _commandError = null;
        });
        if (status == CommandDeliveryStatus.delivered) return;
      } on ApiException catch (e) {
        if (e.isAuthError && mounted) {
          await context.read<AuthProvider>().forceLogoutOnSessionExpired();
        }
        return;
      }
    }
    if (mounted && _commandSeq[actuator] == seq) _markNotDelivered(actuator, revert);
  }

  String _freshnessLabel(AppLocalizations l10n) {
    final frame = _frame;
    if (frame == null) return '';
    final seconds = DateTime.now().toUtc().difference(frame.capturedAt.toUtc()).inSeconds;
    return l10n.updatedSecondsAgo(seconds < 0 ? 0 : seconds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_commandError != null) ...[
            _ErrorBanner(
              message: _commandError!(l10n),
              onDismiss: () => setState(() => _commandError = null),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _FeedCard(
            loading: _feedLoading,
            errorMessage: _feedError?.call(l10n),
            frame: _frame,
            freshnessLabel: _freshnessLabel(l10n),
            occupancy: _occupancy,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PanTiltCard(
            status: _actuatorStatus['pan_tilt'],
            onDirection: (panDelta, tiltDelta) => _sendCommand(
              'pan_tilt',
              () => _repository.sendPanTilt(widget.deviceId, panDelta: panDelta, tiltDelta: tiltDelta),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ToggleControlCard(
            titleKey: 'controlLightTitle',
            icon: Icons.lightbulb_outline,
            value: _lightOn,
            status: _actuatorStatus['light'],
            onChanged: (value) {
              final previous = _lightOn;
              setState(() => _lightOn = value);
              _sendCommand(
                'light',
                () => _repository.sendLight(widget.deviceId, on: value),
                revert: () => _lightOn = previous,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _ToggleControlCard(
            titleKey: 'controlBuzzerTitle',
            icon: Icons.campaign_outlined,
            value: _buzzerOn,
            status: _actuatorStatus['buzzer'],
            onChanged: (value) {
              final previous = _buzzerOn;
              setState(() => _buzzerOn = value);
              _sendCommand(
                'buzzer',
                () => _repository.sendBuzzer(widget.deviceId, on: value),
                revert: () => _buzzerOn = previous,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // No revert callback: a door press has no toggle state to restore,
          // and the command sequence lets a newer press supersede an older one.
          _DoorCard(
            status: _actuatorStatus['door'],
            onOpen: () => _sendCommand('door', () => _repository.sendDoor(widget.deviceId, open: true)),
            onClose: () => _sendCommand('door', () => _repository.sendDoor(widget.deviceId, open: false)),
          ),
        ],
      ),
    );
  }
}

/// D-07: announced, dismissible error banner. Icon plus text (never color
/// alone) and a dismiss control at the minimum touch target.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.alerta),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.alerta),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                // Only the message is the live region: the dismiss control
                // stays its own focusable, actionable semantics node.
                child: Semantics(
                  liveRegion: true,
                  child: Text(message, style: const TextStyle(color: AppColors.alerta, fontSize: 14)),
                ),
              ),
            ),
            Semantics(
              container: true,
              button: true,
              label: l10n.t('controlErrorDismiss'),
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.texto),
                  onPressed: onDismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.loading,
    required this.errorMessage,
    required this.frame,
    required this.freshnessLabel,
    required this.occupancy,
  });

  final bool loading;
  final String? errorMessage;
  final LatestFrame? frame;
  final String freshnessLabel;
  final Occupancy? occupancy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('controlFeedTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto)),
            const SizedBox(height: AppSpacing.sm),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator(color: AppColors.marca)))
            else if (frame != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Semantics(
                  label: l10n.t('controlFeedImageAlt'),
                  image: true,
                  child: Image.memory(base64Decode(frame!.frameBase64), fit: BoxFit.cover),
                ),
              )
            else if (errorMessage != null)
              Semantics(liveRegion: true, child: Text(errorMessage!, style: const TextStyle(color: AppColors.alerta))),
            if (frame != null) ...[
              const SizedBox(height: AppSpacing.sm),
              // FEED-05: "live" is never conveyed by the image alone —
              // always paired with an explicit relative-time label,
              // re-announced to assistive tech as it changes.
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.verificado),
                    const SizedBox(width: AppSpacing.xs),
                    Text(freshnessLabel, style: const TextStyle(color: AppColors.textoMute, fontSize: 13)),
                  ],
                ),
              ),
            ],
            if (occupancy != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.occupancyCount(occupancy!.count),
                  style: const TextStyle(color: AppColors.texto, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanTiltCard extends StatelessWidget {
  const _PanTiltCard({required this.status, required this.onDirection});

  final CommandDeliveryStatus? status;
  final void Function(double panDelta, double tiltDelta) onDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget directionButton(IconData icon, String labelKey, double panDelta, double tiltDelta) {
      return Semantics(
        button: true,
        label: l10n.t(labelKey),
        child: SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: IconButton(
            icon: Icon(icon, color: AppColors.texto),
            onPressed: () => onDirection(panDelta, tiltDelta),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.t('controlPanTiltTitle'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto)),
                ),
                _StatusLabel(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Column(
                children: [
                  directionButton(Icons.keyboard_arrow_up, 'controlTiltUp', 0, -_panTiltStep),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      directionButton(Icons.keyboard_arrow_left, 'controlPanLeft', -_panTiltStep, 0),
                      const SizedBox(width: AppSpacing.xxxl),
                      directionButton(Icons.keyboard_arrow_right, 'controlPanRight', _panTiltStep, 0),
                    ],
                  ),
                  directionButton(Icons.keyboard_arrow_down, 'controlTiltDown', 0, _panTiltStep),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleControlCard extends StatelessWidget {
  const _ToggleControlCard({
    required this.titleKey,
    required this.icon,
    required this.value,
    required this.status,
    required this.onChanged,
  });

  final String titleKey;
  final IconData icon;
  final bool value;
  final CommandDeliveryStatus? status;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: AppColors.texto),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.t(titleKey), style: const TextStyle(color: AppColors.texto, fontSize: 15)),
            ),
            _StatusLabel(status: status),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              toggled: value,
              label: l10n.t(titleKey),
              child: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.marca),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual door control: two plain buttons, each with icon plus text and a
/// 48 dp minimum height. The buttons sit in a [Wrap] so they reflow onto two
/// lines at large text scale instead of overflowing.
class _DoorCard extends StatelessWidget {
  const _DoorCard({required this.status, required this.onOpen, required this.onClose});

  final CommandDeliveryStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  static const double _buttonHeight = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openLabel = l10n.t('controlDoorOpen');
    final closeLabel = l10n.t('controlDoorClose');
    const minimumSize = Size(AppSpacing.minTouchTarget, _buttonHeight);

    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, color: AppColors.texto),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.t('controlDoorTitle'),
                      style: const TextStyle(color: AppColors.texto, fontSize: 15)),
                ),
                _StatusLabel(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // Default button semantics expose the visible text as the
                // label and keep the tap action, so no extra wrapper is needed.
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: minimumSize),
                  onPressed: onOpen,
                  icon: const Icon(Icons.lock_open),
                  label: Text(openLabel),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: minimumSize),
                  onPressed: onClose,
                  icon: const Icon(Icons.lock),
                  label: Text(closeLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CTRL-05: pending -> entregado feedback, icon + text (never color alone).
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final CommandDeliveryStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null || status == CommandDeliveryStatus.none) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final delivered = status == CommandDeliveryStatus.delivered;
    final label = l10n.t(delivered ? 'controlStatusDelivered' : 'controlStatusPending');
    final color = delivered ? AppColors.verificado : AppColors.senal;

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!delivered)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.senal),
            )
          else
            Icon(Icons.check_circle, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
