import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/contract_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// On a hired job's page: where the work stands and the way into the
/// contract, where starting, submitting and confirming happen.
class OpenContractCard extends ConsumerWidget {
  const OpenContractCard({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final contract = ref.watch(contractForJobProvider(jobId));
    final c = contract.value;
    if (contract.isLoading && c == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(color: sb.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: sb.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(l.contractCardTitle, style: t.titleSmall)),
          if (c != null) ContractStageBadge(stage: c.stage),
        ]),
        const SizedBox(height: SbSpace.s1),
        Text(c == null ? l.contractNoneForJob : l.contractCardBody, style: t.bodySmall),
        if (c != null) ...[
          const SizedBox(height: SbSpace.s3),
          SbButton(
            label: l.contractOpen,
            icon: Icons.description_outlined,
            expand: true,
            onPressed: () => context.push(RouteNames.contractDetailsLocation(c.id), extra: c),
          ),
        ],
      ]),
    );
  }
}
