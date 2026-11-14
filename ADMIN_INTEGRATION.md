# SkillBridge Centralized Admin Integration

## Overview
The SkillBridge platform has been unified under a single Firebase backend, servicing the Flutter mobile application, the public website, and a secured centralized Admin Dashboard accessible via `/adminpanel`. This integration eliminates the need for isolated admin data and provides live, secure production data management capabilities to authorized super-administrators.

## Architecture

- **Backend:** Firebase (Firestore, Authentication, Cloud Storage).
- **Mobile Client:** Flutter App (uses standard Firebase Client SDK).
- **Admin Dashboard:** Next.js Server-rendered Web App, hosted securely on the `/adminpanel` route.
- **Admin Authentication:** Firebase Client SDK for initial login, validated server-side by Firebase Admin SDK generating a secure HTTP-only session cookie.
- **Role-Based Access Control (RBAC):** Next.js middleware and API routes verify the custom `SUPER_ADMIN` Custom Claim attached to a user's Firebase Auth token.

```
                         FIREBASE BACKEND
                            |
           ---------------------------------
           |               |               |
     Flutter App      Public Website    Admin Panel
                                      (/adminpanel)
```

## Security & RBAC Configuration

### 1. Custom Claims Authentication
Super administrators are verified using Firebase Auth Custom Claims. 
The custom claim `role: 'SUPER_ADMIN'` is used to define privileged access.
To provision the very first Super Admin:
- Configure the environment variable `SETUP_SECRET` on your server.
- Send a `POST` request to `/api/setup-admin` with the body `{"email": "your_email@example.com", "secret": "YOUR_SECRET_KEY"}`.
- This will assign the `SUPER_ADMIN` claim to the respective Firebase user.

### 2. Next.js Route Protection
All routes under `/adminpanel/*` (excluding `/adminpanel/login`) are protected by Next.js `middleware.ts`.
- Unauthenticated users are redirected to `/adminpanel/login`.
- A secure HTTP-only `session` cookie handles authentication across requests.

### 3. API Route Protection
Any administrative operations hitting `/api/admin/*` must pass:
1. Session existence check.
2. Verification of the token by Firebase Admin SDK.
3. Verification that the `decodedClaims.role === 'SUPER_ADMIN'`.

### 4. Firestore Rules
Firestore Security Rules (`firestore.rules`) have been updated to check the custom claim directly:
```javascript
function isAdmin() {
  return isAuthenticated() && 
    (request.auth.token.role == 'admin' || request.auth.token.role == 'SUPER_ADMIN');
}
function isSuperAdmin() {
  return isAuthenticated() && request.auth.token.role == 'SUPER_ADMIN';
}
```

### 5. Storage Security Rules
Verification documents (e.g., driver's licenses, certifications) are shielded from public access while still allowing authorized Admin/Backend APIs to view them using `storage.rules`:
```javascript
match /users/{userId} {
  // Sensitive verification documents
  match /verificationDocuments/{documentId} {
    allow read: if isOwner(userId);
    allow write: if isOwner(userId) && (isImage() || isPdf()) && isValidSize();
  }
}
```

## Audit Logging

An un-tamperable audit trail has been implemented. Any destructive or critical administrative action (such as suspending users or verifying workers) writes a record to the `auditLogs` Firestore collection using the server-side Admin SDK.
- Action Type
- Target User ID
- Actor ID (The Admin who performed the action)
- Timestamp
- Reason (if provided)

## Admin Features Available

- **User Management:** View all users, inspect profiles, and suspend/restore accounts. Suspended users will immediately lose access on the Flutter app when their token refreshes.
- **Worker Verification:** Approve or revoke worker verification statuses. These changes are instantly reflected on the mobile app's worker listings.
- **Jobs & Reports:** Live access to all active and completed jobs, dispute reports, and platform metrics directly fed from Firestore.

## Deployment Notes

To deploy the unified system:
1. Ensure all Firebase service account credentials (`FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_PROJECT_ID`) are configured securely in your hosting provider (e.g. Vercel) for the Next.js application.
2. Provide the `SETUP_SECRET` environment variable for initial admin bootstrapping if not done already.
3. The Admin dashboard can be deployed as part of your main website repository or on a designated subdomain matching the `/adminpanel` routing scheme.

---
*Setup completed and validated by Antigravity*
