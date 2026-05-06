import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/in_app_notification.dart';
import '../services/in_app_notification_service.dart';

/// Ana sayfa üzerinde sağdan kayan, dar bildirim paneli açar (tam ekran değil).
Future<void> showInAppNotificationsPanel(BuildContext context) {
  final barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.05, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(dialogContext);
      final maxW = math.min(400.0, size.width * 0.92);
      final maxH = size.height * 0.88;
      return SafeArea(
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 8, bottom: 8, end: 8),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxW,
                  maxHeight: maxH,
                ),
                child: const _NotificationsPanelCard(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _NotificationsPanelCard extends StatelessWidget {
  const _NotificationsPanelCard();

  static const _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C4DFF),
      Color(0xFFE040FB),
      Color(0xFFFF6E40),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadiusDirectional.only(
        topStart: const Radius.circular(28),
        bottomStart: const Radius.circular(28),
      ).resolve(Directionality.of(context)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(28),
            bottomStart: const Radius.circular(28),
          ).resolve(Directionality.of(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(-6, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(gradient: _headerGradient),
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.elasticOut,
                        builder: (context, t, child) {
                          return Transform.rotate(
                            angle: (1 - t) * 0.4,
                            child: Transform.scale(
                              scale: 0.85 + 0.15 * t,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🔔', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.notificationsTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '✨ ${l.notificationsPanelSubtitle}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<InAppNotificationService>(
                    builder: (context, svc, _) {
                      if (svc.items.isEmpty) return const SizedBox.shrink();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _KidChipButton(
                            icon: Icons.mark_email_read_rounded,
                            label: l.notificationsMarkAllRead,
                            enabled: svc.unreadCount > 0,
                            onTap: () => svc.markAllRead(),
                          ),
                          _KidChipButton(
                            icon: Icons.delete_sweep_rounded,
                            label: l.notificationsDeleteAll,
                            enabled: true,
                            color: Colors.red.shade100,
                            foreground: Colors.red.shade900,
                            onTap: () => _confirmDeleteAll(
                              context,
                              svc,
                              svc.items.length,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<InAppNotificationService>(
                builder: (context, svc, _) {
                  if (svc.items.isEmpty) {
                    return _EmptyNotificationsState(message: l.notificationsEmpty);
                  }
                  return SlidableAutoCloseBehavior(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                      itemCount: svc.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = svc.items[index];
                        return _NotificationTile(
                          item: item,
                          message: _messageForItem(l, item),
                          dateStr: item.createdAt != null
                              ? DateFormat(
                                  'd MMM yyyy, HH:mm',
                                  Localizations.localeOf(context).languageCode,
                                ).format(item.createdAt!.toLocal())
                              : '',
                          read: item.read,
                          onDelete: () => _confirmDeleteOne(
                            context,
                            svc,
                            item.id,
                          ),
                          swipeDeleteLabel: l.notificationsSwipeDelete,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageForItem(AppLocalizations l, InAppNotificationItem item) {
  if (item.type == 'display_name_changed') {
    return l.notificationsBodyRename
        .replaceAll('{old}', item.oldDisplayName)
        .replaceAll('{new}', item.newDisplayName);
  }
  if (item.type == 'family_remote_duel_invite_timeout') {
    return l.notificationsBodyDuelInviteTimeout;
  }
  return '';
}

Future<void> _confirmDeleteOne(
  BuildContext context,
  InAppNotificationService service,
  String id,
) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _KidConfirmDialog(
      title: l.notificationsTitle,
      message: l.notificationsDeleteOneConfirm,
    ),
  );
  if (ok == true && context.mounted) {
    await service.deleteById(id);
  }
}

Future<void> _confirmDeleteAll(
  BuildContext context,
  InAppNotificationService service,
  int count,
) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _KidConfirmDialog(
      title: l.notificationsTitle,
      message: l.notificationsDeleteAllConfirm.replaceAll('{count}', '$count'),
    ),
  );
  if (ok == true && context.mounted) {
    await service.deleteAll();
  }
}

class _KidChipButton extends StatelessWidget {
  const _KidChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.color,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white.withValues(alpha: 0.28);
    final fg = foreground ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.45 : 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg.withValues(alpha: enabled ? 1 : 0.5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg.withValues(alpha: enabled ? 1 : 0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatefulWidget {
  const _EmptyNotificationsState({required this.message});

  final String message;

  @override
  State<_EmptyNotificationsState> createState() => _EmptyNotificationsStateState();
}

class _EmptyNotificationsStateState extends State<_EmptyNotificationsState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final scale = 1.0 + 0.06 * math.sin(_c.value * math.pi * 2);
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📭', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.message,
    required this.dateStr,
    required this.read,
    required this.onDelete,
    required this.swipeDeleteLabel,
  });

  final InAppNotificationItem item;
  final String message;
  final String dateStr;
  final bool read;
  final VoidCallback onDelete;
  final String swipeDeleteLabel;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey<String>(item.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.24,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: swipeDeleteLabel,
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: read
              ? const Color(0xFFF3E5F5).withValues(alpha: 0.45)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: read
              ? null
              : [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: read
                ? null
                : () {
                    unawaited(
                      Provider.of<InAppNotificationService>(context, listen: false)
                          .markOneRead(item.id),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    read ? '✉️' : '✨',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontWeight: read ? FontWeight.w500 : FontWeight.w800,
                            fontSize: 14,
                            height: 1.3,
                            color: const Color(0xFF4A148C),
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade300,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KidConfirmDialog extends StatelessWidget {
  const _KidConfirmDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤔', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5E35B1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7E57C2),
                        side: const BorderSide(color: Color(0xFF7E57C2), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(l.no, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(l.yes, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
