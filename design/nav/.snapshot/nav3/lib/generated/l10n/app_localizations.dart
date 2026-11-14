import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Skill Bridge'**
  String get appName;

  /// General greeting
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting;

  /// Greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String greetingWithName(String name);

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRole;

  /// No description provided for @selectRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to use SkillBridge?'**
  String get selectRoleSubtitle;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @clientDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to hire skilled workers for my jobs'**
  String get clientDescription;

  /// No description provided for @workerDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to offer my skills and find work'**
  String get workerDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search electrician, plumber...'**
  String get searchPlaceholder;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @topRatedNearYou.
  ///
  /// In en, this message translates to:
  /// **'Top rated near you'**
  String get topRatedNearYou;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs experience'**
  String yearsExperience(int years);

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get perHour;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get perDay;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postJob;

  /// No description provided for @jobType.
  ///
  /// In en, this message translates to:
  /// **'Job Type'**
  String get jobType;

  /// No description provided for @temporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get temporary;

  /// No description provided for @permanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get permanent;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget (PKR)'**
  String get budget;

  /// No description provided for @budgetRange.
  ///
  /// In en, this message translates to:
  /// **'Budget Range'**
  String get budgetRange;

  /// No description provided for @submitJob.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get submitJob;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeJobs;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedJobs;

  /// No description provided for @cancelledJobs.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledJobs;

  /// No description provided for @openJobs.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openJobs;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @proposedRate.
  ///
  /// In en, this message translates to:
  /// **'Proposed Rate'**
  String get proposedRate;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @activeContracts.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeContracts;

  /// No description provided for @completedContracts.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedContracts;

  /// No description provided for @contractDetails.
  ///
  /// In en, this message translates to:
  /// **'Contract Details'**
  String get contractDetails;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @hireForJob.
  ///
  /// In en, this message translates to:
  /// **'Hire for a Job'**
  String get hireForJob;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @dailyRate.
  ///
  /// In en, this message translates to:
  /// **'Daily Rate'**
  String get dailyRate;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @jazzcash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get jazzcash;

  /// No description provided for @easypaisa.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa'**
  String get easypaisa;

  /// No description provided for @nearbyWorkers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Workers'**
  String get nearbyWorkers;

  /// No description provided for @filterResults.
  ///
  /// In en, this message translates to:
  /// **'Filter Results'**
  String get filterResults;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @ratingFilter.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingFilter;

  /// No description provided for @experienceFilter.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceFilter;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChats;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'PKR'**
  String get currency;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get currencySymbol;

  /// No description provided for @currencyFormat.
  ///
  /// In en, this message translates to:
  /// **'Rs {amount}'**
  String currencyFormat(String amount);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @customerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get customerSupport;

  /// No description provided for @chatOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get chatOnWhatsApp;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed.'**
  String get whatsappNotInstalled;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsContent.
  ///
  /// In en, this message translates to:
  /// **'By using SkillBridge, you agree to our terms of service.\n\n1. Users must provide accurate information.\n2. Payments must be processed through the app or directly as agreed.\n3. SkillBridge is not liable for disputes between workers and clients.\n4. Respect and professionalism are required at all times.'**
  String get termsContent;

  /// No description provided for @viewReceivedProposals.
  ///
  /// In en, this message translates to:
  /// **'View Received Proposals ({count})'**
  String viewReceivedProposals(int count);

  /// No description provided for @receivedProposals.
  ///
  /// In en, this message translates to:
  /// **'Received Proposals'**
  String get receivedProposals;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Local expertise, made easier to trust.'**
  String get appTagline;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get authEmailHint;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {label}'**
  String onboardingStepOf(int step, int total, String label);

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, like name@example.com.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters, including a number.'**
  String get validationPasswordWeak;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get validationPasswordMismatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get validationNameRequired;

  /// No description provided for @validationNameLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be 2–60 characters.'**
  String get validationNameLength;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a Pakistani mobile number, like 300 1234567.'**
  String get validationPhoneInvalid;

  /// No description provided for @errInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errInvalidCredential;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get errEmailInUse;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get errUserDisabled;

  /// No description provided for @errSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. Contact support.'**
  String get errSuspended;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errTooManyRequests;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Check your connection and try again.'**
  String get errTimeout;

  /// No description provided for @errAccountExistsDifferent.
  ///
  /// In en, this message translates to:
  /// **'This email is registered with a different sign-in method.'**
  String get errAccountExistsDifferent;

  /// No description provided for @errOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method isn\'t available right now.'**
  String get errOperationNotAllowed;

  /// No description provided for @errRoleLocked.
  ///
  /// In en, this message translates to:
  /// **'This account already has a role.'**
  String get errRoleLocked;

  /// No description provided for @errSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errSignInAgain;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Find trusted local help, or get hired for your skills'**
  String get welcomeTitle;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeSignIn;

  /// No description provided for @welcomePointTrust.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles and real reviews'**
  String get welcomePointTrust;

  /// No description provided for @welcomePointNearby.
  ///
  /// In en, this message translates to:
  /// **'Skilled workers near you, across Pakistan'**
  String get welcomePointNearby;

  /// No description provided for @welcomePointChat.
  ///
  /// In en, this message translates to:
  /// **'Chat and agree the price before booking'**
  String get welcomePointChat;

  /// No description provided for @welcomeTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our'**
  String get welcomeTermsPrefix;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to SkillBridge.'**
  String get loginSubtitle;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get loginSigningIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to SkillBridge?'**
  String get loginNoAccount;

  /// No description provided for @signupTitleClient.
  ///
  /// In en, this message translates to:
  /// **'Create a client account'**
  String get signupTitleClient;

  /// No description provided for @signupTitleWorker.
  ///
  /// In en, this message translates to:
  /// **'Create a worker account'**
  String get signupTitleWorker;

  /// No description provided for @signupSubtitleClient.
  ///
  /// In en, this message translates to:
  /// **'Hire trusted workers near you.'**
  String get signupSubtitleClient;

  /// No description provided for @signupSubtitleWorker.
  ///
  /// In en, this message translates to:
  /// **'Get found by clients near you.'**
  String get signupSubtitleWorker;

  /// No description provided for @signupRoleQuestion.
  ///
  /// In en, this message translates to:
  /// **'I want to'**
  String get signupRoleQuestion;

  /// No description provided for @roleClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Hire workers'**
  String get roleClientTitle;

  /// No description provided for @roleClientDesc.
  ///
  /// In en, this message translates to:
  /// **'Post jobs and book trusted people nearby.'**
  String get roleClientDesc;

  /// No description provided for @roleWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Find work'**
  String get roleWorkerTitle;

  /// No description provided for @roleWorkerDesc.
  ///
  /// In en, this message translates to:
  /// **'Offer your skills and get hired for jobs.'**
  String get roleWorkerDesc;

  /// No description provided for @signupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signupNameLabel;

  /// No description provided for @signupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tariq Mahmood'**
  String get signupNameHint;

  /// No description provided for @signupPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get signupPhoneLabel;

  /// No description provided for @signupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'300 1234567'**
  String get signupPhoneHint;

  /// No description provided for @signupPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Used so clients and workers can reach you.'**
  String get signupPhoneHelp;

  /// No description provided for @signupPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, including a number.'**
  String get signupPasswordHelp;

  /// No description provided for @signupConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signupConfirmPasswordLabel;

  /// No description provided for @signupAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get signupAgree;

  /// No description provided for @signupReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get signupReadTerms;

  /// No description provided for @signupAgreeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms & Conditions to continue.'**
  String get signupAgreeRequired;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupButton;

  /// No description provided for @signupCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get signupCreating;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupHaveAccount;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use SkillBridge?'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one to finish setting up your account.'**
  String get roleSelectSubtitle;

  /// No description provided for @roleSelectSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get roleSelectSaving;

  /// No description provided for @roleSelectDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get roleSelectDifferentAccount;

  /// No description provided for @roleSelectSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String roleSelectSignedInAs(String email);

  /// No description provided for @roleSelectRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose client or worker to continue.'**
  String get roleSelectRequired;

  /// No description provided for @roleSelectPermanentNote.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be changed later, so pick the one that fits you.'**
  String get roleSelectPermanentNote;

  /// No description provided for @roleSelectSignedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get roleSelectSignedOutTitle;

  /// No description provided for @roleSelectSignedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to continue.'**
  String get roleSelectSignedOutBody;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we\'ll send you a reset link.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotSend;

  /// No description provided for @forgotSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get forgotSending;

  /// No description provided for @forgotSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotSentTitle;

  /// No description provided for @forgotSentBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way. Open it, choose a new password, then sign in.'**
  String forgotSentBody(String email);

  /// No description provided for @forgotSentTip.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Check your spam folder.'**
  String get forgotSentTip;

  /// No description provided for @forgotResend.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get forgotResend;

  /// No description provided for @forgotResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String forgotResendIn(int seconds);

  /// No description provided for @forgotBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotBackToSignIn;

  /// No description provided for @forgotDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get forgotDifferentEmail;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {phone}.'**
  String otpSubtitle(String phone);

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCodeLabel;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent.'**
  String get otpSent;

  /// No description provided for @otpError.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it or request a new one.'**
  String get otpError;

  /// No description provided for @otpVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified.'**
  String get otpVerified;

  /// No description provided for @mediaTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get mediaTakePhoto;

  /// No description provided for @mediaChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get mediaChooseFromGallery;

  /// No description provided for @mediaPickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera or gallery.'**
  String get mediaPickerUnavailable;

  /// No description provided for @mediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is over 5 MB. Choose a smaller one.'**
  String get mediaTooLarge;

  /// No description provided for @mediaUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPG, PNG or WebP image.'**
  String get mediaUnsupportedType;

  /// No description provided for @mediaPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to upload this file.'**
  String get mediaPermissionDenied;

  /// No description provided for @mediaUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get mediaUploadFailed;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileChangePhoto;

  /// No description provided for @portfolioAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get portfolioAdd;

  /// No description provided for @portfolioAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added to your work.'**
  String get portfolioAdded;

  /// No description provided for @portfolioRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get portfolioRemove;

  /// No description provided for @portfolioRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get portfolioRemoveTitle;

  /// No description provided for @portfolioRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'It will no longer appear on your public profile.'**
  String get portfolioRemoveBody;

  /// No description provided for @portfolioRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed.'**
  String get portfolioRemoved;

  /// No description provided for @portfolioCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} photos'**
  String portfolioCount(int count, int max);

  /// No description provided for @portfolioNeedsProfile.
  ///
  /// In en, this message translates to:
  /// **'Finish your professional details first, then add work photos.'**
  String get portfolioNeedsProfile;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Verifying helps protect your account.'**
  String verifyEmailBody(String email);

  /// No description provided for @verifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verifyEmailSent;

  /// No description provided for @verifyEmailCheck.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified'**
  String get verifyEmailCheck;

  /// No description provided for @verifyEmailStillPending.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet. Open the link in the email, then try again.'**
  String get verifyEmailStillPending;

  /// No description provided for @availabilityHelp.
  ///
  /// In en, this message translates to:
  /// **'Clients see this on your profile.'**
  String get availabilityHelp;

  /// No description provided for @availabilityAvailableNote.
  ///
  /// In en, this message translates to:
  /// **'Clients can find and message you for new work.'**
  String get availabilityAvailableNote;

  /// No description provided for @availabilityBusyNote.
  ///
  /// In en, this message translates to:
  /// **'Shown as busy. Clients can still message you.'**
  String get availabilityBusyNote;

  /// No description provided for @availabilityOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Shown as offline until you switch back.'**
  String get availabilityOfflineNote;

  /// No description provided for @onboardingStepYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get onboardingStepYou;

  /// No description provided for @onboardingStepContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get onboardingStepContact;

  /// No description provided for @onboardingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get onboardingStepLocation;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkip;

  /// No description provided for @onboardingSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip this step'**
  String get onboardingSkipStep;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingFinish;

  /// No description provided for @onboardingPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'A clear photo helps workers recognise you.'**
  String get onboardingPhotoHint;

  /// No description provided for @clientOnboardingYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get clientOnboardingYouTitle;

  /// No description provided for @clientOnboardingYouBody.
  ///
  /// In en, this message translates to:
  /// **'Add your name and a photo.'**
  String get clientOnboardingYouBody;

  /// No description provided for @clientOnboardingContactTitle.
  ///
  /// In en, this message translates to:
  /// **'How can workers reach you?'**
  String get clientOnboardingContactTitle;

  /// No description provided for @clientOnboardingContactBody.
  ///
  /// In en, this message translates to:
  /// **'Your number is shared only with workers you hire.'**
  String get clientOnboardingContactBody;

  /// No description provided for @clientOnboardingPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in your profile.'**
  String get clientOnboardingPhoneHelp;

  /// No description provided for @clientOnboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you need help?'**
  String get clientOnboardingLocationTitle;

  /// No description provided for @clientOnboardingLocationBody.
  ///
  /// In en, this message translates to:
  /// **'We use your city to show workers near you.'**
  String get clientOnboardingLocationBody;

  /// No description provided for @completeTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String completeTitle(int percent);

  /// No description provided for @completeFix.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeFix;

  /// No description provided for @completeAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo so clients can recognise you.'**
  String get completeAddPhoto;

  /// No description provided for @completeAddWork.
  ///
  /// In en, this message translates to:
  /// **'Add your title, trade and a short description.'**
  String get completeAddWork;

  /// No description provided for @completeAddSkills.
  ///
  /// In en, this message translates to:
  /// **'Add the skills clients search for.'**
  String get completeAddSkills;

  /// No description provided for @completeAddRate.
  ///
  /// In en, this message translates to:
  /// **'Add an hourly or daily rate.'**
  String get completeAddRate;

  /// No description provided for @completeAddArea.
  ///
  /// In en, this message translates to:
  /// **'Set the area you work in.'**
  String get completeAddArea;

  /// No description provided for @completeAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your work.'**
  String get completeAddPhotos;

  /// No description provided for @completeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to earn the Verified badge.'**
  String get completeVerify;

  /// No description provided for @profileAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area or neighbourhood'**
  String get profileAreaLabel;

  /// No description provided for @profileAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. G-11, Islamabad'**
  String get profileAreaHint;

  /// No description provided for @profileAreaHelp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t enter your house number. Exact addresses are shared only for booked jobs.'**
  String get profileAreaHelp;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileCityHint.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get profileCityHint;

  /// No description provided for @profileContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get profileContactDetails;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your email is your sign-in and can’t be changed here.'**
  String get profileEmailReadOnly;

  /// No description provided for @profileHires.
  ///
  /// In en, this message translates to:
  /// **'Hires'**
  String get profileHires;

  /// No description provided for @profileJobsPosted.
  ///
  /// In en, this message translates to:
  /// **'Jobs posted'**
  String get profileJobsPosted;

  /// No description provided for @profileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationLabel;

  /// No description provided for @profileNoName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get profileNoName;

  /// No description provided for @profileNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get profileNoReviews;

  /// No description provided for @profileNoReviewsBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews appear here after completed jobs.'**
  String get profileNoReviewsBody;

  /// No description provided for @profileNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get profileNotAdded;

  /// No description provided for @profileOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get profileOptional;

  /// No description provided for @profileReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String profileReviewsCount(int count);

  /// No description provided for @profileReviewsError.
  ///
  /// In en, this message translates to:
  /// **'Reviews couldn\'t load'**
  String get profileReviewsError;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @profileVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get profileVerifyPhone;

  /// No description provided for @publicProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker profile'**
  String get publicProfileTitle;

  /// No description provided for @publicProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'This profile couldn\'t load'**
  String get publicProfileLoadError;

  /// No description provided for @publicProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not available'**
  String get publicProfileNotFound;

  /// No description provided for @publicProfileNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This worker may have removed their profile.'**
  String get publicProfileNotFoundBody;

  /// No description provided for @publicProfileOwnPreview.
  ///
  /// In en, this message translates to:
  /// **'This is how clients see your profile.'**
  String get publicProfileOwnPreview;

  /// No description provided for @publicProfilePreview.
  ///
  /// In en, this message translates to:
  /// **'See public profile'**
  String get publicProfilePreview;

  /// No description provided for @publicProfileWorkTab.
  ///
  /// In en, this message translates to:
  /// **'Work photos'**
  String get publicProfileWorkTab;

  /// No description provided for @publicProfileNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get publicProfileNew;

  /// No description provided for @publicProfileJobsDone.
  ///
  /// In en, this message translates to:
  /// **'Jobs done'**
  String get publicProfileJobsDone;

  /// No description provided for @publicProfileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get publicProfileMemberSince;

  /// No description provided for @publicProfilePriceNote.
  ///
  /// In en, this message translates to:
  /// **'Final price is agreed in chat before booking.'**
  String get publicProfilePriceNote;

  /// No description provided for @publicProfileNoBio.
  ///
  /// In en, this message translates to:
  /// **'No description added yet.'**
  String get publicProfileNoBio;

  /// No description provided for @publicProfileServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get publicProfileServiceArea;

  /// No description provided for @publicProfileAreaValue.
  ///
  /// In en, this message translates to:
  /// **'{city} · within {km} km'**
  String publicProfileAreaValue(String city, int km);

  /// No description provided for @publicProfileAreaPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Approximate area. Exact locations are shared only for booked jobs.'**
  String get publicProfileAreaPrivacy;

  /// No description provided for @publicProfileNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No work photos yet'**
  String get publicProfileNoPhotos;

  /// No description provided for @publicProfilePhotoN.
  ///
  /// In en, this message translates to:
  /// **'Work photo {n} of {total}'**
  String publicProfilePhotoN(int n, int total);

  /// No description provided for @publicProfileRequestBooking.
  ///
  /// In en, this message translates to:
  /// **'Request booking'**
  String get publicProfileRequestBooking;

  /// No description provided for @publicProfileRatingReviews.
  ///
  /// In en, this message translates to:
  /// **'Rating & reviews'**
  String get publicProfileRatingReviews;

  /// No description provided for @publicProfileRecentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get publicProfileRecentReviews;

  /// No description provided for @rateHourly.
  ///
  /// In en, this message translates to:
  /// **'{price} / hour'**
  String rateHourly(String price);

  /// No description provided for @rateDaily.
  ///
  /// In en, this message translates to:
  /// **'{price} / day'**
  String rateDaily(String price);

  /// No description provided for @rateOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Rate on request'**
  String get rateOnRequest;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfile;

  /// No description provided for @reportProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this profile?'**
  String get reportProfileTitle;

  /// No description provided for @reportReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get reportReasonSafety;

  /// No description provided for @reportReasonMisleading.
  ///
  /// In en, this message translates to:
  /// **'Misleading profile or credentials'**
  String get reportReasonMisleading;

  /// No description provided for @reportReasonConduct.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate conduct'**
  String get reportReasonConduct;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Our team will review it.'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report. Please try again.'**
  String get reportFailed;

  /// No description provided for @reviewsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get reviewsSortRecent;

  /// No description provided for @reviewsSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest rating'**
  String get reviewsSortHighest;

  /// No description provided for @reviewsSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest rating'**
  String get reviewsSortLowest;

  /// No description provided for @reviewsHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful ({count})'**
  String reviewsHelpful(int count);

  /// No description provided for @reviewsReplyFrom.
  ///
  /// In en, this message translates to:
  /// **'Reply from {name}'**
  String reviewsReplyFrom(String name);

  /// No description provided for @reviewsReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to review'**
  String get reviewsReplyTitle;

  /// No description provided for @reviewsReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a polite, helpful reply…'**
  String get reviewsReplyHint;

  /// No description provided for @reviewsReplySubmit.
  ///
  /// In en, this message translates to:
  /// **'Post reply'**
  String get reviewsReplySubmit;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & legal'**
  String get settingsHelp;

  /// No description provided for @settingsSupportBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp or email.'**
  String get settingsSupportBody;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of SkillBridge?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to see your jobs and messages.'**
  String get signOutConfirmBody;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get verificationTitle;

  /// No description provided for @verificationBadge.
  ///
  /// In en, this message translates to:
  /// **'ID verified'**
  String get verificationBadge;

  /// No description provided for @verificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get verificationOpen;

  /// No description provided for @verificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Verification status couldn\'t load'**
  String get verificationLoadError;

  /// No description provided for @verificationIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the Verified badge'**
  String get verificationIntroTitle;

  /// No description provided for @verificationIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Verified workers show clients their identity was checked by SkillBridge.'**
  String get verificationIntroBody;

  /// No description provided for @verificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verificationPendingTitle;

  /// No description provided for @verificationPendingShort.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get verificationPendingShort;

  /// No description provided for @verificationPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing your documents. You will be notified when it’s done.'**
  String get verificationPendingBody;

  /// No description provided for @verificationVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'You are verified'**
  String get verificationVerifiedTitle;

  /// No description provided for @verificationVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Clients see the Verified badge on your profile.'**
  String get verificationVerifiedBody;

  /// No description provided for @verificationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get verificationRejectedTitle;

  /// No description provided for @verificationRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify these documents. Please submit clear photos again.'**
  String get verificationRejectedBody;

  /// No description provided for @verificationCnicOnFile.
  ///
  /// In en, this message translates to:
  /// **'CNIC: {cnic}'**
  String verificationCnicOnFile(String cnic);

  /// No description provided for @verificationDocsOnFile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document} other{{count} documents}}'**
  String verificationDocsOnFile(int count);

  /// No description provided for @verificationSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String verificationSubmittedOn(String date);

  /// No description provided for @verificationUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update submission'**
  String get verificationUpdate;

  /// No description provided for @verificationCnicLabel.
  ///
  /// In en, this message translates to:
  /// **'CNIC number'**
  String get verificationCnicLabel;

  /// No description provided for @verificationCnicHelp.
  ///
  /// In en, this message translates to:
  /// **'Kept private. Only SkillBridge staff can see it.'**
  String get verificationCnicHelp;

  /// No description provided for @verificationCnicInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 13 digits, like 35202-1234567-1.'**
  String get verificationCnicInvalid;

  /// No description provided for @verificationDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get verificationDocsTitle;

  /// No description provided for @verificationDocsHelp.
  ///
  /// In en, this message translates to:
  /// **'Clear photos, all four corners visible. Max 5 MB each.'**
  String get verificationDocsHelp;

  /// No description provided for @verificationDocFront.
  ///
  /// In en, this message translates to:
  /// **'CNIC — front'**
  String get verificationDocFront;

  /// No description provided for @verificationDocBack.
  ///
  /// In en, this message translates to:
  /// **'CNIC — back'**
  String get verificationDocBack;

  /// No description provided for @verificationDocExtra.
  ///
  /// In en, this message translates to:
  /// **'Trade certificate'**
  String get verificationDocExtra;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get verificationRequired;

  /// No description provided for @verificationUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get verificationUpload;

  /// No description provided for @verificationReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get verificationReplace;

  /// No description provided for @verificationUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get verificationUploaded;

  /// No description provided for @verificationUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String verificationUploading(int percent);

  /// No description provided for @verificationDocMissing.
  ///
  /// In en, this message translates to:
  /// **'Upload this document.'**
  String get verificationDocMissing;

  /// No description provided for @verificationConsent.
  ///
  /// In en, this message translates to:
  /// **'These documents are mine, and SkillBridge staff may review them to verify my identity.'**
  String get verificationConsent;

  /// No description provided for @verificationConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm to continue.'**
  String get verificationConsentRequired;

  /// No description provided for @verificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get verificationSubmit;

  /// No description provided for @verificationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted. We’ll let you know once it’s reviewed.'**
  String get verificationSubmitted;

  /// No description provided for @verificationSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit. Check your connection and try again.'**
  String get verificationSubmitFailed;

  /// No description provided for @verificationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your CNIC and documents are stored privately. They never appear on your public profile.'**
  String get verificationPrivacyNote;

  /// No description provided for @verificationLegacyNotice.
  ///
  /// In en, this message translates to:
  /// **'An older version saved your CNIC on your public profile. You can remove that copy.'**
  String get verificationLegacyNotice;

  /// No description provided for @verificationLegacyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from public profile'**
  String get verificationLegacyRemove;

  /// No description provided for @verificationLegacyRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove CNIC from your public profile?'**
  String get verificationLegacyRemoveTitle;

  /// No description provided for @verificationLegacyRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the old public copy only. Submit your CNIC below to keep it private.'**
  String get verificationLegacyRemoveBody;

  /// No description provided for @verificationLegacyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from your public profile.'**
  String get verificationLegacyRemoved;

  /// No description provided for @workerProfileNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not set up yet.'**
  String get workerProfileNotStarted;

  /// No description provided for @workerProfileRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get workerProfileRate;

  /// No description provided for @workerSetupStepWork.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get workerSetupStepWork;

  /// No description provided for @workerSetupStepRates.
  ///
  /// In en, this message translates to:
  /// **'Rates & area'**
  String get workerSetupStepRates;

  /// No description provided for @workerSetupStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Work photos'**
  String get workerSetupStepPhotos;

  /// No description provided for @workerSetupStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get workerSetupStepVerify;

  /// No description provided for @workerSetupYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Let clients know who you are'**
  String get workerSetupYouTitle;

  /// No description provided for @workerSetupYouBody.
  ///
  /// In en, this message translates to:
  /// **'A real photo and name build trust.'**
  String get workerSetupYouBody;

  /// No description provided for @workerSetupPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Use a clear photo of your face.'**
  String get workerSetupPhotoHint;

  /// No description provided for @workerSetupPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Clients you work with can call you on this number.'**
  String get workerSetupPhoneHelp;

  /// No description provided for @workerSetupWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you do?'**
  String get workerSetupWorkTitle;

  /// No description provided for @workerSetupWorkBody.
  ///
  /// In en, this message translates to:
  /// **'Clients search by trade and skills.'**
  String get workerSetupWorkBody;

  /// No description provided for @workerSetupHeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional title'**
  String get workerSetupHeadlineLabel;

  /// No description provided for @workerSetupHeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Certified electrician, 9 years'**
  String get workerSetupHeadlineHint;

  /// No description provided for @workerSetupHeadlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title of at least 8 characters.'**
  String get workerSetupHeadlineRequired;

  /// No description provided for @workerSetupCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose your main trade.'**
  String get workerSetupCategoryRequired;

  /// No description provided for @workerSetupSkillsRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose or add at least one skill.'**
  String get workerSetupSkillsRequired;

  /// No description provided for @workerSetupAddSkill.
  ///
  /// In en, this message translates to:
  /// **'Add another skill'**
  String get workerSetupAddSkill;

  /// No description provided for @workerSetupAddSkillHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Solar wiring'**
  String get workerSetupAddSkillHint;

  /// No description provided for @workerSetupAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get workerSetupAdd;

  /// No description provided for @workerSetupExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get workerSetupExperienceLabel;

  /// No description provided for @workerSetupExperienceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 60.'**
  String get workerSetupExperienceInvalid;

  /// No description provided for @workerSetupBioLabel.
  ///
  /// In en, this message translates to:
  /// **'About your work'**
  String get workerSetupBioLabel;

  /// No description provided for @workerSetupBioHint.
  ///
  /// In en, this message translates to:
  /// **'What you do best, tools you bring, areas you cover…'**
  String get workerSetupBioHint;

  /// No description provided for @workerSetupBioRequired.
  ///
  /// In en, this message translates to:
  /// **'Write at least 30 characters.'**
  String get workerSetupBioRequired;

  /// No description provided for @workerSetupLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get workerSetupLanguages;

  /// No description provided for @workerSetupRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rates and service area'**
  String get workerSetupRatesTitle;

  /// No description provided for @workerSetupRatesBody.
  ///
  /// In en, this message translates to:
  /// **'Clients see your rate before contacting you.'**
  String get workerSetupRatesBody;

  /// No description provided for @workerSetupRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero, or leave it empty.'**
  String get workerSetupRateInvalid;

  /// No description provided for @workerSetupRateNote.
  ///
  /// In en, this message translates to:
  /// **'Leave both empty to show “Rate on request”.'**
  String get workerSetupRateNote;

  /// No description provided for @workerSetupServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Where you work'**
  String get workerSetupServiceArea;

  /// No description provided for @workerSetupNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get workerSetupNoLocation;

  /// No description provided for @workerSetupPickLocation.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get workerSetupPickLocation;

  /// No description provided for @workerSetupAreaRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your location or choose a city.'**
  String get workerSetupAreaRequired;

  /// No description provided for @workerSetupRadius.
  ///
  /// In en, this message translates to:
  /// **'Travel up to {km} km'**
  String workerSetupRadius(int km);

  /// No description provided for @workerSetupLocationPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Clients see your city and travel distance, not your address.'**
  String get workerSetupLocationPrivacy;

  /// No description provided for @workerSetupPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Show your work'**
  String get workerSetupPhotosTitle;

  /// No description provided for @workerSetupPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Photos of real jobs help clients choose you.'**
  String get workerSetupPhotosBody;

  /// No description provided for @workerSetupVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get workerSetupVerifyTitle;

  /// No description provided for @workerSetupVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Optional, and it can be done later.'**
  String get workerSetupVerifyBody;

  /// No description provided for @workerSetupVerifyPoint1.
  ///
  /// In en, this message translates to:
  /// **'Clients trust verified workers more.'**
  String get workerSetupVerifyPoint1;

  /// No description provided for @workerSetupVerifyPoint2.
  ///
  /// In en, this message translates to:
  /// **'Your CNIC stays private — only staff see it.'**
  String get workerSetupVerifyPoint2;

  /// No description provided for @workerSetupVerifyPoint3.
  ///
  /// In en, this message translates to:
  /// **'It takes about two minutes.'**
  String get workerSetupVerifyPoint3;

  /// No description provided for @workerSetupVerifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify my identity'**
  String get workerSetupVerifyNow;

  /// No description provided for @workerSetupSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & continue'**
  String get workerSetupSaveContinue;

  /// No description provided for @jobBand15kTo50k.
  ///
  /// In en, this message translates to:
  /// **'Rs 15,000 – 50,000'**
  String get jobBand15kTo50k;

  /// No description provided for @jobBand2kTo5k.
  ///
  /// In en, this message translates to:
  /// **'Rs 2,000 – 5,000'**
  String get jobBand2kTo5k;

  /// No description provided for @jobBand5kTo15k.
  ///
  /// In en, this message translates to:
  /// **'Rs 5,000 – 15,000'**
  String get jobBand5kTo15k;

  /// No description provided for @jobBandOver50k.
  ///
  /// In en, this message translates to:
  /// **'Rs 50,000+'**
  String get jobBandOver50k;

  /// No description provided for @jobBandUnder2k.
  ///
  /// In en, this message translates to:
  /// **'Under Rs 2,000'**
  String get jobBandUnder2k;

  /// No description provided for @jobBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get jobBudget;

  /// No description provided for @jobBudgetFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'{amount} · Fixed price'**
  String jobBudgetFixedPrice(String amount);

  /// No description provided for @jobBudgetNotSet.
  ///
  /// In en, this message translates to:
  /// **'Budget on request'**
  String get jobBudgetNotSet;

  /// No description provided for @jobBudgetPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String jobBudgetPerDay(String amount);

  /// No description provided for @jobBudgetPerHour.
  ///
  /// In en, this message translates to:
  /// **'{amount} / hour'**
  String jobBudgetPerHour(String amount);

  /// No description provided for @jobBudgetTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get jobBudgetTypeDaily;

  /// No description provided for @jobBudgetTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get jobBudgetTypeFixed;

  /// No description provided for @jobBudgetTypeHourly.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get jobBudgetTypeHourly;

  /// No description provided for @jobCannotEditBody.
  ///
  /// In en, this message translates to:
  /// **'Only open jobs you posted can be edited.'**
  String get jobCannotEditBody;

  /// No description provided for @jobCannotEditTitle.
  ///
  /// In en, this message translates to:
  /// **'This job can\'t be edited'**
  String get jobCannotEditTitle;

  /// No description provided for @jobClientEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get jobClientEmailVerified;

  /// No description provided for @jobClientFallback.
  ///
  /// In en, this message translates to:
  /// **'SkillBridge client'**
  String get jobClientFallback;

  /// No description provided for @jobClose.
  ///
  /// In en, this message translates to:
  /// **'Close job'**
  String get jobClose;

  /// No description provided for @jobCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Workers will no longer see it. It stays in your history and you can reopen it later.'**
  String get jobCloseBody;

  /// No description provided for @jobCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this job?'**
  String get jobCloseTitle;

  /// No description provided for @jobClosed.
  ///
  /// In en, this message translates to:
  /// **'Job closed.'**
  String get jobClosed;

  /// No description provided for @jobClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This job is closed. Workers can no longer find it.'**
  String get jobClosedNotice;

  /// No description provided for @jobConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Workers in {city} will be able to find it. You can edit or close it later.'**
  String jobConfirmBody(String city);

  /// No description provided for @jobConfirmDirectBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will get your request and can accept or decline it.'**
  String jobConfirmDirectBody(String name);

  /// No description provided for @jobConfirmDirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this request to {name}?'**
  String jobConfirmDirectTitle(String name);

  /// No description provided for @jobConfirmKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get jobConfirmKeepEditing;

  /// No description provided for @jobConfirmPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish job'**
  String get jobConfirmPublish;

  /// No description provided for @jobConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get jobConfirmSend;

  /// No description provided for @jobConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish this job?'**
  String get jobConfirmTitle;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobDescription;

  /// No description provided for @jobDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobDetailsTitle;

  /// No description provided for @jobDirectRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested from'**
  String get jobDirectRequestLabel;

  /// No description provided for @jobDirectTo.
  ///
  /// In en, this message translates to:
  /// **'Request to {name}'**
  String jobDirectTo(String name);

  /// No description provided for @jobEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get jobEdit;

  /// No description provided for @jobFeedBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get jobFeedBudget;

  /// No description provided for @jobFeedClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get jobFeedClearAll;

  /// No description provided for @jobFeedClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get jobFeedClearSearch;

  /// No description provided for @jobFeedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When clients post jobs, they will appear here. Pull down to check again.'**
  String get jobFeedEmptyBody;

  /// No description provided for @jobFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No open jobs yet'**
  String get jobFeedEmptyTitle;

  /// No description provided for @jobFeedEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen all matching jobs.'**
  String get jobFeedEnd;

  /// No description provided for @jobFeedErrorIndex.
  ///
  /// In en, this message translates to:
  /// **'Search for this combination is being set up. Try fewer filters for now.'**
  String get jobFeedErrorIndex;

  /// No description provided for @jobFeedErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t browse jobs right now.'**
  String get jobFeedErrorPermission;

  /// No description provided for @jobFeedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load jobs'**
  String get jobFeedErrorTitle;

  /// No description provided for @jobFeedFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get jobFeedFilters;

  /// No description provided for @jobFeedLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get jobFeedLoadMore;

  /// No description provided for @jobFeedLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more. Tap to try again.'**
  String get jobFeedLoadMoreFailed;

  /// No description provided for @jobFeedNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or remove a filter.'**
  String get jobFeedNoMatchBody;

  /// No description provided for @jobFeedNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No jobs match'**
  String get jobFeedNoMatchTitle;

  /// No description provided for @jobFeedPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get jobFeedPosted;

  /// No description provided for @jobFeedRemoveFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String jobFeedRemoveFilter(String label);

  /// No description provided for @jobFeedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, e.g. wiring, plumber'**
  String get jobFeedSearchHint;

  /// No description provided for @jobFeedSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get jobFeedSearching;

  /// No description provided for @jobFeedShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get jobFeedShowResults;

  /// No description provided for @jobFeedShowing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs} =1{1 job} other{{count} jobs}}'**
  String jobFeedShowing(int count);

  /// No description provided for @jobFeedSkillsNeedCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category to filter by skills.'**
  String get jobFeedSkillsNeedCategory;

  /// No description provided for @jobFeedSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get jobFeedSort;

  /// No description provided for @jobFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Find work'**
  String get jobFeedTitle;

  /// No description provided for @jobFormAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gulberg III'**
  String get jobFormAreaHint;

  /// No description provided for @jobFormBudgetHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave “Up to” empty for a single amount. Final price is agreed with the worker.'**
  String get jobFormBudgetHelp;

  /// No description provided for @jobFormBudgetMaxInvalid.
  ///
  /// In en, this message translates to:
  /// **'“Up to” must be at least the first amount.'**
  String get jobFormBudgetMaxInvalid;

  /// No description provided for @jobFormBudgetMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Up to'**
  String get jobFormBudgetMaxLabel;

  /// No description provided for @jobFormBudgetMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get jobFormBudgetMinLabel;

  /// No description provided for @jobFormBudgetRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0.'**
  String get jobFormBudgetRequired;

  /// No description provided for @jobFormBudgetTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Enter up to Rs 10,000,000.'**
  String get jobFormBudgetTooHigh;

  /// No description provided for @jobFormBudgetTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'How will you pay?'**
  String get jobFormBudgetTypeLabel;

  /// No description provided for @jobFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get jobFormCategoryLabel;

  /// No description provided for @jobFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category.'**
  String get jobFormCategoryRequired;

  /// No description provided for @jobFormCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose your city.'**
  String get jobFormCityRequired;

  /// No description provided for @jobFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What needs doing, what you\'ve noticed, and anything the worker should bring.'**
  String get jobFormDescriptionHint;

  /// No description provided for @jobFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe the work'**
  String get jobFormDescriptionLabel;

  /// No description provided for @jobFormDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least 30 characters so workers understand the job.'**
  String get jobFormDescriptionRequired;

  /// No description provided for @jobFormDirectNote.
  ///
  /// In en, this message translates to:
  /// **'Only {name} will see this request.'**
  String jobFormDirectNote(String name);

  /// No description provided for @jobFormFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get jobFormFixErrors;

  /// No description provided for @jobFormPhotosHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Up to {max} clear photos of the problem.'**
  String jobFormPhotosHelp(int max);

  /// No description provided for @jobFormPreferredDateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a preferred date (optional)'**
  String get jobFormPreferredDateAdd;

  /// No description provided for @jobFormPreferredDateClear.
  ///
  /// In en, this message translates to:
  /// **'Remove date'**
  String get jobFormPreferredDateClear;

  /// No description provided for @jobFormPreferredDateValue.
  ///
  /// In en, this message translates to:
  /// **'Preferred: {date}'**
  String jobFormPreferredDateValue(String date);

  /// No description provided for @jobFormRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'Fields marked * are required.'**
  String get jobFormRequiredNote;

  /// No description provided for @jobFormReview.
  ///
  /// In en, this message translates to:
  /// **'Review and publish'**
  String get jobFormReview;

  /// No description provided for @jobFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get jobFormSaveChanges;

  /// No description provided for @jobFormSectionBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get jobFormSectionBudget;

  /// No description provided for @jobFormSectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get jobFormSectionPhotos;

  /// No description provided for @jobFormSectionWhat.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get jobFormSectionWhat;

  /// No description provided for @jobFormSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get jobFormSectionWhen;

  /// No description provided for @jobFormSectionWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get jobFormSectionWhere;

  /// No description provided for @jobFormSkillAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get jobFormSkillAdd;

  /// No description provided for @jobFormSkillAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gas leak check'**
  String get jobFormSkillAddHint;

  /// No description provided for @jobFormSkillAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Another skill'**
  String get jobFormSkillAddLabel;

  /// No description provided for @jobFormSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick the skills the job needs (up to {max}).'**
  String jobFormSkillsHelp(int max);

  /// No description provided for @jobFormSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills needed'**
  String get jobFormSkillsLabel;

  /// No description provided for @jobFormSkillsMax.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 10 skills.'**
  String get jobFormSkillsMax;

  /// No description provided for @jobFormTitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Request {name}'**
  String jobFormTitleDirect(String name);

  /// No description provided for @jobFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get jobFormTitleEdit;

  /// No description provided for @jobFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fix two kitchen sockets'**
  String get jobFormTitleHint;

  /// No description provided for @jobFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobFormTitleLabel;

  /// No description provided for @jobFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get jobFormTitleNew;

  /// No description provided for @jobFormTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title of at least 10 characters.'**
  String get jobFormTitleRequired;

  /// No description provided for @jobLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this job'**
  String get jobLoadError;

  /// No description provided for @jobMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String jobMemberSince(String date);

  /// No description provided for @jobMessageClient.
  ///
  /// In en, this message translates to:
  /// **'Message client'**
  String get jobMessageClient;

  /// No description provided for @jobMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the chat. Please try again.'**
  String get jobMessageFailed;

  /// No description provided for @jobNoProposalsYet.
  ///
  /// In en, this message translates to:
  /// **'No proposals yet'**
  String get jobNoProposalsYet;

  /// No description provided for @jobNotClient.
  ///
  /// In en, this message translates to:
  /// **'Only client accounts can post jobs.'**
  String get jobNotClient;

  /// No description provided for @jobOwnerPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Your job'**
  String get jobOwnerPanelTitle;

  /// No description provided for @jobPostedAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get jobPostedAnyTime;

  /// No description provided for @jobPostedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get jobPostedBy;

  /// No description provided for @jobPostedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {days} days ago'**
  String jobPostedDaysAgo(int days);

  /// No description provided for @jobPostedLast24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get jobPostedLast24h;

  /// No description provided for @jobPostedLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get jobPostedLast30Days;

  /// No description provided for @jobPostedLast3Days.
  ///
  /// In en, this message translates to:
  /// **'Last 3 days'**
  String get jobPostedLast3Days;

  /// No description provided for @jobPostedLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get jobPostedLast7Days;

  /// No description provided for @jobPostedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted {date}'**
  String jobPostedOn(String date);

  /// No description provided for @jobPostedToday.
  ///
  /// In en, this message translates to:
  /// **'Posted today'**
  String get jobPostedToday;

  /// No description provided for @jobPostedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Posted yesterday'**
  String get jobPostedYesterday;

  /// No description provided for @jobPreferredOn.
  ///
  /// In en, this message translates to:
  /// **'Preferred {date}'**
  String jobPreferredOn(String date);

  /// No description provided for @jobProposalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 proposal} other{{count} proposals}}'**
  String jobProposalsCount(int count);

  /// No description provided for @jobPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish the job. Check your connection and try again.'**
  String get jobPublishFailed;

  /// No description provided for @jobPublished.
  ///
  /// In en, this message translates to:
  /// **'Job published. Workers can now find it.'**
  String get jobPublished;

  /// No description provided for @jobQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. The job is saved on this phone and will publish when you\'re back online.'**
  String get jobQueuedOffline;

  /// No description provided for @jobReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get jobReopen;

  /// No description provided for @jobReopenBody.
  ///
  /// In en, this message translates to:
  /// **'Workers will be able to find it again.'**
  String get jobReopenBody;

  /// No description provided for @jobReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen this job?'**
  String get jobReopenTitle;

  /// No description provided for @jobReopened.
  ///
  /// In en, this message translates to:
  /// **'Job reopened.'**
  String get jobReopened;

  /// No description provided for @jobReport.
  ///
  /// In en, this message translates to:
  /// **'Report job'**
  String get jobReport;

  /// No description provided for @jobReportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get jobReportInappropriate;

  /// No description provided for @jobReportMisleading.
  ///
  /// In en, this message translates to:
  /// **'Misleading or fake job'**
  String get jobReportMisleading;

  /// No description provided for @jobReportScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get jobReportScam;

  /// No description provided for @jobReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this job?'**
  String get jobReportTitle;

  /// No description provided for @jobSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get jobSaved;

  /// No description provided for @jobSortBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget: high to low'**
  String get jobSortBudgetHigh;

  /// No description provided for @jobSortBudgetLow.
  ///
  /// In en, this message translates to:
  /// **'Budget: low to high'**
  String get jobSortBudgetLow;

  /// No description provided for @jobSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get jobSortNewest;

  /// No description provided for @jobSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get jobSortOldest;

  /// No description provided for @jobStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get jobStatusAssigned;

  /// No description provided for @jobStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get jobStatusClosed;

  /// No description provided for @jobStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobStatusCompleted;

  /// No description provided for @jobStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobStatusInProgress;

  /// No description provided for @jobStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get jobStatusOpen;

  /// No description provided for @jobSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended, so you can\'t post jobs.'**
  String get jobSuspended;

  /// No description provided for @jobSuspendedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. You can view jobs but not act on them.'**
  String get jobSuspendedNotice;

  /// No description provided for @jobUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been closed or filled.'**
  String get jobUnavailableBody;

  /// No description provided for @jobUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer available'**
  String get jobUnavailableTitle;

  /// No description provided for @jobUrgencyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get jobUrgencyFlexible;

  /// No description provided for @jobUrgencyImmediate.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get jobUrgencyImmediate;

  /// No description provided for @jobUrgencyThreeDays.
  ///
  /// In en, this message translates to:
  /// **'Within 3 days'**
  String get jobUrgencyThreeDays;

  /// No description provided for @jobView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get jobView;

  /// No description provided for @myJobsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Post a job and nearby workers will be able to find it.'**
  String get myJobsEmptyBody;

  /// No description provided for @myJobsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted a job yet'**
  String get myJobsEmptyTitle;

  /// No description provided for @myJobsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your jobs'**
  String get myJobsLoadError;

  /// No description provided for @myJobsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myJobsTabActive;

  /// No description provided for @myJobsTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jobs here.'**
  String get myJobsTabEmpty;

  /// No description provided for @myJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My jobs'**
  String get myJobsTitle;

  /// No description provided for @jobSortBudgetWithin.
  ///
  /// In en, this message translates to:
  /// **'{sort} · {type}'**
  String jobSortBudgetWithin(String sort, String type);

  /// No description provided for @jobFeedBudgetSortNote.
  ///
  /// In en, this message translates to:
  /// **'Budget order compares jobs of one pay type at a time.'**
  String get jobFeedBudgetSortNote;

  /// No description provided for @myProposalsTitle.
  ///
  /// In en, this message translates to:
  /// **'My proposals'**
  String get myProposalsTitle;

  /// No description provided for @myProposalsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your proposals'**
  String get myProposalsLoadError;

  /// No description provided for @myProposalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No proposals yet'**
  String get myProposalsEmptyTitle;

  /// No description provided for @myProposalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Find an open job and send your price and a short note to the client.'**
  String get myProposalsEmptyBody;

  /// No description provided for @myProposalsFindWork.
  ///
  /// In en, this message translates to:
  /// **'Find work'**
  String get myProposalsFindWork;

  /// No description provided for @myProposalsTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No proposals here.'**
  String get myProposalsTabEmpty;

  /// No description provided for @proposalStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get proposalStatusPending;

  /// No description provided for @proposalStatusViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get proposalStatusViewed;

  /// No description provided for @proposalStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get proposalStatusAccepted;

  /// No description provided for @proposalStatusFilled.
  ///
  /// In en, this message translates to:
  /// **'Job filled'**
  String get proposalStatusFilled;

  /// No description provided for @proposalStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get proposalStatusDeclined;

  /// No description provided for @proposalStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get proposalStatusWithdrawn;

  /// No description provided for @proposalTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get proposalTabActive;

  /// No description provided for @proposalTabNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get proposalTabNotSelected;

  /// No description provided for @proposalRating.
  ///
  /// In en, this message translates to:
  /// **'★ {rating} ({count} reviews)'**
  String proposalRating(String rating, int count);

  /// No description provided for @proposalExperience.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs experience'**
  String proposalExperience(int years);

  /// No description provided for @proposalViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get proposalViewProfile;

  /// No description provided for @proposalFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a proposal'**
  String get proposalFormTitle;

  /// No description provided for @proposalFormTitleAgain.
  ///
  /// In en, this message translates to:
  /// **'Send proposal again'**
  String get proposalFormTitleAgain;

  /// No description provided for @proposalOnlyWorkers.
  ///
  /// In en, this message translates to:
  /// **'Only workers can send proposals'**
  String get proposalOnlyWorkers;

  /// No description provided for @proposalOnlyWorkersBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a worker account to apply for jobs.'**
  String get proposalOnlyWorkersBody;

  /// No description provided for @proposalSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended'**
  String get proposalSuspended;

  /// No description provided for @proposalOwnJob.
  ///
  /// In en, this message translates to:
  /// **'This is your job'**
  String get proposalOwnJob;

  /// No description provided for @proposalOwnJobBody.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send a proposal for a job you posted.'**
  String get proposalOwnJobBody;

  /// No description provided for @proposalAlreadySentTitle.
  ///
  /// In en, this message translates to:
  /// **'You already sent a proposal'**
  String get proposalAlreadySentTitle;

  /// No description provided for @proposalAlreadySentBody.
  ///
  /// In en, this message translates to:
  /// **'One proposal per job. You can view it, or withdraw it while it\'s pending.'**
  String get proposalAlreadySentBody;

  /// No description provided for @proposalView.
  ///
  /// In en, this message translates to:
  /// **'View proposal'**
  String get proposalView;

  /// No description provided for @proposalJobClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'This job isn\'t taking proposals'**
  String get proposalJobClosedTitle;

  /// No description provided for @proposalJobClosedBody.
  ///
  /// In en, this message translates to:
  /// **'The job was filled, closed or changed. Look for other open jobs.'**
  String get proposalJobClosedBody;

  /// No description provided for @proposalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this proposal?'**
  String get proposalConfirmTitle;

  /// No description provided for @proposalConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The client will see your price, timing, note and public profile. You can withdraw it while it\'s pending.'**
  String get proposalConfirmBody;

  /// No description provided for @proposalSend.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get proposalSend;

  /// No description provided for @proposalSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get proposalSendAgain;

  /// No description provided for @proposalSendCta.
  ///
  /// In en, this message translates to:
  /// **'Send a proposal'**
  String get proposalSendCta;

  /// No description provided for @proposalSent.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent'**
  String get proposalSent;

  /// No description provided for @proposalSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your proposal. Try again.'**
  String get proposalSendFailed;

  /// No description provided for @proposalDurationSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get proposalDurationSameDay;

  /// No description provided for @proposalDuration1to2.
  ///
  /// In en, this message translates to:
  /// **'1–2 days'**
  String get proposalDuration1to2;

  /// No description provided for @proposalDuration3to5.
  ///
  /// In en, this message translates to:
  /// **'3–5 days'**
  String get proposalDuration3to5;

  /// No description provided for @proposalDurationWeek.
  ///
  /// In en, this message translates to:
  /// **'About a week'**
  String get proposalDurationWeek;

  /// No description provided for @proposalDuration2Weeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks or more'**
  String get proposalDuration2Weeks;

  /// No description provided for @proposalReview.
  ///
  /// In en, this message translates to:
  /// **'Review and send'**
  String get proposalReview;

  /// No description provided for @proposalClientBudget.
  ///
  /// In en, this message translates to:
  /// **'Client\'s budget: {budget}'**
  String proposalClientBudget(String budget);

  /// No description provided for @proposalResendNote.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your earlier proposal. Sending again puts it back in the client\'s list.'**
  String get proposalResendNote;

  /// No description provided for @proposalPriceSection.
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get proposalPriceSection;

  /// No description provided for @proposalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (Rs)'**
  String get proposalPriceLabel;

  /// No description provided for @proposalDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'How long it will take'**
  String get proposalDurationLabel;

  /// No description provided for @proposalDurationField.
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get proposalDurationField;

  /// No description provided for @proposalDurationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 days'**
  String get proposalDurationHint;

  /// No description provided for @proposalDurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Say how long the work will take'**
  String get proposalDurationRequired;

  /// No description provided for @proposalCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Note to the client'**
  String get proposalCoverLabel;

  /// No description provided for @proposalCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Your experience with this kind of work, and how you\'d do it'**
  String get proposalCoverHint;

  /// No description provided for @proposalCoverRequired.
  ///
  /// In en, this message translates to:
  /// **'Write at least 30 characters'**
  String get proposalCoverRequired;

  /// No description provided for @proposalProfileNote.
  ///
  /// In en, this message translates to:
  /// **'Your public profile (photo, skills, work photos, reviews) is shared with this proposal.'**
  String get proposalProfileNote;

  /// No description provided for @proposalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposal'**
  String get proposalDetailsTitle;

  /// No description provided for @proposalUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposal not available'**
  String get proposalUnavailableTitle;

  /// No description provided for @proposalUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or this account can\'t see it.'**
  String get proposalUnavailableBody;

  /// No description provided for @proposalAcceptUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This job or proposal changed. Refresh and try again.'**
  String get proposalAcceptUnavailable;

  /// No description provided for @proposalActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the proposal. Try again.'**
  String get proposalActionFailed;

  /// No description provided for @proposalWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get proposalWithdraw;

  /// No description provided for @proposalWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this proposal?'**
  String get proposalWithdrawTitle;

  /// No description provided for @proposalWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'The client will no longer see it. You can send it again while the job is open.'**
  String get proposalWithdrawBody;

  /// No description provided for @proposalWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Proposal withdrawn'**
  String get proposalWithdrawn;

  /// No description provided for @proposalDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get proposalDecline;

  /// No description provided for @proposalDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline {name}\'s proposal?'**
  String proposalDeclineTitle(String name);

  /// No description provided for @proposalDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll see it was not selected. This can\'t be undone.'**
  String get proposalDeclineBody;

  /// No description provided for @proposalDeclined.
  ///
  /// In en, this message translates to:
  /// **'Proposal declined'**
  String get proposalDeclined;

  /// No description provided for @proposalAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and hire'**
  String get proposalAccept;

  /// No description provided for @proposalAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Hire {name}?'**
  String proposalAcceptTitle(String name);

  /// No description provided for @proposalAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'The job is assigned to them, a contract is created at this price and the other proposals are closed. No payment is taken in the app.'**
  String get proposalAcceptBody;

  /// No description provided for @proposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted. Contract created.'**
  String get proposalAccepted;

  /// No description provided for @proposalAcceptedNotice.
  ///
  /// In en, this message translates to:
  /// **'Accepted. The contract is in Contracts; agree how and when to pay in chat.'**
  String get proposalAcceptedNotice;

  /// No description provided for @proposalMessageWorker.
  ///
  /// In en, this message translates to:
  /// **'Message worker'**
  String get proposalMessageWorker;

  /// No description provided for @proposalViewJob.
  ///
  /// In en, this message translates to:
  /// **'View job'**
  String get proposalViewJob;

  /// No description provided for @proposalJobNotOpenNotice.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer open, so proposals can\'t be accepted.'**
  String get proposalJobNotOpenNotice;

  /// No description provided for @proposalFilledNotice.
  ///
  /// In en, this message translates to:
  /// **'The client hired someone else for this job.'**
  String get proposalFilledNotice;

  /// No description provided for @proposalAboutWorker.
  ///
  /// In en, this message translates to:
  /// **'About the worker'**
  String get proposalAboutWorker;

  /// No description provided for @proposalHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get proposalHistory;

  /// No description provided for @proposalSentOn.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String proposalSentOn(String date);

  /// No description provided for @proposalViewedOn.
  ///
  /// In en, this message translates to:
  /// **'Viewed by the client {date}'**
  String proposalViewedOn(String date);

  /// No description provided for @proposalAcceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Accepted {date}'**
  String proposalAcceptedOn(String date);

  /// No description provided for @proposalClosedOn.
  ///
  /// In en, this message translates to:
  /// **'Closed {date}'**
  String proposalClosedOn(String date);

  /// No description provided for @proposalWithdrawnOn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn {date}'**
  String proposalWithdrawnOn(String date);

  /// No description provided for @proposalViewMine.
  ///
  /// In en, this message translates to:
  /// **'View your proposal'**
  String get proposalViewMine;

  /// No description provided for @proposalYourStatus.
  ///
  /// In en, this message translates to:
  /// **'Your proposal:'**
  String get proposalYourStatus;

  /// No description provided for @receivedProposalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get receivedProposalsTitle;

  /// No description provided for @receivedProposalsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load proposals'**
  String get receivedProposalsLoadError;

  /// No description provided for @receivedProposalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No proposals yet'**
  String get receivedProposalsEmptyTitle;

  /// No description provided for @receivedProposalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Workers who apply will appear here.'**
  String get receivedProposalsEmptyBody;

  /// No description provided for @receivedProposalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No proposals} =1{1 proposal} other{{count} proposals}}'**
  String receivedProposalsCount(int count);

  /// No description provided for @proposalsViewReceived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{View proposals} other{View proposals ({count})}}'**
  String proposalsViewReceived(int count);

  /// No description provided for @proposalSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort proposals'**
  String get proposalSortTooltip;

  /// No description provided for @proposalSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get proposalSortNewest;

  /// No description provided for @proposalSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get proposalSortOldest;

  /// No description provided for @proposalSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get proposalSortPrice;

  /// No description provided for @proposalPriceSortNote.
  ///
  /// In en, this message translates to:
  /// **'Prices are compared within the same rate type (fixed, per day, per hour).'**
  String get proposalPriceSortNote;

  /// No description provided for @proposalCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get proposalCompare;

  /// No description provided for @proposalCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare proposals'**
  String get proposalCompareTitle;

  /// No description provided for @proposalReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get proposalReviewAction;

  /// No description provided for @proposalRateFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get proposalRateFixed;

  /// No description provided for @proposalRateDaily.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get proposalRateDaily;

  /// No description provided for @proposalRateHourly.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get proposalRateHourly;

  /// No description provided for @proposalYourBudget.
  ///
  /// In en, this message translates to:
  /// **'Your budget: {budget}'**
  String proposalYourBudget(String budget);

  /// No description provided for @jobHiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get jobHiredLabel;

  /// No description provided for @contractsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contractsTitle;

  /// No description provided for @contractsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your contracts'**
  String get contractsLoadError;

  /// No description provided for @contractsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get contractsEmptyTitle;

  /// No description provided for @contractsEmptyClient.
  ///
  /// In en, this message translates to:
  /// **'When you hire a worker, the contract appears here.'**
  String get contractsEmptyClient;

  /// No description provided for @contractsEmptyWorker.
  ///
  /// In en, this message translates to:
  /// **'When a client hires you, the contract appears here.'**
  String get contractsEmptyWorker;

  /// No description provided for @contractsTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get contractsTabRequests;

  /// No description provided for @contractsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get contractsTabActive;

  /// No description provided for @contractsTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get contractsTabCompleted;

  /// No description provided for @contractsTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get contractsTabCancelled;

  /// No description provided for @contractsTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contracts here.'**
  String get contractsTabEmpty;

  /// No description provided for @contractStageRequested.
  ///
  /// In en, this message translates to:
  /// **'Booking request'**
  String get contractStageRequested;

  /// No description provided for @contractStageNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get contractStageNotStarted;

  /// No description provided for @contractStageInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get contractStageInProgress;

  /// No description provided for @contractStageSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get contractStageSubmitted;

  /// No description provided for @contractStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get contractStageCompleted;

  /// No description provided for @contractStageCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get contractStageCancelled;

  /// No description provided for @contractStageDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get contractStageDeclined;

  /// No description provided for @contractCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String contractCreatedOn(String date);

  /// No description provided for @contractNextClientRequested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the worker to answer your request.'**
  String get contractNextClientRequested;

  /// No description provided for @contractNextWorkerRequested.
  ///
  /// In en, this message translates to:
  /// **'Accept or decline this booking request.'**
  String get contractNextWorkerRequested;

  /// No description provided for @contractNextClientNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the worker to start.'**
  String get contractNextClientNotStarted;

  /// No description provided for @contractNextWorkerNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start the work when you begin.'**
  String get contractNextWorkerNotStarted;

  /// No description provided for @contractNextClientInProgress.
  ///
  /// In en, this message translates to:
  /// **'The worker is on it. You\'ll review the work when it is submitted.'**
  String get contractNextClientInProgress;

  /// No description provided for @contractNextClientSubmitted.
  ///
  /// In en, this message translates to:
  /// **'The work was submitted. Review it and confirm completion.'**
  String get contractNextClientSubmitted;

  /// No description provided for @contractNextWorkerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Waiting for the client to confirm.'**
  String get contractNextWorkerSubmitted;

  /// No description provided for @contractProgressStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started {date}'**
  String contractProgressStarted(String date);

  /// No description provided for @contractProgressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String contractProgressCompleted(String date);

  /// No description provided for @contractProgressCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {date}'**
  String contractProgressCancelled(String date);

  /// No description provided for @contractDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractDetailsTitle;

  /// No description provided for @contractUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract not available'**
  String get contractUnavailableTitle;

  /// No description provided for @contractUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Only the client and the hired worker can see a contract.'**
  String get contractUnavailableBody;

  /// No description provided for @contractAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get contractAgreedPrice;

  /// No description provided for @contractPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Payment is agreed between you and is not processed in the app.'**
  String get contractPaymentNote;

  /// No description provided for @contractWorkSection.
  ///
  /// In en, this message translates to:
  /// **'The work'**
  String get contractWorkSection;

  /// No description provided for @contractArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get contractArea;

  /// No description provided for @contractExactAddress.
  ///
  /// In en, this message translates to:
  /// **'Exact address'**
  String get contractExactAddress;

  /// No description provided for @contractAddressNotShared.
  ///
  /// In en, this message translates to:
  /// **'The client hasn\'t shared it yet.'**
  String get contractAddressNotShared;

  /// No description provided for @contractShareAddress.
  ///
  /// In en, this message translates to:
  /// **'Share the exact address'**
  String get contractShareAddress;

  /// No description provided for @contractUpdateAddress.
  ///
  /// In en, this message translates to:
  /// **'Change the address'**
  String get contractUpdateAddress;

  /// No description provided for @contractShareAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Only the hired worker will see it, on this contract. Your public job shows just the area.'**
  String get contractShareAddressBody;

  /// No description provided for @contractShareAddressAction.
  ///
  /// In en, this message translates to:
  /// **'Share with the worker'**
  String get contractShareAddressAction;

  /// No description provided for @contractAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter the full address'**
  String get contractAddressTooShort;

  /// No description provided for @contractAddressShared.
  ///
  /// In en, this message translates to:
  /// **'Address shared with the worker'**
  String get contractAddressShared;

  /// No description provided for @contractYourWorker.
  ///
  /// In en, this message translates to:
  /// **'Your worker'**
  String get contractYourWorker;

  /// No description provided for @contractYourClient.
  ///
  /// In en, this message translates to:
  /// **'Your client'**
  String get contractYourClient;

  /// No description provided for @contractTrackWorker.
  ///
  /// In en, this message translates to:
  /// **'Track the worker'**
  String get contractTrackWorker;

  /// No description provided for @contractTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker location'**
  String get contractTrackTitle;

  /// No description provided for @contractTrackNote.
  ///
  /// In en, this message translates to:
  /// **'Shown only while the worker chooses to share it, and only to you.'**
  String get contractTrackNote;

  /// No description provided for @contractHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get contractHistory;

  /// No description provided for @contractEventRequested.
  ///
  /// In en, this message translates to:
  /// **'Booking requested'**
  String get contractEventRequested;

  /// No description provided for @contractEventRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted by the worker'**
  String get contractEventRequestAccepted;

  /// No description provided for @contractEventRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined by the worker'**
  String get contractEventRequestDeclined;

  /// No description provided for @contractEventProposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted'**
  String get contractEventProposalAccepted;

  /// No description provided for @contractEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Contract created'**
  String get contractEventCreated;

  /// No description provided for @contractEventAddressShared.
  ///
  /// In en, this message translates to:
  /// **'Exact address shared'**
  String get contractEventAddressShared;

  /// No description provided for @contractEventStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get contractEventStarted;

  /// No description provided for @contractEventSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Work submitted for review'**
  String get contractEventSubmitted;

  /// No description provided for @contractEventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completion confirmed by the client'**
  String get contractEventCompleted;

  /// No description provided for @contractEventCancelledByClient.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the client'**
  String get contractEventCancelledByClient;

  /// No description provided for @contractEventCancelledByWorker.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the worker'**
  String get contractEventCancelledByWorker;

  /// No description provided for @contractStart.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get contractStart;

  /// No description provided for @contractStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the work now?'**
  String get contractStartTitle;

  /// No description provided for @contractStartBody.
  ///
  /// In en, this message translates to:
  /// **'The client will see that work has started. Do this when you begin the job.'**
  String get contractStartBody;

  /// No description provided for @contractStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get contractStarted;

  /// No description provided for @contractSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit work'**
  String get contractSubmit;

  /// No description provided for @contractSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit work'**
  String get contractSubmitTitle;

  /// No description provided for @contractSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'The client will review it and either confirm completion or ask for changes. What you send is kept with the contract.'**
  String get contractSubmitBody;

  /// No description provided for @contractSubmitExplainer.
  ///
  /// In en, this message translates to:
  /// **'Describe what you did. Photos help the client check the work.'**
  String get contractSubmitExplainer;

  /// No description provided for @contractSubmitNote.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get contractSubmitNote;

  /// No description provided for @contractSubmitNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Replaced both sockets and tested the circuit'**
  String get contractSubmitNoteHint;

  /// No description provided for @contractSubmitNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Write at least 10 characters'**
  String get contractSubmitNoteRequired;

  /// No description provided for @contractSubmitPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional, up to {count})'**
  String contractSubmitPhotos(int count);

  /// No description provided for @contractSubmitPhotosNote.
  ///
  /// In en, this message translates to:
  /// **'Only you and the client can see them.'**
  String get contractSubmitPhotosNote;

  /// No description provided for @contractAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get contractAddPhoto;

  /// No description provided for @contractRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get contractRemovePhoto;

  /// No description provided for @contractPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is over 5 MB'**
  String get contractPhotoTooLarge;

  /// No description provided for @contractUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo {current} of {total}…'**
  String contractUploading(int current, int total);

  /// No description provided for @contractSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get contractSubmitReview;

  /// No description provided for @contractSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Work submitted for review'**
  String get contractSubmitted;

  /// No description provided for @contractSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit the work. Try again.'**
  String get contractSubmitFailed;

  /// No description provided for @contractOnlyWorkerSubmits.
  ///
  /// In en, this message translates to:
  /// **'Only the hired worker can submit the work.'**
  String get contractOnlyWorkerSubmits;

  /// No description provided for @contractAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'The work was already submitted.'**
  String get contractAlreadySubmitted;

  /// No description provided for @contractStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Start the work before submitting it.'**
  String get contractStartFirst;

  /// No description provided for @contractSubmittedWork.
  ///
  /// In en, this message translates to:
  /// **'Submitted work'**
  String get contractSubmittedWork;

  /// No description provided for @contractReviewWork.
  ///
  /// In en, this message translates to:
  /// **'Review the work'**
  String get contractReviewWork;

  /// No description provided for @contractSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String contractSubmittedOn(String date);

  /// No description provided for @contractEvidencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Work photo {number}'**
  String contractEvidencePhoto(int number);

  /// No description provided for @contractConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get contractConfirm;

  /// No description provided for @contractConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the work is complete?'**
  String get contractConfirmTitle;

  /// No description provided for @contractConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The contract and job are marked completed and you can both leave a review. This can\'t be undone.'**
  String get contractConfirmBody;

  /// No description provided for @contractConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Completion confirmed'**
  String get contractConfirmed;

  /// No description provided for @contractNoRevisionNote.
  ///
  /// In en, this message translates to:
  /// **'If something isn\'t right, message the worker before confirming.'**
  String get contractNoRevisionNote;

  /// No description provided for @contractCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'This contract is complete.'**
  String get contractCompletedNotice;

  /// No description provided for @contractWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get contractWriteReview;

  /// No description provided for @contractRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get contractRequestAccept;

  /// No description provided for @contractRequestAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this booking?'**
  String get contractRequestAcceptTitle;

  /// No description provided for @contractRequestAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'The contract becomes active. Start the work when you begin.'**
  String get contractRequestAcceptBody;

  /// No description provided for @contractRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking accepted'**
  String get contractRequestAccepted;

  /// No description provided for @contractRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get contractRequestDecline;

  /// No description provided for @contractRequestDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this booking?'**
  String get contractRequestDeclineTitle;

  /// No description provided for @contractRequestDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'The client will be told. This can\'t be undone.'**
  String get contractRequestDeclineBody;

  /// No description provided for @contractRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Booking declined'**
  String get contractRequestDeclined;

  /// No description provided for @contractDeclinedNotice.
  ///
  /// In en, this message translates to:
  /// **'The worker declined this booking request.'**
  String get contractDeclinedNotice;

  /// No description provided for @contractCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel contract'**
  String get contractCancel;

  /// No description provided for @contractWithdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get contractWithdrawRequest;

  /// No description provided for @contractCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this contract?'**
  String get contractCancelTitle;

  /// No description provided for @contractCancelBody.
  ///
  /// In en, this message translates to:
  /// **'The other person is told, and the reason is kept in the contract history. This can\'t be undone.'**
  String get contractCancelBody;

  /// No description provided for @contractCancelNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get contractCancelNote;

  /// No description provided for @contractKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep the contract'**
  String get contractKeep;

  /// No description provided for @contractCancelled.
  ///
  /// In en, this message translates to:
  /// **'Contract cancelled'**
  String get contractCancelled;

  /// No description provided for @contractCancelledNotice.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the {role}: {reason}'**
  String contractCancelledNotice(String role, String reason);

  /// No description provided for @contractRoleClient.
  ///
  /// In en, this message translates to:
  /// **'client'**
  String get contractRoleClient;

  /// No description provided for @contractRoleWorker.
  ///
  /// In en, this message translates to:
  /// **'worker'**
  String get contractRoleWorker;

  /// No description provided for @contractCancelReasonSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get contractCancelReasonSchedule;

  /// No description provided for @contractCancelReasonNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'No longer needed'**
  String get contractCancelReasonNotNeeded;

  /// No description provided for @contractCancelReasonAgreed.
  ///
  /// In en, this message translates to:
  /// **'Agreed with the other person'**
  String get contractCancelReasonAgreed;

  /// No description provided for @contractCancelReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get contractCancelReasonSafety;

  /// No description provided for @contractCancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get contractCancelReasonOther;

  /// No description provided for @contractActionChanged.
  ///
  /// In en, this message translates to:
  /// **'This contract changed. Check its current status.'**
  String get contractActionChanged;

  /// No description provided for @contractActionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do that on this contract.'**
  String get contractActionNotAllowed;

  /// No description provided for @contractActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the contract. Try again.'**
  String get contractActionFailed;

  /// No description provided for @contractCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractCardTitle;

  /// No description provided for @contractCardBody.
  ///
  /// In en, this message translates to:
  /// **'Start, submit and confirm the work on the contract.'**
  String get contractCardBody;

  /// No description provided for @contractNoneForJob.
  ///
  /// In en, this message translates to:
  /// **'No contract was found for this job.'**
  String get contractNoneForJob;

  /// No description provided for @contractOpen.
  ///
  /// In en, this message translates to:
  /// **'Open contract'**
  String get contractOpen;

  /// No description provided for @contractEventDirectAccepted.
  ///
  /// In en, this message translates to:
  /// **'Direct request accepted by the worker'**
  String get contractEventDirectAccepted;

  /// No description provided for @contractDirectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent to you'**
  String get contractDirectRequestTitle;

  /// No description provided for @contractDirectRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Only you received this job. Accepting creates a contract at the client\'s budget; agree the final price in chat.'**
  String get contractDirectRequestBody;

  /// No description provided for @contractDirectAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this request?'**
  String get contractDirectAcceptTitle;

  /// No description provided for @contractDirectAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'The job is assigned to you and a contract is created. Start the work when you begin.'**
  String get contractDirectAcceptBody;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatsTitle;

  /// No description provided for @chatsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your conversations'**
  String get chatsLoadError;

  /// No description provided for @chatsOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing conversations saved on this device.'**
  String get chatsOffline;

  /// No description provided for @chatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmptyTitle;

  /// No description provided for @chatsEmptyClient.
  ///
  /// In en, this message translates to:
  /// **'Message a worker from their profile, a proposal or a contract. Your conversations appear here.'**
  String get chatsEmptyClient;

  /// No description provided for @chatsEmptyWorker.
  ///
  /// In en, this message translates to:
  /// **'When you message a client about a job, or a client messages you, the conversation appears here.'**
  String get chatsEmptyWorker;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String chatYouPrefix(String text);

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @chatUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String chatUnreadCount(int count);

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatRoomLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this conversation'**
  String get chatRoomLoadError;

  /// No description provided for @chatRoomUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This conversation isn\'t available'**
  String get chatRoomUnavailableTitle;

  /// No description provided for @chatRoomUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Only the two people in a conversation can open it. Check that you\'re signed in with the right account.'**
  String get chatRoomUnavailableBody;

  /// No description provided for @chatMessagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get chatMessagesLoadError;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Messages here are visible only to you and {name}.'**
  String chatEmptyBody(String name);

  /// No description provided for @chatEarlier.
  ///
  /// In en, this message translates to:
  /// **'Show earlier messages'**
  String get chatEarlier;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get chatAddPhoto;

  /// No description provided for @chatRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get chatRemovePhoto;

  /// No description provided for @chatSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatSending;

  /// No description provided for @chatWaitingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get chatWaitingNetwork;

  /// No description provided for @chatSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatSent;

  /// No description provided for @chatSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get chatSeen;

  /// No description provided for @chatNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get chatNotSent;

  /// No description provided for @chatRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// No description provided for @chatDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get chatDiscard;

  /// No description provided for @chatNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This message can\'t be sent. The account may no longer be available.'**
  String get chatNotAllowed;

  /// No description provided for @chatOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Messages will send when you reconnect.'**
  String get chatOffline;

  /// No description provided for @chatPeerSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is no longer active. You can read past messages but can\'t send new ones.'**
  String get chatPeerSuspended;

  /// No description provided for @chatPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Each photo must be under 5 MB.'**
  String get chatPhotoTooLarge;

  /// No description provided for @chatPhotoType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG or WebP photo.'**
  String get chatPhotoType;

  /// No description provided for @chatPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 photos per message.'**
  String get chatPhotoLimit;

  /// No description provided for @chatPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get chatPhotoUnavailable;

  /// No description provided for @chatTooLong.
  ///
  /// In en, this message translates to:
  /// **'Messages can be up to 2,000 characters.'**
  String get chatTooLong;

  /// No description provided for @chatViewContract.
  ///
  /// In en, this message translates to:
  /// **'View contract'**
  String get chatViewContract;

  /// No description provided for @contractWhereThingsStand.
  ///
  /// In en, this message translates to:
  /// **'Where things stand'**
  String get contractWhereThingsStand;

  /// No description provided for @contractStepHired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get contractStepHired;

  /// No description provided for @contractStepStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get contractStepStarted;

  /// No description provided for @contractStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get contractStepSubmitted;

  /// No description provided for @contractStepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get contractStepConfirmed;

  /// No description provided for @contractStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps done'**
  String contractStepsLabel(int done, int total);

  /// No description provided for @contractEventResubmitted.
  ///
  /// In en, this message translates to:
  /// **'Work resubmitted (round {round})'**
  String contractEventResubmitted(int round);

  /// No description provided for @contractEventRevision.
  ///
  /// In en, this message translates to:
  /// **'Client asked for changes'**
  String get contractEventRevision;

  /// No description provided for @contractEventUpdate.
  ///
  /// In en, this message translates to:
  /// **'Progress update'**
  String get contractEventUpdate;

  /// No description provided for @contractRequestChanges.
  ///
  /// In en, this message translates to:
  /// **'Ask for changes'**
  String get contractRequestChanges;

  /// No description provided for @contractRevisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for changes?'**
  String get contractRevisionTitle;

  /// No description provided for @contractRevisionBody.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} what needs to change. The work goes back to in progress and they can submit it again. Rounds left: {left}.'**
  String contractRevisionBody(String name, int left);

  /// No description provided for @contractRevisionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'What needs to change'**
  String get contractRevisionNoteLabel;

  /// No description provided for @contractRevisionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The left socket cover is loose'**
  String get contractRevisionNoteHint;

  /// No description provided for @contractRevisionNoteTooShort.
  ///
  /// In en, this message translates to:
  /// **'Describe the changes (at least 10 characters).'**
  String get contractRevisionNoteTooShort;

  /// No description provided for @contractRevisionSend.
  ///
  /// In en, this message translates to:
  /// **'Send back for changes'**
  String get contractRevisionSend;

  /// No description provided for @contractRevisionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent back for changes'**
  String get contractRevisionSent;

  /// No description provided for @contractRevisionsLeft.
  ///
  /// In en, this message translates to:
  /// **'Not quite right? You can ask for changes (rounds left: {count}).'**
  String contractRevisionsLeft(int count);

  /// No description provided for @contractNoRevisionsLeft.
  ///
  /// In en, this message translates to:
  /// **'No revision rounds left. Confirm the work, or talk to {name} in chat.'**
  String contractNoRevisionsLeft(String name);

  /// No description provided for @contractRevisionBannerWorker.
  ///
  /// In en, this message translates to:
  /// **'{name} asked for changes: {note}'**
  String contractRevisionBannerWorker(String name, String note);

  /// No description provided for @contractRevisionBannerClient.
  ///
  /// In en, this message translates to:
  /// **'You asked for changes. Waiting for {name} to submit the work again.'**
  String contractRevisionBannerClient(String name);

  /// No description provided for @contractResubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit changes'**
  String get contractResubmit;

  /// No description provided for @contractWorkerSubmittedNotice.
  ///
  /// In en, this message translates to:
  /// **'You submitted the work on {date}. {name} will review it and confirm, or ask for changes.'**
  String contractWorkerSubmittedNotice(String date, String name);

  /// No description provided for @contractClientConfirmedNotice.
  ///
  /// In en, this message translates to:
  /// **'{name} confirmed the work was completed on {date}.'**
  String contractClientConfirmedNotice(String name, String date);

  /// No description provided for @contractClientCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'You confirmed this work as completed on {date}.'**
  String contractClientCompletedNotice(String date);

  /// No description provided for @contractUpdatesSection.
  ///
  /// In en, this message translates to:
  /// **'Progress updates'**
  String get contractUpdatesSection;

  /// No description provided for @contractUpdatesEmptyWorker.
  ///
  /// In en, this message translates to:
  /// **'Keep the client informed: post a short update when something changes.'**
  String get contractUpdatesEmptyWorker;

  /// No description provided for @contractUpdatesEmptyClient.
  ///
  /// In en, this message translates to:
  /// **'No updates yet. {name}\'s updates will appear here.'**
  String contractUpdatesEmptyClient(String name);

  /// No description provided for @contractPostUpdate.
  ///
  /// In en, this message translates to:
  /// **'Post an update'**
  String get contractPostUpdate;

  /// No description provided for @contractUpdateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a progress update'**
  String get contractUpdateSheetTitle;

  /// No description provided for @contractUpdateSheetBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is notified. Updates are kept with the contract and can\'t be edited.'**
  String contractUpdateSheetBody(String name);

  /// No description provided for @contractUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get contractUpdateLabel;

  /// No description provided for @contractUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Parts bought, I\'ll start tomorrow at 10am'**
  String get contractUpdateHint;

  /// No description provided for @contractUpdateTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write a short update.'**
  String get contractUpdateTooShort;

  /// No description provided for @contractUpdatePost.
  ///
  /// In en, this message translates to:
  /// **'Post update'**
  String get contractUpdatePost;

  /// No description provided for @contractUpdatePosted.
  ///
  /// In en, this message translates to:
  /// **'Update posted'**
  String get contractUpdatePosted;

  /// No description provided for @contractSubmissionHistory.
  ///
  /// In en, this message translates to:
  /// **'Earlier submissions'**
  String get contractSubmissionHistory;

  /// No description provided for @contractSubmissionN.
  ///
  /// In en, this message translates to:
  /// **'Submission {number}'**
  String contractSubmissionN(int number);

  /// No description provided for @contractSubmissionChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested: {note}'**
  String contractSubmissionChangesRequested(String note);

  /// No description provided for @contractEvidenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get contractEvidenceUnavailable;

  /// No description provided for @liveSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Live location'**
  String get liveSectionTitle;

  /// No description provided for @liveWorkerIntro.
  ///
  /// In en, this message translates to:
  /// **'Share your live location with {name} while you travel to the job. Only {name} can see it, and only for this contract.'**
  String liveWorkerIntro(String name);

  /// No description provided for @liveStartSharing.
  ///
  /// In en, this message translates to:
  /// **'Share my location'**
  String get liveStartSharing;

  /// No description provided for @liveStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get liveStopSharing;

  /// No description provided for @liveConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your live location?'**
  String get liveConsentTitle;

  /// No description provided for @liveConsentBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will see where you are on a map while sharing is on. It stops when you tap Stop sharing, when you submit the work, or when the contract is completed or cancelled. Nobody else can see it.'**
  String liveConsentBody(String name);

  /// No description provided for @liveConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'Start sharing'**
  String get liveConsentAgree;

  /// No description provided for @liveNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get liveNotNow;

  /// No description provided for @liveSharingWith.
  ///
  /// In en, this message translates to:
  /// **'Sharing your location with {name}. Last sent {time}.'**
  String liveSharingWith(String name, String time);

  /// No description provided for @liveStarting.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get liveStarting;

  /// No description provided for @livePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off. Allow location to share it.'**
  String get livePermissionDenied;

  /// No description provided for @livePermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for SkillBridge. Turn it on in Settings.'**
  String get livePermissionBlocked;

  /// No description provided for @liveServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s location (GPS) is off. Turn it on to share.'**
  String get liveServiceOff;

  /// No description provided for @liveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location isn\'t available on this device.'**
  String get liveUnavailable;

  /// No description provided for @liveEnded.
  ///
  /// In en, this message translates to:
  /// **'Sharing stopped because the work was submitted or the contract closed.'**
  String get liveEnded;

  /// No description provided for @liveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again.'**
  String get liveError;

  /// No description provided for @liveOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get liveOpenSettings;

  /// No description provided for @liveOfflineWorker.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your location will update when you reconnect.'**
  String get liveOfflineWorker;

  /// No description provided for @liveStartedNotice.
  ///
  /// In en, this message translates to:
  /// **'Sharing your location with {name}'**
  String liveStartedNotice(String name);

  /// No description provided for @liveStoppedNotice.
  ///
  /// In en, this message translates to:
  /// **'Location sharing stopped'**
  String get liveStoppedNotice;

  /// No description provided for @liveClientNotSharing.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t sharing their location right now.'**
  String liveClientNotSharing(String name);

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @liveBadgeStale.
  ///
  /// In en, this message translates to:
  /// **'Not live'**
  String get liveBadgeStale;

  /// No description provided for @liveUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String liveUpdated(String time);

  /// No description provided for @liveClientStale.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s location hasn\'t updated recently and may be out of date.'**
  String liveClientStale(String name);

  /// No description provided for @liveClientOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. This is the last location received and may be out of date.'**
  String get liveClientOffline;

  /// No description provided for @liveClientExplainer.
  ///
  /// In en, this message translates to:
  /// **'Shown only while {name} chooses to share it, and only to you. It stops automatically when the work is submitted or the contract closes.'**
  String liveClientExplainer(String name);

  /// No description provided for @liveOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get liveOpenInMaps;

  /// No description provided for @liveAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accurate to about {meters} m'**
  String liveAccuracy(int meters);

  /// No description provided for @liveJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get liveJustNow;

  /// No description provided for @liveMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String liveMinutesAgo(int minutes);

  /// No description provided for @liveMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A map preview isn\'t available here. Open the location in Google Maps.'**
  String get liveMapUnavailable;

  /// No description provided for @liveLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the location.'**
  String get liveLoadError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
