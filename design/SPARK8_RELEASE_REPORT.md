# SkillBridge — Free plan, Phase S8: release

Status: **released.** The free-plan rules are live in production, and v1.1.0 is on GitHub for anyone to download. This ends the free-plan track (S1–S8).

## 1. What was done

| Step | Result |
|---|---|
| Production admins (read-only check, Admin SDK) | **One staff account, already holding the `SUPER_ADMIN` claim**, so admin access carries over to the new rules unchanged. **No account had given itself admin** while the old hole was open. Production has 8 accounts (4 workers, 3 clients, 1 without a role). No claims were changed. |
| Backfills | **Skipped:** with 8 accounts, each app fills in its own public profile and counts the next time it's opened. |
| Version | **1.1.0+2** (pubspec). |
| Release APK | Built (72.8 MB), signed with the development key as before. |
| Code | Committed as `f812790`, "Run on the free Firebase plan (no Cloud Functions, no Storage)", and pushed to `ui-improvements-2026` and `main`. No secrets: both `.env` files are git-ignored. |
| **Firestore rules and indexes** | **Deployed to `skill-bridge-c68c3`** (`firestore:rules,firestore:indexes`; allowed on the free plan). This replaces the old rules plus the 14 Nov hotfix. Spot check after deploy: signed-out reads of accounts, public profiles, contracts and ratings are refused (403). |
| **GitHub release v1.1.0** | https://github.com/10-aqib/SkillBridge-/releases/tag/v1.1.0 is marked **latest**. Asset `SkillBridge-v1.1.0.apk` uploaded (76,318,705 bytes, the same as the build). |
| v1.0.0 | Renamed "SkillBridge v1.0.0 (replaced by v1.1.0)", marked as pre-release, with a notice at the top asking people to install v1.1.0. It no longer works with the server. |

The connection dropped while I was re-downloading the APK to compare checksums; GitHub's reported asset size and "uploaded" state confirm the upload instead.

## 2. Still open (your choice; nothing started)
1. **Google Play:**
   - Decide on the upload key: I create it, or you provide one.
   - The US$25 Play Console account.
   - A privacy policy at a public URL (I can draft it, and GitHub Pages hosts it free).
   - A signed `.aab`, the data-safety form and the location declaration.
   - Keep App Check enforcement off while APKs are also distributed outside Play.
2. **Public photo uploads:** add `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET` (unsigned preset: images only, 2 MB, folder `skillbridge/`), then rebuild.
3. **Admin web hosting:** Firebase's framework hosting needs Blaze, so run it locally, or host it on a free Next.js host with the service-account key as a server secret.
4. **Deployed earlier and now unused:** nothing. No functions or Storage were ever deployed.

## 3. How to roll back (if ever needed)
Redeploy the previous rules from git (`git show 6d047f2:firestore.rules`), or the hotfix copy in `design/spark/LIVE_HOTFIX_2026-11-14.rules`. Only v1.0.0 fits those rules, so the release would have to be switched back too. Rolling back is not recommended: the old rules were the permissive ones.
