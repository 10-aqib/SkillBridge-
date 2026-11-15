import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Lets the person choose camera or gallery (gallery only on web).
Future<XFile?> pickProfileImage(BuildContext context, {bool allowCamera = true, double maxSide = 1600, int quality = 85}) async {
  final l = context.l10n;
  ImageSource? source = ImageSource.gallery;
  if (allowCamera && !kIsWeb) {
    source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.mediaTakePhoto),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.mediaChooseFromGallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
  }
  if (source == null) return null;
  try {
    return await ImagePicker().pickImage(source: source, maxWidth: maxSide, maxHeight: maxSide, imageQuality: quality);
  } catch (_) {
    if (context.mounted) _snack(context, l.mediaPickerUnavailable, error: true);
    return null;
  }
}

String mediaErrorText(AppLocalizations l, Object e) {
  if (e is MediaUploadException) {
    return switch (e.code) {
      'too-large' => l.mediaTooLarge,
      'too-large-private' => l.mediaTooLargePrivate,
      'not-configured' => l.mediaNotConfigured,
      'unsupported-type' => l.mediaUnsupportedType,
      'permission-denied' => l.mediaPermissionDenied,
      _ => l.mediaUploadFailed,
    };
  }
  return l.mediaUploadFailed;
}

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? context.sb.error : null,
    ));
}

/// Avatar with a "change photo" control. Uploads to Storage and saves photoUrl
/// on the profile; replaces (and cleans up) the previous upload.
class ProfilePhotoPicker extends ConsumerStatefulWidget {
  const ProfilePhotoPicker({super.key, required this.user, this.size = 96, this.onUpdated});

  final UserEntity user;
  final double size;
  final VoidCallback? onUpdated;

  @override
  ConsumerState<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends ConsumerState<ProfilePhotoPicker> {
  bool _busy = false;

  Future<void> _change() async {
    final l = context.l10n;
    final file = await pickProfileImage(context);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    final media = ref.read(profileMediaServiceProvider);
    try {
      final previous = widget.user.photoUrl;
      final url = await media.uploadProfilePhoto(uid: widget.user.uid, file: file);
      final result = await ref
          .read(updateUserProfileUseCaseProvider)
          .call(uid: widget.user.uid, data: {'photoUrl': url});
      if (!mounted) return;
      await result.fold(
        (_) async => _snack(context, l.profileSaveFailed, error: true),
        (_) async {
          if (previous != null && previous != url) {
            // Old upload only — Google photos and other external URLs are kept.
            try {
              await media.deleteOwnedByUrl(uid: widget.user.uid, url: previous);
            } catch (_) {}
          }
          if (mounted) _snack(context, l.profilePhotoUpdated);
          widget.onUpdated?.call();
        },
      );
    } catch (e) {
      if (mounted) _snack(context, mediaErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final l = context.l10n;
    // Free plan: without the image host the photo can't be changed, so it is
    // shown as a plain avatar (no camera badge, not a button).
    final canChange = ref.watch(publicPhotoUploadsProvider);
    if (!canChange) {
      return SbAvatar(name: widget.user.displayName, imageUrl: widget.user.photoUrl, size: widget.size);
    }
    return Semantics(
      button: true,
      label: l.profileChangePhoto,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : _change,
        child: Stack(clipBehavior: Clip.none, children: [
          SbAvatar(name: widget.user.displayName, imageUrl: widget.user.photoUrl, size: widget.size),
          if (_busy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.scrim.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: Center(
                  child: SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onPrimary),
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            end: -2,
            bottom: -2,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
              child: Icon(Icons.photo_camera_outlined, size: 18, color: c.onPrimary),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Work photos: grid with add / remove. Each change is saved immediately to
/// workerProfile.portfolioImages (public by design — these are shown on the
/// public profile).
class PortfolioManager extends ConsumerStatefulWidget {
  const PortfolioManager({super.key, required this.user, this.maxImages = 12});

  final UserEntity user;
  final int maxImages;

  @override
  ConsumerState<PortfolioManager> createState() => _PortfolioManagerState();
}

class _PortfolioManagerState extends ConsumerState<PortfolioManager> {
  bool _uploading = false;
  final Set<String> _removing = {};

  List<String> get _images => widget.user.workerProfile?.portfolioImages ?? const [];

  Future<bool> _save(List<String> images) async {
    final profile = widget.user.workerProfile;
    if (profile == null) return false;
    final map = WorkerProfileModel.fromEntity(profile).toMap()..['portfolioImages'] = images;
    final result = await ref
        .read(updateUserProfileUseCaseProvider)
        .call(uid: widget.user.uid, data: {'workerProfile': map});
    return result.isRight();
  }

  Future<void> _add() async {
    final l = context.l10n;
    final file = await pickProfileImage(context);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(profileMediaServiceProvider).uploadPortfolioImage(uid: widget.user.uid, file: file);
      final ok = await _save([..._images, url]);
      if (!mounted) return;
      if (ok) {
        _snack(context, l.portfolioAdded);
      } else {
        // Don't leave an orphaned file if the profile update failed.
        await ref.read(profileMediaServiceProvider).deleteOwnedByUrl(uid: widget.user.uid, url: url);
        if (mounted) _snack(context, l.profileSaveFailed, error: true);
      }
    } catch (e) {
      if (mounted) _snack(context, mediaErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _remove(String url) async {
    final l = context.l10n;
    final confirmed = await showSbConfirmSheet(
      context,
      title: l.portfolioRemoveTitle,
      message: l.portfolioRemoveBody,
      confirmLabel: l.portfolioRemove,
      cancelLabel: l.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _removing.add(url));
    final ok = await _save(_images.where((u) => u != url).toList());
    if (ok) {
      try {
        await ref.read(profileMediaServiceProvider).deleteOwnedByUrl(uid: widget.user.uid, url: url);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _removing.remove(url));
    _snack(context, ok ? l.portfolioRemoved : l.profileSaveFailed, error: !ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final images = _images;
    final canAdd = images.length < widget.maxImages && widget.user.workerProfile != null;
    // Free plan: without the image host nothing can be added; say so instead
    // of showing an empty grid.
    if (images.isEmpty && !ref.watch(publicPhotoUploadsProvider)) {
      return Text(l.mediaNotConfigured, style: t.bodyMedium!.copyWith(color: c.textSecondary));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.portfolioCount(images.length, widget.maxImages), style: t.bodySmall),
      const SizedBox(height: SbSpace.s3),
      GridView.count(
        crossAxisCount: SbWindowSize.of(context) == SbWindowSize.compact ? 3 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: SbSpace.s2,
        crossAxisSpacing: SbSpace.s2,
        children: [
          for (final url in images)
            Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(SbRadius.control),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SbSkeleton(height: double.infinity, radius: SbRadius.control),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: c.surfaceSunken,
                    child: Icon(Icons.broken_image_outlined, color: c.textSecondary),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 4,
                end: 4,
                child: _removing.contains(url)
                    ? const SizedBox.square(dimension: 32, child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Material(
                        color: c.surface.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: l.portfolioRemove,
                          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(Icons.delete_outline_rounded, color: c.error),
                          onPressed: () => _remove(url),
                        ),
                      ),
              ),
            ]),
          if (canAdd && ref.watch(publicPhotoUploadsProvider))
            Semantics(
              button: true,
              label: l.portfolioAdd,
              child: InkWell(
                borderRadius: BorderRadius.circular(SbRadius.control),
                onTap: _uploading ? null : _add,
                child: DottedBox(
                  child: _uploading
                      ? const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, color: c.primary),
                          const SizedBox(height: SbSpace.s1),
                          Text(l.portfolioAdd, style: t.labelMedium!.copyWith(color: c.primary), textAlign: TextAlign.center),
                        ]),
                ),
              ),
            ),
        ],
      ),
      if (widget.user.workerProfile == null)
        Padding(
          padding: const EdgeInsets.only(top: SbSpace.s3),
          child: SbInlineBanner(message: l.portfolioNeedsProfile, tone: SbTone.info),
        ),
    ]);
  }
}

/// Bordered placeholder tile for "add" actions.
class DottedBox extends StatelessWidget {
  const DottedBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    return Container(
      decoration: BoxDecoration(
        color: c.primarySubtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(SbRadius.control),
        border: Border.all(color: c.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: child,
    );
  }
}

/// Shown while the account's email is unverified: resend + "I've verified".
class EmailVerificationCard extends ConsumerWidget {
  const EmailVerificationCard({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.isEmailVerified || user.email.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final state = ref.watch(emailVerificationViewModelProvider);
    final vm = ref.read(emailVerificationViewModelProvider.notifier);

    String? note;
    SbTone tone = SbTone.info;
    if (state.failure != null) {
      note = l.errGeneric;
      tone = SbTone.error;
    } else if (state.verified == false) {
      note = l.verifyEmailStillPending;
      tone = SbTone.warning;
    } else if (state.sent) {
      note = l.verifyEmailSent;
    }

    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: c.warningSubtle,
        borderRadius: BorderRadius.circular(SbRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.mark_email_unread_outlined, color: c.onWarningSubtle),
          const SizedBox(width: SbSpace.s2),
          Expanded(child: Text(l.verifyEmailTitle, style: t.titleSmall!.copyWith(color: c.onWarningSubtle))),
        ]),
        const SizedBox(height: SbSpace.s1),
        Text(l.verifyEmailBody(user.email), style: t.bodyMedium!.copyWith(color: c.onWarningSubtle)),
        if (note != null) ...[
          const SizedBox(height: SbSpace.s3),
          SbInlineBanner(message: note, tone: tone),
        ],
        const SizedBox(height: SbSpace.s3),
        Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
          SbButton(
            label: l.verifyEmailCheck,
            size: SbButtonSize.compact,
            isLoading: state.isChecking,
            onPressed: vm.refresh,
          ),
          SbButton(
            label: l.verifyEmailResend,
            size: SbButtonSize.compact,
            variant: SbButtonVariant.secondary,
            isLoading: state.isSending,
            onPressed: state.sent ? null : vm.resend,
          ),
        ]),
      ]),
    );
  }
}
