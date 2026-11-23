import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/worker/data/verification_service.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';

/// CNIC verification, for workers and clients (the CNIC step of "Get
/// verified"). Documents go to the owner/staff-only folder and the CNIC +
/// document paths to users/{uid}/private/verification — never to the public
/// profile. "Verified" is shown only when staff have approved them
/// (workerProfile.isVerified or isCnicVerified); this screen never decides
/// that itself.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SbDetailSkeleton());
    final submission = ref.watch(verificationSubmissionProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: Text(l.verificationTitle)),
      body: submission.when(
        loading: () => const SbDetailSkeleton(),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.verificationLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(verificationSubmissionProvider(user.uid)),
        ),
        data: (sub) => _VerificationBody(user: user, submission: sub),
      ),
    );
  }
}

enum _Status { notSubmitted, pending, verified, rejected }

class _VerificationBody extends ConsumerStatefulWidget {
  const _VerificationBody({required this.user, required this.submission});
  final UserEntity user;
  final VerificationSubmission? submission;

  @override
  ConsumerState<_VerificationBody> createState() => _VerificationBodyState();
}

class _VerificationBodyState extends ConsumerState<_VerificationBody> {
  bool _resubmitting = false;

  _Status get _status {
    if (cnicDocumentsApproved(widget.user)) return _Status.verified;
    final s = widget.submission?.status ?? widget.user.workerProfile?.verificationStatus;
    if (s == 'rejected') return _Status.rejected;
    if (s == 'pending' || widget.submission != null) return _Status.pending;
    return _Status.notSubmitted;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final edge = SbLayout.edge(context);
    final status = _status;
    final showForm = status == _Status.notSubmitted || status == _Status.rejected || _resubmitting;

    return ListView(
      padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s8),
      children: [
        SbReadableWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _StatusCard(status: status, submission: widget.submission),
            const SizedBox(height: SbSpace.s4),
            if ((widget.user.cnicNumber ?? '').isNotEmpty) ...[
              _LegacyCnicNotice(user: widget.user),
              const SizedBox(height: SbSpace.s4),
            ],
            if (showForm)
              _SubmissionForm(
                user: widget.user,
                onSubmitted: () => setState(() => _resubmitting = false),
              )
            else if (status == _Status.pending)
              SbButton(
                label: l.verificationUpdate,
                variant: SbButtonVariant.secondary,
                expand: true,
                onPressed: () => setState(() => _resubmitting = true),
              ),
            const SizedBox(height: SbSpace.s5),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: context.sb.textSecondary),
              const SizedBox(width: SbSpace.s2),
              Expanded(child: Text(l.verificationPrivacyNote, style: t.bodySmall)),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.submission});
  final _Status status;
  final VerificationSubmission? submission;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final (SbTone tone, IconData icon, String title, String body) = switch (status) {
      _Status.verified => (SbTone.success, Icons.verified_rounded, l.verificationVerifiedTitle, l.verificationVerifiedBody),
      _Status.pending => (SbTone.warning, Icons.schedule_rounded, l.verificationPendingTitle, l.verificationPendingBody),
      _Status.rejected => (SbTone.error, Icons.error_outline_rounded, l.verificationRejectedTitle, l.verificationRejectedBody),
      _Status.notSubmitted => (SbTone.info, Icons.badge_outlined, l.verificationIntroTitle, l.verificationIntroBody),
    };
    final pair = c.tone(tone);
    final submittedAt = submission?.submittedAt;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(SbSpace.s4),
        decoration: BoxDecoration(color: pair.background, borderRadius: BorderRadius.circular(SbRadius.card)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: pair.foreground, size: 28),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.titleMedium!.copyWith(color: pair.foreground)),
              const SizedBox(height: SbSpace.s1),
              Text(body, style: t.bodyMedium!.copyWith(color: pair.foreground)),
              if (status == _Status.pending && submission != null) ...[
                const SizedBox(height: SbSpace.s2),
                if (submission!.maskedCnic != null)
                  Text(l.verificationCnicOnFile(submission!.maskedCnic!), style: t.bodySmall!.copyWith(color: pair.foreground)),
                Text(l.verificationDocsOnFile(submission!.documentCount), style: t.bodySmall!.copyWith(color: pair.foreground)),
                if (submittedAt != null)
                  Text(
                    l.verificationSubmittedOn(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(submittedAt)),
                    style: t.bodySmall!.copyWith(color: pair.foreground),
                  ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Older app versions saved the CNIC on the public profile. The owner can
/// remove that copy here (their choice — nothing is deleted automatically).
class _LegacyCnicNotice extends ConsumerStatefulWidget {
  const _LegacyCnicNotice({required this.user});
  final UserEntity user;

  @override
  ConsumerState<_LegacyCnicNotice> createState() => _LegacyCnicNoticeState();
}

class _LegacyCnicNoticeState extends ConsumerState<_LegacyCnicNotice> {
  bool _busy = false;

  Future<void> _remove() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.verificationLegacyRemoveTitle,
      message: l.verificationLegacyRemoveBody,
      confirmLabel: l.verificationLegacyRemove,
      cancelLabel: l.cancel,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(updateUserProfileUseCaseProvider)
        .call(uid: widget.user.uid, data: {'cnicNumber': FieldValue.delete()});
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.isRight() ? l.verificationLegacyRemoved : l.profileSaveFailed),
      backgroundColor: result.isRight() ? null : context.sb.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SbInlineBanner(message: l.verificationLegacyNotice, tone: SbTone.warning, icon: Icons.privacy_tip_outlined),
      const SizedBox(height: SbSpace.s2),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SbButton(
          label: l.verificationLegacyRemove,
          size: SbButtonSize.compact,
          variant: SbButtonVariant.secondary,
          isLoading: _busy,
          onPressed: _remove,
        ),
      ),
    ]);
  }
}

/// CNIC "12345-1234567-1" with dashes inserted as you type.
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 13 ? digits.substring(0, 13) : digits;
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 5 || i == 12) b.write('-');
      b.write(d[i]);
    }
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _DocSlot {
  _DocSlot(this.label, {required this.required});
  final String label;
  final bool required;
  String? path;
  double? progress; // null = idle
  String? error;
}

class _SubmissionForm extends ConsumerStatefulWidget {
  const _SubmissionForm({required this.user, required this.onSubmitted});
  final UserEntity user;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends ConsumerState<_SubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _cnic = TextEditingController();
  List<_DocSlot> _slots = const [];
  bool _consent = false;
  bool _showErrors = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slots.isNotEmpty) return; // keep uploads across rebuilds
    final l = context.l10n;
    _slots = [
      _DocSlot(l.verificationDocFront, required: true),
      _DocSlot(l.verificationDocBack, required: true),
      // A trade certificate only makes sense for workers.
      if (widget.user.isWorker) _DocSlot(l.verificationDocExtra, required: false),
    ];
  }

  @override
  void dispose() {
    _cnic.dispose();
    super.dispose();
  }

  bool get _uploading => _slots.any((s) => s.progress != null);

  Future<void> _pick(_DocSlot slot, String key) async {
    final l = context.l10n;
    // Kept privately in Firestore: shrink so it fits the private size limit.
    final file = await pickProfileImage(context, maxSide: 1400, quality: 70);
    if (file == null || !mounted) return;
    final media = ref.read(profileMediaServiceProvider);
    final previous = slot.path;
    setState(() {
      slot.progress = 0;
      slot.error = null;
    });
    try {
      final path = await media.uploadVerificationDocument(
        uid: widget.user.uid,
        file: file,
        label: key,
        onProgress: (p) {
          if (mounted) setState(() => slot.progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        slot.path = path;
        slot.progress = null;
      });
      if (previous != null) {
        try {
          await media.deleteOwnedVerificationPath(uid: widget.user.uid, path: previous);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        slot.progress = null;
        slot.error = mediaErrorText(l, e);
      });
    }
  }

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() {
      _showErrors = true;
      _submitError = null;
    });
    final formOk = _formKey.currentState?.validate() ?? false;
    final docsOk = _slots.where((s) => s.required).every((s) => s.path != null);
    if (!formOk || !docsOk || !_consent || _uploading) return;
    setState(() => _submitting = true);
    try {
      await ref.read(verificationServiceProvider).submit(
            uid: widget.user.uid,
            cnic: _cnic.text.trim(),
            documentPaths: [for (final s in _slots) if (s.path != null) s.path!],
            isWorker: widget.user.isWorker,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.verificationSubmitted)));
      widget.onSubmitted();
    } catch (_) {
      if (mounted) setState(() => _submitError = l.verificationSubmitFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_submitError != null) ...[
          SbInlineBanner(message: _submitError!, tone: SbTone.error),
          const SizedBox(height: SbSpace.s4),
        ],
        SbTextField(
          label: l.verificationCnicLabel,
          hint: '35202-1234567-1',
          helper: l.verificationCnicHelp,
          controller: _cnic,
          keyboardType: TextInputType.number,
          inputFormatters: [CnicInputFormatter()],
          prefixIcon: Icons.badge_outlined,
          autovalidateMode: AutovalidateMode.disabled,
          validator: (v) => VerificationService.cnicPattern.hasMatch(v?.trim() ?? '') ? null : l.verificationCnicInvalid,
        ),
        const SizedBox(height: SbSpace.s5),
        Semantics(header: true, child: Text(l.verificationDocsTitle, style: t.titleSmall)),
        const SizedBox(height: SbSpace.s1),
        Text(l.verificationDocsHelp, style: t.bodySmall),
        const SizedBox(height: SbSpace.s3),
        for (final (i, slot) in _slots.indexed) ...[
          _DocTile(
            slot: slot,
            showMissing: _showErrors && slot.required && slot.path == null,
            onPick: _submitting ? null : () => _pick(slot, ['cnic_front', 'cnic_back', 'supporting'][i]),
          ),
          const SizedBox(height: SbSpace.s2),
        ],
        const SizedBox(height: SbSpace.s3),
        MergeSemantics(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(value: _consent, onChanged: _submitting ? null : (v) => setState(() => _consent = v ?? false)),
            Expanded(
              child: GestureDetector(
                onTap: _submitting ? null : () => setState(() => _consent = !_consent),
                child: Padding(
                  padding: const EdgeInsets.only(top: SbSpace.s3),
                  child: Text(l.verificationConsent, style: t.bodyMedium),
                ),
              ),
            ),
          ]),
        ),
        if (_showErrors && !_consent)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: SbSpace.s3),
            child: Text(l.verificationConsentRequired, style: t.bodySmall!.copyWith(color: c.error)),
          ),
        const SizedBox(height: SbSpace.s4),
        SbButton(
          label: l.verificationSubmit,
          expand: true,
          isLoading: _submitting,
          onPressed: _uploading ? null : _submit,
        ),
        if (context.canPop()) ...[
          const SizedBox(height: SbSpace.s1),
          SbButton(label: l.cancel, variant: SbButtonVariant.quiet, expand: true, onPressed: _submitting ? null : () => context.pop()),
        ],
      ]),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.slot, required this.showMissing, required this.onPick});
  final _DocSlot slot;
  final bool showMissing;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final uploading = slot.progress != null;
    final done = slot.path != null && !uploading;
    final borderColor = showMissing || slot.error != null ? c.error : (done ? c.success : c.border);
    return Container(
      padding: const EdgeInsets.all(SbSpace.s3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SbRadius.control),
        border: Border.all(color: borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(done ? Icons.check_circle_rounded : Icons.upload_file_outlined, color: done ? c.success : c.textSecondary),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(slot.label, style: t.titleSmall),
              Text(
                uploading
                    ? l.verificationUploading((slot.progress! * 100).round())
                    : done
                        ? l.verificationUploaded
                        : (slot.required ? l.verificationRequired : l.profileOptional),
                style: t.bodySmall,
              ),
            ]),
          ),
          SbButton(
            label: done ? l.verificationReplace : l.verificationUpload,
            size: SbButtonSize.compact,
            variant: SbButtonVariant.secondary,
            onPressed: uploading ? null : onPick,
          ),
        ]),
        if (uploading) ...[
          const SizedBox(height: SbSpace.s2),
          LinearProgressIndicator(value: slot.progress == 0 ? null : slot.progress),
        ],
        if (slot.error != null || showMissing) ...[
          const SizedBox(height: SbSpace.s2),
          Text(slot.error ?? l.verificationDocMissing, style: t.bodySmall!.copyWith(color: c.error)),
        ],
      ]),
    );
  }
}
