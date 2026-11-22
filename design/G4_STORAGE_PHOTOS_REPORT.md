# SkillBridge — Track G, Phase G4: photos in Firebase Storage

Status: **code done and tested locally; Storage rules NOT deployed.** Part of the overnight run you approved (G4–G8). Nothing committed or deployed.

Date: 21–22 Nov 2026 · Snapshot of files before G4: `design/nav/.snapshot/g4/`

## 1. What changed

| Area | Change |
|---|---|
| Public photos (profile, portfolio, job photos) | **Firebase Storage** instead of the never-configured Cloudinary host. Paths: `users/{uid}/profile/…`, `users/{uid}/portfolio/…`, `users/{uid}/jobPhotos/…`. The app stores the download link. Cloudinary code and its settings are gone. |
| Private files (chat photos, work evidence, ID documents) | **Unchanged on purpose:** they already work securely as Firestore records (≤ 700 KB, readable only by the chat members, the contract parties or the owner, plus staff; covered by existing rules tests). Moving them would mean a data migration for no security gain. |
| Validation | Name/MIME must say JPEG, PNG or WebP, **and the file's first bytes must match** (a renamed executable is refused). Size limit 2 MB; empty files refused. Photos are resized on the device (profile photo ≤ 1024 px, quality 85). |
| Profile photo control | A sheet with **Take photo / Choose from gallery / Remove photo** (remove only when there is a photo). The upload shows a **progress ring and a cancel button**. Order of steps: upload → save `photoUrl` → only then delete the old file. If the save fails, the *new* file is deleted and the old photo is kept. **Remove** asks first, clears `photoUrl` (initials avatar shows) and deletes the file. A missing file is fine. |
| Deleting | `deleteOwned` deletes only links that point into the person's **own** `profile/portfolio/jobPhotos` folder. A Google account photo or anyone else's file is never touched. |
| Display everywhere | `photoUrl` on the account → the public profile follows automatically (existing account listener). A new link each time, so cached images update at once. Copies stored on jobs, proposals and contracts are refreshed by a server trigger in **G5**. |
| Switch | Photo uploads show when the Firebase app has a Storage bucket (it does: `skill-bridge-c68c3.firebasestorage.app`). Build with `--dart-define=PHOTO_UPLOADS=off` to hide them in a build that must run before Storage is enabled. |
| New strings (English + Urdu) | Remove photo, the confirmation, photo removed, upload cancelled, cancel upload. |

## 2. Storage rules (`storage.rules`)
- Public photo folders: **read by anyone** (shown on public profiles and jobs). **Create** only by the owner: JPEG/PNG/WebP, 0 < size < 2 MB, file name `[A-Za-z0-9._-]{1,100}`, never over an existing file. **Delete** only by the owner.
- **Removed** the old catch-all `users/{uid}/{anyFolder}/**` (it allowed PDFs and any folder) and the public `users/{uid}/{file}` rule. Production Storage was never enabled, so no existing files are affected.
- Verification documents, contract evidence and chat-photo rules unchanged. The default rule is deny-all.

## 3. Tests run
| Check | Result |
|---|---|
| Rules (Firestore + Storage emulators) | **166 passed / 0 failed**. New cases: PDF/GIF/SVG refused, 2 MB refused, overwrite refused, bad name refused, other folders and files directly under `users/{uid}` refused, owner-only delete, signed-out upload refused. |
| `test/unit/free_plan_s6_media_test.dart` (rewritten) | **11 passed**: Storage link parsing, own-folder check, byte sniffing, upload routing per folder with progress, refusals before upload, cancel and permission errors, delete delegation, private 700 KB limit. |
| `test/widget/profile_photo_test.dart` (new) | **6 passed**: gallery → resized pick → upload → save → old file deleted; failed save → new file deleted, old kept; progress shown and cancel works (nothing saved); renamed non-image refused; remove flow with confirmation; no remove option without a photo, plain avatar when uploads are off. |
| `dart analyze` | 0 errors. |
| Packages | `image_picker_platform_interface` became a dev dependency (same locked version). No other version changed. |

**Not verified:** a real upload to the production bucket (Storage isn't enabled until Blaze).

## 4. To go live (account owner)
1. Blaze on → Firebase console → **Storage → Get started** (default bucket `skill-bridge-c68c3.firebasestorage.app`, a region near Pakistan if offered).
2. Deploy rules: `firebase deploy --only storage` (only after reviewing; see the setup guide for the full order).
3. Old Cloudinary: nothing to do (it was never configured).
