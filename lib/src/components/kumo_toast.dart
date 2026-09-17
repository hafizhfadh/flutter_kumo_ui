import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_focusable.dart';

/// The four states a [KumoToast] can report.
enum KumoToastKind {
  /// Neutral notice. Tinted with the palette info blue.
  info,

  /// Completed work. Tinted with the palette success green.
  success,

  /// Something needs attention. Tinted with the palette warning amber.
  warning,

  /// Failed work. Tinted with the palette error red.
  error,
}

/// A floating status banner.
///
/// Toasts sit on the `gray1` surface with a 1px `gray3` outline, lead with a
/// state icon, and carry an explicit close action — the banner never relies on
/// auto-dismissal alone, so a user who needs longer can keep it on screen.
class KumoToast extends StatelessWidget {
  /// Creates a Kumo toast banner.
  const KumoToast({
    super.key,
    required this.message,
    this.title,
    this.kind = KumoToastKind.info,
    this.onClose,
  });

  /// Body text describing the outcome.
  final String message;

  /// Optional emphasised first line.
  final String? title;

  /// Which state this toast reports.
  final KumoToastKind kind;

  /// Called when the close action is activated. When null no close action is
  /// rendered, which is only appropriate when the toast is owned by another
  /// auto-dismissing host.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final (IconData icon, Color accent) = switch (kind) {
      KumoToastKind.info => (PhosphorIconsRegular.info, colors.info),
      KumoToastKind.success => (
        PhosphorIconsRegular.checkCircle,
        colors.success,
      ),
      KumoToastKind.warning => (PhosphorIconsRegular.warning, colors.warning),
      // The icon is a graphic, not text, so it takes the indicator red: red5
      // still clears the 3:1 WCAG 1.4.11 floor for non-text content.
      KumoToastKind.error => (
        PhosphorIconsRegular.warningCircle,
        colors.danger,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PhosphorIcon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: KumoTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(message, style: KumoTypography.bodyMuted),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Dismiss notification',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: KumoFocusable(
                  onActivate: onClose,
                  borderRadius: BorderRadius.circular(6),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows [KumoToast] banners as an overlay above the current route.
///
/// Toasts stack upward from the bottom edge, newest nearest the thumb, and each
/// one auto-dismisses after its own duration. The overlay is inserted lazily and
/// torn down once the last toast leaves, so an app that never shows a toast
/// carries no extra overlay.
abstract final class KumoToastManager {
  /// Default time a toast stays on screen before dismissing itself.
  static const Duration defaultDuration = Duration(seconds: 4);

  static final ValueNotifier<List<_ActiveToast>> _active =
      ValueNotifier<List<_ActiveToast>>(<_ActiveToast>[]);

  static OverlayEntry? _entry;
  static int _nextId = 0;

  /// Number of toasts currently on screen.
  static int get activeCount => _active.value.length;

  /// Shows a toast over the nearest root overlay.
  ///
  /// Does nothing when there is no [Overlay] ancestor.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    KumoToastKind kind = KumoToastKind.info,
    Duration duration = defaultDuration,
  }) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    final _ActiveToast toast = _ActiveToast(
      id: _nextId++,
      message: message,
      title: title,
      kind: kind,
      duration: duration,
    );
    _active.value = <_ActiveToast>[..._active.value, toast];
    _ensureLayer(overlay, KumoTheme.of(context));
  }

  /// Removes the toast with [id], if it is still on screen.
  static void dismiss(int id) {
    _active.value = _active.value
        .where((_ActiveToast toast) => toast.id != id)
        .toList();
  }

  /// Removes every visible toast.
  static void clear() => _active.value = <_ActiveToast>[];

  static void _ensureLayer(OverlayState overlay, KumoColors colors) {
    final OverlayEntry? existing = _entry;
    if (existing != null && existing.mounted) {
      return;
    }
    // A previous layer whose overlay has already been torn down cannot carry
    // new toasts, so fall through and install a fresh one.
    _entry = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => KumoTheme(
        colors: colors,
        child: _KumoToastLayer(
          active: _active,
          onEmpty: () {
            if (entry.mounted) {
              entry.remove();
            }
            if (identical(_entry, entry)) {
              _entry = null;
            }
          },
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// One queued toast.
@immutable
class _ActiveToast {
  const _ActiveToast({
    required this.id,
    required this.message,
    required this.title,
    required this.kind,
    required this.duration,
  });

  final int id;
  final String message;
  final String? title;
  final KumoToastKind kind;
  final Duration duration;
}

class _KumoToastLayer extends StatefulWidget {
  const _KumoToastLayer({required this.active, required this.onEmpty});

  final ValueNotifier<List<_ActiveToast>> active;
  final VoidCallback onEmpty;

  @override
  State<_KumoToastLayer> createState() => _KumoToastLayerState();
}

class _KumoToastLayerState extends State<_KumoToastLayer> {
  @override
  void initState() {
    super.initState();
    widget.active.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.active.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) {
      return;
    }
    if (widget.active.value.isEmpty) {
      widget.onEmpty();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final _ActiveToast toast in widget.active.value)
                  Padding(
                    key: ValueKey<int>(toast.id),
                    padding: const EdgeInsets.only(top: 8),
                    child: _AutoDismissingToast(
                      toast: toast,
                      onDismissed: () => KumoToastManager.dismiss(toast.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoDismissingToast extends StatefulWidget {
  const _AutoDismissingToast({required this.toast, required this.onDismissed});

  final _ActiveToast toast;
  final VoidCallback onDismissed;

  @override
  State<_AutoDismissingToast> createState() => _AutoDismissingToastState();
}

class _AutoDismissingToastState extends State<_AutoDismissingToast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.toast.duration, widget.onDismissed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KumoToast(
      message: widget.toast.message,
      title: widget.toast.title,
      kind: widget.toast.kind,
      onClose: widget.onDismissed,
    );
  }
}
