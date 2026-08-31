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
  /// **'Digital Midwife'**
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

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

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
  /// **'Select how you\'ll be using Digital Midwife to personalize your experience.'**
  String get subUserType;

  /// No description provided for @userTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;

  /// No description provided for @userSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I am seeking care and support'**
  String get userSubtitle;

  /// No description provided for @midwifeTitle.
  ///
  /// In en, this message translates to:
  /// **'Midwife'**
  String get midwifeTitle;

  /// No description provided for @midwifeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I am a healthcare provider'**
  String get midwifeSubtitle;

  /// No description provided for @enterContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your contact details'**
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
  /// **'Your trusted companion for women\'s health\\nand midwife support'**
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
  /// **'Midwife Login'**
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
  /// **'Our midwives are available for talk or visit any time.'**
  String get ourMidwivesAvailable;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @findAMidwife.
  ///
  /// In en, this message translates to:
  /// **'Find a Midwife'**
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
  /// **'Saved Midwives'**
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
  /// **'Online • Verified Midwife'**
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
  /// **'Free cancellation up to 24 hours before\\nyour appointment.'**
  String get freeCancellationNotice;

  /// No description provided for @waitingForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation.'**
  String get waitingForConfirmation;

  /// No description provided for @yourMidwife.
  ///
  /// In en, this message translates to:
  /// **'Your Midwife'**
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
  /// **'You can now sign in using your\\nnew password.'**
  String get signInNewPassword;

  /// No description provided for @midwifeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Midwife Registration'**
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
  /// **'Certified Midwife'**
  String get certifiedMidwife;

  /// No description provided for @keepAppointment.
  ///
  /// In en, this message translates to:
  /// **'Keep Appointment'**
  String get keepAppointment;

  /// No description provided for @noMidwivesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No midwives available at the moment.'**
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
  /// **'Verified Midwife'**
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
  /// **'In-person'**
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
  /// **'View All'**
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
  /// **'SOS'**
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
  /// **'Use the SOS button above to notify contacts.'**
  String get useSosButton;

  /// No description provided for @lifeThreateningEmergency.
  ///
  /// In en, this message translates to:
  /// **'If this is a life-threatening medical\\nemergency, tap SOS immediately.'**
  String get lifeThreateningEmergency;

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
  /// **'Version 2.4.1 (Build 890)'**
  String get appVersion;

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
  /// **'Connect with a certified midwife for a consultation'**
  String get connectWithCertifiedMidwife;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;
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
