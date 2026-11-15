import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/contract_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Picks a photo; overridable in tests (no platform picker there).
typedef EvidencePicker = Future<({Uint8List bytes, String contentType})?> Function();

Future<({Uint8List bytes, String contentType})?> _pickWithImagePicker() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final type = file.mimeType ?? (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
  return (bytes: bytes, contentType: type);
}

/// The hired worker hands the work in for the client's review: a short note
/// and up to three photos, stored privately with the contract.
class SubmitWorkScreen extends ConsumerStatefulWidget {
  const SubmitWorkScreen({super.key, required this.contractId, this.initial, this.picker});
  final String contractId;
  final ContractEntity? initial;
  final EvidencePicker? picker;

  static const int maxPhotos = 3;
  // Kept privately in Firestore (free plan, Phase S6).
  static const int maxBytes = privateMediaMaxBytes;

  @override
  ConsumerState<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends ConsumerState<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  final List<({Uint8List bytes, String contentType})> _photos = [];
  bool _sending = false;
  bool _sent = false;
  String? _progress;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final l = context.l10n;
    final picked = await (widget.picker ?? _pickWithImagePicker)();
    if (picked == null || !mounted) return;
    if (picked.bytes.length > SubmitWorkScreen.maxBytes) {
      context.showSnackBar(l.contractPhotoTooLarge, isError: true);
      return;
    }
    setState(() => _photos.add(picked));
  }

  Future<void> _submit(ContractEntity c) async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    if (_sending || _sent) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final resubmit = c.awaitingResubmission;
    final ok = await showSbConfirmSheet(
      context,
      title: resubmit ? l.contractResubmit : l.contractSubmitTitle,
      message: l.contractSubmitBody,
      confirmLabel: resubmit ? l.contractResubmit : l.contractSubmit,
      cancelLabel: l.jobConfirmKeepEditing,
    );
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    final actions = ref.read(contractActionsProvider);
    try {
      final paths = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        setState(() => _progress = l.contractUploading(i + 1, _photos.length));
        paths.add(await actions.uploadEvidence(c.id, _photos[i].bytes, contentType: _photos[i].contentType));
      }
      setState(() => _progress = null);
      await actions.submitWork(c.id, note: _note.text.trim(), attachments: paths);
      if (!mounted) return;
      _sent = true;
      context.showSnackBar(l.contractSubmitted);
      // Back to the contract (or open it when this screen was the first one).
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.contractDetailsLocation(c.id));
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        switch (contractFailureOf(e)) {
          ContractFailure.wrongState => l.contractActionChanged,
          ContractFailure.network => l.errNetwork,
          _ => l.contractSubmitFailed,
        },
        isError: true,
      );
    } finally {
      if (mounted) setState(() { _sending = false; _progress = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final edge = SbLayout.edge(context);
    final me = ref.watch(currentUserProvider);
    final live = ref.watch(contractByIdProvider(widget.contractId));
    final c = live.hasError ? null : (live.value ?? (live.isLoading ? widget.initial : null));

    Widget blocked(String title, String body) => Scaffold(
          appBar: AppBar(title: Text(l.contractSubmitTitle)),
          body: SbStateView(kind: SbStateKind.empty, title: title, message: body),
        );
    if (c == null) {
      return live.isLoading && !live.hasError
          ? Scaffold(appBar: AppBar(title: Text(l.contractSubmitTitle)), body: const Center(child: CircularProgressIndicator()))
          : blocked(l.contractUnavailableTitle, l.contractUnavailableBody);
    }
    if (me == null || me.uid != c.workerId) return blocked(l.contractActionNotAllowed, l.contractOnlyWorkerSubmits);
    if (!_sending && !_sent && c.stage != ContractStage.inProgress) {
      return blocked(contractStageLabel(l, c.stage), c.stage == ContractStage.submitted ? l.contractAlreadySubmitted : l.contractStartFirst);
    }

    return Scaffold(
      appBar: AppBar(title: Text(c.awaitingResubmission ? l.contractResubmit : l.contractSubmitTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_progress != null) ...[
              Text(_progress!, style: t.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: SbSpace.s2),
            ],
            SbButton(
              label: l.contractSubmitReview,
              expand: true,
              isLoading: _sending,
              onPressed: _sending || _sent ? null : () => _submit(c),
            ),
          ]),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
          children: [
            SbReadableWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(c.jobTitle, style: t.titleMedium),
                Text(contractPriceLabel(l, c), style: t.bodySmall),
                const SizedBox(height: SbSpace.s4),
                // Sent back for changes: what the client asked for, first.
                if (c.awaitingResubmission) ...[
                  SbInlineBanner(
                    message: l.contractRevisionBannerWorker(c.clientName, c.revisionNote ?? ''),
                    tone: SbTone.warning,
                    icon: Icons.replay_rounded,
                  ),
                  const SizedBox(height: SbSpace.s3),
                ],
                SbInlineBanner(message: l.contractSubmitExplainer, tone: SbTone.info),
                const SizedBox(height: SbSpace.s4),
                SbTextField(
                  label: l.contractSubmitNote,
                  hint: l.contractSubmitNoteHint,
                  requiredMarker: '*',
                  controller: _note,
                  maxLines: 5,
                  maxLength: 1000,
                  enabled: !_sending,
                  validator: (v) => (v ?? '').trim().length < 10 ? l.contractSubmitNoteRequired : null,
                ),
                const SizedBox(height: SbSpace.s4),
                Text(l.contractSubmitPhotos(SubmitWorkScreen.maxPhotos), style: t.titleSmall),
                const SizedBox(height: SbSpace.s1),
                Text(l.contractSubmitPhotosNote, style: t.bodySmall),
                const SizedBox(height: SbSpace.s3),
                Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(SbRadius.control),
                        child: Image.memory(_photos[i].bytes, width: 96, height: 96, fit: BoxFit.cover,
                            semanticLabel: l.contractEvidencePhoto(i + 1)),
                      ),
                      if (!_sending)
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: l.contractRemovePhoto,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => setState(() => _photos.removeAt(i)),
                          ),
                        ),
                    ]),
                  if (_photos.length < SubmitWorkScreen.maxPhotos && !_sending)
                    InkWell(
                      borderRadius: BorderRadius.circular(SbRadius.control),
                      onTap: _addPhoto,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SbRadius.control),
                          border: Border.all(color: sb.border),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, color: sb.textSecondary),
                          const SizedBox(height: SbSpace.s1),
                          Text(l.contractAddPhoto, style: t.bodySmall),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
