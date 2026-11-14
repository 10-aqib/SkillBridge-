import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// For the worker a direct request was sent to: accept (creates the
/// contract through the trusted function) or decline (closes the request).
class DirectRequestActions extends ConsumerStatefulWidget {
  const DirectRequestActions({super.key, required this.jobId, required this.jobTitle});
  final String jobId;
  final String jobTitle;

  @override
  ConsumerState<DirectRequestActions> createState() => _DirectRequestActionsState();
}

class _DirectRequestActionsState extends ConsumerState<DirectRequestActions> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: accept ? l.contractDirectAcceptTitle : l.contractRequestDeclineTitle,
      message: accept ? l.contractDirectAcceptBody : l.contractRequestDeclineBody,
      confirmLabel: accept ? l.contractRequestAccept : l.contractRequestDecline,
      cancelLabel: l.cancel,
      destructive: !accept,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(contractActionsProvider).respondToDirectRequest(widget.jobId, accept: accept);
      if (!mounted) return;
      context.showSnackBar(accept ? l.contractRequestAccepted : l.contractRequestDeclined);
      if (accept && id != null) {
        context.push(RouteNames.contractDetailsLocation(id));
      } else if (context.canPop()) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (contractFailureOf(e)) {
          ContractFailure.wrongState => l.contractActionChanged,
          ContractFailure.notAllowed => l.contractActionNotAllowed,
          ContractFailure.network => l.errNetwork,
          _ => l.contractActionFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(color: sb.surface, borderRadius: BorderRadius.circular(SbRadius.card), border: Border.all(color: sb.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.contractDirectRequestTitle, style: t.titleSmall),
        const SizedBox(height: SbSpace.s1),
        Text(l.contractDirectRequestBody, style: t.bodySmall),
        const SizedBox(height: SbSpace.s3),
        Row(children: [
          Expanded(
            child: SbButton(
              label: l.contractRequestDecline,
              variant: SbButtonVariant.secondary,
              expand: true,
              onPressed: _busy ? null : () => _answer(false),
            ),
          ),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: SbButton(
              label: l.contractRequestAccept,
              expand: true,
              isLoading: _busy,
              onPressed: _busy ? null : () => _answer(true),
            ),
          ),
        ]),
      ]),
    );
  }
}
