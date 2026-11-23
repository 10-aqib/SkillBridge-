import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/viewmodels/post_job_viewmodel.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';

/// Create a job (or a direct request to one worker), or edit an open job.
class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key, this.workerId, this.workerName, this.editJob});

  /// Direct request: only this worker sees the job.
  final String? workerId;
  final String? workerName;

  /// Edit mode (open jobs only).
  final JobEntity? editJob;

  static const int titleMin = 10;
  static const int titleMax = 80;
  static const int descriptionMin = 30;
  static const int descriptionMax = 1000;
  static const int maxSkills = 10;
  static const int maxPhotos = 4;
  static const double budgetLimit = 10000000;

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  final _area = TextEditingController();
  final _customSkill = TextEditingController();

  String? _categoryId;
  final List<String> _skills = [];
  String _budgetType = 'fixed';
  String? _city;
  String _urgency = 'within_3_days';
  DateTime? _preferredDate;
  final List<String> _photos = [];
  bool _uploading = false;
  bool _showChoiceErrors = false;

  bool get _editing => widget.editJob != null;
  bool get _direct => widget.workerId != null && widget.workerId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final j = widget.editJob;
    if (j != null) {
      _title.text = j.title;
      _description.text = j.description;
      _categoryId = PakistanConstants.categoryById(j.categoryId) != null ? j.categoryId : null;
      _skills.addAll(j.requiredSkills);
      _budgetType = ['fixed', 'hourly', 'daily'].contains(j.budgetType) ? j.budgetType : 'fixed';
      if (j.budgetMin > 0) _budgetMin.text = j.budgetMin.round().toString();
      if (j.budgetMax > j.budgetMin) _budgetMax.text = j.budgetMax.round().toString();
      if (j.budgetMin <= 0 && j.budgetMax > 0) _budgetMin.text = j.budgetMax.round().toString();
      _city = PakistanConstants.majorCities.contains(j.city) ? j.city : null;
      _area.text = j.address;
      _urgency = switch (j.urgency) {
        'immediate' || 'urgent' => 'immediate',
        'flexible' => 'flexible',
        _ => 'within_3_days',
      };
      _preferredDate = j.startDate;
      _photos.addAll(j.images);
    } else {
      _city = ref.read(currentUserProvider)?.city;
      if (!PakistanConstants.majorCities.contains(_city)) _city = null;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _budgetMin, _budgetMax, _area, _customSkill]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _amount(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim());

  JobDraft _draft() {
    final lo = _amount(_budgetMin) ?? 0;
    final hi = _amount(_budgetMax);
    final cat = PakistanConstants.categoryById(_categoryId!)!;
    return JobDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      categoryId: _categoryId!,
      categoryName: cat['name'] as String,
      skills: List.of(_skills),
      budgetType: _budgetType,
      budgetMin: lo,
      budgetMax: (hi == null || hi <= 0) ? lo : hi,
      city: _city!,
      area: _area.text.trim(),
      urgency: _urgency,
      preferredDate: _preferredDate,
      images: List.of(_photos),
    );
  }

  void _addSkill(String raw) {
    final l = context.l10n;
    final s = raw.trim();
    if (s.isEmpty) return;
    if (_skills.any((x) => x.toLowerCase() == s.toLowerCase())) {
      _customSkill.clear();
      return;
    }
    if (_skills.length >= PostJobScreen.maxSkills) {
      context.showSnackBar(l.jobFormSkillsMax, isError: true);
      return;
    }
    setState(() => _skills.add(s));
    _customSkill.clear();
  }

  Future<void> _addPhoto() async {
    final l = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final file = await pickProfileImage(context);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(profileMediaServiceProvider).uploadJobPhoto(uid: user.uid, file: file);
      if (mounted) setState(() => _photos.add(url));
    } catch (e) {
      if (mounted) context.showSnackBar(mediaErrorText(l, e), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(String url) {
    setState(() => _photos.remove(url));
    // Only photos added in this session that were never saved are deleted;
    // saved ones stay until the edit is saved (and are kept for history).
    if (!(widget.editJob?.images.contains(url) ?? false)) {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid != null) {
        ref.read(profileMediaServiceProvider).deleteOwnedByUrl(uid: uid, url: url).catchError((_) {});
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate != null && _preferredDate!.isAfter(now) ? _preferredDate! : now,
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() => _showChoiceErrors = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _categoryId == null || _city == null || _uploading) {
      context.showSnackBar(l.jobFormFixErrors, isError: true);
      return;
    }
    final draft = _draft();
    final vm = ref.read(postJobNotifierProvider.notifier);
    if (_editing) {
      await vm.saveEdit(widget.editJob!, draft);
    } else {
      final ok = await showSbConfirmSheet(
        context,
        title: _direct ? l.jobConfirmDirectTitle(widget.workerName ?? '') : l.jobConfirmTitle,
        message: _direct ? l.jobConfirmDirectBody(widget.workerName ?? '') : l.jobConfirmBody(draft.city),
        confirmLabel: _direct ? l.jobConfirmSend : l.jobConfirmPublish,
        cancelLabel: l.jobConfirmKeepEditing,
        details: _Summary(draft: draft),
      );
      if (!ok || !mounted) return;
      await vm.publish(draft, directWorkerId: widget.workerId, directWorkerName: widget.workerName);
    }
    if (!mounted) return;
    final s = ref.read(postJobNotifierProvider);
    if (s.error != null) {
      context.showSnackBar(
        switch (s.error!) {
          PostJobError.notClient => l.jobNotClient,
          PostJobError.suspended => l.jobSuspended,
          PostJobError.failed => _editing ? l.profileSaveFailed : l.jobPublishFailed,
        },
        isError: true,
      );
      return;
    }
    if (s.jobId == null) return;
    if (_editing) {
      context.showSnackBar(l.jobSaved);
      ref.invalidate(jobByIdProvider(s.jobId!));
      context.canPop() ? context.pop() : context.go(RouteNames.jobDetailsLocation(s.jobId!));
    } else if (s.queuedOffline) {
      context.showSnackBar(l.jobQueuedOffline);
      context.go(RouteNames.clientJobsPath);
    } else {
      context.showSnackBar(l.jobPublished);
      context.pushReplacement(RouteNames.jobDetailsLocation(s.jobId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final state = ref.watch(postJobNotifierProvider);
    final busy = state.isLoading;
    final edge = SbLayout.edge(context);
    final suggestions = PakistanConstants.skillSuggestions[_categoryId] ?? const <String>[];

    String? budgetMinError(String? v) {
      final a = _amount(_budgetMin);
      if (a == null || a <= 0) return l.jobFormBudgetRequired;
      if (a > PostJobScreen.budgetLimit) return l.jobFormBudgetTooHigh;
      return null;
    }

    String? budgetMaxError(String? v) {
      if ((v ?? '').trim().isEmpty) return null;
      final hi = _amount(_budgetMax);
      final lo = _amount(_budgetMin) ?? 0;
      if (hi == null || hi < lo) return l.jobFormBudgetMaxInvalid;
      if (hi > PostJobScreen.budgetLimit) return l.jobFormBudgetTooHigh;
      return null;
    }

    Widget section(String title, {String? subtitle, required List<Widget> children}) => Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(header: true, child: Text(title, style: t.titleMedium)),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: t.bodySmall)],
            const SizedBox(height: SbSpace.s3),
            ...children,
          ]),
        );

    Widget choiceError(String text) => Padding(
          padding: const EdgeInsets.only(top: SbSpace.s2),
          child: Text(text, style: t.bodySmall!.copyWith(color: c.error)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing
            ? l.jobFormTitleEdit
            : _direct
                ? l.jobFormTitleDirect(widget.workerName ?? '')
                : l.jobFormTitleNew),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
          child: SbButton(
            label: _editing ? l.jobFormSaveChanges : l.jobFormReview,
            expand: true,
            isLoading: busy,
            onPressed: busy || state.jobId != null ? null : _submit,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s4, edge, SbSpace.s8),
          children: [
            SbReadableWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_direct) ...[
                  SbInlineBanner(message: l.jobFormDirectNote(widget.workerName ?? ''), tone: SbTone.info),
                  const SizedBox(height: SbSpace.s5),
                ],
                Text(l.jobFormRequiredNote, style: t.bodySmall),
                const SizedBox(height: SbSpace.s4),
                section(l.jobFormSectionWhat, children: [
                  SbTextField(
                    label: l.jobFormTitleLabel,
                    hint: l.jobFormTitleHint,
                    requiredMarker: '*',
                    controller: _title,
                    maxLength: PostJobScreen.titleMax,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().length < PostJobScreen.titleMin ? l.jobFormTitleRequired : null,
                  ),
                  const SizedBox(height: SbSpace.s4),
                  Text.rich(TextSpan(text: l.jobFormCategoryLabel, style: t.labelLarge, children: [
                    TextSpan(text: ' *', style: TextStyle(color: c.error)),
                  ])),
                  const SizedBox(height: SbSpace.s2),
                  Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                    for (final cat in PakistanConstants.categories)
                      ChoiceChip(
                        avatar: Icon(cat['icon'] as IconData, size: 18),
                        label: Text(context.isUrdu ? cat['urdu'] as String : cat['name'] as String),
                        selected: _categoryId == cat['id'],
                        showCheckmark: false,
                        onSelected: busy ? null : (_) => setState(() => _categoryId = cat['id'] as String),
                      ),
                  ]),
                  if (_showChoiceErrors && _categoryId == null) choiceError(l.jobFormCategoryRequired),
                  const SizedBox(height: SbSpace.s4),
                  SbTextField(
                    label: l.jobFormDescriptionLabel,
                    hint: l.jobFormDescriptionHint,
                    requiredMarker: '*',
                    controller: _description,
                    maxLines: 6,
                    maxLength: PostJobScreen.descriptionMax,
                    keyboardType: TextInputType.multiline,
                    validator: (v) => (v ?? '').trim().length < PostJobScreen.descriptionMin ? l.jobFormDescriptionRequired : null,
                  ),
                ]),
                section(l.jobFormSkillsLabel, subtitle: l.jobFormSkillsHelp(PostJobScreen.maxSkills), children: [
                  Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                    for (final s in {...suggestions, ..._skills})
                      FilterChip(
                        label: Text(s),
                        selected: _skills.contains(s),
                        onSelected: busy
                            ? null
                            : (on) => on ? _addSkill(s) : setState(() => _skills.remove(s)),
                      ),
                  ]),
                  const SizedBox(height: SbSpace.s3),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: SbTextField(
                        label: l.jobFormSkillAddLabel,
                        hint: l.jobFormSkillAddHint,
                        controller: _customSkill,
                        maxLength: 30,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addSkill,
                      ),
                    ),
                    const SizedBox(width: SbSpace.s2),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: SbButton(
                        label: l.jobFormSkillAdd,
                        variant: SbButtonVariant.secondary,
                        size: SbButtonSize.compact,
                        onPressed: busy ? null : () => _addSkill(_customSkill.text),
                      ),
                    ),
                  ]),
                ]),
                section(l.jobFormSectionBudget, children: [
                  Text(l.jobFormBudgetTypeLabel, style: t.labelLarge),
                  const SizedBox(height: SbSpace.s2),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'fixed', label: Text(l.jobBudgetTypeFixed)),
                      ButtonSegment(value: 'hourly', label: Text(l.jobBudgetTypeHourly)),
                      ButtonSegment(value: 'daily', label: Text(l.jobBudgetTypeDaily)),
                    ],
                    selected: {_budgetType},
                    showSelectedIcon: false,
                    onSelectionChanged: busy ? null : (s) => setState(() => _budgetType = s.first),
                  ),
                  const SizedBox(height: SbSpace.s4),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: SbTextField(
                        label: l.jobFormBudgetMinLabel,
                        requiredMarker: '*',
                        controller: _budgetMin,
                        prefixText: 'Rs ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        validator: budgetMinError,
                      ),
                    ),
                    const SizedBox(width: SbSpace.s3),
                    Expanded(
                      child: SbTextField(
                        label: l.jobFormBudgetMaxLabel,
                        optionalLabel: l.profileOptional,
                        controller: _budgetMax,
                        prefixText: 'Rs ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        validator: budgetMaxError,
                      ),
                    ),
                  ]),
                  const SizedBox(height: SbSpace.s1),
                  Text(l.jobFormBudgetHelp, style: t.bodySmall),
                ]),
                section(l.jobFormSectionWhere, children: [
                  CityDropdown(
                    value: _city,
                    onChanged: (v) => setState(() => _city = v),
                  ),
                  if (_showChoiceErrors && _city == null) choiceError(l.jobFormCityRequired),
                  const SizedBox(height: SbSpace.s4),
                  SbTextField(
                    label: l.profileAreaLabel,
                    hint: l.jobFormAreaHint,
                    helper: l.profileAreaHelp,
                    optionalLabel: l.profileOptional,
                    controller: _area,
                    maxLength: 60,
                    prefixIcon: Icons.place_outlined,
                  ),
                ]),
                section(l.jobFormSectionWhen, children: [
                  Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                    for (final u in const ['immediate', 'within_3_days', 'flexible'])
                      ChoiceChip(
                        label: Text(urgencyLabel(l, u)),
                        selected: _urgency == u,
                        onSelected: busy ? null : (_) => setState(() => _urgency = u),
                      ),
                  ]),
                  const SizedBox(height: SbSpace.s3),
                  Row(children: [
                    Expanded(
                      child: SbButton(
                        label: _preferredDate == null
                            ? l.jobFormPreferredDateAdd
                            : l.jobFormPreferredDateValue(
                                DateFormat.yMMMEd(Localizations.localeOf(context).toLanguageTag()).format(_preferredDate!)),
                        icon: Icons.event_outlined,
                        variant: SbButtonVariant.secondary,
                        onPressed: busy ? null : _pickDate,
                      ),
                    ),
                    if (_preferredDate != null)
                      IconButton(
                        tooltip: l.jobFormPreferredDateClear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _preferredDate = null),
                      ),
                  ]),
                ]),
                // Free plan: photo uploads need the image host; without it the
                // section is shown only for a job that already has photos.
                if (ref.watch(publicPhotoUploadsProvider) || _photos.isNotEmpty)
                  section(l.jobFormSectionPhotos, subtitle: l.jobFormPhotosHelp(PostJobScreen.maxPhotos), children: [
                    _PhotoGrid(
                      photos: _photos,
                      uploading: _uploading,
                      canAdd: !busy && _photos.length < PostJobScreen.maxPhotos && ref.watch(publicPhotoUploadsProvider),
                      onAdd: _addPhoto,
                      onRemove: _removePhoto,
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

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos, required this.uploading, required this.canAdd, required this.onAdd, required this.onRemove});
  final List<String> photos;
  final bool uploading;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.sb;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SbSpace.s2,
      crossAxisSpacing: SbSpace.s2,
      children: [
        for (final url in photos)
          Stack(fit: StackFit.expand, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SbRadius.control),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
            ),
            PositionedDirectional(
              top: 2,
              end: 2,
              child: Material(
                color: c.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: l.portfolioRemove,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: Icon(Icons.close_rounded, color: c.error),
                  onPressed: () => onRemove(url),
                ),
              ),
            ),
          ]),
        if (canAdd || uploading)
          Semantics(
            button: true,
            label: l.portfolioAdd,
            child: InkWell(
              borderRadius: BorderRadius.circular(SbRadius.control),
              onTap: uploading ? null : onAdd,
              child: DottedBox(
                child: uploading
                    ? const Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
                    : Icon(Icons.add_photo_alternate_outlined, color: c.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.draft});
  final JobDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final preview = _DraftJob(draft);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: SbSpace.s1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: SbSpace.s2),
            Expanded(child: Text(text, style: t.bodyMedium)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(SbSpace.s3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(SbRadius.control)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(draft.title, style: t.titleSmall),
        const SizedBox(height: SbSpace.s2),
        row(jobCategoryIcon(draft.categoryId), jobCategoryLabel(context, draft.categoryId, draft.categoryName)),
        row(Icons.payments_outlined, jobBudgetLabel(l, preview)),
        row(Icons.place_outlined, jobAreaLabel(preview)),
        row(Icons.schedule_rounded, urgencyLabel(l, draft.urgency)),
        if (draft.skills.isNotEmpty) row(Icons.build_outlined, draft.skills.join(', ')),
      ]),
    );
  }
}

/// Lets the shared labels format a draft that isn't saved yet.
class _DraftJob extends JobEntity {
  _DraftJob(JobDraft d)
      : super(
          id: '',
          clientId: '',
          clientName: '',
          title: d.title,
          description: d.description,
          categoryId: d.categoryId,
          categoryName: d.categoryName,
          requiredSkills: d.skills,
          jobType: JobType.temporary,
          budgetMin: d.budgetMin,
          budgetMax: d.budgetMax,
          budgetType: d.budgetType,
          address: d.area,
          city: d.city,
          status: JobStatus.open,
          urgency: d.urgency,
          images: d.images,
          totalProposals: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
}

/// Edit route: loads the job, then shows the form (owners of open jobs only).
class EditJobScreen extends ConsumerWidget {
  const EditJobScreen({super.key, required this.jobId, this.initial});
  final String jobId;
  final JobEntity? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final async = initial != null ? AsyncValue<JobEntity?>.data(initial) : ref.watch(jobByIdProvider(jobId));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SbDetailSkeleton()),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: SbStateView(kind: SbStateKind.error, title: l.jobLoadError, message: l.errNetwork),
      ),
      data: (job) {
        if (job == null || job.clientId != user?.uid || job.status != JobStatus.open) {
          return Scaffold(
            appBar: AppBar(),
            body: SbStateView(kind: SbStateKind.empty, title: l.jobCannotEditTitle, message: l.jobCannotEditBody),
          );
        }
        return PostJobScreen(editJob: job);
      },
    );
  }
}
