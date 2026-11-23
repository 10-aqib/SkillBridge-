// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Skill Bridge';

  @override
  String get greeting => 'Hello';

  @override
  String greetingWithName(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get continueText => 'Continue';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get selectRole => 'Select Your Role';

  @override
  String get selectRoleSubtitle => 'How do you want to use SkillBridge?';

  @override
  String get client => 'Client';

  @override
  String get worker => 'Worker';

  @override
  String get clientDescription => 'I want to hire skilled workers for my jobs';

  @override
  String get workerDescription => 'I want to offer my skills and find work';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get chats => 'Chats';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get searchPlaceholder => 'Search electrician, plumber...';

  @override
  String get allCategories => 'All';

  @override
  String get topRatedNearYou => 'Top rated near you';

  @override
  String get seeAll => 'See all';

  @override
  String get verified => 'Verified';

  @override
  String yearsExperience(int years) {
    return '$years yrs experience';
  }

  @override
  String get perHour => '/hr';

  @override
  String get perDay => '/day';

  @override
  String get fixed => 'Fixed';

  @override
  String get postJob => 'Post a Job';

  @override
  String get jobType => 'Job Type';

  @override
  String get temporary => 'Temporary';

  @override
  String get permanent => 'Permanent';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get location => 'Location';

  @override
  String get budget => 'Budget (PKR)';

  @override
  String get budgetRange => 'Budget Range';

  @override
  String get submitJob => 'Post Job';

  @override
  String get urgency => 'Urgency';

  @override
  String get normal => 'Normal';

  @override
  String get urgent => 'Urgent';

  @override
  String get myJobs => 'My Jobs';

  @override
  String get activeJobs => 'Active';

  @override
  String get completedJobs => 'Completed';

  @override
  String get cancelledJobs => 'Cancelled';

  @override
  String get openJobs => 'Open';

  @override
  String get inProgress => 'In Progress';

  @override
  String get proposals => 'Proposals';

  @override
  String get submitProposal => 'Submit Proposal';

  @override
  String get coverLetter => 'Cover Letter';

  @override
  String get proposedRate => 'Proposed Rate';

  @override
  String get estimatedDuration => 'Estimated Duration';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get contracts => 'Contracts';

  @override
  String get activeContracts => 'Active';

  @override
  String get completedContracts => 'Completed';

  @override
  String get contractDetails => 'Contract Details';

  @override
  String get message => 'Message';

  @override
  String get hireForJob => 'Hire for a Job';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get reviews => 'Reviews';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get rating => 'Rating';

  @override
  String get comment => 'Comment';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get viewAll => 'View all';

  @override
  String get skills => 'Skills';

  @override
  String get about => 'About';

  @override
  String get experience => 'Experience';

  @override
  String get certifications => 'Certifications';

  @override
  String get availability => 'Availability';

  @override
  String get available => 'Available';

  @override
  String get busy => 'Busy';

  @override
  String get offline => 'Offline';

  @override
  String get hourlyRate => 'Hourly Rate';

  @override
  String get dailyRate => 'Daily Rate';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get payment => 'Payment';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get jazzcash => 'JazzCash';

  @override
  String get easypaisa => 'EasyPaisa';

  @override
  String get nearbyWorkers => 'Nearby Workers';

  @override
  String get filterResults => 'Filter Results';

  @override
  String get sortBy => 'Sort By';

  @override
  String get distance => 'Distance';

  @override
  String get ratingFilter => 'Rating';

  @override
  String get experienceFilter => 'Experience';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get noChats => 'No conversations yet';

  @override
  String get noJobs => 'No jobs found';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get loading => 'Loading...';

  @override
  String get currency => 'PKR';

  @override
  String get currencySymbol => 'Rs';

  @override
  String currencyFormat(String amount) {
    return 'Rs $amount';
  }

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get customerSupport => 'Customer Support';

  @override
  String get chatOnWhatsApp => 'Chat on WhatsApp';

  @override
  String get whatsappNotInstalled => 'WhatsApp is not installed.';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get termsContent =>
      'By using SkillBridge, you agree to our terms of service.\n\n1. Users must provide accurate information.\n2. Payments must be processed through the app or directly as agreed.\n3. SkillBridge is not liable for disputes between workers and clients.\n4. Respect and professionalism are required at all times.';

  @override
  String viewReceivedProposals(int count) {
    return 'View Received Proposals ($count)';
  }

  @override
  String get receivedProposals => 'Received Proposals';

  @override
  String get appTagline => 'Local expertise, made easier to trust.';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOr => 'or';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String onboardingStepOf(int step, int total, String label) {
    return 'Step $step of $total · $label';
  }

  @override
  String get validationEmailRequired => 'Enter your email address.';

  @override
  String get validationEmailInvalid =>
      'Enter a valid email, like name@example.com.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get validationPasswordWeak =>
      'Use at least 8 characters, including a number.';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get validationNameRequired => 'Enter your full name.';

  @override
  String get validationNameLength => 'Name must be 2–60 characters.';

  @override
  String get validationPhoneInvalid =>
      'Enter a Pakistani mobile number, like 300 1234567.';

  @override
  String get errInvalidCredential => 'Email or password is incorrect.';

  @override
  String get errEmailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get errUserDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get errSuspended => 'Your account is suspended. Contact support.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errNetwork => 'No connection. Check your internet and try again.';

  @override
  String get errTimeout =>
      'This is taking too long. Check your connection and try again.';

  @override
  String get errAccountExistsDifferent =>
      'This email is registered with a different sign-in method.';

  @override
  String get errOperationNotAllowed =>
      'This sign-in method isn\'t available right now.';

  @override
  String get errRoleLocked => 'This account already has a role.';

  @override
  String get errSignInAgain => 'Please sign in again to continue.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get welcomeTitle =>
      'Find trusted local help, or get hired for your skills';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get welcomeSignIn => 'I already have an account';

  @override
  String get welcomePointTrust => 'Verified profiles and real reviews';

  @override
  String get welcomePointNearby => 'Skilled workers near you, across Pakistan';

  @override
  String get welcomePointChat => 'Chat and agree the price before booking';

  @override
  String get welcomeTermsPrefix => 'By continuing you agree to our';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue to SkillBridge.';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginSigningIn => 'Signing in';

  @override
  String get loginNoAccount => 'New to SkillBridge?';

  @override
  String get signupTitleClient => 'Create a client account';

  @override
  String get signupTitleWorker => 'Create a worker account';

  @override
  String get signupSubtitleClient => 'Hire trusted workers near you.';

  @override
  String get signupSubtitleWorker => 'Get found by clients near you.';

  @override
  String get signupRoleQuestion => 'I want to';

  @override
  String get roleClientTitle => 'Hire workers';

  @override
  String get roleClientDesc => 'Post jobs and book trusted people nearby.';

  @override
  String get roleWorkerTitle => 'Find work';

  @override
  String get roleWorkerDesc => 'Offer your skills and get hired for jobs.';

  @override
  String get signupNameLabel => 'Full name';

  @override
  String get signupNameHint => 'e.g. Tariq Mahmood';

  @override
  String get signupPhoneLabel => 'Mobile number';

  @override
  String get signupPhoneHint => '300 1234567';

  @override
  String get signupPhoneHelp => 'Used so clients and workers can reach you.';

  @override
  String get signupPasswordHelp => 'At least 8 characters, including a number.';

  @override
  String get signupConfirmPasswordLabel => 'Confirm password';

  @override
  String get signupAgree =>
      'I agree to the Terms & Conditions and Privacy policy';

  @override
  String get signupReadTerms => 'Read';

  @override
  String get signupAgreeRequired =>
      'Please accept the Terms & Conditions and Privacy policy to continue.';

  @override
  String get signupButton => 'Create account';

  @override
  String get signupCreating => 'Creating your account';

  @override
  String get signupHaveAccount => 'Already have an account?';

  @override
  String get roleSelectTitle => 'How will you use SkillBridge?';

  @override
  String get roleSelectSubtitle =>
      'Choose one to finish setting up your account.';

  @override
  String get roleSelectSaving => 'Saving';

  @override
  String get roleSelectDifferentAccount => 'Use a different account';

  @override
  String roleSelectSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get roleSelectRequired => 'Choose client or worker to continue.';

  @override
  String get roleSelectPermanentNote =>
      'This can\'t be changed later, so pick the one that fits you.';

  @override
  String get roleSelectSignedOutTitle => 'You are not signed in';

  @override
  String get roleSelectSignedOutBody =>
      'Sign in or create an account to continue.';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotSubtitle =>
      'Enter the email you signed up with and we\'ll send you a reset link.';

  @override
  String get forgotSend => 'Send reset link';

  @override
  String get forgotSending => 'Sending';

  @override
  String get forgotSentTitle => 'Check your email';

  @override
  String forgotSentBody(String email) {
    return 'If an account exists for $email, a reset link is on its way. Open it, choose a new password, then sign in.';
  }

  @override
  String get forgotSentTip => 'Can\'t find it? Check your spam folder.';

  @override
  String get forgotResend => 'Resend link';

  @override
  String forgotResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgotBackToSignIn => 'Back to sign in';

  @override
  String get forgotDifferentEmail => 'Use a different email';

  @override
  String get otpTitle => 'Verify your phone';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code we sent to $phone.';
  }

  @override
  String get otpCodeLabel => 'Verification code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpSent => 'Code sent.';

  @override
  String get otpError =>
      'That code didn\'t work. Check it or request a new one.';

  @override
  String get otpVerified => 'Phone number verified.';

  @override
  String get mediaTakePhoto => 'Take a photo';

  @override
  String get mediaChooseFromGallery => 'Choose from gallery';

  @override
  String get mediaPickerUnavailable => 'Couldn\'t open the camera or gallery.';

  @override
  String get mediaTooLarge => 'That file is over 2 MB. Choose a smaller one.';

  @override
  String get mediaTooLargePrivate =>
      'That photo is too large even after shrinking. Try another photo.';

  @override
  String get mediaNotConfigured => 'Photo uploads aren\'t available yet.';

  @override
  String get mediaUnsupportedType => 'Use a JPG, PNG or WebP image.';

  @override
  String get mediaPermissionDenied =>
      'You don\'t have permission to upload this file.';

  @override
  String get mediaUploadFailed =>
      'Upload failed. Check your connection and try again.';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save your profile. Please try again.';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profileChangePhoto => 'Change profile photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profileRemovePhotoConfirm => 'Remove your profile photo?';

  @override
  String get profileRemovePhotoBody => 'People will see your initials instead.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String get mediaUploadCancelled => 'Upload cancelled.';

  @override
  String get mediaCancelUpload => 'Cancel upload';

  @override
  String get portfolioAdd => 'Add photo';

  @override
  String get portfolioAdded => 'Photo added to your work.';

  @override
  String get portfolioRemove => 'Remove photo';

  @override
  String get portfolioRemoveTitle => 'Remove this photo?';

  @override
  String get portfolioRemoveBody =>
      'It will no longer appear on your public profile.';

  @override
  String get portfolioRemoved => 'Photo removed.';

  @override
  String portfolioCount(int count, int max) {
    return '$count of $max photos';
  }

  @override
  String get portfolioNeedsProfile =>
      'Finish your professional details first, then add work photos.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a link to $email. Verifying helps protect your account.';
  }

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String get verifyEmailSent => 'Verification email sent.';

  @override
  String get verifyEmailCheck => 'I\'ve verified';

  @override
  String get verifyEmailStillPending =>
      'Not verified yet. Open the link in the email, then try again.';

  @override
  String get availabilityHelp => 'Clients see this on your profile.';

  @override
  String get availabilityAvailableNote =>
      'Clients can find and message you for new work.';

  @override
  String get availabilityBusyNote =>
      'Shown as busy. Clients can still message you.';

  @override
  String get availabilityOfflineNote =>
      'Shown as offline until you switch back.';

  @override
  String get onboardingStepYou => 'You';

  @override
  String get onboardingStepContact => 'Contact';

  @override
  String get onboardingStepLocation => 'Location';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get onboardingSkipStep => 'Skip this step';

  @override
  String get onboardingFinish => 'Finish';

  @override
  String get onboardingPhotoHint =>
      'A clear photo helps workers recognise you.';

  @override
  String get clientOnboardingYouTitle => 'Tell us about you';

  @override
  String get clientOnboardingYouBody => 'Add your name and a photo.';

  @override
  String get clientOnboardingContactTitle => 'How can workers reach you?';

  @override
  String get clientOnboardingContactBody =>
      'Your number is shared only with workers you hire.';

  @override
  String get clientOnboardingPhoneHelp =>
      'You can change this later in your profile.';

  @override
  String get clientOnboardingLocationTitle => 'Where do you need help?';

  @override
  String get clientOnboardingLocationBody =>
      'We use your city to show workers near you.';

  @override
  String completeTitle(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get completeFix => 'Complete';

  @override
  String get completeAddPhoto =>
      'Add a profile photo so clients can recognise you.';

  @override
  String get completeAddWork =>
      'Add your title, trade and a short description.';

  @override
  String get completeAddSkills => 'Add the skills clients search for.';

  @override
  String get completeAddRate => 'Add an hourly or daily rate.';

  @override
  String get completeAddArea => 'Set the area you work in.';

  @override
  String get completeAddPhotos => 'Add photos of your work.';

  @override
  String get completeVerify =>
      'Verify your identity to earn the Verified badge.';

  @override
  String get profileAreaLabel => 'Area or neighbourhood';

  @override
  String get profileAreaHint => 'e.g. G-11, Islamabad';

  @override
  String get profileAreaHelp =>
      'Don\'t enter your house number. Exact addresses are shared only for booked jobs.';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileCityHint => 'Select your city';

  @override
  String get profileContactDetails => 'Contact details';

  @override
  String get profileEmailReadOnly =>
      'Your email is your sign-in and can’t be changed here.';

  @override
  String get profileHires => 'Hires';

  @override
  String get profileJobsPosted => 'Jobs posted';

  @override
  String get profileLocationLabel => 'Location';

  @override
  String get profileNoName => 'Add your name';

  @override
  String get profileNoReviews => 'No reviews yet';

  @override
  String get profileNoReviewsBody =>
      'Reviews appear here after completed jobs.';

  @override
  String get profileNotAdded => 'Not added';

  @override
  String get profileOptional => '(optional)';

  @override
  String profileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get profileReviewsError => 'Reviews couldn\'t load';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileVerifyPhone => 'Verify';

  @override
  String get publicProfileTitle => 'Worker profile';

  @override
  String get publicProfileLoadError => 'This profile couldn\'t load';

  @override
  String get publicProfileNotFound => 'Profile not available';

  @override
  String get publicProfileNotFoundBody =>
      'This worker may have removed their profile.';

  @override
  String get publicProfileOwnPreview => 'This is how clients see your profile.';

  @override
  String get publicProfilePreview => 'See public profile';

  @override
  String get publicProfileWorkTab => 'Work photos';

  @override
  String get publicProfileNew => 'New';

  @override
  String get publicProfileJobsDone => 'Jobs done';

  @override
  String get publicProfileMemberSince => 'Member since';

  @override
  String get publicProfilePriceNote =>
      'Final price is agreed in chat before booking.';

  @override
  String get publicProfileNoBio => 'No description added yet.';

  @override
  String get publicProfileServiceArea => 'Service area';

  @override
  String publicProfileAreaValue(String city, int km) {
    return '$city · within $km km';
  }

  @override
  String get publicProfileAreaPrivacy =>
      'Approximate area. Exact locations are shared only for booked jobs.';

  @override
  String get publicProfileNoPhotos => 'No work photos yet';

  @override
  String publicProfilePhotoN(int n, int total) {
    return 'Work photo $n of $total';
  }

  @override
  String get publicProfileRequestBooking => 'Request booking';

  @override
  String get publicProfileRatingReviews => 'Rating & reviews';

  @override
  String get publicProfileRecentReviews => 'Recent reviews';

  @override
  String rateHourly(String price) {
    return '$price / hour';
  }

  @override
  String rateDaily(String price) {
    return '$price / day';
  }

  @override
  String get rateOnRequest => 'Rate on request';

  @override
  String get reportProfile => 'Report profile';

  @override
  String get reportProfileTitle => 'Why are you reporting this profile?';

  @override
  String get reportReasonSafety => 'Safety concern';

  @override
  String get reportReasonMisleading => 'Misleading profile or credentials';

  @override
  String get reportReasonConduct => 'Inappropriate conduct';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportSubmitted => 'Report sent. Our team will review it.';

  @override
  String get reportFailed => 'Couldn\'t send the report. Please try again.';

  @override
  String get reviewsSortRecent => 'Most recent';

  @override
  String get reviewsSortHighest => 'Highest rating';

  @override
  String get reviewsSortLowest => 'Lowest rating';

  @override
  String reviewsHelpful(int count) {
    return 'Helpful ($count)';
  }

  @override
  String reviewsReplyFrom(String name) {
    return 'Reply from $name';
  }

  @override
  String get reviewsReplyTitle => 'Reply to review';

  @override
  String get reviewsReplyHint => 'Write a polite, helpful reply…';

  @override
  String get reviewsReplySubmit => 'Post reply';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsHelp => 'Help & legal';

  @override
  String get settingsSupportBody => 'Chat with us on WhatsApp or email.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushAll => 'Push notifications';

  @override
  String get settingsPushAllBody =>
      'Alerts on this phone. Your in-app notifications always work.';

  @override
  String get settingsPushMessages => 'New messages';

  @override
  String get settingsPushWork => 'Jobs, proposals and contracts';

  @override
  String get settingsSaveFailed =>
      'The setting couldn\'t be saved. Check your connection.';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordBody =>
      'We\'ll email you a link to set a new password.';

  @override
  String get settingsPasswordEmailSent =>
      'Check your email for a link to change your password.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, photos, saved jobs, notifications and sign-in. People you worked with keep their records of past jobs, shown as \"Deleted user\". This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete my account';

  @override
  String get deleteAccountWorking => 'Deleting your account…';

  @override
  String get deleteAccountDone => 'Your account was deleted.';

  @override
  String get deleteAccountRecentLogin =>
      'For your safety, sign in again, then delete your account.';

  @override
  String get deleteAccountSignInAgain => 'Sign in again';

  @override
  String get deleteAccountActive =>
      'Finish or cancel your active contracts first.';

  @override
  String get deleteAccountUnavailable =>
      'Account deletion isn\'t available right now. Please contact support.';

  @override
  String get deleteAccountFailed =>
      'The account couldn\'t be deleted. Please try again.';

  @override
  String get savedJobsTitle => 'Saved jobs';

  @override
  String get savedJobsEmptyTitle => 'No saved jobs';

  @override
  String get savedJobsEmptyBody => 'Tap the bookmark on a job to keep it here.';

  @override
  String get savedJobsLoadError => 'Saved jobs couldn\'t be loaded.';

  @override
  String get jobBookmarkAdd => 'Save job';

  @override
  String get jobBookmarkRemove => 'Remove from saved';

  @override
  String get jobBookmarkSaved => 'Job saved.';

  @override
  String get jobBookmarkRemoved => 'Removed from saved jobs.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out of SkillBridge?';

  @override
  String get signOutConfirmBody =>
      'You\'ll need to sign in again to see your jobs and messages.';

  @override
  String get verificationTitle => 'Identity verification';

  @override
  String get verificationBadge => 'ID documents reviewed';

  @override
  String get verificationOpen => 'Open';

  @override
  String get verificationLoadError => 'Verification status couldn\'t load';

  @override
  String get verificationIntroTitle => 'Get the Verified badge';

  @override
  String get verificationIntroBody =>
      'Verified profiles show others that SkillBridge checked their identity.';

  @override
  String get verificationPendingTitle => 'Under review';

  @override
  String get verificationPendingShort => 'Verification pending';

  @override
  String get verificationPendingBody =>
      'Our team is reviewing your documents. You will be notified when it’s done.';

  @override
  String get verificationVerifiedTitle => 'You are verified';

  @override
  String get verificationVerifiedBody =>
      'People see the Verified badge on your profile.';

  @override
  String get verificationRejectedTitle => 'Not approved';

  @override
  String get verificationRejectedBody =>
      'We couldn\'t verify these documents. Please submit clear photos again.';

  @override
  String verificationCnicOnFile(String cnic) {
    return 'CNIC: $cnic';
  }

  @override
  String verificationDocsOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String verificationSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get verificationUpdate => 'Update submission';

  @override
  String get verificationCnicLabel => 'CNIC number';

  @override
  String get verificationCnicHelp =>
      'Kept private. Only SkillBridge staff can see it.';

  @override
  String get verificationCnicInvalid =>
      'Enter 13 digits, like 35202-1234567-1.';

  @override
  String get verificationDocsTitle => 'Documents';

  @override
  String get verificationDocsHelp =>
      'Clear photos, all four corners visible. Photos are shrunk automatically; a PDF must be under 700 KB.';

  @override
  String get verificationDocFront => 'CNIC — front';

  @override
  String get verificationDocBack => 'CNIC — back';

  @override
  String get verificationDocExtra => 'Trade certificate';

  @override
  String get verificationRequired => 'Required';

  @override
  String get verificationUpload => 'Upload';

  @override
  String get verificationReplace => 'Replace';

  @override
  String get verificationUploaded => 'Uploaded';

  @override
  String verificationUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get verificationDocMissing => 'Upload this document.';

  @override
  String get verificationConsent =>
      'These documents are mine, and SkillBridge staff may review them to verify my identity.';

  @override
  String get verificationConsentRequired => 'Please confirm to continue.';

  @override
  String get verificationSubmit => 'Submit for review';

  @override
  String get verificationSubmitted =>
      'Submitted. We’ll let you know once it’s reviewed.';

  @override
  String get verificationSubmitFailed =>
      'Couldn\'t submit. Check your connection and try again.';

  @override
  String get verificationPrivacyNote =>
      'Your CNIC and documents are stored privately. They never appear on your public profile.';

  @override
  String get verificationLegacyNotice =>
      'An older version saved your CNIC on your public profile. You can remove that copy.';

  @override
  String get verificationLegacyRemove => 'Remove from public profile';

  @override
  String get verificationLegacyRemoveTitle =>
      'Remove CNIC from your public profile?';

  @override
  String get verificationLegacyRemoveBody =>
      'This deletes the old public copy only. Submit your CNIC below to keep it private.';

  @override
  String get verificationLegacyRemoved => 'Removed from your public profile.';

  @override
  String get workerProfileNotStarted => 'Not set up yet.';

  @override
  String get workerProfileRate => 'Rate';

  @override
  String get workerSetupStepWork => 'Your work';

  @override
  String get workerSetupStepRates => 'Rates & area';

  @override
  String get workerSetupStepPhotos => 'Work photos';

  @override
  String get workerSetupStepVerify => 'Verification';

  @override
  String get workerSetupYouTitle => 'Let clients know who you are';

  @override
  String get workerSetupYouBody => 'A real photo and name build trust.';

  @override
  String get workerSetupPhotoHint => 'Use a clear photo of your face.';

  @override
  String get workerSetupPhoneHelp =>
      'Clients you work with can call you on this number.';

  @override
  String get workerSetupWorkTitle => 'What do you do?';

  @override
  String get workerSetupWorkBody => 'Clients search by trade and skills.';

  @override
  String get workerSetupHeadlineLabel => 'Professional title';

  @override
  String get workerSetupHeadlineHint => 'e.g. Certified electrician, 9 years';

  @override
  String get workerSetupHeadlineRequired =>
      'Add a title of at least 8 characters.';

  @override
  String get workerSetupCategoryRequired => 'Choose your main trade.';

  @override
  String get workerSetupSkillsRequired => 'Choose or add at least one skill.';

  @override
  String get workerSetupAddSkill => 'Add another skill';

  @override
  String get workerSetupAddSkillHint => 'e.g. Solar wiring';

  @override
  String get workerSetupAdd => 'Add';

  @override
  String get workerSetupExperienceLabel => 'Years of experience';

  @override
  String get workerSetupExperienceInvalid => 'Enter a number from 0 to 60.';

  @override
  String get workerSetupBioLabel => 'About your work';

  @override
  String get workerSetupBioHint =>
      'What you do best, tools you bring, areas you cover…';

  @override
  String get workerSetupBioRequired => 'Write at least 30 characters.';

  @override
  String get workerSetupLanguages => 'Languages';

  @override
  String get workerSetupRatesTitle => 'Rates and service area';

  @override
  String get workerSetupRatesBody =>
      'Clients see your rate before contacting you.';

  @override
  String get workerSetupRateInvalid =>
      'Enter an amount above zero, or leave it empty.';

  @override
  String get workerSetupRateNote =>
      'Leave both empty to show “Rate on request”.';

  @override
  String get workerSetupServiceArea => 'Where you work';

  @override
  String get workerSetupNoLocation => 'No location set';

  @override
  String get workerSetupPickLocation => 'Set on map';

  @override
  String get workerSetupAreaRequired => 'Set your location or choose a city.';

  @override
  String workerSetupRadius(int km) {
    return 'Travel up to $km km';
  }

  @override
  String get workerSetupLocationPrivacy =>
      'Clients see your city and travel distance, not your address.';

  @override
  String get workerSetupPhotosTitle => 'Show your work';

  @override
  String get workerSetupPhotosBody =>
      'Photos of real jobs help clients choose you.';

  @override
  String get workerSetupVerifyTitle => 'Get verified';

  @override
  String get workerSetupVerifyBody => 'Optional, and it can be done later.';

  @override
  String get workerSetupVerifyPoint1 => 'Clients trust verified workers more.';

  @override
  String get workerSetupVerifyPoint2 =>
      'Your CNIC stays private — only staff see it.';

  @override
  String get workerSetupVerifyPoint3 => 'It takes about two minutes.';

  @override
  String get workerSetupVerifyNow => 'Verify my identity';

  @override
  String get workerSetupSaveContinue => 'Save & continue';

  @override
  String get jobBand15kTo50k => 'Rs 15,000 – 50,000';

  @override
  String get jobBand2kTo5k => 'Rs 2,000 – 5,000';

  @override
  String get jobBand5kTo15k => 'Rs 5,000 – 15,000';

  @override
  String get jobBandOver50k => 'Rs 50,000+';

  @override
  String get jobBandUnder2k => 'Under Rs 2,000';

  @override
  String get jobBudget => 'Budget';

  @override
  String jobBudgetFixedPrice(String amount) {
    return '$amount · Fixed price';
  }

  @override
  String get jobBudgetNotSet => 'Budget on request';

  @override
  String jobBudgetPerDay(String amount) {
    return '$amount / day';
  }

  @override
  String jobBudgetPerHour(String amount) {
    return '$amount / hour';
  }

  @override
  String get jobBudgetTypeDaily => 'Per day';

  @override
  String get jobBudgetTypeFixed => 'Fixed price';

  @override
  String get jobBudgetTypeHourly => 'Per hour';

  @override
  String get jobCannotEditBody => 'Only open jobs you posted can be edited.';

  @override
  String get jobCannotEditTitle => 'This job can\'t be edited';

  @override
  String get jobClientEmailVerified => 'Email verified';

  @override
  String get jobClientFallback => 'SkillBridge client';

  @override
  String get jobClose => 'Close job';

  @override
  String get jobCloseBody =>
      'Workers will no longer see it. It stays in your history and you can reopen it later.';

  @override
  String get jobCloseTitle => 'Close this job?';

  @override
  String get jobClosed => 'Job closed.';

  @override
  String get jobClosedNotice =>
      'This job is closed. Workers can no longer find it.';

  @override
  String jobConfirmBody(String city) {
    return 'Workers in $city will be able to find it. You can edit or close it later.';
  }

  @override
  String jobConfirmDirectBody(String name) {
    return '$name will get your request and can accept or decline it.';
  }

  @override
  String jobConfirmDirectTitle(String name) {
    return 'Send this request to $name?';
  }

  @override
  String get jobConfirmKeepEditing => 'Keep editing';

  @override
  String get jobConfirmPublish => 'Publish job';

  @override
  String get jobConfirmSend => 'Send request';

  @override
  String get jobConfirmTitle => 'Publish this job?';

  @override
  String get jobDescription => 'Description';

  @override
  String get jobDetailsTitle => 'Job details';

  @override
  String get jobDirectRequestLabel => 'Requested from';

  @override
  String jobDirectTo(String name) {
    return 'Request to $name';
  }

  @override
  String get jobEdit => 'Edit';

  @override
  String get jobFeedBudget => 'Budget';

  @override
  String get jobFeedClearAll => 'Clear all';

  @override
  String get jobFeedClearSearch => 'Clear search';

  @override
  String get jobFeedEmptyBody =>
      'When clients post jobs, they will appear here. Pull down to check again.';

  @override
  String get jobFeedEmptyTitle => 'No open jobs yet';

  @override
  String get jobFeedEnd => 'You\'ve seen all matching jobs.';

  @override
  String get jobFeedErrorIndex =>
      'Search for this combination is being set up. Try fewer filters for now.';

  @override
  String get jobFeedErrorPermission =>
      'Your account can\'t browse jobs right now.';

  @override
  String get jobFeedErrorTitle => 'Couldn\'t load jobs';

  @override
  String get jobFeedFilters => 'Filters';

  @override
  String get jobFeedLoadMore => 'Load more';

  @override
  String get jobFeedLoadMoreFailed => 'Couldn\'t load more. Tap to try again.';

  @override
  String get jobFeedNoMatchBody => 'Try another word, or remove a filter.';

  @override
  String get jobFeedNoMatchTitle => 'No jobs match';

  @override
  String get jobFeedPosted => 'Posted';

  @override
  String jobFeedRemoveFilter(String label) {
    return 'Remove $label';
  }

  @override
  String get jobFeedSearchHint => 'Search jobs, e.g. wiring, plumber';

  @override
  String get jobFeedSearching => 'Searching…';

  @override
  String get jobFeedShowResults => 'Show results';

  @override
  String jobFeedShowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
      zero: 'No jobs',
    );
    return '$_temp0';
  }

  @override
  String get jobFeedSkillsNeedCategory =>
      'Choose a category to filter by skills.';

  @override
  String get jobFeedSort => 'Sort';

  @override
  String get jobFeedTitle => 'Find work';

  @override
  String get jobFormAreaHint => 'e.g. Gulberg III';

  @override
  String get jobFormBudgetHelp =>
      'Leave “Up to” empty for a single amount. Final price is agreed with the worker.';

  @override
  String get jobFormBudgetMaxInvalid =>
      '“Up to” must be at least the first amount.';

  @override
  String get jobFormBudgetMaxLabel => 'Up to';

  @override
  String get jobFormBudgetMinLabel => 'Amount';

  @override
  String get jobFormBudgetRequired => 'Enter an amount above 0.';

  @override
  String get jobFormBudgetTooHigh => 'Enter up to Rs 10,000,000.';

  @override
  String get jobFormBudgetTypeLabel => 'How will you pay?';

  @override
  String get jobFormCategoryLabel => 'Category';

  @override
  String get jobFormCategoryRequired => 'Choose a category.';

  @override
  String get jobFormCityRequired => 'Choose your city.';

  @override
  String get jobFormDescriptionHint =>
      'What needs doing, what you\'ve noticed, and anything the worker should bring.';

  @override
  String get jobFormDescriptionLabel => 'Describe the work';

  @override
  String get jobFormDescriptionRequired =>
      'Add at least 30 characters so workers understand the job.';

  @override
  String jobFormDirectNote(String name) {
    return 'Only $name will see this request.';
  }

  @override
  String get jobFormFixErrors => 'Please fix the highlighted fields.';

  @override
  String jobFormPhotosHelp(int max) {
    return 'Optional. Up to $max clear photos of the problem.';
  }

  @override
  String get jobFormPreferredDateAdd => 'Add a preferred date (optional)';

  @override
  String get jobFormPreferredDateClear => 'Remove date';

  @override
  String jobFormPreferredDateValue(String date) {
    return 'Preferred: $date';
  }

  @override
  String get jobFormRequiredNote => 'Fields marked * are required.';

  @override
  String get jobFormReview => 'Review and publish';

  @override
  String get jobFormSaveChanges => 'Save changes';

  @override
  String get jobFormSectionBudget => 'Budget';

  @override
  String get jobFormSectionPhotos => 'Photos';

  @override
  String get jobFormSectionWhat => 'What do you need?';

  @override
  String get jobFormSectionWhen => 'When';

  @override
  String get jobFormSectionWhere => 'Where';

  @override
  String get jobFormSkillAdd => 'Add';

  @override
  String get jobFormSkillAddHint => 'e.g. Gas leak check';

  @override
  String get jobFormSkillAddLabel => 'Another skill';

  @override
  String jobFormSkillsHelp(int max) {
    return 'Pick the skills the job needs (up to $max).';
  }

  @override
  String get jobFormSkillsLabel => 'Skills needed';

  @override
  String get jobFormSkillsMax => 'You can add up to 10 skills.';

  @override
  String jobFormTitleDirect(String name) {
    return 'Request $name';
  }

  @override
  String get jobFormTitleEdit => 'Edit job';

  @override
  String get jobFormTitleHint => 'e.g. Fix two kitchen sockets';

  @override
  String get jobFormTitleLabel => 'Job title';

  @override
  String get jobFormTitleNew => 'Post a job';

  @override
  String get jobFormTitleRequired => 'Add a title of at least 10 characters.';

  @override
  String get jobLoadError => 'Couldn\'t load this job';

  @override
  String jobMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get jobMessageClient => 'Message client';

  @override
  String get jobMessageFailed => 'Couldn\'t open the chat. Please try again.';

  @override
  String get jobNoProposalsYet => 'No proposals yet';

  @override
  String get jobNotClient => 'Only client accounts can post jobs.';

  @override
  String get jobOwnerPanelTitle => 'Your job';

  @override
  String get jobPostedAnyTime => 'Any time';

  @override
  String get jobPostedBy => 'Posted by';

  @override
  String jobPostedDaysAgo(int days) {
    return 'Posted $days days ago';
  }

  @override
  String get jobPostedLast24h => 'Last 24 hours';

  @override
  String get jobPostedLast30Days => 'Last 30 days';

  @override
  String get jobPostedLast3Days => 'Last 3 days';

  @override
  String get jobPostedLast7Days => 'Last 7 days';

  @override
  String jobPostedOn(String date) {
    return 'Posted $date';
  }

  @override
  String get jobPostedToday => 'Posted today';

  @override
  String get jobPostedYesterday => 'Posted yesterday';

  @override
  String jobPreferredOn(String date) {
    return 'Preferred $date';
  }

  @override
  String jobProposalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proposals',
      one: '1 proposal',
    );
    return '$_temp0';
  }

  @override
  String get jobPublishFailed =>
      'Couldn\'t publish the job. Check your connection and try again.';

  @override
  String get jobPublished => 'Job published. Workers can now find it.';

  @override
  String get jobQueuedOffline =>
      'You\'re offline. The job is saved on this phone and will publish when you\'re back online.';

  @override
  String get jobReopen => 'Reopen';

  @override
  String get jobReopenBody => 'Workers will be able to find it again.';

  @override
  String get jobReopenTitle => 'Reopen this job?';

  @override
  String get jobReopened => 'Job reopened.';

  @override
  String get jobReport => 'Report job';

  @override
  String get jobReportInappropriate => 'Inappropriate content';

  @override
  String get jobReportMisleading => 'Misleading or fake job';

  @override
  String get jobReportScam => 'Scam or fraud';

  @override
  String get jobReportTitle => 'Why are you reporting this job?';

  @override
  String get jobSaved => 'Changes saved.';

  @override
  String get jobSortBudgetHigh => 'Budget: high to low';

  @override
  String get jobSortBudgetLow => 'Budget: low to high';

  @override
  String get jobSortNewest => 'Newest';

  @override
  String get jobSortOldest => 'Oldest';

  @override
  String get jobStatusAssigned => 'Assigned';

  @override
  String get jobStatusClosed => 'Closed';

  @override
  String get jobStatusCompleted => 'Completed';

  @override
  String get jobStatusInProgress => 'In progress';

  @override
  String get jobStatusOpen => 'Open';

  @override
  String get jobSuspended =>
      'Your account is suspended, so you can\'t post jobs.';

  @override
  String get jobSuspendedNotice =>
      'Your account is suspended. You can view jobs but not act on them.';

  @override
  String get jobUnavailableBody => 'It may have been closed or filled.';

  @override
  String get jobUnavailableTitle => 'This job is no longer available';

  @override
  String get jobUrgencyFlexible => 'Flexible';

  @override
  String get jobUrgencyImmediate => 'Urgent';

  @override
  String get jobUrgencyThreeDays => 'Within 3 days';

  @override
  String get jobView => 'View';

  @override
  String get myJobsEmptyBody =>
      'Post a job and nearby workers will be able to find it.';

  @override
  String get myJobsEmptyTitle => 'You haven\'t posted a job yet';

  @override
  String get myJobsLoadError => 'Couldn\'t load your jobs';

  @override
  String get myJobsTabActive => 'Active';

  @override
  String get myJobsTabEmpty => 'No jobs here.';

  @override
  String get myJobsTitle => 'My jobs';

  @override
  String jobSortBudgetWithin(String sort, String type) {
    return '$sort · $type';
  }

  @override
  String get jobFeedBudgetSortNote =>
      'Budget order compares jobs of one pay type at a time.';

  @override
  String get myProposalsTitle => 'My proposals';

  @override
  String get myProposalsLoadError => 'Couldn\'t load your proposals';

  @override
  String get myProposalsEmptyTitle => 'No proposals yet';

  @override
  String get myProposalsEmptyBody =>
      'Find an open job and send your price and a short note to the client.';

  @override
  String get myProposalsFindWork => 'Find work';

  @override
  String get myProposalsTabEmpty => 'No proposals here.';

  @override
  String get proposalStatusPending => 'Pending';

  @override
  String get proposalStatusViewed => 'Viewed';

  @override
  String get proposalStatusAccepted => 'Accepted';

  @override
  String get proposalStatusFilled => 'Job filled';

  @override
  String get proposalStatusDeclined => 'Declined';

  @override
  String get proposalStatusWithdrawn => 'Withdrawn';

  @override
  String get proposalTabActive => 'Active';

  @override
  String get proposalTabNotSelected => 'Not selected';

  @override
  String proposalRating(String rating, int count) {
    return '★ $rating ($count reviews)';
  }

  @override
  String proposalExperience(int years) {
    return '$years yrs experience';
  }

  @override
  String get proposalViewProfile => 'View profile';

  @override
  String get proposalFormTitle => 'Send a proposal';

  @override
  String get proposalFormTitleAgain => 'Send proposal again';

  @override
  String get proposalOnlyWorkers => 'Only workers can send proposals';

  @override
  String get proposalOnlyWorkersBody =>
      'Sign in with a worker account to apply for jobs.';

  @override
  String get proposalSuspended => 'Your account is suspended';

  @override
  String get proposalOwnJob => 'This is your job';

  @override
  String get proposalOwnJobBody =>
      'You can\'t send a proposal for a job you posted.';

  @override
  String get proposalAlreadySentTitle => 'You already sent a proposal';

  @override
  String get proposalAlreadySentBody =>
      'One proposal per job. You can view it, or withdraw it while it\'s pending.';

  @override
  String get proposalView => 'View proposal';

  @override
  String get proposalJobClosedTitle => 'This job isn\'t taking proposals';

  @override
  String get proposalJobClosedBody =>
      'The job was filled, closed or changed. Look for other open jobs.';

  @override
  String get proposalConfirmTitle => 'Send this proposal?';

  @override
  String get proposalConfirmBody =>
      'The client will see your price, timing, note and public profile. You can withdraw it while it\'s pending.';

  @override
  String get proposalSend => 'Send proposal';

  @override
  String get proposalSendAgain => 'Send again';

  @override
  String get proposalSendCta => 'Send a proposal';

  @override
  String get proposalSent => 'Proposal sent';

  @override
  String get proposalSendFailed => 'Couldn\'t send your proposal. Try again.';

  @override
  String get proposalDurationSameDay => 'Same day';

  @override
  String get proposalDuration1to2 => '1–2 days';

  @override
  String get proposalDuration3to5 => '3–5 days';

  @override
  String get proposalDurationWeek => 'About a week';

  @override
  String get proposalDuration2Weeks => '2 weeks or more';

  @override
  String get proposalReview => 'Review and send';

  @override
  String proposalClientBudget(String budget) {
    return 'Client\'s budget: $budget';
  }

  @override
  String get proposalResendNote =>
      'You withdrew your earlier proposal. Sending again puts it back in the client\'s list.';

  @override
  String get proposalPriceSection => 'Your price';

  @override
  String get proposalPriceLabel => 'Price (Rs)';

  @override
  String get proposalDurationLabel => 'How long it will take';

  @override
  String get proposalDurationField => 'Estimated time';

  @override
  String get proposalDurationHint => 'e.g. 2 days';

  @override
  String get proposalDurationRequired => 'Say how long the work will take';

  @override
  String get proposalCoverLabel => 'Note to the client';

  @override
  String get proposalCoverHint =>
      'Your experience with this kind of work, and how you\'d do it';

  @override
  String get proposalCoverRequired => 'Write at least 30 characters';

  @override
  String get proposalProfileNote =>
      'Your public profile (photo, skills, work photos, reviews) is shared with this proposal.';

  @override
  String get proposalDetailsTitle => 'Proposal';

  @override
  String get proposalUnavailableTitle => 'Proposal not available';

  @override
  String get proposalUnavailableBody =>
      'It may have been removed, or this account can\'t see it.';

  @override
  String get proposalAcceptUnavailable =>
      'This job or proposal changed. Refresh and try again.';

  @override
  String get proposalActionFailed =>
      'Couldn\'t update the proposal. Try again.';

  @override
  String get proposalWithdraw => 'Withdraw';

  @override
  String get proposalWithdrawTitle => 'Withdraw this proposal?';

  @override
  String get proposalWithdrawBody =>
      'The client will no longer see it. You can send it again while the job is open.';

  @override
  String get proposalWithdrawn => 'Proposal withdrawn';

  @override
  String get proposalDecline => 'Decline';

  @override
  String proposalDeclineTitle(String name) {
    return 'Decline $name\'s proposal?';
  }

  @override
  String get proposalDeclineBody =>
      'They\'ll see it was not selected. This can\'t be undone.';

  @override
  String get proposalDeclined => 'Proposal declined';

  @override
  String get proposalAccept => 'Accept and hire';

  @override
  String proposalAcceptTitle(String name) {
    return 'Hire $name?';
  }

  @override
  String get proposalAcceptBody =>
      'The job is assigned to them, a contract is created at this price and the other proposals are closed. No payment is taken in the app.';

  @override
  String get proposalAccepted => 'Proposal accepted. Contract created.';

  @override
  String get proposalAcceptedNotice =>
      'Accepted. The contract is in Contracts; agree how and when to pay in chat.';

  @override
  String get proposalMessageWorker => 'Message worker';

  @override
  String get proposalViewJob => 'View job';

  @override
  String get proposalJobNotOpenNotice =>
      'This job is no longer open, so proposals can\'t be accepted.';

  @override
  String get proposalFilledNotice =>
      'The client hired someone else for this job.';

  @override
  String get proposalAboutWorker => 'About the worker';

  @override
  String get proposalHistory => 'History';

  @override
  String proposalSentOn(String date) {
    return 'Sent $date';
  }

  @override
  String proposalViewedOn(String date) {
    return 'Viewed by the client $date';
  }

  @override
  String proposalAcceptedOn(String date) {
    return 'Accepted $date';
  }

  @override
  String proposalClosedOn(String date) {
    return 'Closed $date';
  }

  @override
  String proposalWithdrawnOn(String date) {
    return 'Withdrawn $date';
  }

  @override
  String get proposalViewMine => 'View your proposal';

  @override
  String get proposalYourStatus => 'Your proposal:';

  @override
  String get receivedProposalsTitle => 'Proposals';

  @override
  String get receivedProposalsLoadError => 'Couldn\'t load proposals';

  @override
  String get receivedProposalsEmptyTitle => 'No proposals yet';

  @override
  String get receivedProposalsEmptyBody =>
      'Workers who apply will appear here.';

  @override
  String receivedProposalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proposals',
      one: '1 proposal',
      zero: 'No proposals',
    );
    return '$_temp0';
  }

  @override
  String proposalsViewReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View proposals ($count)',
      zero: 'View proposals',
    );
    return '$_temp0';
  }

  @override
  String get proposalSortTooltip => 'Sort proposals';

  @override
  String get proposalSortNewest => 'Newest first';

  @override
  String get proposalSortOldest => 'Oldest first';

  @override
  String get proposalSortPrice => 'Lowest price';

  @override
  String get proposalPriceSortNote =>
      'Prices are compared within the same rate type (fixed, per day, per hour).';

  @override
  String get proposalCompare => 'Compare';

  @override
  String get proposalCompareTitle => 'Compare proposals';

  @override
  String get proposalReviewAction => 'Review';

  @override
  String get proposalRateFixed => 'Fixed price';

  @override
  String get proposalRateDaily => 'Per day';

  @override
  String get proposalRateHourly => 'Per hour';

  @override
  String proposalYourBudget(String budget) {
    return 'Your budget: $budget';
  }

  @override
  String get jobHiredLabel => 'Hired';

  @override
  String get contractsTitle => 'Contracts';

  @override
  String get contractsLoadError => 'Couldn\'t load your contracts';

  @override
  String get contractsEmptyTitle => 'No contracts yet';

  @override
  String get contractsEmptyClient =>
      'When you hire a worker, the contract appears here.';

  @override
  String get contractsEmptyWorker =>
      'When a client hires you, the contract appears here.';

  @override
  String get contractsTabRequests => 'Requests';

  @override
  String get contractsTabActive => 'Active';

  @override
  String get contractsTabCompleted => 'Completed';

  @override
  String get contractsTabCancelled => 'Cancelled';

  @override
  String get contractsTabEmpty => 'No contracts here.';

  @override
  String get contractStageRequested => 'Booking request';

  @override
  String get contractStageNotStarted => 'Not started';

  @override
  String get contractStageInProgress => 'In progress';

  @override
  String get contractStageSubmitted => 'Awaiting review';

  @override
  String get contractStageCompleted => 'Completed';

  @override
  String get contractStageCancelled => 'Cancelled';

  @override
  String get contractStageDeclined => 'Declined';

  @override
  String contractCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String get contractNextClientRequested =>
      'Waiting for the worker to answer your request.';

  @override
  String get contractNextWorkerRequested =>
      'Accept or decline this booking request.';

  @override
  String get contractNextClientNotStarted => 'Waiting for the worker to start.';

  @override
  String get contractNextWorkerNotStarted => 'Start the work when you begin.';

  @override
  String get contractNextClientInProgress =>
      'The worker is on it. You\'ll review the work when it is submitted.';

  @override
  String get contractNextClientSubmitted =>
      'The work was submitted. Review it and confirm completion.';

  @override
  String get contractNextWorkerSubmitted =>
      'Submitted. Waiting for the client to confirm.';

  @override
  String contractProgressStarted(String date) {
    return 'Work started $date';
  }

  @override
  String contractProgressCompleted(String date) {
    return 'Completed $date';
  }

  @override
  String contractProgressCancelled(String date) {
    return 'Cancelled $date';
  }

  @override
  String get contractDetailsTitle => 'Contract';

  @override
  String get contractUnavailableTitle => 'Contract not available';

  @override
  String get contractUnavailableBody =>
      'Only the client and the hired worker can see a contract.';

  @override
  String get contractAgreedPrice => 'Agreed price';

  @override
  String get contractPaymentNote =>
      'Payment is agreed between you and is not processed in the app.';

  @override
  String get contractWorkSection => 'The work';

  @override
  String get contractArea => 'Area';

  @override
  String get contractExactAddress => 'Exact address';

  @override
  String get contractAddressNotShared => 'The client hasn\'t shared it yet.';

  @override
  String get contractShareAddress => 'Share the exact address';

  @override
  String get contractUpdateAddress => 'Change the address';

  @override
  String get contractShareAddressBody =>
      'Only the hired worker will see it, on this contract. Your public job shows just the area.';

  @override
  String get contractShareAddressAction => 'Share with the worker';

  @override
  String get contractAddressTooShort => 'Enter the full address';

  @override
  String get contractAddressShared => 'Address shared with the worker';

  @override
  String get contractYourWorker => 'Your worker';

  @override
  String get contractYourClient => 'Your client';

  @override
  String get contractTrackWorker => 'Track the worker';

  @override
  String get contractTrackTitle => 'Worker location';

  @override
  String get contractTrackNote =>
      'Shown only while the worker chooses to share it, and only to you.';

  @override
  String get contractHistory => 'History';

  @override
  String get contractEventRequested => 'Booking requested';

  @override
  String get contractEventRequestAccepted => 'Request accepted by the worker';

  @override
  String get contractEventRequestDeclined => 'Request declined by the worker';

  @override
  String get contractEventProposalAccepted => 'Proposal accepted';

  @override
  String get contractEventCreated => 'Contract created';

  @override
  String get contractEventAddressShared => 'Exact address shared';

  @override
  String get contractEventStarted => 'Work started';

  @override
  String get contractEventSubmitted => 'Work submitted for review';

  @override
  String get contractEventCompleted => 'Completion confirmed by the client';

  @override
  String get contractEventCancelledByClient => 'Cancelled by the client';

  @override
  String get contractEventCancelledByWorker => 'Cancelled by the worker';

  @override
  String get contractStart => 'Start work';

  @override
  String get contractStartTitle => 'Start the work now?';

  @override
  String get contractStartBody =>
      'The client will see that work has started. Do this when you begin the job.';

  @override
  String get contractStarted => 'Work started';

  @override
  String get contractSubmit => 'Submit work';

  @override
  String get contractSubmitTitle => 'Submit work';

  @override
  String get contractSubmitBody =>
      'The client will review it and either confirm completion or ask for changes. What you send is kept with the contract.';

  @override
  String get contractSubmitExplainer =>
      'Describe what you did. Photos help the client check the work.';

  @override
  String get contractSubmitNote => 'What was done';

  @override
  String get contractSubmitNoteHint =>
      'e.g. Replaced both sockets and tested the circuit';

  @override
  String get contractSubmitNoteRequired => 'Write at least 10 characters';

  @override
  String contractSubmitPhotos(int count) {
    return 'Photos (optional, up to $count)';
  }

  @override
  String get contractSubmitPhotosNote =>
      'Only you and the client can see them.';

  @override
  String get contractAddPhoto => 'Add photo';

  @override
  String get contractRemovePhoto => 'Remove photo';

  @override
  String get contractPhotoTooLarge =>
      'That photo is too large even after shrinking';

  @override
  String contractUploading(int current, int total) {
    return 'Uploading photo $current of $total…';
  }

  @override
  String get contractSubmitReview => 'Review and submit';

  @override
  String get contractSubmitted => 'Work submitted for review';

  @override
  String get contractSubmitFailed => 'Couldn\'t submit the work. Try again.';

  @override
  String get contractOnlyWorkerSubmits =>
      'Only the hired worker can submit the work.';

  @override
  String get contractAlreadySubmitted => 'The work was already submitted.';

  @override
  String get contractStartFirst => 'Start the work before submitting it.';

  @override
  String get contractSubmittedWork => 'Submitted work';

  @override
  String get contractReviewWork => 'Review the work';

  @override
  String contractSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String contractEvidencePhoto(int number) {
    return 'Work photo $number';
  }

  @override
  String get contractConfirm => 'Confirm completion';

  @override
  String get contractConfirmTitle => 'Confirm the work is complete?';

  @override
  String get contractConfirmBody =>
      'The contract and job are marked completed and you can both leave a review. This can\'t be undone.';

  @override
  String get contractConfirmed => 'Completion confirmed';

  @override
  String get contractNoRevisionNote =>
      'If something isn\'t right, message the worker before confirming.';

  @override
  String get contractCompletedNotice => 'This contract is complete.';

  @override
  String get contractWriteReview => 'Write a review';

  @override
  String get contractRequestAccept => 'Accept request';

  @override
  String get contractRequestAcceptTitle => 'Accept this booking?';

  @override
  String get contractRequestAcceptBody =>
      'The contract becomes active. Start the work when you begin.';

  @override
  String get contractRequestAccepted => 'Booking accepted';

  @override
  String get contractRequestDecline => 'Decline';

  @override
  String get contractRequestDeclineTitle => 'Decline this booking?';

  @override
  String get contractRequestDeclineBody =>
      'The client will be told. This can\'t be undone.';

  @override
  String get contractRequestDeclined => 'Booking declined';

  @override
  String get contractDeclinedNotice =>
      'The worker declined this booking request.';

  @override
  String get contractCancel => 'Cancel contract';

  @override
  String get contractWithdrawRequest => 'Withdraw request';

  @override
  String get contractCancelTitle => 'Cancel this contract?';

  @override
  String get contractCancelBody =>
      'The other person is told, and the reason is kept in the contract history. This can\'t be undone.';

  @override
  String get contractCancelNote => 'Add a note (optional)';

  @override
  String get contractKeep => 'Keep the contract';

  @override
  String get contractCancelled => 'Contract cancelled';

  @override
  String contractCancelledNotice(String role, String reason) {
    return 'Cancelled by the $role: $reason';
  }

  @override
  String get contractRoleClient => 'client';

  @override
  String get contractRoleWorker => 'worker';

  @override
  String get contractCancelReasonSchedule => 'Schedule conflict';

  @override
  String get contractCancelReasonNotNeeded => 'No longer needed';

  @override
  String get contractCancelReasonAgreed => 'Agreed with the other person';

  @override
  String get contractCancelReasonSafety => 'Safety concern';

  @override
  String get contractCancelReasonOther => 'Other';

  @override
  String get contractActionChanged =>
      'This contract changed. Check its current status.';

  @override
  String get contractActionNotAllowed => 'You can\'t do that on this contract.';

  @override
  String get contractActionFailed =>
      'Couldn\'t update the contract. Try again.';

  @override
  String get contractCardTitle => 'Contract';

  @override
  String get contractCardBody =>
      'Start, submit and confirm the work on the contract.';

  @override
  String get contractNoneForJob => 'No contract was found for this job.';

  @override
  String get contractOpen => 'Open contract';

  @override
  String get contractEventDirectAccepted =>
      'Direct request accepted by the worker';

  @override
  String get contractDirectRequestTitle => 'Request sent to you';

  @override
  String get contractDirectRequestBody =>
      'Only you received this job. Accepting creates a contract at the client\'s budget; agree the final price in chat.';

  @override
  String get contractDirectAcceptTitle => 'Accept this request?';

  @override
  String get contractDirectAcceptBody =>
      'The job is assigned to you and a contract is created. Start the work when you begin.';

  @override
  String get chatsTitle => 'Messages';

  @override
  String get chatsLoadError => 'Couldn\'t load your conversations';

  @override
  String get chatsOffline =>
      'You\'re offline. Showing conversations saved on this device.';

  @override
  String get chatsEmptyTitle => 'No conversations yet';

  @override
  String get chatsEmptyClient =>
      'Message a worker from their profile, a proposal or a contract. Your conversations appear here.';

  @override
  String get chatsEmptyWorker =>
      'When you message a client about a job, or a client messages you, the conversation appears here.';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String chatYouPrefix(String text) {
    return 'You: $text';
  }

  @override
  String get chatYou => 'You';

  @override
  String get chatPhoto => 'Photo';

  @override
  String chatUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatRoomLoadError => 'Couldn\'t open this conversation';

  @override
  String get chatRoomUnavailableTitle => 'This conversation isn\'t available';

  @override
  String get chatRoomUnavailableBody =>
      'Only the two people in a conversation can open it. Check that you\'re signed in with the right account.';

  @override
  String get chatMessagesLoadError => 'Couldn\'t load messages';

  @override
  String get chatEmptyTitle => 'Start the conversation';

  @override
  String chatEmptyBody(String name) {
    return 'Messages here are visible only to you and $name.';
  }

  @override
  String get chatEarlier => 'Show earlier messages';

  @override
  String get chatInputHint => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAddPhoto => 'Add photo';

  @override
  String get chatRemovePhoto => 'Remove photo';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatWaitingNetwork => 'Waiting for connection';

  @override
  String get chatSent => 'Sent';

  @override
  String get chatSeen => 'Seen';

  @override
  String get chatNotSent => 'Not sent';

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatDiscard => 'Discard';

  @override
  String get chatNotAllowed =>
      'This message can\'t be sent. The account may no longer be available.';

  @override
  String get chatOffline =>
      'You\'re offline. Messages will send when you reconnect.';

  @override
  String get chatPeerSuspended =>
      'This account is no longer active. You can read past messages but can\'t send new ones.';

  @override
  String get chatPhotoTooLarge =>
      'That photo is too large even after shrinking. Try another one.';

  @override
  String get chatPhotoType => 'Use a JPEG, PNG or WebP photo.';

  @override
  String get chatPhotoLimit => 'Up to 3 photos per message.';

  @override
  String get chatPhotoUnavailable => 'Photo unavailable';

  @override
  String get chatTooLong => 'Messages can be up to 2,000 characters.';

  @override
  String get chatViewContract => 'View contract';

  @override
  String get contractWhereThingsStand => 'Where things stand';

  @override
  String get contractStepHired => 'Hired';

  @override
  String get contractStepStarted => 'Started';

  @override
  String get contractStepSubmitted => 'Submitted';

  @override
  String get contractStepConfirmed => 'Confirmed';

  @override
  String contractStepsLabel(int done, int total) {
    return '$done of $total steps done';
  }

  @override
  String contractEventResubmitted(int round) {
    return 'Work resubmitted (round $round)';
  }

  @override
  String get contractEventRevision => 'Client asked for changes';

  @override
  String get contractEventUpdate => 'Progress update';

  @override
  String get contractRequestChanges => 'Ask for changes';

  @override
  String get contractRevisionTitle => 'Ask for changes?';

  @override
  String contractRevisionBody(String name, int left) {
    return 'Tell $name what needs to change. The work goes back to in progress and they can submit it again. Rounds left: $left.';
  }

  @override
  String get contractRevisionNoteLabel => 'What needs to change';

  @override
  String get contractRevisionNoteHint => 'e.g. The left socket cover is loose';

  @override
  String get contractRevisionNoteTooShort =>
      'Describe the changes (at least 10 characters).';

  @override
  String get contractRevisionSend => 'Send back for changes';

  @override
  String get contractRevisionSent => 'Sent back for changes';

  @override
  String contractRevisionsLeft(int count) {
    return 'Not quite right? You can ask for changes (rounds left: $count).';
  }

  @override
  String contractNoRevisionsLeft(String name) {
    return 'No revision rounds left. Confirm the work, or talk to $name in chat.';
  }

  @override
  String contractRevisionBannerWorker(String name, String note) {
    return '$name asked for changes: $note';
  }

  @override
  String contractRevisionBannerClient(String name) {
    return 'You asked for changes. Waiting for $name to submit the work again.';
  }

  @override
  String get contractResubmit => 'Submit changes';

  @override
  String contractWorkerSubmittedNotice(String date, String name) {
    return 'You submitted the work on $date. $name will review it and confirm, or ask for changes.';
  }

  @override
  String contractClientConfirmedNotice(String name, String date) {
    return '$name confirmed the work was completed on $date.';
  }

  @override
  String contractClientCompletedNotice(String date) {
    return 'You confirmed this work as completed on $date.';
  }

  @override
  String get contractUpdatesSection => 'Progress updates';

  @override
  String get contractUpdatesEmptyWorker =>
      'Keep the client informed: post a short update when something changes.';

  @override
  String contractUpdatesEmptyClient(String name) {
    return 'No updates yet. $name\'s updates will appear here.';
  }

  @override
  String get contractPostUpdate => 'Post an update';

  @override
  String get contractUpdateSheetTitle => 'Post a progress update';

  @override
  String contractUpdateSheetBody(String name) {
    return '$name is notified. Updates are kept with the contract and can\'t be edited.';
  }

  @override
  String get contractUpdateLabel => 'Update';

  @override
  String get contractUpdateHint =>
      'e.g. Parts bought, I\'ll start tomorrow at 10am';

  @override
  String get contractUpdateTooShort => 'Write a short update.';

  @override
  String get contractUpdatePost => 'Post update';

  @override
  String get contractUpdatePosted => 'Update posted';

  @override
  String get contractSubmissionHistory => 'Earlier submissions';

  @override
  String contractSubmissionN(int number) {
    return 'Submission $number';
  }

  @override
  String contractSubmissionChangesRequested(String note) {
    return 'Changes requested: $note';
  }

  @override
  String get contractEvidenceUnavailable => 'Photo unavailable';

  @override
  String get liveSectionTitle => 'Live location';

  @override
  String liveWorkerIntro(String name) {
    return 'Share your live location with $name while you travel to the job. Only $name can see it, and only for this contract.';
  }

  @override
  String get liveStartSharing => 'Share my location';

  @override
  String get liveStopSharing => 'Stop sharing';

  @override
  String get liveConsentTitle => 'Share your live location?';

  @override
  String liveConsentBody(String name) {
    return '$name will see where you are on a map while sharing is on. It stops when you tap Stop sharing, when you submit the work, or when the contract is completed or cancelled. Nobody else can see it.';
  }

  @override
  String get liveConsentAgree => 'Start sharing';

  @override
  String get liveNotNow => 'Not now';

  @override
  String liveSharingWith(String name, String time) {
    return 'Sharing your location with $name. Last sent $time.';
  }

  @override
  String get liveStarting => 'Getting your location…';

  @override
  String get livePermissionDenied =>
      'Location permission is off. Allow location to share it.';

  @override
  String get livePermissionBlocked =>
      'Location is blocked for SkillBridge. Turn it on in Settings.';

  @override
  String get liveServiceOff =>
      'Your device\'s location (GPS) is off. Turn it on to share.';

  @override
  String get liveUnavailable => 'Location isn\'t available on this device.';

  @override
  String get liveEnded =>
      'Sharing stopped because the work was submitted or the contract closed.';

  @override
  String get liveError => 'Couldn\'t get your location. Try again.';

  @override
  String get liveOpenSettings => 'Open settings';

  @override
  String get liveOfflineWorker =>
      'You\'re offline. Your location will update when you reconnect.';

  @override
  String liveStartedNotice(String name) {
    return 'Sharing your location with $name';
  }

  @override
  String get liveStoppedNotice => 'Location sharing stopped';

  @override
  String liveClientNotSharing(String name) {
    return '$name isn\'t sharing their location right now.';
  }

  @override
  String get liveBadge => 'Live';

  @override
  String get liveBadgeStale => 'Not live';

  @override
  String liveUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String liveClientStale(String name) {
    return '$name\'s location hasn\'t updated recently and may be out of date.';
  }

  @override
  String get liveClientOffline =>
      'You\'re offline. This is the last location received and may be out of date.';

  @override
  String liveClientExplainer(String name) {
    return 'Shown only while $name chooses to share it, and only to you. It stops automatically when the work is submitted or the contract closes.';
  }

  @override
  String get liveOpenInMaps => 'Open in a maps app';

  @override
  String liveAccuracy(int meters) {
    return 'Accurate to about $meters m';
  }

  @override
  String get liveJustNow => 'just now';

  @override
  String liveMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get liveMapUnavailable =>
      'The map can\'t be shown here. You can open the location in a maps app.';

  @override
  String get liveLoadError => 'Couldn\'t load the location.';

  @override
  String get mapLabel => 'Map';

  @override
  String get mapUnavailableTitle => 'Map unavailable';

  @override
  String get mapUnavailableBody =>
      'The map isn\'t set up correctly in this version of the app.';

  @override
  String get mapOffline => 'You\'re offline. The map may be incomplete.';

  @override
  String get mapTilesFailed => 'The map couldn\'t load. Check your connection.';

  @override
  String get mapRecenter => 'Show my location';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapYouAreHere => 'You are here';

  @override
  String get mapSearchCentre => 'Search centre';

  @override
  String get pickerTitle => 'Choose a location';

  @override
  String get pickerSearchHint => 'Search for an address or place';

  @override
  String get pickerSearchNoResults =>
      'No places found. Try other words, or move the map to place the pin.';

  @override
  String get pickerSearchFailed =>
      'Search isn\'t available right now. Move the map to place the pin.';

  @override
  String get pickerSearchTooShort => 'Type at least 3 characters.';

  @override
  String get pickerSearchAttributionGoogle => 'Results from Google Maps';

  @override
  String get pickerMoveHint => 'Move the map so the pin is on the exact place.';

  @override
  String get pickerZoomInHint => 'Zoom in to place the pin precisely.';

  @override
  String get pickerFindingAddress => 'Finding the address…';

  @override
  String get pickerPinnedLocation => 'Pinned location';

  @override
  String get pickerConfirm => 'Confirm location';

  @override
  String get pickerLocating => 'Finding your location…';

  @override
  String get pickerLocationDenied =>
      'Location permission is off. You can still choose a place on the map.';

  @override
  String get pickerLocationBlocked =>
      'Location is blocked for SkillBridge. Turn it on in Settings, or choose a place on the map.';

  @override
  String get pickerLocationServiceOff =>
      'Location (GPS) is off. Turn it on, or choose a place on the map.';

  @override
  String get pickerLocationFailed =>
      'Couldn\'t get your location. Choose a place on the map.';

  @override
  String get navTitle => 'Directions';

  @override
  String get navOpenGoogleMaps => 'Directions in Google Maps';

  @override
  String get navCalculating => 'Finding the best road route…';

  @override
  String navRouteTo(String place) {
    return 'Route to $place';
  }

  @override
  String get navFastest => 'Fastest';

  @override
  String get navStart => 'Start';

  @override
  String navArriveAt(String time) {
    return 'Arrive $time';
  }

  @override
  String get navEstimateNote =>
      'Times are estimates and don\'t include live traffic.';

  @override
  String get navErrNoDestination =>
      'This job has no map location yet, so directions can\'t start.';

  @override
  String get navErrPermission =>
      'Directions need your location. Allow location to continue.';

  @override
  String get navErrBlocked =>
      'Location is blocked for SkillBridge. Turn it on in Settings to get directions.';

  @override
  String get navErrServiceOff =>
      'Location (GPS) is off. Turn it on to get directions.';

  @override
  String get navErrNoFix =>
      'Couldn\'t get your location. Move to an open area and try again.';

  @override
  String get navErrNoRoute => 'No road route was found to this place.';

  @override
  String get navErrOffline =>
      'You\'re offline. Connect to the internet to get a route.';

  @override
  String get navErrRouting =>
      'Directions aren\'t available right now. Try again in a moment.';

  @override
  String navMeters(int meters) {
    return '$meters m';
  }

  @override
  String navKilometres(String km) {
    return '$km km';
  }

  @override
  String navMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String navHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get navUnderAMinute => 'Under 1 min';

  @override
  String get contractPinTitle => 'Place on the map';

  @override
  String get contractPinHelp =>
      'Pin the exact door so the worker can get directions. Only the worker you hired sees it.';

  @override
  String get contractPinAdd => 'Pin it on the map';

  @override
  String get contractPinChange => 'Change pin';

  @override
  String get contractPinRemove => 'Remove pin';

  @override
  String get contractPinSet => 'Pinned on the map';

  @override
  String get contractPinMissing =>
      'The client hasn\'t pinned the place on the map yet.';

  @override
  String get contractStartNavigation => 'Start navigation';

  @override
  String contractNavigationNeedsPin(String name) {
    return 'Directions need the place pinned on the map. Ask $name to pin it.';
  }

  @override
  String get contractViewOnMap => 'View on map';

  @override
  String get trackTitle => 'Live location';

  @override
  String get trackOpen => 'Open live map';

  @override
  String trackRoadLeft(String distance, String time) {
    return '$distance by road · about $time';
  }

  @override
  String trackArriveAbout(String time) {
    return 'Arrives about $time';
  }

  @override
  String get trackNoPin =>
      'Pin the place on the map to see how far away they are.';

  @override
  String get trackNoRoute => 'The road distance isn\'t available right now.';

  @override
  String trackArrived(String name) {
    return '$name is at the place.';
  }

  @override
  String get trackOnlyClient =>
      'Only the client of this job can follow the worker\'s location.';

  @override
  String get navOnlyWorker =>
      'Only the worker hired for this job can get directions to it.';

  @override
  String get navJobClosed =>
      'This job is no longer active, so directions and live location are off.';

  @override
  String get navJobLoadError => 'Couldn\'t load this job.';

  @override
  String navArrivedTell(String name) {
    return 'Tell $name I\'ve arrived';
  }

  @override
  String get navArrivedNote => 'I\'ve arrived at the place.';

  @override
  String navArrivedSent(String name) {
    return '$name has been told you\'ve arrived.';
  }

  @override
  String get navArrivedSendFailed =>
      'Couldn\'t send. Check your connection and try again.';

  @override
  String get identityTitle => 'Identity verification';

  @override
  String get identityIntro =>
      'Confirm who you are with your CNIC and a fingerprint, checked by NADRA. Workers and hirers use the same check.';

  @override
  String get identityNotAvailableTitle =>
      'NADRA verification isn\'t available yet';

  @override
  String get identityNotAvailableBody =>
      'SkillBridge is waiting for official NADRA approval and an approved fingerprint scanner. Until then nobody can be NADRA-verified and no fingerprints are collected. You can keep using SkillBridge as usual.';

  @override
  String get identityTestBanner =>
      'TEST VERIFICATION: simulated, not a real NADRA check. Use the synthetic test CNICs only.';

  @override
  String get identityStart => 'Start verification';

  @override
  String get identityStartAgain => 'Start a new verification';

  @override
  String get identityHistory => 'Verification history';

  @override
  String get identityHistoryEmpty => 'No verification attempts yet.';

  @override
  String get identityStatusNone => 'Not verified';

  @override
  String get identityStatusInProgress => 'In progress';

  @override
  String get identityStatusVerified => 'Verified';

  @override
  String get identityStatusRejected => 'Not confirmed';

  @override
  String get identityStatusFailed => 'Didn\'t finish';

  @override
  String get identityStatusReview => 'Under review';

  @override
  String get identityStatusExpired => 'Expired';

  @override
  String get identityStatusCancelled => 'Cancelled';

  @override
  String get identityBadgeNadra => 'NADRA verified';

  @override
  String get identityBadgeTest => 'TEST verification';

  @override
  String identityVerifiedOn(String date) {
    return 'Verified $date';
  }

  @override
  String get identityMethodFingerprint =>
      'Method: fingerprint matched to CNIC by NADRA';

  @override
  String get identityOtherChecks =>
      'Email, phone and ID-document review are separate from this check.';

  @override
  String get cnicTitle => 'Your CNIC';

  @override
  String get cnicLabel => 'CNIC number';

  @override
  String get cnicHint => 'XXXXX-XXXXXXX-X';

  @override
  String get cnicHelp =>
      '13 digits, as printed on your CNIC. A correct format doesn\'t verify anything; only NADRA\'s check does.';

  @override
  String get cnicInvalid => 'Enter all 13 digits of a valid CNIC.';

  @override
  String get cnicTestOnly => 'Test mode accepts only these synthetic CNICs:';

  @override
  String get identityContinue => 'Continue';

  @override
  String get consentTitle => 'Before we scan your fingerprint';

  @override
  String get consentWhy =>
      'Why: to confirm you are the person on the CNIC you entered, so others can trust your SkillBridge profile.';

  @override
  String get consentWho =>
      'Who checks it: NADRA (National Database and Registration Authority), the Government of Pakistan\'s identity service.';

  @override
  String get consentWhat =>
      'What is sent: your CNIC number and one fingerprint capture, only through NADRA\'s approved channel.';

  @override
  String get consentResult =>
      'What SkillBridge receives: whether the fingerprint matches the CNIC, nothing else.';

  @override
  String get consentKeep =>
      'What we keep: the result, the date and a masked CNIC (like 35202-•••••••-1). We never store your fingerprint, a fingerprint template or your full CNIC. No CNIC images are needed.';

  @override
  String get consentRetention =>
      'Retention: verification records stay while your account exists and are deleted with it.';

  @override
  String get consentWithdraw =>
      'You can stop at any time before the fingerprint is submitted. Questions: Settings, Customer support.';

  @override
  String get consentCheckbox =>
      'I agree to have my CNIC and fingerprint checked by NADRA for identity verification only (not for marketing or anything else).';

  @override
  String get consentAgree => 'Agree and continue';

  @override
  String consentVersion(String version) {
    return 'Consent version $version';
  }

  @override
  String get captureTitle => 'Scan your fingerprint';

  @override
  String get captureInstructions =>
      'Place your right thumb flat on the scanner and keep it still until the scan finishes.';

  @override
  String get captureStart => 'Start scan';

  @override
  String get captureRetry => 'Scan again';

  @override
  String get captureSubmit => 'Submit for verification';

  @override
  String get captureWaiting => 'Waiting for the fingerprint scanner…';

  @override
  String get captureConnected => 'Scanner connected';

  @override
  String get captureReady => 'Ready: place your finger on the scanner';

  @override
  String get captureFingerDetected => 'Finger detected, hold still';

  @override
  String get captureCapturing => 'Capturing…';

  @override
  String get captureSuccess =>
      'Fingerprint captured. It hasn\'t been checked yet.';

  @override
  String get capturePoorQuality =>
      'The scan quality was too low. Wipe the scanner, press your finger flat and scan again.';

  @override
  String get captureNotDetected =>
      'No finger detected. Place your finger on the scanner.';

  @override
  String get captureFailed => 'The scan didn\'t work. Try again.';

  @override
  String get captureDisconnected =>
      'The fingerprint scanner is not connected. Connect it and try again.';

  @override
  String get captureExpired => 'This session has expired. Start again.';

  @override
  String get captureNoApprovedScanner =>
      'No approved fingerprint scanner is available. NADRA needs an approved scanner; your phone\'s fingerprint unlock can\'t be used for this.';

  @override
  String get captureScenario => 'Test scenario';

  @override
  String get scenarioGood => 'Good capture';

  @override
  String get scenarioPoor => 'Poor quality';

  @override
  String get scenarioNoFinger => 'No finger';

  @override
  String get scenarioDisconnected => 'Scanner unplugged';

  @override
  String get scenarioFails => 'Capture fails';

  @override
  String get processingTitle => 'Checking your identity';

  @override
  String get processingBody =>
      'NADRA is matching your fingerprint against your CNIC. This can take a moment.';

  @override
  String get processingBodyTest =>
      'Simulating a NADRA check (test mode). Nothing is sent to NADRA.';

  @override
  String get resultVerifiedTitle => 'Identity verified';

  @override
  String get resultVerifiedBody =>
      'NADRA confirmed your fingerprint matches your CNIC. Your profile now shows the NADRA verified badge.';

  @override
  String get resultTestTitle => 'TEST verification passed';

  @override
  String get resultTestBody =>
      'This was a simulated check. It is not a real NADRA verification and gives no verified badge.';

  @override
  String get resultRejectedTitle => 'We couldn\'t confirm your identity';

  @override
  String get resultRejectedBody =>
      'The check didn\'t confirm a match. If you think this is wrong, contact support.';

  @override
  String get resultReviewTitle => 'Additional review needed';

  @override
  String get resultReviewBody =>
      'Your verification needs an extra check. We\'ll notify you.';

  @override
  String resultRetryPoor(int count) {
    return 'NADRA couldn\'t read the fingerprint well enough. Scan again ($count left).';
  }

  @override
  String resultRetryService(int count) {
    return 'NADRA\'s service couldn\'t be reached. Your request is kept; try again shortly ($count left).';
  }

  @override
  String get resultFailedTitle => 'Verification didn\'t finish';

  @override
  String get resultFailedBody =>
      'A technical problem stopped the check. Nothing was decided about your identity. You can start again.';

  @override
  String get resultExpired => 'This session expired. Start a new verification.';

  @override
  String get resultTryAgain => 'Try again';

  @override
  String get resultDone => 'Done';

  @override
  String get identityErrRecentLogin =>
      'For your security, sign out and sign in again, then start verification.';

  @override
  String get identityErrInUse =>
      'This CNIC is already verified on another account. Contact support.';

  @override
  String get identityErrDaily => 'Too many attempts today. Try again tomorrow.';

  @override
  String get identityErrAlready => 'Your identity is already verified.';

  @override
  String get identityErrAttempts =>
      'No attempts left in this session. Start a new verification.';

  @override
  String get identityErrSynthetic =>
      'Test mode accepts only the synthetic test CNICs.';

  @override
  String get identityErrOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get identityErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get identityCancelled => 'Verification cancelled.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get legalAnd => 'and';

  @override
  String get drawerGuest => 'Guest';

  @override
  String get drawerSignInPrompt => 'Sign in to post jobs and hire workers.';

  @override
  String get drawerClose => 'Close menu';

  @override
  String get drawerSectionWork => 'Your work';

  @override
  String get drawerSectionAccount => 'Account';

  @override
  String get drawerPostJob => 'Post a job';

  @override
  String get drawerMyJobs => 'My jobs';

  @override
  String get drawerContracts => 'Contracts';

  @override
  String get drawerMessages => 'Messages';

  @override
  String get drawerNotifications => 'Notifications';

  @override
  String get drawerNearbyWorkers => 'Find workers near me';

  @override
  String get drawerProfile => 'My profile';

  @override
  String get drawerVerifyIdentity => 'Verify identity';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerShare => 'Share SkillBridge';

  @override
  String get drawerShareText =>
      'Find trusted local workers on SkillBridge: electricians, plumbers, cleaners and more.';

  @override
  String get drawerAbout => 'About SkillBridge';

  @override
  String get drawerAboutBody =>
      'SkillBridge connects people in Pakistan with skilled local workers. Post a job, compare proposals, hire, chat and track the work in one place.';

  @override
  String drawerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get drawerSignIn => 'Sign in';

  @override
  String get drawerCreateAccount => 'Create account';

  @override
  String get drawerSignOut => 'Sign out';

  @override
  String get offlineNow => 'You\'re offline';

  @override
  String get phoneRequiredTitle => 'Add your phone number';

  @override
  String get phoneRequiredSubtitle =>
      'We\'ll text you a 6-digit code to confirm the number is yours.';

  @override
  String get phoneRequiredHelp =>
      'Pakistani mobile number. Shared only with people you hire or work for.';

  @override
  String get phoneRequiredSend => 'Send code';

  @override
  String get phoneRequiredInvalid =>
      'Enter a Pakistani mobile number, like 300 1234567.';

  @override
  String get phoneRequiredSignOut => 'Sign out';

  @override
  String phoneRequiredSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get phoneInUse =>
      'This number is already used by another SkillBridge account.';

  @override
  String get otpTooMany =>
      'Too many tries. Please wait a little and try again.';

  @override
  String get otpExpired => 'This code has expired. Request a new one.';

  @override
  String get otpSendFailed =>
      'We couldn\'t send the code. Check the number and try again.';

  @override
  String get otpNotSetUp =>
      'Phone verification isn\'t available right now. Please try again later.';

  @override
  String get getVerifiedTitle => 'Get verified';

  @override
  String get getVerifiedHeaderTitle => 'Get the Verified badge';

  @override
  String get getVerifiedIntro =>
      'Verify your identity with your CNIC and fingerprint. People trust verified profiles more.';

  @override
  String get getVerifiedCardBody =>
      'Verify with your CNIC and fingerprint to get the Verified badge.';

  @override
  String get getVerifiedReviewTitle => 'Verification under review';

  @override
  String get getVerifiedReviewBody =>
      'Our team is checking your CNIC. We\'ll let you know when it\'s done.';

  @override
  String get getVerifiedDoneTitle => 'You\'re verified';

  @override
  String get getVerifiedDoneBody => 'Your profile shows the Verified badge.';

  @override
  String getVerifiedStepN(int number) {
    return 'Step $number';
  }

  @override
  String get getVerifiedStepCnic => 'CNIC';

  @override
  String get getVerifiedStepCnicBody =>
      'Enter your CNIC number and add photos of the front and back of your card. Our team checks them, usually within 2 working days.';

  @override
  String get getVerifiedStepFingerprint => 'Fingerprint';

  @override
  String get getVerifiedStepFingerprintBody =>
      'Match your fingerprint with your CNIC record at NADRA.';

  @override
  String get getVerifiedFingerprintSoon =>
      'Fingerprint matching with NADRA will open here once SkillBridge\'s NADRA access is approved. Nothing is collected until then.';

  @override
  String get getVerifiedComingSoon => 'Coming soon';

  @override
  String get getVerifiedStatusNotStarted => 'Not started';

  @override
  String get getVerifiedStatusInProgress => 'In progress';

  @override
  String get getVerifiedStatusReview => 'Under review';

  @override
  String get getVerifiedStatusDone => 'Done';

  @override
  String get getVerifiedStatusRejected => 'Not approved';

  @override
  String get getVerifiedStart => 'Start';

  @override
  String get getVerifiedTryAgain => 'Try again';

  @override
  String get getVerifiedView => 'View';

  @override
  String get getVerifiedPrivacy =>
      'Your CNIC and card photos are private: only SkillBridge\'s verification team sees them. Fingerprints are never stored.';

  @override
  String get verifiedBadge => 'Verified';

  @override
  String get verifiedPopupTitle => 'You\'re verified!';

  @override
  String get verifiedPopupBody =>
      'SkillBridge checked your identity. The Verified badge now shows on your profile.';

  @override
  String get verifiedPopupOk => 'Great';
}
