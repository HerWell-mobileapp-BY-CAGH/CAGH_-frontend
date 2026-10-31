import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

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
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Her Well'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @subChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select the language you feel most comfortable using for your health journey.'**
  String get subChooseLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @changeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get changeLater;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @keepMeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me logged in'**
  String get keepMeLoggedIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @emailPhone.
  ///
  /// In en, this message translates to:
  /// **'Email / Phone Number'**
  String get emailPhone;

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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

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

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @chooseJourney.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Journey'**
  String get chooseJourney;

  /// No description provided for @subUserType.
  ///
  /// In en, this message translates to:
  /// **'Select how you\'ll be using Her Well to personalize your experience.'**
  String get subUserType;

  /// No description provided for @userTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;

  /// No description provided for @userSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For adolescent girls and young women'**
  String get userSubtitle;

  /// No description provided for @midwifeTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Professional'**
  String get midwifeTitle;

  /// No description provided for @midwifeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For healthcare professionals'**
  String get midwifeSubtitle;

  /// No description provided for @enterContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number'**
  String get enterContactDetails;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @joinOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Join Our Team'**
  String get joinOurTeam;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your trusted companion for women\'s health and professional healthcare support'**
  String get createAccountSubtitle;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy.'**
  String get agreeTerms;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'ABOUT US'**
  String get aboutUs;

  /// No description provided for @aboutUsDesc.
  ///
  /// In en, this message translates to:
  /// **'We provide confidential consultation, education and care to help women and adolescent girls make informed choices and live healthier lives.'**
  String get aboutUsDesc;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPassword;

  /// No description provided for @resetSub.
  ///
  /// In en, this message translates to:
  /// **'Enter the email or phone number linked to your account and we will send you a verification code.'**
  String get resetSub;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @midwifeLogin.
  ///
  /// In en, this message translates to:
  /// **'Professional Login'**
  String get midwifeLogin;

  /// No description provided for @todaysAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todaysAppointments;

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Appointments Booked Today'**
  String get noAppointments;

  /// No description provided for @noAppointmentsSub.
  ///
  /// In en, this message translates to:
  /// **'When patients book consultations with you, they will appear here.'**
  String get noAppointmentsSub;

  /// No description provided for @pendingChatRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Chat Requests'**
  String get pendingChatRequests;

  /// No description provided for @noChatRequests.
  ///
  /// In en, this message translates to:
  /// **'No Pending Chat Requests'**
  String get noChatRequests;

  /// No description provided for @noChatRequestsSub.
  ///
  /// In en, this message translates to:
  /// **'Requests from patients seeking healthcare advice will show up here.'**
  String get noChatRequestsSub;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @consult.
  ///
  /// In en, this message translates to:
  /// **'Consult'**
  String get consult;

  /// No description provided for @consults.
  ///
  /// In en, this message translates to:
  /// **'Consults'**
  String get consults;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @aiNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get aiNearby;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @startNewConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start New Consultation'**
  String get startNewConsultation;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @consultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultations;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @voiceConsultation.
  ///
  /// In en, this message translates to:
  /// **'Voice Consultation'**
  String get voiceConsultation;

  /// No description provided for @nutritionConsultation.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Consultation'**
  String get nutritionConsultation;

  /// No description provided for @joinCall.
  ///
  /// In en, this message translates to:
  /// **'Join Call'**
  String get joinCall;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @needToSeeSomeone.
  ///
  /// In en, this message translates to:
  /// **'Need to see someone?'**
  String get needToSeeSomeone;

  /// No description provided for @ourMidwivesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Our health professionals are available for talk or visit any time.'**
  String get ourMidwivesAvailable;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @findAMidwife.
  ///
  /// In en, this message translates to:
  /// **'Find a Health Professional'**
  String get findAMidwife;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// No description provided for @savedMidwives.
  ///
  /// In en, this message translates to:
  /// **'Saved Health Professionals'**
  String get savedMidwives;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @emergencySupport.
  ///
  /// In en, this message translates to:
  /// **'Emergency Support'**
  String get emergencySupport;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @onlineVerifiedMidwife.
  ///
  /// In en, this message translates to:
  /// **'Online • Verified Health Professional'**
  String get onlineVerifiedMidwife;

  /// No description provided for @valEmailPhoneReq.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number is required.'**
  String get valEmailPhoneReq;

  /// No description provided for @valEmailReq.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get valEmailReq;

  /// No description provided for @valPhoneReq.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get valPhoneReq;

  /// No description provided for @valInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get valInvalidEmail;

  /// No description provided for @valInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get valInvalidPhone;

  /// No description provided for @valInvalidEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email or phone number.'**
  String get valInvalidEmailPhone;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email, phone number, or password. Please try again.'**
  String get invalidCredentials;

  /// No description provided for @valPasswordReq.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get valPasswordReq;

  /// No description provided for @valPasswordFormat.
  ///
  /// In en, this message translates to:
  /// **'Password must meet the required format.'**
  String get valPasswordFormat;

  /// No description provided for @valPasswordConfirmReq.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get valPasswordConfirmReq;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get valPasswordMismatch;

  /// No description provided for @valNameReq.
  ///
  /// In en, this message translates to:
  /// **'Full name is required.'**
  String get valNameReq;

  /// No description provided for @valCodeReq.
  ///
  /// In en, this message translates to:
  /// **'Verification code is required.'**
  String get valCodeReq;

  /// No description provided for @valFileReq.
  ///
  /// In en, this message translates to:
  /// **'File selection is required.'**
  String get valFileReq;

  /// No description provided for @secureConnection.
  ///
  /// In en, this message translates to:
  /// **'Secure & Private Connection'**
  String get secureConnection;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessful;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @incomingVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming voice call'**
  String get incomingVoiceCall;

  /// No description provided for @encryptedCall.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Call'**
  String get encryptedCall;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @aiHelpPrompt.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get aiHelpPrompt;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This AI is for informational purposes only and is not a substitute for professional medical advice. In case of emergency, use the SOS button.'**
  String get aiDisclaimer;

  /// No description provided for @emergencySOS.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySOS;

  /// No description provided for @digitalAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Digital AI Assistant'**
  String get digitalAiAssistant;

  /// No description provided for @typeHealthQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your health question...'**
  String get typeHealthQuestion;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @areYouSureCancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment request?'**
  String get areYouSureCancelAppointment;

  /// No description provided for @appointmentCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled successfully.'**
  String get appointmentCancelledSuccessfully;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String status(String status);

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @freeCancellationNotice.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation up to 24 hours before your appointment.'**
  String get freeCancellationNotice;

  /// No description provided for @waitingForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation.'**
  String get waitingForConfirmation;

  /// No description provided for @yourMidwife.
  ///
  /// In en, this message translates to:
  /// **'Your Health Professional'**
  String get yourMidwife;

  /// No description provided for @reasonForVisit.
  ///
  /// In en, this message translates to:
  /// **'REASON FOR VISIT'**
  String get reasonForVisit;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @consultationFee.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get consultationFee;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @describeSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms or reason for the consultation...'**
  String get describeSymptoms;

  /// No description provided for @selectTimeSlotFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a time slot first.'**
  String get selectTimeSlotFirst;

  /// No description provided for @healthDataEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Your health data is encrypted and handled according to HerWell'**
  String get healthDataEncrypted;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get bookingSummary;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION TYPE'**
  String get consultationType;

  /// No description provided for @availableTimes.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE TIMES'**
  String get availableTimes;

  /// No description provided for @returnToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get returnToDashboard;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @passwordMustContain.
  ///
  /// In en, this message translates to:
  /// **'Password must contain:'**
  String get passwordMustContain;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @sendingVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Sending verification code…'**
  String get sendingVerificationCode;

  /// No description provided for @checkEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your email inbox — the code was likely sent.'**
  String get checkEmailInbox;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your email below. If you did not receive it, tap Resend after the timer expires.'**
  String get enter6DigitCode;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated!'**
  String get passwordUpdated;

  /// No description provided for @signInNewPassword.
  ///
  /// In en, this message translates to:
  /// **'You can now sign in using your new password.'**
  String get signInNewPassword;

  /// No description provided for @midwifeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Professional Sign Up'**
  String get midwifeRegistration;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @continueToAdminCheck.
  ///
  /// In en, this message translates to:
  /// **'Continue to Admin Check'**
  String get continueToAdminCheck;

  /// No description provided for @selectQualification.
  ///
  /// In en, this message translates to:
  /// **'Select qualification'**
  String get selectQualification;

  /// No description provided for @tapToUploadCV.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload your CV or resume'**
  String get tapToUploadCV;

  /// No description provided for @consultationSession.
  ///
  /// In en, this message translates to:
  /// **'Consultation Session'**
  String get consultationSession;

  /// No description provided for @followUpRequired.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Required'**
  String get followUpRequired;

  /// No description provided for @completeConsultation.
  ///
  /// In en, this message translates to:
  /// **'Complete Consultation'**
  String get completeConsultation;

  /// No description provided for @consultationReport.
  ///
  /// In en, this message translates to:
  /// **'Consultation Report'**
  String get consultationReport;

  /// No description provided for @summaryAndDiagnosisRequired.
  ///
  /// In en, this message translates to:
  /// **'Summary and Diagnosis are required.'**
  String get summaryAndDiagnosisRequired;

  /// No description provided for @consultationCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Consultation completed successfully!'**
  String get consultationCompletedSuccessfully;

  /// No description provided for @noActiveChatFound.
  ///
  /// In en, this message translates to:
  /// **'No active chat found. Patient must initiate.'**
  String get noActiveChatFound;

  /// No description provided for @pleaseAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Please accept the request before sending messages.'**
  String get pleaseAcceptRequest;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @seekHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Seek Healthcare'**
  String get seekHealthcare;

  /// No description provided for @consultationDetails.
  ///
  /// In en, this message translates to:
  /// **'Consultation Details'**
  String get consultationDetails;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @whenPatientsMessageYou.
  ///
  /// In en, this message translates to:
  /// **'When patients message you, they will appear here.'**
  String get whenPatientsMessageYou;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @myMessages.
  ///
  /// In en, this message translates to:
  /// **'My Messages'**
  String get myMessages;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select Time Slot'**
  String get selectTimeSlot;

  /// No description provided for @confirmReschedule.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reschedule'**
  String get confirmReschedule;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @certifiedMidwife.
  ///
  /// In en, this message translates to:
  /// **'Certified Health Professional'**
  String get certifiedMidwife;

  /// No description provided for @keepAppointment.
  ///
  /// In en, this message translates to:
  /// **'Keep Appointment'**
  String get keepAppointment;

  /// No description provided for @noMidwivesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No health professionals available at the moment.'**
  String get noMidwivesAvailable;

  /// No description provided for @availableToday.
  ///
  /// In en, this message translates to:
  /// **'Available today'**
  String get availableToday;

  /// No description provided for @searchByNameOrSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Search by name or specialty...'**
  String get searchByNameOrSpecialty;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @verifiedMidwife.
  ///
  /// In en, this message translates to:
  /// **'Verified Health Professional'**
  String get verifiedMidwife;

  /// No description provided for @hospital.
  ///
  /// In en, this message translates to:
  /// **'HOSPITAL'**
  String get hospital;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE'**
  String get experience;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @inPerson.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get inPerson;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGES'**
  String get languages;

  /// No description provided for @offeredConsultations.
  ///
  /// In en, this message translates to:
  /// **'OFFERED CONSULTATIONS'**
  String get offeredConsultations;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @yourConversationsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your conversations will appear here.'**
  String get yourConversationsWillAppearHere;

  /// No description provided for @manageAvailability.
  ///
  /// In en, this message translates to:
  /// **'Manage Availability'**
  String get manageAvailability;

  /// No description provided for @learningModule.
  ///
  /// In en, this message translates to:
  /// **'Learning module'**
  String get learningModule;

  /// No description provided for @virtualVoiceConsultation.
  ///
  /// In en, this message translates to:
  /// **'Virtual Voice Consultation'**
  String get virtualVoiceConsultation;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @ourFocusAreas.
  ///
  /// In en, this message translates to:
  /// **'Our Focus Areas'**
  String get ourFocusAreas;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @facilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Facility Details'**
  String get facilityDetails;

  /// No description provided for @emergencyServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'24/7 Emergency Services Available'**
  String get emergencyServicesAvailable;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @callFacility.
  ///
  /// In en, this message translates to:
  /// **'Call Facility'**
  String get callFacility;

  /// No description provided for @findNearby.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby'**
  String get findNearby;

  /// No description provided for @healthcareNearYou.
  ///
  /// In en, this message translates to:
  /// **'Healthcare Near You'**
  String get healthcareNearYou;

  /// No description provided for @findTrustedMaternal.
  ///
  /// In en, this message translates to:
  /// **'Find trusted maternal and reproductive healthcare services around you.'**
  String get findTrustedMaternal;

  /// No description provided for @findCareByType.
  ///
  /// In en, this message translates to:
  /// **'Find Care By Type'**
  String get findCareByType;

  /// No description provided for @nearbyFacilities.
  ///
  /// In en, this message translates to:
  /// **'Nearby Facilities'**
  String get nearbyFacilities;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @noHealthcareFacilitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No healthcare facilities found nearby.'**
  String get noHealthcareFacilitiesFound;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @tryIncreasingSearchRadius.
  ///
  /// In en, this message translates to:
  /// **'Try increasing your search radius or changing your filters.'**
  String get tryIncreasingSearchRadius;

  /// No description provided for @expandSearchRadius.
  ///
  /// In en, this message translates to:
  /// **'Expand Search Radius'**
  String get expandSearchRadius;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @appearanceAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Accessibility'**
  String get appearanceAccessibility;

  /// No description provided for @professionalTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFESSIONAL TITLE'**
  String get professionalTitle;

  /// No description provided for @editProfessionalProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Professional Profile'**
  String get editProfessionalProfile;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'ABOUT ME'**
  String get aboutMe;

  /// No description provided for @editPersonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Personal Profile'**
  String get editPersonalProfile;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// No description provided for @chooseAvatarStyle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE AVATAR STYLE'**
  String get chooseAvatarStyle;

  /// No description provided for @setWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Set Working Hours'**
  String get setWorkingHours;

  /// No description provided for @addAvailability.
  ///
  /// In en, this message translates to:
  /// **'Add Availability'**
  String get addAvailability;

  /// No description provided for @addBlockedDate.
  ///
  /// In en, this message translates to:
  /// **'Add Blocked Date'**
  String get addBlockedDate;

  /// No description provided for @manageBlockedDates.
  ///
  /// In en, this message translates to:
  /// **'Manage Blocked Dates'**
  String get manageBlockedDates;

  /// No description provided for @currentAvailabilities.
  ///
  /// In en, this message translates to:
  /// **'Current Availabilities'**
  String get currentAvailabilities;

  /// No description provided for @defineRegularWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Define your regular working hours. This will automatically generate 30-minute bookable slots for patients.'**
  String get defineRegularWorkingHours;

  /// No description provided for @manageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Manage Schedule'**
  String get manageSchedule;

  /// No description provided for @blockDate.
  ///
  /// In en, this message translates to:
  /// **'Block Date'**
  String get blockDate;

  /// No description provided for @addTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Add Time Range'**
  String get addTimeRange;

  /// No description provided for @blockedDates.
  ///
  /// In en, this message translates to:
  /// **'Blocked Dates'**
  String get blockedDates;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every {dayName}'**
  String everyDay(String dayName);

  /// No description provided for @noRecurringSchedules.
  ///
  /// In en, this message translates to:
  /// **'No recurring schedules configured.'**
  String get noRecurringSchedules;

  /// No description provided for @yourSchedule.
  ///
  /// In en, this message translates to:
  /// **'Your Schedule'**
  String get yourSchedule;

  /// No description provided for @addLeave.
  ///
  /// In en, this message translates to:
  /// **'Add Leave'**
  String get addLeave;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @availabilityManagement.
  ///
  /// In en, this message translates to:
  /// **'AVAILABILITY MANAGEMENT'**
  String get availabilityManagement;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get sos;

  /// No description provided for @emergencyHotlines.
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotlines'**
  String get emergencyHotlines;

  /// No description provided for @areYouOkay.
  ///
  /// In en, this message translates to:
  /// **'Are you okay?'**
  String get areYouOkay;

  /// No description provided for @useSosButton.
  ///
  /// In en, this message translates to:
  /// **'Your emergency contacts will receive an urgent SMS with your live GPS location.'**
  String get useSosButton;

  /// No description provided for @lifeThreateningEmergency.
  ///
  /// In en, this message translates to:
  /// **'If you are in danger or need immediate medical attention, send an emergency alert or call the hotlines below.'**
  String get lifeThreateningEmergency;

  /// No description provided for @emergencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get emergencyHelp;

  /// No description provided for @pressAndHold.
  ///
  /// In en, this message translates to:
  /// **'Hold 2s for Help'**
  String get pressAndHold;

  /// No description provided for @directEmergencyLines.
  ///
  /// In en, this message translates to:
  /// **'Direct Emergency Lines'**
  String get directEmergencyLines;

  /// No description provided for @tollFree.
  ///
  /// In en, this message translates to:
  /// **'Toll-Free'**
  String get tollFree;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callNow;

  /// No description provided for @allHotlines.
  ///
  /// In en, this message translates to:
  /// **'All Emergency Hotlines'**
  String get allHotlines;

  /// No description provided for @gpsLocationActive.
  ///
  /// In en, this message translates to:
  /// **'GPS Active • Accurate location ready'**
  String get gpsLocationActive;

  /// No description provided for @sendAlertNow.
  ///
  /// In en, this message translates to:
  /// **'Send Alert Now'**
  String get sendAlertNow;

  /// No description provided for @sendingAlertIn.
  ///
  /// In en, this message translates to:
  /// **'Sending alert in {seconds}s...'**
  String sendingAlertIn(int seconds);

  /// No description provided for @cancelAlert.
  ///
  /// In en, this message translates to:
  /// **'Cancel Alert'**
  String get cancelAlert;

  /// No description provided for @alertSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert Sent Successfully!'**
  String get alertSentSuccess;

  /// No description provided for @alertSentDescription.
  ///
  /// In en, this message translates to:
  /// **'Your emergency contacts have been notified with your GPS coordinates and an urgent SMS.'**
  String get alertSentDescription;

  /// No description provided for @iAmSafe.
  ///
  /// In en, this message translates to:
  /// **'I am Safe Now'**
  String get iAmSafe;

  /// No description provided for @ambulance907Title.
  ///
  /// In en, this message translates to:
  /// **'Ambulance & Medical'**
  String get ambulance907Title;

  /// No description provided for @ambulance907Sub.
  ///
  /// In en, this message translates to:
  /// **'National Health Hotline (907)'**
  String get ambulance907Sub;

  /// No description provided for @police911Title.
  ///
  /// In en, this message translates to:
  /// **'Police & Security'**
  String get police911Title;

  /// No description provided for @police911Sub.
  ///
  /// In en, this message translates to:
  /// **'Immediate Emergency Response (911)'**
  String get police911Sub;

  /// No description provided for @redCross939Title.
  ///
  /// In en, this message translates to:
  /// **'Red Cross Ambulance'**
  String get redCross939Title;

  /// No description provided for @redCross939Sub.
  ///
  /// In en, this message translates to:
  /// **'First Aid & Medical Transport (939)'**
  String get redCross939Sub;

  /// No description provided for @helpline8044Title.
  ///
  /// In en, this message translates to:
  /// **'Helpline & Protection'**
  String get helpline8044Title;

  /// No description provided for @helpline8044Sub.
  ///
  /// In en, this message translates to:
  /// **'Women & Youth Support (8044)'**
  String get helpline8044Sub;

  /// No description provided for @emergencyContactsAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts Alert'**
  String get emergencyContactsAlert;

  /// No description provided for @contactsConfiguredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts configured to receive alert'**
  String contactsConfiguredCount(String count);

  /// No description provided for @previewContacts.
  ///
  /// In en, this message translates to:
  /// **'View Contacts'**
  String get previewContacts;

  /// No description provided for @accountAndRecords.
  ///
  /// In en, this message translates to:
  /// **'Account & Records'**
  String get accountAndRecords;

  /// No description provided for @oneUpcoming.
  ///
  /// In en, this message translates to:
  /// **'1 UPCOMING'**
  String get oneUpcoming;

  /// No description provided for @themeAndTextSize.
  ///
  /// In en, this message translates to:
  /// **'Theme and text size'**
  String get themeAndTextSize;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @emergencyContactsList.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContactsList;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {build})'**
  String appVersion(String version, String build);

  /// No description provided for @adolescentGirlsHealthAndNutrition.
  ///
  /// In en, this message translates to:
  /// **'Adolescent Girls Health & Nutrition'**
  String get adolescentGirlsHealthAndNutrition;

  /// No description provided for @adolescentGirlsHealthAndNutritionDesc.
  ///
  /// In en, this message translates to:
  /// **'Puberty, menstrual health, nutrition & healthy lifestyle, life skills & well-being.'**
  String get adolescentGirlsHealthAndNutritionDesc;

  /// No description provided for @preventionAndAwareness.
  ///
  /// In en, this message translates to:
  /// **'Prevention and Awareness'**
  String get preventionAndAwareness;

  /// No description provided for @preventionAndAwarenessDesc.
  ///
  /// In en, this message translates to:
  /// **'STI/HIV prevention, HPV & cervical cancer awareness, healthy relationships.'**
  String get preventionAndAwarenessDesc;

  /// No description provided for @psychosocialSupportAndProtection.
  ///
  /// In en, this message translates to:
  /// **'Psychosocial Support & Protection'**
  String get psychosocialSupportAndProtection;

  /// No description provided for @psychosocialSupportAndProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Mental health, GBV support, counseling services, and emergency help.'**
  String get psychosocialSupportAndProtectionDesc;

  /// No description provided for @reproductiveHealthAndCare.
  ///
  /// In en, this message translates to:
  /// **'Reproductive Health & Care'**
  String get reproductiveHealthAndCare;

  /// No description provided for @reproductiveHealthAndCareDesc.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy prevention, maternal care, ANC, newborn care, and checkups.'**
  String get reproductiveHealthAndCareDesc;

  /// No description provided for @tomorrowAt10AM.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at 10:00 AM • Sr. Martha T.'**
  String get tomorrowAt10AM;

  /// No description provided for @searchHospitalsClinicsMidwives.
  ///
  /// In en, this message translates to:
  /// **'Search hospitals, clinics, midwives...'**
  String get searchHospitalsClinicsMidwives;

  /// No description provided for @clinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinic;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @noConsultationRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No consultation requests yet'**
  String get noConsultationRequestsYet;

  /// No description provided for @noUpcomingConsultations.
  ///
  /// In en, this message translates to:
  /// **'No upcoming consultations'**
  String get noUpcomingConsultations;

  /// No description provided for @noPastConsultations.
  ///
  /// In en, this message translates to:
  /// **'No past consultations'**
  String get noPastConsultations;

  /// No description provided for @connectWithCertifiedMidwife.
  ///
  /// In en, this message translates to:
  /// **'Connect with a certified health professional for a consultation'**
  String get connectWithCertifiedMidwife;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @credentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentials;

  /// No description provided for @professionalCv.
  ///
  /// In en, this message translates to:
  /// **'Professional CV'**
  String get professionalCv;

  /// No description provided for @remoteConnectionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Remote connection interrupted. Reconnecting...'**
  String get remoteConnectionInterrupted;

  /// No description provided for @callConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Call connection failed'**
  String get callConnectionFailed;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Call failed'**
  String get callFailed;

  /// No description provided for @multiPartyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Multi-party consultation available in group mode.'**
  String get multiPartyAvailable;

  /// No description provided for @failedToPickFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick file'**
  String get failedToPickFile;

  /// No description provided for @failedToCancel.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel'**
  String get failedToCancel;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'BOOKED'**
  String get booked;

  /// No description provided for @generateSlots.
  ///
  /// In en, this message translates to:
  /// **'Generate Slots'**
  String get generateSlots;

  /// No description provided for @noSlotsFound.
  ///
  /// In en, this message translates to:
  /// **'No slots found for this date'**
  String get noSlotsFound;

  /// No description provided for @addSlot.
  ///
  /// In en, this message translates to:
  /// **'Add Slot'**
  String get addSlot;

  /// No description provided for @deleteSlot.
  ///
  /// In en, this message translates to:
  /// **'Delete Slot'**
  String get deleteSlot;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @sessionFee.
  ///
  /// In en, this message translates to:
  /// **'Session Fee'**
  String get sessionFee;

  /// No description provided for @emergencyHotline.
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotlines'**
  String get emergencyHotline;

  /// No description provided for @callAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Call Ambulance (907)'**
  String get callAmbulance;

  /// No description provided for @callPolice.
  ///
  /// In en, this message translates to:
  /// **'Call Police (991)'**
  String get callPolice;

  /// No description provided for @callRedCross.
  ///
  /// In en, this message translates to:
  /// **'Call Red Cross (922)'**
  String get callRedCross;

  /// No description provided for @emergencySupportDesc.
  ///
  /// In en, this message translates to:
  /// **'If you are experiencing an acute medical emergency, please call one of the national hotlines immediately.'**
  String get emergencySupportDesc;

  /// No description provided for @findNearbyHelp.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby Health Facility'**
  String get findNearbyHelp;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @confirmedAppointments.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Appointments'**
  String get confirmedAppointments;

  /// No description provided for @acceptedConsultations.
  ///
  /// In en, this message translates to:
  /// **'Accepted Consultations'**
  String get acceptedConsultations;

  /// No description provided for @patientNotes.
  ///
  /// In en, this message translates to:
  /// **'Patient Notes'**
  String get patientNotes;

  /// No description provided for @saveNotes.
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get saveNotes;

  /// No description provided for @typingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typingPlaceholder;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @audioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio Call'**
  String get audioCall;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCall;

  /// No description provided for @muteMic.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteMic;

  /// No description provided for @unmuteMic.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteMic;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @earpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get earpiece;

  /// No description provided for @digitalMidwife.
  ///
  /// In en, this message translates to:
  /// **'Her Well'**
  String get digitalMidwife;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @blockADate.
  ///
  /// In en, this message translates to:
  /// **'Block a Date'**
  String get blockADate;

  /// No description provided for @selectDateToBlock.
  ///
  /// In en, this message translates to:
  /// **'Select the date you want to take off or block from bookings.'**
  String get selectDateToBlock;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (Optional)'**
  String get reasonOptional;

  /// No description provided for @reasonLeavePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g., Sick leave, Vacation)'**
  String get reasonLeavePlaceholder;

  /// No description provided for @noBlockedDates.
  ///
  /// In en, this message translates to:
  /// **'No blocked dates.'**
  String get noBlockedDates;

  /// No description provided for @dateAlreadyBlocked.
  ///
  /// In en, this message translates to:
  /// **'This date is already blocked.'**
  String get dateAlreadyBlocked;

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start Call'**
  String get startCall;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @hospitalAffiliationOptional.
  ///
  /// In en, this message translates to:
  /// **'Hospital / Health Center (Optional)'**
  String get hospitalAffiliationOptional;

  /// No description provided for @generalHealthCenter.
  ///
  /// In en, this message translates to:
  /// **'General Health Center'**
  String get generalHealthCenter;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @profileCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully!'**
  String get profileCreatedSuccess;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @cameraPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Camera photo captured and profile updated!'**
  String get cameraPhotoUpdated;

  /// No description provided for @galleryPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Gallery photo uploaded successfully!'**
  String get galleryPhotoUpdated;

  /// No description provided for @noWorkingHoursConfigured.
  ///
  /// In en, this message translates to:
  /// **'No working hours configured yet.'**
  String get noWorkingHoursConfigured;

  /// No description provided for @addedWorkingHoursSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Added working hours successfully!'**
  String get addedWorkingHoursSuccessfully;

  /// No description provided for @failedToAddWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Failed to add working hours'**
  String get failedToAddWorkingHours;

  /// No description provided for @dayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get dayOfWeek;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully!'**
  String get preferencesSaved;

  /// No description provided for @blockedDateRemoved.
  ///
  /// In en, this message translates to:
  /// **'Blocked date removed.'**
  String get blockedDateRemoved;

  /// No description provided for @noSlotsAvailableForDay.
  ///
  /// In en, this message translates to:
  /// **'No slots available for this day.'**
  String get noSlotsAvailableForDay;

  /// No description provided for @noConsultationOptionsOffered.
  ///
  /// In en, this message translates to:
  /// **'No consultation options currently offered.'**
  String get noConsultationOptionsOffered;

  /// No description provided for @selectDayToSetRecurring.
  ///
  /// In en, this message translates to:
  /// **'Select a day of the week to set recurring hours'**
  String get selectDayToSetRecurring;

  /// No description provided for @mySchedules.
  ///
  /// In en, this message translates to:
  /// **'My Schedules'**
  String get mySchedules;

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(String count);

  /// No description provided for @saveSelectedSlots.
  ///
  /// In en, this message translates to:
  /// **'Save Selected Slots ({count})'**
  String saveSelectedSlots(int count);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @noHotlinesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hotlines available'**
  String get noHotlinesAvailable;

  /// No description provided for @couldNotLaunchDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch dialer'**
  String get couldNotLaunchDialer;

  /// No description provided for @sosAlertTriggered.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert Triggered! Notified {count} contacts.'**
  String sosAlertTriggered(String count);

  /// No description provided for @failedToTriggerSos.
  ///
  /// In en, this message translates to:
  /// **'Failed to trigger SOS alert. Please call a hotline directly.'**
  String get failedToTriggerSos;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @failedToLoadMidwives.
  ///
  /// In en, this message translates to:
  /// **'Failed to load midwives'**
  String get failedToLoadMidwives;

  /// No description provided for @unableToConnectConsultation.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to consultation. Please try again.'**
  String get unableToConnectConsultation;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @failedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request. Try again.'**
  String get failedToSendRequest;

  /// No description provided for @waitForMidwifeAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for health professional to accept request before sending more messages.'**
  String get waitForMidwifeAccept;

  /// No description provided for @waitForChatConnected.
  ///
  /// In en, this message translates to:
  /// **'Wait for the chat to be connected.'**
  String get waitForChatConnected;

  /// No description provided for @failedToUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get failedToUploadFile;

  /// No description provided for @failedToAcceptChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept chat'**
  String get failedToAcceptChat;

  /// No description provided for @failedToRejectChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject chat'**
  String get failedToRejectChat;

  /// No description provided for @failedToInitializeSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize session'**
  String get failedToInitializeSession;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get voiceCall;

  /// No description provided for @hotlines.
  ///
  /// In en, this message translates to:
  /// **'Hotlines'**
  String get hotlines;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Primary Qualification'**
  String get qualification;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @conversationsCount.
  ///
  /// In en, this message translates to:
  /// **'Conversations ({count})'**
  String conversationsCount(int count);

  /// No description provided for @midwivesCount.
  ///
  /// In en, this message translates to:
  /// **'Midwives ({count})'**
  String midwivesCount(int count);

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @connectAndMessageDirectly.
  ///
  /// In en, this message translates to:
  /// **'Connect and message directly with our verified health professionals.'**
  String get connectAndMessageDirectly;

  /// No description provided for @startChatWithMidwife.
  ///
  /// In en, this message translates to:
  /// **'Start Chat with a Health Professional'**
  String get startChatWithMidwife;

  /// No description provided for @upcomingConsultation.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Consultation'**
  String get upcomingConsultation;

  /// No description provided for @consultationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Consultation Accepted'**
  String get consultationAccepted;

  /// No description provided for @consultationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Consultation Cancelled'**
  String get consultationCancelled;

  /// No description provided for @consultationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Consultation Declined'**
  String get consultationDeclined;

  /// No description provided for @newConsultationRequest.
  ///
  /// In en, this message translates to:
  /// **'New Consultation Request'**
  String get newConsultationRequest;

  /// No description provided for @newChatMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newChatMessage;

  /// No description provided for @yearsExp.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs exp'**
  String yearsExp(int years);

  /// No description provided for @ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingsCount(int count);

  /// No description provided for @upcomingBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} UPCOMING'**
  String upcomingBadge(int count);

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcomeUser(String name);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @patientConsultationBookingsPending.
  ///
  /// In en, this message translates to:
  /// **'You have {count} patient consultation bookings pending.'**
  String patientConsultationBookingsPending(int count);

  /// No description provided for @patientBookingsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your patient bookings will appear here.'**
  String get patientBookingsWillAppearHere;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Total'**
  String totalCount(int count);

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get confirmed;

  /// No description provided for @generalNotifications.
  ///
  /// In en, this message translates to:
  /// **'General Notifications'**
  String get generalNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @consultationRequests.
  ///
  /// In en, this message translates to:
  /// **'Consultation Requests'**
  String get consultationRequests;

  /// No description provided for @scheduleReminders.
  ///
  /// In en, this message translates to:
  /// **'Schedule Reminders'**
  String get scheduleReminders;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @scheduledDay.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Day'**
  String get scheduledDay;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get statusConfirmed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get statusCancelled;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'DECLINED'**
  String get statusDeclined;

  /// No description provided for @helpfulServices.
  ///
  /// In en, this message translates to:
  /// **'Helpful Services'**
  String get helpfulServices;

  /// No description provided for @healthResources.
  ///
  /// In en, this message translates to:
  /// **'Health Resources'**
  String get healthResources;

  /// No description provided for @findNearbyServices.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby Services'**
  String get findNearbyServices;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to support your health, well-being and informed choices.'**
  String get welcomeSubtitle;

  /// No description provided for @needUrgentHelp.
  ///
  /// In en, this message translates to:
  /// **'Need urgent help?'**
  String get needUrgentHelp;

  /// No description provided for @talkToProfessionalNow.
  ///
  /// In en, this message translates to:
  /// **'Talk to a trained professional now.'**
  String get talkToProfessionalNow;

  /// No description provided for @startQuickConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start Quick Consultation'**
  String get startQuickConsultation;

  /// No description provided for @focusAreas.
  ///
  /// In en, this message translates to:
  /// **'Focus Areas'**
  String get focusAreas;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @prenatalCare.
  ///
  /// In en, this message translates to:
  /// **'Prenatal Care'**
  String get prenatalCare;

  /// No description provided for @postnatalCare.
  ///
  /// In en, this message translates to:
  /// **'Postnatal Care'**
  String get postnatalCare;

  /// No description provided for @laborAndDelivery.
  ///
  /// In en, this message translates to:
  /// **'Labor & Delivery'**
  String get laborAndDelivery;

  /// No description provided for @familyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Family Planning'**
  String get familyPlanning;

  /// No description provided for @consultationMethod.
  ///
  /// In en, this message translates to:
  /// **'Consultation Method'**
  String get consultationMethod;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @rating45Up.
  ///
  /// In en, this message translates to:
  /// **'4.5 & up'**
  String get rating45Up;

  /// No description provided for @rating40Up.
  ///
  /// In en, this message translates to:
  /// **'4.0 & up'**
  String get rating40Up;

  /// No description provided for @rating35Up.
  ///
  /// In en, this message translates to:
  /// **'3.5 & up'**
  String get rating35Up;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any Time'**
  String get anyTime;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @requestChat.
  ///
  /// In en, this message translates to:
  /// **'Request Chat'**
  String get requestChat;

  /// No description provided for @maternalHealthSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Maternal Health Specialist'**
  String get maternalHealthSpecialist;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @hospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get hospitals;

  /// No description provided for @clinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get clinics;

  /// No description provided for @pharmacies.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get pharmacies;

  /// No description provided for @healthCenters.
  ///
  /// In en, this message translates to:
  /// **'Health Centers'**
  String get healthCenters;

  /// No description provided for @aboutMidwife.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String aboutMidwife(String name);

  /// No description provided for @dedicatedMidwifeDesc.
  ///
  /// In en, this message translates to:
  /// **'A dedicated health professional committed to providing the best care.'**
  String get dedicatedMidwifeDesc;

  /// No description provided for @noMidwivesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No health professionals match your filters. Try resetting.'**
  String get noMidwivesMatchFilters;

  /// No description provided for @userRegistration.
  ///
  /// In en, this message translates to:
  /// **'User Sign Up'**
  String get userRegistration;

  /// No description provided for @seekingCareTitle.
  ///
  /// In en, this message translates to:
  /// **'User Login / Sign Up'**
  String get seekingCareTitle;

  /// No description provided for @seekingCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For adolescent girls and young women.'**
  String get seekingCareSubtitle;

  /// No description provided for @midwifeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Login / Sign Up'**
  String get midwifeRoleTitle;

  /// No description provided for @midwifeRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For healthcare professionals.'**
  String get midwifeRoleSubtitle;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @tapToUploadCv.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload your CV or resume'**
  String get tapToUploadCv;

  /// No description provided for @cvFileFormatLimit.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOC (Max 5MB)'**
  String get cvFileFormatLimit;

  /// No description provided for @midwifeReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Your registration will be reviewed by an administrator before approval.'**
  String get midwifeReviewNotice;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get dateOfBirthRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @nameNoSpecialChars.
  ///
  /// In en, this message translates to:
  /// **'Cannot contain numbers or special characters'**
  String get nameNoSpecialChars;

  /// No description provided for @phoneNumberEthiopia.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Ethiopia)'**
  String get phoneNumberEthiopia;

  /// No description provided for @cvResume.
  ///
  /// In en, this message translates to:
  /// **'CV / Resume'**
  String get cvResume;

  /// No description provided for @availabilityCalendar.
  ///
  /// In en, this message translates to:
  /// **'Availability Calendar'**
  String get availabilityCalendar;

  /// No description provided for @availabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the times clients may request.'**
  String get availabilitySubtitle;

  /// No description provided for @selectDayToManage.
  ///
  /// In en, this message translates to:
  /// **'Select a day to manage\nits availability.'**
  String get selectDayToManage;

  /// No description provided for @pastStatus.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastStatus;

  /// No description provided for @editAvailableTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Available Time'**
  String get editAvailableTime;

  /// No description provided for @addAvailableTime.
  ///
  /// In en, this message translates to:
  /// **'Add Available Time'**
  String get addAvailableTime;

  /// No description provided for @addTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a time clients may request.'**
  String get addTimeSubtitle;

  /// No description provided for @dateTimeSection.
  ///
  /// In en, this message translates to:
  /// **'DATE AND TIME'**
  String get dateTimeSection;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get dateRequired;

  /// No description provided for @selectDatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDatePrompt;

  /// No description provided for @startTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Start time *'**
  String get startTimeRequired;

  /// No description provided for @selectStartTimePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get selectStartTimePrompt;

  /// No description provided for @endTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'End time *'**
  String get endTimeRequired;

  /// No description provided for @selectEndTimePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select end time'**
  String get selectEndTimePrompt;

  /// No description provided for @consultationMethodSection.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION METHOD'**
  String get consultationMethodSection;

  /// No description provided for @saveAvailability.
  ///
  /// In en, this message translates to:
  /// **'Save Availability'**
  String get saveAvailability;

  /// No description provided for @noAvailabilityCreated.
  ///
  /// In en, this message translates to:
  /// **'No availability created'**
  String get noAvailabilityCreated;

  /// No description provided for @addTimeSlotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a time slot for this date.'**
  String get addTimeSlotPrompt;

  /// No description provided for @calendarEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} calendar entries'**
  String calendarEntries(int count);

  /// No description provided for @inPersonAndVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'In-person & Voice call'**
  String get inPersonAndVoiceCall;

  /// No description provided for @inPersonHospital.
  ///
  /// In en, this message translates to:
  /// **'In-person meeting · Hospital'**
  String get inPersonHospital;

  /// No description provided for @onlinePhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Online meeting · Phone call'**
  String get onlinePhoneCall;

  /// No description provided for @pleaseSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get pleaseSelectDateTime;

  /// No description provided for @endTimeAfterStartTime.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeAfterStartTime;

  /// No description provided for @selectConsultationMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one consultation method'**
  String get selectConsultationMethod;

  /// No description provided for @availabilityUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Availability updated successfully'**
  String get availabilityUpdatedSuccess;

  /// No description provided for @availabilityAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Availability added successfully'**
  String get availabilityAddedSuccess;

  /// No description provided for @failedToAddAvailability.
  ///
  /// In en, this message translates to:
  /// **'Failed to add availability'**
  String get failedToAddAvailability;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteSlotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this availability slot?'**
  String get deleteSlotConfirm;

  /// No description provided for @midwifeBookingsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Bookings from adolescent girls\nwill appear here.'**
  String get midwifeBookingsAppearHere;

  /// No description provided for @setDaysAndTimesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set the days and times when girls can book\na consultation with you.'**
  String get setDaysAndTimesPrompt;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No appointments today'**
  String get noAppointmentsToday;

  /// No description provided for @whenGirlBooksConsultation.
  ///
  /// In en, this message translates to:
  /// **'When an adolescent girl books a consultation\nwith you, it will appear here.'**
  String get whenGirlBooksConsultation;

  /// No description provided for @aiWelcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your AI Health Assistant. How can I help you today?'**
  String get aiWelcomeGreeting;

  /// No description provided for @roleMismatchMidwifeError.
  ///
  /// In en, this message translates to:
  /// **'This account is registered as a user. Please use User Login.'**
  String get roleMismatchMidwifeError;

  /// No description provided for @roleMismatchPatientError.
  ///
  /// In en, this message translates to:
  /// **'This account is registered as a healthcare professional. Please use Professional Login.'**
  String get roleMismatchPatientError;

  /// No description provided for @startTimeCannotBeInPast.
  ///
  /// In en, this message translates to:
  /// **'Start time cannot be in the past for today'**
  String get startTimeCannotBeInPast;

  /// No description provided for @verifiedMaternalCare.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED MATERNAL CARE'**
  String get verifiedMaternalCare;

  /// No description provided for @certifiedMidwivesNetwork.
  ///
  /// In en, this message translates to:
  /// **'Certified Health Professionals Network'**
  String get certifiedMidwivesNetwork;

  /// No description provided for @heroConsultGuidance.
  ///
  /// In en, this message translates to:
  /// **'Direct 1-on-1 consultations, prenatal guidance & trusted care.'**
  String get heroConsultGuidance;

  /// No description provided for @searchMidwivesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, hospital, or specialty...'**
  String get searchMidwivesHint;

  /// No description provided for @noMidwivesFound.
  ///
  /// In en, this message translates to:
  /// **'No health professionals found'**
  String get noMidwivesFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query.'**
  String get tryAdjustingSearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @certifiedHealthcareMidwife.
  ///
  /// In en, this message translates to:
  /// **'Certified Health Professional'**
  String get certifiedHealthcareMidwife;

  /// No description provided for @bookConsultation.
  ///
  /// In en, this message translates to:
  /// **'Book Consultation'**
  String get bookConsultation;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @startConsultationHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message to a certified health professional to start a consultation.'**
  String get startConsultationHint;

  /// No description provided for @emptyPendingAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you book an appointment, it will appear here awaiting confirmation.'**
  String get emptyPendingAppointmentsSubtitle;

  /// No description provided for @emptyUpcomingAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming consultations scheduled at this time.'**
  String get emptyUpcomingAppointmentsSubtitle;

  /// No description provided for @emptyPastAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled appointments will appear here.'**
  String get emptyPastAppointmentsSubtitle;

  /// Welcome message for midwife
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeMidwife(String name);

  /// No description provided for @midwifeDailySupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to support adolescent girls today with confidential healthcare.'**
  String get midwifeDailySupportSubtitle;

  /// No description provided for @reviewRequestsAndSchedule.
  ///
  /// In en, this message translates to:
  /// **'Review Requests & Schedule'**
  String get reviewRequestsAndSchedule;

  /// No description provided for @adolescentCareProtocolTitle.
  ///
  /// In en, this message translates to:
  /// **'Adolescent Care Protocol 2026'**
  String get adolescentCareProtocolTitle;

  /// No description provided for @adolescentCareProtocolDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard guidelines for confidential consultations, menstrual health education, and adolescent counseling.'**
  String get adolescentCareProtocolDesc;

  /// No description provided for @publishHealthTip.
  ///
  /// In en, this message translates to:
  /// **'Publish Health Tip'**
  String get publishHealthTip;

  /// No description provided for @publishHealthTipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share clinical advice directly with adolescent girls'**
  String get publishHealthTipSubtitle;

  /// No description provided for @keyTopicsCovered.
  ///
  /// In en, this message translates to:
  /// **'Key Topics Covered'**
  String get keyTopicsCovered;

  /// No description provided for @exploreInLearnCenter.
  ///
  /// In en, this message translates to:
  /// **'Explore in Learn Center'**
  String get exploreInLearnCenter;

  /// No description provided for @myBookmarks.
  ///
  /// In en, this message translates to:
  /// **'My Bookmarks'**
  String get myBookmarks;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password (min. 8 characters)'**
  String get enterNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordRequired;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks Yet'**
  String get noBookmarksYet;

  /// No description provided for @noBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Save educational guides and clinical materials to read anytime.'**
  String get noBookmarksDesc;

  /// No description provided for @exploreLearningModules.
  ///
  /// In en, this message translates to:
  /// **'Explore Learning Modules'**
  String get exploreLearningModules;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading Module'**
  String get startReading;

  /// No description provided for @accessClinicalGuide.
  ///
  /// In en, this message translates to:
  /// **'Access Clinical Guide'**
  String get accessClinicalGuide;

  /// No description provided for @actionRequiredForConsultations.
  ///
  /// In en, this message translates to:
  /// **'Action required for consultation slots'**
  String get actionRequiredForConsultations;

  /// No description provided for @noPendingRequestsAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'No pending requests at this time'**
  String get noPendingRequestsAtThisTime;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @midwifeWorkflowsAndTools.
  ///
  /// In en, this message translates to:
  /// **'Professional Workflows & Tools'**
  String get midwifeWorkflowsAndTools;

  /// No description provided for @manageHours.
  ///
  /// In en, this message translates to:
  /// **'Manage Hours'**
  String get manageHours;

  /// No description provided for @manageHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set daily availability slots'**
  String get manageHoursSubtitle;

  /// No description provided for @clientMessages.
  ///
  /// In en, this message translates to:
  /// **'Client Messages'**
  String get clientMessages;

  /// No description provided for @clientMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct non-urgent chat'**
  String get clientMessagesSubtitle;

  /// No description provided for @consultCalendar.
  ///
  /// In en, this message translates to:
  /// **'Consult Calendar'**
  String get consultCalendar;

  /// No description provided for @consultCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View confirmed sessions'**
  String get consultCalendarSubtitle;

  /// No description provided for @clinicalProtocols.
  ///
  /// In en, this message translates to:
  /// **'Clinical Protocols'**
  String get clinicalProtocols;

  /// No description provided for @todaysConfirmedConsultations.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Confirmed Consultations'**
  String get todaysConfirmedConsultations;

  /// No description provided for @caghEmergencyHotlineBadge.
  ///
  /// In en, this message translates to:
  /// **'CAGH EMERGENCY • 24/7'**
  String get caghEmergencyHotlineBadge;

  /// No description provided for @priorityBadge.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get priorityBadge;

  /// No description provided for @adolescentEmergencyHelpline.
  ///
  /// In en, this message translates to:
  /// **'Adolescent Emergency Helpline'**
  String get adolescentEmergencyHelpline;

  /// No description provided for @caghHotlineDescAdolescent.
  ///
  /// In en, this message translates to:
  /// **'24/7 confidential helpline for adolescent girls facing acute health emergencies, sudden pain, or needing urgent clinical guidance.'**
  String get caghHotlineDescAdolescent;

  /// No description provided for @callNowAction.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNowAction;

  /// No description provided for @shareLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocationAction;

  /// No description provided for @locatingAction.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locatingAction;

  /// No description provided for @yourLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocationTitle;

  /// No description provided for @acquiringGps.
  ///
  /// In en, this message translates to:
  /// **'Acquiring coordinates...'**
  String get acquiringGps;

  /// No description provided for @nationalEmergencyServices.
  ///
  /// In en, this message translates to:
  /// **'National Emergency Services'**
  String get nationalEmergencyServices;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// No description provided for @categorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get categorySecurity;

  /// No description provided for @categorySupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get categorySupport;

  /// No description provided for @nationalAmbulanceTitle.
  ///
  /// In en, this message translates to:
  /// **'National Ambulance & Health'**
  String get nationalAmbulanceTitle;

  /// No description provided for @nationalAmbulanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free emergency & urgent health response (24/7)'**
  String get nationalAmbulanceSubtitle;

  /// No description provided for @policeSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Police & Security Services'**
  String get policeSecurityTitle;

  /// No description provided for @policeSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'National emergency security response'**
  String get policeSecuritySubtitle;

  /// No description provided for @redCrossTitle.
  ///
  /// In en, this message translates to:
  /// **'Red Cross Ambulance'**
  String get redCrossTitle;

  /// No description provided for @redCrossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency first aid and patient transport'**
  String get redCrossSubtitle;

  /// No description provided for @womenChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Women & Child Protection'**
  String get womenChildTitle;

  /// No description provided for @womenChildSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helpline for adolescent girls & youth support'**
  String get womenChildSubtitle;

  /// No description provided for @publicHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Health Advisory (EPHI)'**
  String get publicHealthTitle;

  /// No description provided for @publicHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National disease & health advisory helpline'**
  String get publicHealthSubtitle;

  /// No description provided for @fireRescueTitle.
  ///
  /// In en, this message translates to:
  /// **'Fire & Rescue Services'**
  String get fireRescueTitle;

  /// No description provided for @fireRescueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Civil emergency, fire and disaster response'**
  String get fireRescueSubtitle;

  /// No description provided for @emergencyLinesNotice.
  ///
  /// In en, this message translates to:
  /// **'All national emergency lines listed are toll-free and accessible 24/7 without credit across Ethio Telecom and Safaricom networks. For CAGH Hotline (0996 71 77 44), standard mobile rates or toll-free assistance applies.'**
  String get emergencyLinesNotice;

  /// No description provided for @userLogin.
  ///
  /// In en, this message translates to:
  /// **'User Login'**
  String get userLogin;

  /// No description provided for @userSignUp.
  ///
  /// In en, this message translates to:
  /// **'User Sign Up'**
  String get userSignUp;

  /// No description provided for @professionalLogin.
  ///
  /// In en, this message translates to:
  /// **'Professional Login'**
  String get professionalLogin;

  /// No description provided for @professionalSignUp.
  ///
  /// In en, this message translates to:
  /// **'Professional Sign Up'**
  String get professionalSignUp;

  /// No description provided for @userRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For adolescent girls and young women'**
  String get userRoleSubtitle;

  /// No description provided for @professionalRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For healthcare professionals'**
  String get professionalRoleSubtitle;

  /// No description provided for @switchToProfessionalLogin.
  ///
  /// In en, this message translates to:
  /// **'Healthcare professional? Professional Login'**
  String get switchToProfessionalLogin;

  /// No description provided for @switchToUserLogin.
  ///
  /// In en, this message translates to:
  /// **'Seeking care? User Login'**
  String get switchToUserLogin;

  /// No description provided for @switchToProfessionalSignUp.
  ///
  /// In en, this message translates to:
  /// **'Healthcare professional? Professional Sign Up'**
  String get switchToProfessionalSignUp;

  /// No description provided for @switchToUserSignUp.
  ///
  /// In en, this message translates to:
  /// **'Seeking care? User Sign Up'**
  String get switchToUserSignUp;

  /// No description provided for @profession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profession;

  /// No description provided for @selectProfession.
  ///
  /// In en, this message translates to:
  /// **'Select Profession'**
  String get selectProfession;

  /// No description provided for @professionMidwife.
  ///
  /// In en, this message translates to:
  /// **'Midwife'**
  String get professionMidwife;

  /// No description provided for @professionNurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get professionNurse;

  /// No description provided for @professionDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor / General Practitioner'**
  String get professionDoctor;

  /// No description provided for @professionGyn.
  ///
  /// In en, this message translates to:
  /// **'Obstetrician / Gynecologist'**
  String get professionGyn;

  /// No description provided for @professionPsychologist.
  ///
  /// In en, this message translates to:
  /// **'Psychologist'**
  String get professionPsychologist;

  /// No description provided for @professionPsychiatrist.
  ///
  /// In en, this message translates to:
  /// **'Psychiatrist'**
  String get professionPsychiatrist;

  /// No description provided for @professionHealthOfficer.
  ///
  /// In en, this message translates to:
  /// **'Health Officer'**
  String get professionHealthOfficer;

  /// No description provided for @professionOther.
  ///
  /// In en, this message translates to:
  /// **'Other Health Professional'**
  String get professionOther;

  /// No description provided for @healthProfessional.
  ///
  /// In en, this message translates to:
  /// **'Health Professional'**
  String get healthProfessional;

  /// No description provided for @professionalDashboard.
  ///
  /// In en, this message translates to:
  /// **'Professional Dashboard'**
  String get professionalDashboard;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
