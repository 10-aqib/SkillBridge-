# SkillBridge Admin Dashboard Implementation Record

## Inspection summary
- Existing portal: Next.js 16 App Router in `super_admin_web`.
- Data: Firebase Auth, Cloud Firestore, Firebase Storage, Cloud Functions; server services use Firebase Admin SDK.
- Existing admin areas: dashboard, users, workers, jobs/contracts, reports, audit logs, and settings.
- Key gaps: pages trust cookie presence without server verification; role enforcement is inconsistent; report moderation uses fabricated records; several controls are inert or hardcoded; dashboard date filters do not affect metrics.

## Implementation decisions
- Keep the existing Next.js app and Firebase project/integrations.
- Use verified Firebase session claims for protected server rendering and mutations; retain middleware/proxy only for optimistic redirects.
- Keep admin operations on server-side Firebase Admin SDK and write audit entries for privileged actions.
- Replace report sample data with the app's existing Firestore `reports` collection.
- Preserve the existing SkillBridge blue visual language while improving responsive layout and making controls functional.

## Planned phases
1. Secure protected routes and normalize admin-role checks.
2. Improve responsive admin shell and live dashboard controls/data.
3. Connect functional user, worker, and job tools to server actions/APIs.
4. Implement real report moderation and audit-log filtering/export.
5. Validate with lint/build and record remaining environment limits.

## Modified files
- This record is created before implementation; append modified files and validation results as work proceeds.
