import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/verification_status_widget.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The person's own verification attempts (VerificationHistoryScreen):
/// status, date, masked CNIC and whether it was a test. Nothing else.
class VerificationHistoryScreen extends ConsumerWidget {
  const VerificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final async = ref.watch(identityHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.identityHistory)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.identityErrGeneric,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(identityHistoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) return SbStateView(kind: SbStateKind.empty, title: l.identityHistoryEmpty);
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s3, SbLayout.edge(context), SbSpace.s8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: SbSpace.s2),
            itemBuilder: (context, i) {
              final a = items[i];
              final label = identityStatusLabel(
                l,
                IdentityState(status: a.status, verified: false, provider: '', test: a.test),
              );
              return Material(
                color: sb.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: sb.border)),
                child: ListTile(
                  leading: Icon(a.test ? Icons.science_outlined : Icons.fingerprint_rounded),
                  title: Text(a.test && a.status != IdentityStatus.verified ? '[TEST] $label' : label, style: t.titleSmall),
                  subtitle: Text(
                    [
                      if (a.createdAt != null) DateFormat.yMMMd(locale).add_jm().format(a.createdAt!),
                      if (a.maskedCnic.isNotEmpty) a.maskedCnic,
                    ].join(' · '),
                    style: t.bodySmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
