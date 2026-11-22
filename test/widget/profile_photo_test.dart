import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/domain/usecases/auth_usecases.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';

import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

// Profile photo (Phase G4): take/choose, upload with progress and cancel,
// save, clean up the old file; remove. Storage is a fake host here.

final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(200, 7)]);

class _NoDb extends Fake implements FirebaseFirestore {}

class _Picker extends ImagePickerPlatform {
  XFile? next;
  ImageSource? lastSource;
  ImagePickerOptions? lastOptions;
  @override
  Future<XFile?> getImageFromSource({required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) async {
    lastSource = source;
    lastOptions = options;
    return next;
  }
}

class _Host implements ImageHost {
  final uploads = <String>[];
  final deletes = <String>[];
  Completer<void>? gate;
  UploadCancel? lastCancel;

  @override
  Future<String> upload(Uint8List bytes,
      {required String contentType,
      required String uid,
      required String folder,
      required String fileName,
      void Function(double progress)? onProgress,
      UploadCancel? cancel}) async {
    lastCancel = cancel;
    onProgress?.call(0.4);
    if (gate != null) await gate!.future;
    if (cancel?.isCancelled ?? false) throw const ImageHostException('cancelled');
    uploads.add('$uid/$folder/$fileName');
    return 'https://firebasestorage.googleapis.com/v0/b/b/o/users%2F$uid%2F$folder%2F$fileName?alt=media&token=t';
  }

  @override
  Future<void> deleteOwned({required String uid, required String url}) async => deletes.add(url);
}

class _Update implements UpdateUserProfileUseCase {
  final calls = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Either<Failure, void>> call({required String uid, required Map<String, dynamic> data}) async {
    calls.add(data);
    return fail ? const Left(ServerFailure()) : const Right(null);
  }
}

const _oldUrl = 'https://firebasestorage.googleapis.com/v0/b/b/o/users%2Fw1%2Fprofile%2Fold.jpg?alt=media&token=t';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  late _Picker picker;
  late _Host host;
  late _Update update;

  Future<void> pump(WidgetTester tester, UserEntity user, {bool uploads = true}) async {
    picker = _Picker();
    ImagePickerPlatform.instance = picker;
    host = _Host();
    update = _Update();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(testApp(
      overrides: [
        imageHostProvider.overrideWithValue(uploads ? host : null),
        firestoreProvider.overrideWithValue(_NoDb()),
        updateUserProfileUseCaseProvider.overrideWithValue(update),
      ],
      home: Scaffold(body: Center(child: ProfilePhotoPicker(user: user))),
    ));
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('choose from gallery: resized on the device, uploaded to the profile folder, saved, old file deleted', (tester) async {
    await pump(tester, testUser('w1', role: 'worker').copyWith(photoUrl: _oldUrl));
    picker.next = XFile.fromData(_jpeg, name: 'me.jpg', mimeType: 'image/jpeg');
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    await tester.tap(find.text(l.mediaChooseFromGallery));
    await settle(tester);
    expect(picker.lastSource, ImageSource.gallery);
    expect(picker.lastOptions!.maxWidth, 1024);
    expect(picker.lastOptions!.imageQuality, 85);
    expect(host.uploads.single, startsWith('w1/profile/avatar_'));
    expect((update.calls.single['photoUrl'] as String), contains('users%2Fw1%2Fprofile%2Favatar_'));
    expect(host.deletes, [_oldUrl], reason: 'previous upload removed after the save');
    expect(find.text(l.profilePhotoUpdated), findsOneWidget);
  });

  testWidgets('if saving the profile fails, the new upload is deleted and the old photo kept', (tester) async {
    await pump(tester, testUser('w1', role: 'worker').copyWith(photoUrl: _oldUrl));
    update.fail = true;
    picker.next = XFile.fromData(_jpeg, name: 'me.jpg', mimeType: 'image/jpeg');
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    await tester.tap(find.text(l.mediaChooseFromGallery));
    await settle(tester);
    expect(host.deletes.single, contains('avatar_'), reason: 'the new file, not the old one');
    expect(host.deletes, isNot(contains(_oldUrl)));
    expect(find.text(l.profileSaveFailed), findsOneWidget);
  });

  testWidgets('progress is shown and the upload can be cancelled: nothing saved', (tester) async {
    await pump(tester, testUser('w1', role: 'worker'));
    host.gate = Completer<void>();
    picker.next = XFile.fromData(_jpeg, name: 'me.jpg', mimeType: 'image/jpeg');
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    await tester.tap(find.text(l.mediaChooseFromGallery));
    await settle(tester);
    final ring = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    expect(ring.value, 0.4);
    await tester.tap(find.byTooltip(l.mediaCancelUpload));
    host.gate!.complete();
    await settle(tester);
    expect(host.lastCancel!.isCancelled, isTrue);
    expect(update.calls, isEmpty);
    expect(find.text(l.mediaUploadCancelled), findsOneWidget);
  });

  testWidgets('a renamed non-image is refused before upload', (tester) async {
    await pump(tester, testUser('w1', role: 'worker'));
    picker.next = XFile.fromData(Uint8List.fromList('MZ fake exe'.codeUnits), name: 'me.jpg', mimeType: 'image/jpeg');
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    await tester.tap(find.text(l.mediaChooseFromGallery));
    await settle(tester);
    expect(host.uploads, isEmpty);
    expect(update.calls, isEmpty);
    expect(find.text(l.mediaUnsupportedType), findsOneWidget);
  });

  testWidgets('remove: asks first, clears photoUrl, deletes the file', (tester) async {
    await pump(tester, testUser('w1', role: 'worker').copyWith(photoUrl: _oldUrl));
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    await tester.tap(find.text(l.profileRemovePhoto));
    await settle(tester);
    expect(find.text(l.profileRemovePhotoConfirm), findsOneWidget);
    await tester.tap(find.text(l.profileRemovePhoto).last);
    await settle(tester);
    expect(update.calls.single, {'photoUrl': null});
    expect(host.deletes, [_oldUrl]);
    expect(find.text(l.profilePhotoRemoved), findsOneWidget);
  });

  testWidgets('no photo: no remove option; uploads off: a plain avatar, not a button', (tester) async {
    await pump(tester, testUser('w1', role: 'worker'));
    await tester.tap(find.bySemanticsLabel(l.profileChangePhoto));
    await settle(tester);
    expect(find.text(l.profileRemovePhoto), findsNothing);
    await pump(tester, testUser('w1', role: 'worker'), uploads: false);
    expect(find.bySemanticsLabel(l.profileChangePhoto), findsNothing);
  });
}
