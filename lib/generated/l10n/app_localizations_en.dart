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
  String viewReceivedProposals(String count) {
    return 'View Received Proposals ($count)';
  }

  @override
  String get receivedProposals => 'Received Proposals';
}
