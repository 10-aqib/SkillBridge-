# SkillBridge — Free plan, Phase S6: photos and files without Firebase Storage

Status: **implemented and tested locally, including the real app code against the real rules on the emulator. Nothing deployed, committed or pushed.** With S6 done, **the app needs neither Cloud Functions nor Firebase Storage.** Awaiting your approval for Phase S7 (full verification).

## 1. Where each kind of file goes now (your choices)

| Files | Before | Now | Who can see them |
|---|---|---|---|
| Profile photo, portfolio, job photos (public) | Firebase Storage | **Image host (Cloudinary)**, unsigned upload; the app stores the https link | Anyone with the link, as on any public profile or job |
| **CNIC / ID documents** | Storage, owner and staff | **Private in Firestore**: `users/{uid}/verificationDocs/{id}` | **Only the worker and staff** (rules) |
| **Chat photos** | Storage, chat members | **Private in Firestore**: `chats/{chat}/media/{message}_p{n}` | **Only the two members** and staff |
| **Work-evidence photos** | Storage, the two parties | **Private in Firestore**: `contracts/{id}/evidence/{photo}` | **Only the client and worker** and staff |

**Private files:**
- **Size:** each is at most **700 KB**, because a Firestore document holds at most 1 MiB. Photos are shrunk when picked: chat and evidence photos to 1280 px at 70% quality, ID documents to 1400 px at 70%. A PDF document must already be under 700 KB.
- **Type:** only JPEG, PNG or WebP images, plus PDF for ID documents.
- **Upload limits:** chat photos come only from a member, as themselves, and only for that message. Evidence comes only from the hired worker while the work is in progress, as on Storage.
- **Never replaced:** once stored, a file can't be overwritten.
- **Messages and submissions** may only point at their own chat's or contract's files, and only ones that exist.

**Public photos:**
- **Off until you add the image host.** The default build has no image host, so the "change photo", "add portfolio photo" and "add job photo" controls are **hidden**, not left as buttons that can't work. Everything else works.
- **To turn them on**, build with the two settings below (on the command line, or in `.env` with `--dart-define-from-file=.env`):

```
CLOUDINARY_CLOUD_NAME=<your cloud name>
CLOUDINARY_UPLOAD_PRESET=<your unsigned preset>
```
- **What the preset allows:** images only (jpg, png, webp), 2 MB, folder `skillbridge/`. The app checks the 2 MB limit and the type before uploading. Uploads go to `skillbridge/{profile|portfolio|jobs}/{uid}/`, and the app accepts only `https://res.cloudinary.com/…` links back.
- **The API secret is never needed and must never be added.**

## 2. Problems found (fixed)
- **The rules evaluation limit.** Firestore evaluates at most 1,000 expressions per rule check, and the contract step from S4 is large. Adding the evidence check there pushed "submit" over the limit. The check now lives on the submission record, which is checked separately and must match the contract's photo list exactly. **Worth knowing for later:** the contract step is close to that limit, so new branches should go into separate documents like this.
- **Building document paths from a full string** (`chats/x/media/y`) doesn't work in rules lookups. They're now built from their parts.
- "Too large" messages said 5 MB. They now say the photo is too large even after shrinking, or 2 MB for public photos, in English and Urdu.

## 3. Trade-offs (stated plainly)
- **Firestore free quota:** viewing a private photo reads up to 700 KB. The free plan allows 50,000 document reads and 10 GiB of transfer a month, which is plenty for an FYP-sized app, but heavy photo use would count.
- **Old public photos can't be deleted from the app** with an unsigned preset: replacing a profile photo leaves the old one on the host. Staff can delete these from the Cloudinary dashboard.
- **No staff screen shows ID documents**, before or after this change. The admin web only changes the status. Staff can check a document in the Firebase console (a byte field). A viewer could be added to the admin web later.
- **Older data:** chat photos, evidence and documents uploaded earlier to Storage (if any exist) point at Storage paths the free plan can't serve.

## 4. Tests

| Check | Result |
|---|---|
| Rules tests (emulator) | **164 / 164 passed**: 159 before plus 5 new. Chat photos: only members, only as themselves, ≤ 700 KB, images only, the id matches its message, never replaced, outsiders can't read. A message may show only the sender's own existing photos for that message; 7 bad cases are refused. Evidence: only the hired worker while in progress, ≤ 700 KB, never replaced; the client reads it and outsiders can't. A submission may show only this contract's own existing evidence. ID documents: owner adds, owner and staff read, type and fields checked, owner may remove. The verification record accepts the new document place. |
| **Real app code vs real rules** (probe, emulator) | **12 / 12 passed**: public uploads off by default ("not-configured"); a CNIC photo stored privately and submitted for verification; a document over 700 KB refused; a client can't read the ID document; a chat photo stored then sent; the other member sees it (bytes match); an outsider can't read it; no evidence before work starts; evidence stored and submitted with the work; the client sees it; an outsider can't. |
| App unit tests (new) | **9 / 9**: image host off unless both settings are set; odd characters refused; the default build has uploads off; the upload is unsigned to the right account and folder with no secret, and returns an https link; a refused upload or unexpected link is an error; public photos need the host; they go to the host per person and kind; over 2 MB or the wrong type is refused before upload; the private 700 KB limit is checked before writing. |
| Full `flutter test` | **504 / 504 passed** (495 + 9 new). One older test checked the 5 MB Storage limit; it now checks the 2 MB image-host limit. |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |

## 5. Files
- New: `lib/core/media/image_host.dart`, `lib/core/media/private_media.dart`, `test/unit/free_plan_s6_media_test.dart`.
- `profile_media_service.dart`: public photos to the host; ID documents private.
- `chat_remote_datasource.dart` (CRLF kept): private photos.
- `contract_remote_datasource.dart`: private evidence.
- `contract_providers.dart`: no Storage.
- `profile_media_widgets.dart`, `post_job_screen.dart` (CRLF kept): upload controls hidden until configured; picker size settings.
- `chat_room_screen.dart` (CRLF), `submit_work_screen.dart`, `verification_screen.dart`: shrink private photos.
- `verification_service.dart`: comments.
- `app_en.arb`, `app_ur.arb` and generated l10n: 2 new strings, 4 updated.
- `firestore.rules`: private file rules for chat media, evidence and ID documents; attachment checks.
- `rules-tests/rules.test.js`: 5 new tests, 1 rewritten.
- Probe (outside the repo): `scratchpad/e2e/entry/s6_probe.dart`. Snapshot: `design/spark/.snapshot/s6/`.

`storage.rules` and the `firebase_storage` package are untouched: unused on the free plan, ready if Blaze becomes possible.
