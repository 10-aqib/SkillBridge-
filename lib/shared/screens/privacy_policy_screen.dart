import 'package:flutter/material.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// In-app privacy policy. A shorter version of PRIVACY_POLICY.md (same
/// sections and facts); update both together and bump [kPrivacyPolicyVersion].
const String kPrivacyPolicyVersion = '2026-11-22';
const String kPrivacyPolicyEffective = '22 November 2026';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(edge, SbSpace.s4, edge, SbSpace.s8),
          children: [
            SbReadableWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text('SkillBridge privacy policy', style: t.headlineSmall)),
                  const SizedBox(height: SbSpace.s2),
                  Text(
                    'Version $kPrivacyPolicyVersion · Effective $kPrivacyPolicyEffective',
                    style: t.bodySmall!.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: SbSpace.s4),
                  Container(
                    padding: const EdgeInsets.all(SbSpace.s4),
                    decoration: BoxDecoration(
                      color: c.primarySubtle,
                      borderRadius: BorderRadius.circular(SbRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('At a glance', style: t.titleMedium),
                        const SizedBox(height: SbSpace.s2),
                        for (final line in _glance) _Bullet(line),
                      ],
                    ),
                  ),
                  const SizedBox(height: SbSpace.s4),
                  for (var i = 0; i < _sections.length; i++) _SectionTile(number: i + 1, section: _sections[i]),
                  const SizedBox(height: SbSpace.s6),
                  Text(
                    'Questions or requests: Settings → Help & legal → Customer support. '
                    'We reply within 30 days.',
                    style: t.bodySmall!.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.title, this.body);
  final String title;

  /// Paragraphs; a line starting with "• " is shown as a bullet.
  final List<String> body;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.number, required this.section});
  final int number;
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: SbSpace.s2),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(SbRadius.card),
          border: Border.all(color: c.border),
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          tilePadding: const EdgeInsets.symmetric(horizontal: SbSpace.s4),
          childrenPadding: const EdgeInsets.fromLTRB(SbSpace.s4, 0, SbSpace.s4, SbSpace.s4),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text('$number. ${section.title}', style: t.titleSmall),
          children: [
            for (final p in section.body)
              p.startsWith('• ')
                  ? _Bullet(p.substring(2))
                  : Padding(
                      padding: const EdgeInsets.only(bottom: SbSpace.s2),
                      child: Text(p, style: t.bodyMedium!.copyWith(height: 1.5)),
                    ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: SbSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Text('•  ', style: t.bodyMedium)),
          Expanded(child: Text(text, style: t.bodyMedium!.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}

const _glance = <String>[
  'We collect what the marketplace needs: your account, profile, jobs, proposals, contracts, messages, reviews, photos you upload, and location when you allow it.',
  'Your phone number, email, exact address, exact location, CNIC and earnings are never on your public profile. Worker locations there are rounded to about 1.1 km. The hired worker gets the service address (and, for a direct booking, the phone number entered) only after hiring.',
  'Live location is shared only by a worker, only during an active job, only when they turn it on, and only with that job\'s client. It is deleted when that stage ends.',
  'We never collect or store fingerprints. NADRA fingerprint verification is not active.',
  'We don\'t sell personal data and show no ads. Our main service provider is Google (Firebase and Google Maps Platform).',
  'You can delete your account in Settings. Your own data is deleted; shared records keep only "Deleted user".',
];

const _sections = <_Section>[
  _Section('Who we are', [
    'SkillBridge is a local services marketplace for Pakistan that connects clients with skilled workers. SkillBridge decides how personal data in the app is used and is responsible for it (the data controller).',
  ]),
  _Section('Information we collect', [
    '• Account: email, name, phone number (required, and confirmed by an SMS code before you use the app, also after Google sign-in), role, and your Google basic profile if you use Google sign-in. Passwords are handled by Firebase Authentication; we never see them.',
    '• Profile: photo, address, city, location pin. Workers also add title, bio, category, skills, experience, rates, languages, availability, service radius, certifications (name, issuer, year) and portfolio photos.',
    '• Location: your profile location; your current position on maps (only while the app is open and you allow it); a worker\'s live location during an active job; address search text and route points.',
    '• Jobs, proposals and contracts: details, budget, city and area, photos, the service address and pin, the phone number on a direct booking, status steps, notes, submissions, evidence photos and cancellation reasons. Saved jobs.',
    '• Messages: text, photos, times sent and read.',
    '• Reviews and ratings.',
    '• Identity verification ("Get verified"): for ID document review, your CNIC number and photos of your card.',
    '• Notifications: in-app notifications, your push settings and device push tokens (up to 10 devices).',
    '• Reports you make, and messages you send to support.',
    '• Usage and diagnostics: screens viewed and key events (Firebase Analytics), crash reports (Crashlytics), and an app-integrity token (App Check), linked to your user ID.',
    'We do not collect fingerprints, card or bank details, contacts, call logs, SMS content, microphone audio, or background location.',
  ]),
  _Section('How we use it', [
    '• Create and secure your account.',
    '• Show public profiles, match clients and workers, and sort by distance.',
    '• Run jobs, proposals and contracts, including directions and live location.',
    '• Let the people working together chat.',
    '• Build trust with ratings, reviews and verification badges.',
    '• Send notifications you haven\'t turned off.',
    '• Prevent fraud and abuse, and handle reports and disputes.',
    '• Fix bugs and improve the app.',
    '• Meet legal obligations.',
    'No advertising, no marketing profiles, no automated decisions with legal effects.',
  ]),
  _Section('Legal bases', [
    'We rely on our contract with you (to provide the service), your consent (location, live sharing, push notifications, identity verification), our legitimate interests (safety, security, diagnostics) and legal obligations. We aim to follow applicable Pakistani law, including the Prevention of Electronic Crimes Act 2016. You can withdraw consent at any time.',
  ]),
  _Section('Who can see what', [
    '• Private account (email, phone, exact address and location, CNIC, push tokens, earnings, verification details): you and staff only.',
    '• Public profile (name, photo, city, badges, rating; for workers their professional details and approximate location if allowed): signed-in users.',
    '• Service address, map pin and, for direct bookings, the client\'s phone number: the client, and the hired worker after hiring.',
    '• Proposals: the worker and the job\'s client.',
    '• Contracts, evidence and live location: the two contract parties and staff.',
    '• Chats: the two members (staff only when investigating a report, dispute or legal request).',
    '• Notifications, saved jobs, preferences: you only.',
    '• Reports: the reporter and staff. The reported person isn\'t told who reported them.',
    'These limits are enforced by the server\'s security rules, not just by the app.',
  ]),
  _Section('Sharing and service providers', [
    'We never sell, rent or trade personal data.',
    '• Google Firebase (sign-in, database, file storage, server functions, push, App Check, Analytics, Crashlytics).',
    '• Google Maps Platform (maps, address search, routes; requests that need a secret key go through our server).',
    '• Google Maps app, when you open directions.',
    '• Email and WhatsApp, only if you contact support.',
    '• NADRA, only if fingerprint verification is ever authorised and switched on, and only with your consent each time (not active).',
    'We may also disclose information when the law requires it, to protect someone\'s safety, or in a merger or transfer (we\'ll tell you first).',
  ]),
  _Section('International transfers', [
    'Google\'s servers may be outside Pakistan; our server functions run in the United States. Google applies its own safeguards.',
  ]),
  _Section('Security', [
    '• All traffic uses HTTPS, and Google encrypts stored data.',
    '• Security rules deny access by default and are tested automatically.',
    '• Protected fields (badges, ratings, staff powers, identity results) can\'t be changed by users.',
    '• Staff permission is a server-side setting, and staff actions are logged.',
    '• Our servers check sign-in and inputs and apply rate limits; secrets are kept in Secret Manager.',
    '• Logs contain no message text, coordinates, tokens or CNICs.',
    '• Deleting your account or verifying identity needs a recent sign-in.',
  ]),
  _Section('How long we keep data', [
    '• Account, profile, settings, saved jobs: until you delete your account.',
    '• Jobs, proposals, contracts, reviews and chats: kept for the other people involved; your name and photo are removed if you delete your account.',
    '• Live location: only during sharing in an active job; deleted when that stage ends.',
    '• Notifications: until you delete them or your account.',
    '• Push tokens: until you sign out of that device or delete your account.',
    '• ID documents and identity records: until you or staff remove them, or you delete your account.',
    '• Analytics and crash data: as set in Firebase\'s retention settings.',
    '• On your device: signing out (or another account signing in) removes your sign-in, cached listings, recent searches and unsent actions. Your theme choice stays. The database library\'s offline copy goes when you clear the app\'s data or uninstall.',
  ]),
  _Section('Deleting your account', [
    'Settings → Account → Delete account. You need to have signed in within the last 10 minutes, and you can\'t delete while a contract is active.',
    'We delete your account, private and ID documents, public profile, saved jobs, notifications, push tokens, live location, rating summary, identity records, your photos and your sign-in. Your open jobs are cancelled and pending proposals withdrawn. Records other people keep show "Deleted user" instead of your name and photo.',
    'Uninstalling the app does not delete your account.',
  ]),
  _Section('Your rights and choices', [
    '• See and correct your data in your profile, or ask support.',
    '• Ask support for a copy of your data (we reply within 30 days).',
    '• Delete your account or individual photos, notifications and saved jobs.',
    '• Turn off location in your phone settings, stop live sharing at any time, or hide your location on your public profile (workers).',
    '• Turn push notifications off in Settings, all or by type.',
    '• Cancel identity verification before submitting.',
    '• Complain to us, then to the relevant Pakistani authority if you\'re not satisfied.',
  ]),
  _Section('Device permissions', [
    '• Location (while using the app): maps, nearby, directions, live sharing. Without it, you pick places by hand.',
    '• Camera and photos: uploading photos.',
    '• Notifications: push notifications.',
    'We never ask for background location, contacts, microphone, SMS or call logs, and never use your phone\'s fingerprint sensor or face unlock for verification.',
  ]),
  _Section('Location in detail', [
    'Location is read only while the app is open and in use. Worker locations on public profiles are rounded to about 1.1 km, and workers can hide them. Before hiring, workers see only the job\'s city and area.',
    'Live location is available only to the worker on an active contract, after they turn it on. Only that job\'s client, the worker and staff can see it. It stops when the worker stops it, signs out or the stage ends, and is then deleted. Positions older than 2 minutes show as out of date.',
    'For address search and routes, only the search text and start/end points are sent to Google, and we don\'t write coordinates to logs.',
  ]),
  _Section('Identity verification', [
    'ID document review: workers and clients can submit a CNIC number and photos of their card under "Get verified". Only they and staff can see them, and staff review them by hand. Approval shows the "Verified" badge; it is not a NADRA check. The fingerprint step says "Coming soon" and collects nothing.',
    'NADRA fingerprint verification is built but not active: SkillBridge has no NADRA access, so nothing is sent to NADRA. If it is ever switched on, it will need an approved scanner and your separate consent. Only a masked CNIC, a one-way code to stop one CNIC verifying several accounts, your consent record, status and an audit trail would be stored. The full CNIC, fingerprint images, templates, biometric hashes and raw capture data are never stored or logged.',
  ]),
  _Section('Messages, photos and files', [
    'Chats are encrypted in transit and at rest by Google, but are not end-to-end encrypted. Photos are resized on your device and must be JPEG, PNG or WebP under 2 MB.',
    'Profile, portfolio and job photos are meant to be seen by others, and anyone with a photo\'s link can open it. Chat photos stay within the conversation, evidence photos within the contract, and ID documents with you and staff.',
    'Check photos before uploading: they can show faces, house numbers or documents.',
  ]),
  _Section('Notifications and emails', [
    'Notification text is checked by our server so nobody can send you a fake one, and it never includes your CNIC. Push notifications follow your settings and stop on a device when you sign out.',
    'We send only account emails (verification, password reset) and SMS verification codes. No marketing.',
  ]),
  _Section('Payments', [
    'Clients and workers arrange payment between themselves. The EasyPaisa screen only shows instructions; SkillBridge doesn\'t process payments or collect card, bank or wallet details.',
  ]),
  _Section('Analytics, crash reports and cookies', [
    'Firebase Analytics records screens and key events, used in aggregate, never for ads. Crashlytics (mobile) records crash details. App Check confirms requests come from the genuine app.',
    'The app keeps your session, cached listings, queued actions, settings and recent searches on your device, and clears the account-related ones when you sign out. The web app uses browser storage and may set analytics cookies. There are no advertising cookies.',
  ]),
  _Section('Staff access and moderation', [
    'Staff read private data only when needed for verification, reports, disputes, fraud prevention or legal requests. Their actions are logged. Staff can suspend accounts, but can\'t set an identity-verification result.',
  ]),
  _Section('Children', [
    'SkillBridge is for adults aged 18 or over. We don\'t knowingly collect children\'s data; tell us and we\'ll delete such an account.',
  ]),
  _Section('Your responsibilities', [
    'Use other people\'s contact details, addresses and locations only for the job you\'re doing together. Don\'t copy or publish others\' information or photos, and respect clients\' homes and privacy. Misuse can lead to suspension.',
  ]),
  _Section('Security incidents', [
    'If an incident affects your data, we will contain it, tell affected users promptly (what happened, what data, what to do), and notify authorities where the law requires.',
  ]),
  _Section('Changes to this policy', [
    'We update the version and date above when this policy changes. For important changes, we\'ll tell you in the app first and ask for consent again where needed.',
  ]),
  _Section('Contact', [
    'Settings → Help & legal → Customer support (email or WhatsApp). Use the subject "Privacy request". We may ask you to confirm your identity before acting on a request.',
  ]),
];
