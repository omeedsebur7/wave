import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('ar'),
    Locale('ckb'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'WAVE'**
  String get appName;

  /// No description provided for @navReels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get navReels;

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarketplace;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @makeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get makeAnOffer;

  /// No description provided for @offersComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Offers are coming soon. Message the seller for now.'**
  String get offersComingSoon;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Find something in the market, or watch a Reel and buy straight from it.'**
  String get cartEmptyBody;

  /// No description provided for @browseTheMarket.
  ///
  /// In en, this message translates to:
  /// **'Browse the market'**
  String get browseTheMarket;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWith;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String lowStockCount(int count);

  /// No description provided for @peopleBought.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Be the first to buy this} =1{1 person bought this} other{{count} people bought this}}'**
  String peopleBought(int count);

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse without an account'**
  String get continueAsGuest;

  /// No description provided for @guestExplainer.
  ///
  /// In en, this message translates to:
  /// **'You can look around freely. An account is needed to buy, post or message.'**
  String get guestExplainer;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @andConnector.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andConnector;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @ageConfirmation.
  ///
  /// In en, this message translates to:
  /// **'I am 13 or older'**
  String get ageConfirmation;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @sendNewCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get sendNewCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyAndContinue;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @oneQuickStep.
  ///
  /// In en, this message translates to:
  /// **'One quick step'**
  String get oneQuickStep;

  /// No description provided for @phoneGateTitle.
  ///
  /// In en, this message translates to:
  /// **'We need a phone number before your first order'**
  String get phoneGateTitle;

  /// No description provided for @phoneGateBody.
  ///
  /// In en, this message translates to:
  /// **'It is how the courier reaches you, and it keeps fraudulent orders off your account. We only ask once — after this, buying takes one tap.'**
  String get phoneGateBody;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get orderOnTheWay;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @yourOrders.
  ///
  /// In en, this message translates to:
  /// **'Your orders'**
  String get yourOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @noOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'What you buy shows up here, with where it has got to.'**
  String get noOrdersBody;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @rateThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate this order'**
  String get rateThisOrder;

  /// No description provided for @stageConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'The seller has your order and is getting it ready. You can still cancel until it leaves.'**
  String get stageConfirmedBody;

  /// No description provided for @stageOnTheWayBody.
  ///
  /// In en, this message translates to:
  /// **'On its way to you. The courier will call the number on your account.'**
  String get stageOnTheWayBody;

  /// No description provided for @stageDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Delivered. Enjoy it.'**
  String get stageDeliveredBody;

  /// No description provided for @trustBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze Trusted'**
  String get trustBronze;

  /// No description provided for @trustSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver Trusted'**
  String get trustSilver;

  /// No description provided for @trustGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Trusted'**
  String get trustGold;

  /// No description provided for @trustPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get trustPlatinum;

  /// No description provided for @trustVerifiedSeller.
  ///
  /// In en, this message translates to:
  /// **'Verified seller'**
  String get trustVerifiedSeller;

  /// No description provided for @trustNewSeller.
  ///
  /// In en, this message translates to:
  /// **'New seller'**
  String get trustNewSeller;

  /// No description provided for @noTrackRecordBody.
  ///
  /// In en, this message translates to:
  /// **'This seller has no completed orders yet, so there are no ratings to go on. Cash on delivery is the safest way to buy from someone new.'**
  String get noTrackRecordBody;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(int count);

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addAComment;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @noCommentsBody.
  ///
  /// In en, this message translates to:
  /// **'Ask about size, condition or delivery — the seller can answer here.'**
  String get noCommentsBody;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @verifiedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Verified purchase'**
  String get verifiedPurchase;

  /// No description provided for @reviewVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only buyers who received this item can review it, so reviews here always come from a real order.'**
  String get reviewVerifiedOnly;

  /// No description provided for @editWindowNote.
  ///
  /// In en, this message translates to:
  /// **'You can edit this for 48 hours, then it is locked.'**
  String get editWindowNote;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @ratingBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get ratingBad;

  /// No description provided for @ratingNotGreat.
  ///
  /// In en, this message translates to:
  /// **'Not great'**
  String get ratingNotGreat;

  /// No description provided for @ratingFine.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get ratingFine;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingExcellent;

  /// No description provided for @tapAStar.
  ///
  /// In en, this message translates to:
  /// **'Tap a star'**
  String get tapAStar;

  /// No description provided for @newReel.
  ///
  /// In en, this message translates to:
  /// **'New Reel'**
  String get newReel;

  /// No description provided for @chooseAVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get chooseAVideo;

  /// No description provided for @caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get caption;

  /// No description provided for @linkAProduct.
  ///
  /// In en, this message translates to:
  /// **'Link a product'**
  String get linkAProduct;

  /// No description provided for @linkAProductBody.
  ///
  /// In en, this message translates to:
  /// **'Adds a Buy Now button to this Reel'**
  String get linkAProductBody;

  /// No description provided for @listAProduct.
  ///
  /// In en, this message translates to:
  /// **'List a product'**
  String get listAProduct;

  /// No description provided for @whatIsIt.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get whatIsIt;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @howMany.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get howMany;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @listingIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your listing is live'**
  String get listingIsLive;

  /// No description provided for @reelIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your Reel is live'**
  String get reelIsLive;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifOrders.
  ///
  /// In en, this message translates to:
  /// **'Order updates'**
  String get notifOrders;

  /// No description provided for @notifOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed, on the way, delivered'**
  String get notifOrdersBody;

  /// No description provided for @notifChat.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifChat;

  /// No description provided for @notifChatBody.
  ///
  /// In en, this message translates to:
  /// **'When a buyer or seller replies'**
  String get notifChatBody;

  /// No description provided for @notifSocial.
  ///
  /// In en, this message translates to:
  /// **'Likes, comments and follows'**
  String get notifSocial;

  /// No description provided for @notifSocialBody.
  ///
  /// In en, this message translates to:
  /// **'Activity on your Reels and profile'**
  String get notifSocialBody;

  /// No description provided for @notifMarketing.
  ///
  /// In en, this message translates to:
  /// **'Offers and announcements'**
  String get notifMarketing;

  /// No description provided for @notifMarketingBody.
  ///
  /// In en, this message translates to:
  /// **'Occasional news about WAVE'**
  String get notifMarketingBody;

  /// No description provided for @nothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get nothingNew;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @errorNoConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorNoConnectionBody;

  /// No description provided for @errorDeadLink.
  ///
  /// In en, this message translates to:
  /// **'This link went nowhere'**
  String get errorDeadLink;

  /// No description provided for @errorDeadLinkBody.
  ///
  /// In en, this message translates to:
  /// **'The page you followed doesn\'t exist or has been removed.'**
  String get errorDeadLinkBody;

  /// No description provided for @searchProductsAndReels.
  ///
  /// In en, this message translates to:
  /// **'Search products and Reels'**
  String get searchProductsAndReels;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update WAVE to keep going'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. The update takes a moment, and your cart and orders are safe.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @acceptAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get acceptAndContinue;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @browsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'You are browsing as a guest'**
  String get browsingAsGuest;

  /// No description provided for @guestUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to buy, sell, save favourites and message sellers. Anything in your cart comes with you.'**
  String get guestUpgradeBody;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @savedReels.
  ///
  /// In en, this message translates to:
  /// **'Saved Reels'**
  String get savedReels;

  /// No description provided for @ordersToFulfil.
  ///
  /// In en, this message translates to:
  /// **'Orders to fulfil'**
  String get ordersToFulfil;

  /// No description provided for @howYouAreDoing.
  ///
  /// In en, this message translates to:
  /// **'How you are doing'**
  String get howYouAreDoing;

  /// No description provided for @termsAndPolicies.
  ///
  /// In en, this message translates to:
  /// **'Terms and policies'**
  String get termsAndPolicies;

  /// No description provided for @downloadYourData.
  ///
  /// In en, this message translates to:
  /// **'Download your data'**
  String get downloadYourData;

  /// No description provided for @preparingYourData.
  ///
  /// In en, this message translates to:
  /// **'Preparing your data — this may take a moment'**
  String get preparingYourData;

  /// No description provided for @deleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteYourAccount;

  /// No description provided for @deleteYourAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteYourAccountQ;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good: your profile, Reels, listings, saved items, addresses and payment methods.\n\nKept without your name: completed orders, and the ratings and reviews you left. Sellers need their transaction records, and removing your ratings would quietly change their score for the next buyer.\n\nIf something is already on its way to you, its delivery details stay until it arrives — the courier is holding your parcel. They are erased within a day of delivery.\n\nThis cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @keepMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get keepMyAccount;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// No description provided for @orderedOn.
  ///
  /// In en, this message translates to:
  /// **'Ordered {date}'**
  String orderedOn(String date);

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find that order'**
  String get orderNotFound;

  /// No description provided for @orderNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or the link may be wrong.'**
  String get orderNotFoundBody;

  /// No description provided for @cancelThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order'**
  String get cancelThisOrder;

  /// No description provided for @cancelThisOrderQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelThisOrderQ;

  /// No description provided for @cancelOrderBuyerBody.
  ///
  /// In en, this message translates to:
  /// **'The seller is told straight away and anything paid is refunded. You cannot undo this.'**
  String get cancelOrderBuyerBody;

  /// No description provided for @howDidItGo.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get howDidItGo;

  /// No description provided for @ratingHelpsNextBuyer.
  ///
  /// In en, this message translates to:
  /// **'Your rating is what gives this seller their badge — and what tells the next buyer whether to trust them.'**
  String get ratingHelpsNextBuyer;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your rating is in'**
  String get ratingSubmitted;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Size, condition, materials — whatever a buyer would ask before deciding'**
  String get descriptionHint;

  /// No description provided for @coverPhotoNote.
  ///
  /// In en, this message translates to:
  /// **'The first photo is what buyers see in the grid. Up to {max}.'**
  String coverPhotoNote(int max);

  /// No description provided for @buyersWillSee.
  ///
  /// In en, this message translates to:
  /// **'Buyers will see {price}'**
  String buyersWillSee(String price);

  /// No description provided for @uploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get uploadingPhotos;

  /// No description provided for @makeAReel.
  ///
  /// In en, this message translates to:
  /// **'Make a Reel'**
  String get makeAReel;

  /// No description provided for @aboutThisItem.
  ///
  /// In en, this message translates to:
  /// **'About this item'**
  String get aboutThisItem;

  /// No description provided for @shareThisItem.
  ///
  /// In en, this message translates to:
  /// **'Share this item'**
  String get shareThisItem;

  /// No description provided for @reportThisListing.
  ///
  /// In en, this message translates to:
  /// **'Report this listing'**
  String get reportThisListing;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find that item'**
  String get productNotFound;

  /// No description provided for @productNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have sold out or been removed by the seller.'**
  String get productNotFoundBody;

  /// No description provided for @backToTheMarket.
  ///
  /// In en, this message translates to:
  /// **'Back to the market'**
  String get backToTheMarket;

  /// No description provided for @otherActions.
  ///
  /// In en, this message translates to:
  /// **'Other actions'**
  String get otherActions;

  /// No description provided for @buyerCanStillCancel.
  ///
  /// In en, this message translates to:
  /// **'The buyer can still cancel until you hand this to a courier.'**
  String get buyerCanStillCancel;

  /// No description provided for @cancelOrderSellerBody.
  ///
  /// In en, this message translates to:
  /// **'The buyer is refunded and told straight away. Cancelling orders you have already accepted affects your trust tier, so only do this if you genuinely cannot fulfil it.'**
  String get cancelOrderSellerBody;

  /// No description provided for @nothingWaitingOnYou.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting on you'**
  String get nothingWaitingOnYou;

  /// No description provided for @nothingWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'New orders show up here the moment someone buys.'**
  String get nothingWaitingBody;

  /// No description provided for @nothingInTransit.
  ///
  /// In en, this message translates to:
  /// **'Nothing in transit'**
  String get nothingInTransit;

  /// No description provided for @nothingInTransitBody.
  ///
  /// In en, this message translates to:
  /// **'Orders you have handed to a courier appear here.'**
  String get nothingInTransitBody;

  /// No description provided for @noCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders yet'**
  String get noCompletedOrders;

  /// No description provided for @noCompletedOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Delivered and cancelled orders are kept here.'**
  String get noCompletedOrdersBody;

  /// No description provided for @filterToDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get filterToDo;

  /// No description provided for @filterOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get filterOnTheWay;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get soldOut;

  /// No description provided for @deliveryArrangedNote.
  ///
  /// In en, this message translates to:
  /// **'Delivery is arranged with the seller after you order.'**
  String get deliveryArrangedNote;

  /// No description provided for @cartMultiSellerWarning.
  ///
  /// In en, this message translates to:
  /// **'Your cart has items from more than one seller. Order them separately for now.'**
  String get cartMultiSellerWarning;

  /// No description provided for @cartStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Some items sold out or dropped below the quantity you chose. Adjust them to continue.'**
  String get cartStockWarning;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @noAddressYet.
  ///
  /// In en, this message translates to:
  /// **'No address yet'**
  String get noAddressYet;

  /// No description provided for @savedAddress.
  ///
  /// In en, this message translates to:
  /// **'Saved address'**
  String get savedAddress;

  /// No description provided for @savedPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Saved payment method'**
  String get savedPaymentMethod;

  /// No description provided for @codAvailableNote.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery is available in your area'**
  String get codAvailableNote;

  /// No description provided for @placeOrderWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Place order · {total}'**
  String placeOrderWithTotal(String total);

  /// No description provided for @signInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Sign in to place this order'**
  String get signInToOrder;

  /// No description provided for @signInToOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Guests can browse and fill a cart, but an order needs an account.'**
  String get signInToOrderBody;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number'**
  String get verifyYourPhone;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get verifyNow;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address'**
  String get addDeliveryAddress;

  /// No description provided for @addAddressBody.
  ///
  /// In en, this message translates to:
  /// **'The seller needs somewhere to send this.'**
  String get addAddressBody;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @chooseHowToPay.
  ///
  /// In en, this message translates to:
  /// **'Choose how to pay'**
  String get chooseHowToPay;

  /// No description provided for @chooseHowToPayBody.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery is available in most areas.'**
  String get chooseHowToPayBody;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @newAddress.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get newAddress;

  /// No description provided for @addANewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get addANewAddress;

  /// No description provided for @whoIsReceiving.
  ///
  /// In en, this message translates to:
  /// **'Who is receiving it'**
  String get whoIsReceiving;

  /// No description provided for @phoneForCourier.
  ///
  /// In en, this message translates to:
  /// **'Phone for the courier'**
  String get phoneForCourier;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @addressLine.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood, street, building'**
  String get addressLine;

  /// No description provided for @landmarkOptional.
  ///
  /// In en, this message translates to:
  /// **'Nearest landmark (optional)'**
  String get landmarkOptional;

  /// No description provided for @landmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Opposite the blue mosque, above the pharmacy…'**
  String get landmarkHint;

  /// No description provided for @landmarkNote.
  ///
  /// In en, this message translates to:
  /// **'Couriers here usually find an address by landmark and a phone call, so this helps more than it looks like it should.'**
  String get landmarkNote;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @chooseADifferentVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose a different video'**
  String get chooseADifferentVideo;

  /// No description provided for @upToNSeconds.
  ///
  /// In en, this message translates to:
  /// **'Up to {seconds} seconds'**
  String upToNSeconds(int seconds);

  /// No description provided for @durationOfMax.
  ///
  /// In en, this message translates to:
  /// **'{actual}s of {max}s'**
  String durationOfMax(int actual, int max);

  /// No description provided for @videoTooLong.
  ///
  /// In en, this message translates to:
  /// **'That video is {actual}s. Trim it to {max} seconds or less and pick it again.'**
  String videoTooLong(int actual, int max);

  /// No description provided for @captionHint.
  ///
  /// In en, this message translates to:
  /// **'Say what it is, and why someone would want it'**
  String get captionHint;

  /// No description provided for @removeTheLink.
  ///
  /// In en, this message translates to:
  /// **'Remove the link'**
  String get removeTheLink;

  /// No description provided for @linkedProductNote.
  ///
  /// In en, this message translates to:
  /// **'Buyers can purchase this straight from the Reel'**
  String get linkedProductNote;

  /// No description provided for @statsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Your numbers didn\'t load'**
  String get statsNotLoaded;

  /// No description provided for @lastNDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String lastNDays(int days);

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'earned'**
  String get earned;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get orders;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get rating;

  /// No description provided for @wherePeopleDropOff.
  ///
  /// In en, this message translates to:
  /// **'Where people drop off'**
  String get wherePeopleDropOff;

  /// No description provided for @funnelExplainer.
  ///
  /// In en, this message translates to:
  /// **'Each step shows how many carried on to the next.'**
  String get funnelExplainer;

  /// No description provided for @funnelLowSample.
  ///
  /// In en, this message translates to:
  /// **'These percentages are unreliable below about 100 views — treat them as a hint, not a verdict.'**
  String get funnelLowSample;

  /// No description provided for @funnelWatched.
  ///
  /// In en, this message translates to:
  /// **'Watched a Reel'**
  String get funnelWatched;

  /// No description provided for @funnelTapped.
  ///
  /// In en, this message translates to:
  /// **'Tapped Buy Now'**
  String get funnelTapped;

  /// No description provided for @funnelCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed the order'**
  String get funnelCompleted;

  /// No description provided for @lowTapThroughNote.
  ///
  /// In en, this message translates to:
  /// **'Few watchers tap Buy Now. The Reel may not be showing the product clearly, or the price may not be visible early enough.'**
  String get lowTapThroughNote;

  /// No description provided for @lowCompletionNote.
  ///
  /// In en, this message translates to:
  /// **'Most people who tap Buy Now do not finish. That is usually price, stock running out, or a first-time buyer meeting the phone verification step.'**
  String get lowCompletionNote;

  /// No description provided for @yourReels.
  ///
  /// In en, this message translates to:
  /// **'Your Reels'**
  String get yourReels;

  /// No description provided for @nothingPublishedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing published yet.'**
  String get nothingPublishedYet;

  /// No description provided for @ordersWaitingOne.
  ///
  /// In en, this message translates to:
  /// **'1 order is waiting on you'**
  String get ordersWaitingOne;

  /// No description provided for @ordersWaitingMany.
  ///
  /// In en, this message translates to:
  /// **'{count} orders are waiting on you'**
  String ordersWaitingMany(int count);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @viewsAndSold.
  ///
  /// In en, this message translates to:
  /// **'{views} views · {sold} sold'**
  String viewsAndSold(int views, int sold);

  /// No description provided for @wastedAudienceNote.
  ///
  /// In en, this message translates to:
  /// **'{views} people watched this and had nothing to buy. Link a product to it.'**
  String wastedAudienceNote(int views);

  /// No description provided for @reportThis.
  ///
  /// In en, this message translates to:
  /// **'Report this'**
  String get reportThis;

  /// No description provided for @whatIsWrongWithIt.
  ///
  /// In en, this message translates to:
  /// **'What is wrong with it?'**
  String get whatIsWrongWithIt;

  /// No description provided for @alsoBlockAccount.
  ///
  /// In en, this message translates to:
  /// **'Also block this account'**
  String get alsoBlockAccount;

  /// No description provided for @blockExplainer.
  ///
  /// In en, this message translates to:
  /// **'You will stop seeing their posts and messages'**
  String get blockExplainer;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @reportSentBody.
  ///
  /// In en, this message translates to:
  /// **'A moderator will look at this. We do not share what happens next, and the person reported is not told who reported them.'**
  String get reportSentBody;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reasonSpam;

  /// No description provided for @reasonCounterfeit.
  ///
  /// In en, this message translates to:
  /// **'Counterfeit or misrepresented item'**
  String get reasonCounterfeit;

  /// No description provided for @reasonProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited item'**
  String get reasonProhibited;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get reasonHarassment;

  /// No description provided for @reasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get reasonSexual;

  /// No description provided for @reasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or dangerous acts'**
  String get reasonViolence;

  /// No description provided for @reasonIntellectualProperty.
  ///
  /// In en, this message translates to:
  /// **'Copyright or trademark'**
  String get reasonIntellectualProperty;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reasonOther;

  /// No description provided for @sellerNotFound.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find that seller'**
  String get sellerNotFound;

  /// No description provided for @sellerNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The account may have been removed.'**
  String get sellerNotFoundBody;

  /// No description provided for @reportOrBlock.
  ///
  /// In en, this message translates to:
  /// **'Report or block'**
  String get reportOrBlock;

  /// No description provided for @sellingSince.
  ///
  /// In en, this message translates to:
  /// **'Selling since {date}'**
  String sellingSince(String date);

  /// No description provided for @nothingListedRightNow.
  ///
  /// In en, this message translates to:
  /// **'Nothing listed right now.'**
  String get nothingListedRightNow;

  /// No description provided for @listings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// No description provided for @listingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} listings'**
  String listingsCount(int count);

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get followers;

  /// No description provided for @ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingsCount(int count);

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'delivered'**
  String get delivered;

  /// No description provided for @goToReels.
  ///
  /// In en, this message translates to:
  /// **'Go to Reels'**
  String get goToReels;

  /// No description provided for @reelsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Reels didn\'t load'**
  String get reelsNotLoaded;

  /// No description provided for @noReelsYet.
  ///
  /// In en, this message translates to:
  /// **'No Reels yet'**
  String get noReelsYet;

  /// No description provided for @noReelsBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post one.'**
  String get noReelsBody;

  /// No description provided for @nothingSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSavedYet;

  /// No description provided for @savedReelsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on a Reel to keep it here.'**
  String get savedReelsBody;

  /// No description provided for @watchSomeReels.
  ///
  /// In en, this message translates to:
  /// **'Watch some Reels'**
  String get watchSomeReels;

  /// No description provided for @favouritesBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on anything you want to come back to.'**
  String get favouritesBody;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Watch, and buy what you see.'**
  String get appTagline;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @marketEmpty.
  ///
  /// In en, this message translates to:
  /// **'The market is empty'**
  String get marketEmpty;

  /// No description provided for @marketEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is listed yet. Be the first to sell something.'**
  String get marketEmptyBody;

  /// No description provided for @productsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Products didn\'t load'**
  String get productsNotLoaded;

  /// No description provided for @nothingMatched.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched \"{query}\"'**
  String nothingMatched(String query);

  /// No description provided for @searchPrefixNoteProducts.
  ///
  /// In en, this message translates to:
  /// **'Search matches the start of a product name. Try a shorter or different word.'**
  String get searchPrefixNoteProducts;

  /// No description provided for @searchPrefixNoteAll.
  ///
  /// In en, this message translates to:
  /// **'Search matches the start of a name or caption, so try the first word rather than a word from the middle.'**
  String get searchPrefixNoteAll;

  /// No description provided for @searchHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Search across everything for sale and every Reel.'**
  String get searchHintEmpty;

  /// No description provided for @searchHintShort.
  ///
  /// In en, this message translates to:
  /// **'Keep typing — searches start at two letters.'**
  String get searchHintShort;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @ordersNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Your orders didn\'t load'**
  String get ordersNotLoaded;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptDocTitle.
  ///
  /// In en, this message translates to:
  /// **'WAVE receipt {id}'**
  String receiptDocTitle(String id);

  /// No description provided for @receiptSoldBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by'**
  String get receiptSoldBy;

  /// No description provided for @receiptBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get receiptBuyer;

  /// No description provided for @receiptDeliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to'**
  String get receiptDeliveredTo;

  /// No description provided for @receiptStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get receiptStatus;

  /// No description provided for @receiptItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get receiptItem;

  /// No description provided for @receiptQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get receiptQty;

  /// No description provided for @receiptUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get receiptUnit;

  /// No description provided for @receiptDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a record of a purchase made through WAVE. WAVE is a marketplace; the sale is between the buyer and the seller named above. It is not a tax invoice unless the seller has issued one separately.'**
  String get receiptDisclaimer;

  /// No description provided for @yourWaveData.
  ///
  /// In en, this message translates to:
  /// **'Your WAVE data'**
  String get yourWaveData;

  /// No description provided for @sellFromThisReel.
  ///
  /// In en, this message translates to:
  /// **'Sell from this Reel'**
  String get sellFromThisReel;

  /// No description provided for @sellFromThisReelBody.
  ///
  /// In en, this message translates to:
  /// **'Pick one of your listings. Buyers get a Buy Now button without leaving the video.'**
  String get sellFromThisReelBody;

  /// No description provided for @nothingListedYet.
  ///
  /// In en, this message translates to:
  /// **'You have nothing listed yet.'**
  String get nothingListedYet;

  /// No description provided for @listAProductFirst.
  ///
  /// In en, this message translates to:
  /// **'List a product first'**
  String get listAProductFirst;

  /// No description provided for @uploadAReel.
  ///
  /// In en, this message translates to:
  /// **'Upload a Reel'**
  String get uploadAReel;

  /// No description provided for @uploadAReelBody.
  ///
  /// In en, this message translates to:
  /// **'Up to 60 seconds. Link a product to sell from it.'**
  String get uploadAReelBody;

  /// No description provided for @listAProductBody.
  ///
  /// In en, this message translates to:
  /// **'Add photos, price and stock.'**
  String get listAProductBody;

  /// No description provided for @versionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · updated {date}'**
  String versionUpdated(String version, String date);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @documentNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'That document didn\'t load'**
  String get documentNotLoaded;

  /// No description provided for @beforeYouStart.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get beforeYouStart;

  /// No description provided for @termsChanged.
  ///
  /// In en, this message translates to:
  /// **'Our terms have changed'**
  String get termsChanged;

  /// No description provided for @documentChanged.
  ///
  /// In en, this message translates to:
  /// **'{title} has changed'**
  String documentChanged(String title);

  /// No description provided for @acceptToUse.
  ///
  /// In en, this message translates to:
  /// **'Please read and accept these to use WAVE.'**
  String get acceptToUse;

  /// No description provided for @readWhatChanged.
  ///
  /// In en, this message translates to:
  /// **'Please read what changed before continuing.'**
  String get readWhatChanged;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addANote;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'When you message a seller about an item, the conversation shows up here.'**
  String get noMessagesBody;

  /// No description provided for @aboutAListing.
  ///
  /// In en, this message translates to:
  /// **'About a listing'**
  String get aboutAListing;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @chatEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask about size, condition, delivery — whatever you need to know before you buy.'**
  String get chatEmptyPrompt;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @notificationsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Notifications didn\'t load'**
  String get notificationsNotLoaded;

  /// No description provided for @nothingNewBody.
  ///
  /// In en, this message translates to:
  /// **'Order updates, replies and activity on your posts show up here.'**
  String get nothingNewBody;

  /// No description provided for @notifOrdersOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Turning off order updates means we will not tell you when something you bought is on its way.'**
  String get notifOrdersOffWarning;

  /// No description provided for @howDoYouWantToPay.
  ///
  /// In en, this message translates to:
  /// **'How do you want to pay?'**
  String get howDoYouWantToPay;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add {method}'**
  String addPaymentMethod(String method);

  /// No description provided for @cardDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'Card details are held by the payment provider, never by WAVE.'**
  String get cardDetailsNote;

  /// No description provided for @railCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get railCashOnDelivery;

  /// No description provided for @railCashOnDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Pay the courier when it arrives'**
  String get railCashOnDeliveryBody;

  /// No description provided for @railMobileWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get railMobileWallet;

  /// No description provided for @railCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get railCard;

  /// No description provided for @railBankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank card'**
  String get railBankCard;

  /// No description provided for @railBankCardBody.
  ///
  /// In en, this message translates to:
  /// **'Visa or Mastercard'**
  String get railBankCardBody;

  /// No description provided for @lowStockShort.
  ///
  /// In en, this message translates to:
  /// **'Only a few left'**
  String get lowStockShort;

  /// No description provided for @phoneGateShortNote.
  ///
  /// In en, this message translates to:
  /// **'We ask once. Your number is used for delivery updates and to protect your account — after this, buying is one tap.'**
  String get phoneGateShortNote;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Code applied. The discount is confirmed at checkout.'**
  String get promoApplied;

  /// No description provided for @stockLimitReached.
  ///
  /// In en, this message translates to:
  /// **'That is all the stock available'**
  String get stockLimitReached;

  /// No description provided for @postComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get postComment;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Watch. Tap. Own it.'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Every Reel can be a shop. If you like what you see, buy it without leaving the video.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Know who you are buying from'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Sellers earn their badge from real, delivered orders — not from what they say about themselves.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Sell what you make'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Post a Reel, link a product, get paid. When something sells we will let you know straight away — you can turn that off any time.'**
  String get onboardingBody3;

  /// No description provided for @startBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Start browsing'**
  String get startBrowsing;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfTotal(int current, int total);

  /// No description provided for @orderStatusSemantic.
  ///
  /// In en, this message translates to:
  /// **'Order status: {status}, step {step} of 3'**
  String orderStatusSemantic(String status, int step);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutQ.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQ;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will stop getting notifications on this device, and nobody using it after you will see your orders.'**
  String get signOutBody;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @promoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Have a code?'**
  String get promoCodeHint;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @promoInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid'**
  String get promoInvalid;

  /// No description provided for @promoExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired'**
  String get promoExpired;

  /// No description provided for @promoUsed.
  ///
  /// In en, this message translates to:
  /// **'You have already used that code'**
  String get promoUsed;

  /// No description provided for @mediaAccessRationale.
  ///
  /// In en, this message translates to:
  /// **'WAVE needs access to your videos so you can pick one to post. We only see the video you choose.'**
  String get mediaAccessRationale;

  /// No description provided for @stageCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled. Any payment taken is refunded to the original method.'**
  String get stageCancelledBody;

  /// No description provided for @shareThisReel.
  ///
  /// In en, this message translates to:
  /// **'Share this Reel'**
  String get shareThisReel;

  /// No description provided for @reportThisReel.
  ///
  /// In en, this message translates to:
  /// **'Report this Reel'**
  String get reportThisReel;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended'**
  String get accountSuspended;

  /// No description provided for @accountSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'You can still see your orders and read our Content Policy, but you cannot post, sell, comment or message while the suspension is in place.'**
  String get accountSuspendedBody;

  /// No description provided for @readContentPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read the Content Policy'**
  String get readContentPolicy;

  /// No description provided for @recoverAccount.
  ///
  /// In en, this message translates to:
  /// **'Recover your account'**
  String get recoverAccount;

  /// No description provided for @recoverByPhone.
  ///
  /// In en, this message translates to:
  /// **'Using your phone number'**
  String get recoverByPhone;

  /// No description provided for @recoverByPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'We will send a code to the number on the account. Entering it signs you back in.'**
  String get recoverByPhoneBody;

  /// No description provided for @recoverByEmail.
  ///
  /// In en, this message translates to:
  /// **'Using your email'**
  String get recoverByEmail;

  /// No description provided for @recoverByEmailBody.
  ///
  /// In en, this message translates to:
  /// **'If you signed up with Google or Apple and no longer have that phone, use the email on the account instead.'**
  String get recoverByEmailBody;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @sendRecoveryEmail.
  ///
  /// In en, this message translates to:
  /// **'Send a recovery email'**
  String get sendRecoveryEmail;

  /// No description provided for @recoveryEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If that address has an account, a recovery email is on its way.'**
  String get recoveryEmailSent;

  /// No description provided for @forgotAccess.
  ///
  /// In en, this message translates to:
  /// **'Lost access to your account?'**
  String get forgotAccess;

  /// No description provided for @offlineBannerBody.
  ///
  /// In en, this message translates to:
  /// **'You are offline. What you do now is saved and will sync when you\'re back.'**
  String get offlineBannerBody;

  /// No description provided for @stagePendingPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment to go through. The seller sees this order once it does — usually within a minute.'**
  String get stagePendingPaymentBody;

  /// No description provided for @stagePaymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment did not go through, so the seller has not been sent this order. Nothing has been charged.'**
  String get stagePaymentFailedBody;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get paymentPending;

  /// No description provided for @promoBelowMinimum.
  ///
  /// In en, this message translates to:
  /// **'That code needs a larger order'**
  String get promoBelowMinimum;

  /// No description provided for @promoTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many code attempts. Try again later.'**
  String get promoTooManyAttempts;

  /// No description provided for @buyNowWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy now · {price}'**
  String buyNowWithPrice(String price);

  /// No description provided for @setDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Set delivery location'**
  String get setDeliveryLocation;

  /// No description provided for @dragMapToSetPin.
  ///
  /// In en, this message translates to:
  /// **'Move the map to put the pin on your door.'**
  String get dragMapToSetPin;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @confirmAndBuy.
  ///
  /// In en, this message translates to:
  /// **'Confirm and buy · {price}'**
  String confirmAndBuy(String price);

  /// No description provided for @deliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Landmark or directions'**
  String get deliveryNote;

  /// No description provided for @deliveryNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Blue gate, second floor, opposite the pharmacy…'**
  String get deliveryNoteHint;

  /// No description provided for @deliveryNoteWhy.
  ///
  /// In en, this message translates to:
  /// **'Couriers here usually find a door by landmark and a phone call, so this helps more than the pin does.'**
  String get deliveryNoteWhy;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off, so place the pin by hand.'**
  String get locationPermissionDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find you. Place the pin by hand.'**
  String get locationUnavailable;

  /// No description provided for @locationTooVague.
  ///
  /// In en, this message translates to:
  /// **'That fix is very rough. Move the pin to your door so the courier is not guessing.'**
  String get locationTooVague;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery location'**
  String get deliveryLocation;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get openInMaps;

  /// No description provided for @noLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No map pin on this order'**
  String get noLocationSet;

  /// No description provided for @approximateFix.
  ///
  /// In en, this message translates to:
  /// **'Approximate — phone before setting off'**
  String get approximateFix;

  /// No description provided for @setDeliveryLocationWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Set delivery location · {price}'**
  String setDeliveryLocationWithPrice(String price);

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get statusPendingPayment;

  /// No description provided for @statusPaymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payment processing'**
  String get statusPaymentProcessing;

  /// No description provided for @statusPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get statusPaymentFailed;

  /// No description provided for @statusNeedsPacking.
  ///
  /// In en, this message translates to:
  /// **'New — needs packing'**
  String get statusNeedsPacking;

  /// No description provided for @statusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get statusPacked;

  /// No description provided for @statusWithCourier.
  ///
  /// In en, this message translates to:
  /// **'With the courier'**
  String get statusWithCourier;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get statusOutForDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLowToHigh;

  /// No description provided for @sortPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHighToLow;

  /// No description provided for @sortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get sortTopRated;

  /// No description provided for @uploadValidating.
  ///
  /// In en, this message translates to:
  /// **'Checking your video'**
  String get uploadValidating;

  /// No description provided for @uploadCompressing.
  ///
  /// In en, this message translates to:
  /// **'Making it smaller'**
  String get uploadCompressing;

  /// No description provided for @uploadPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get uploadPreparing;

  /// No description provided for @uploadUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadUploading;

  /// No description provided for @uploadProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing — you can leave this screen'**
  String get uploadProcessing;

  /// No description provided for @uploadPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get uploadPublishing;

  /// No description provided for @uploadDone.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get uploadDone;

  /// No description provided for @ratePromptProduct.
  ///
  /// In en, this message translates to:
  /// **'How is {name}?'**
  String ratePromptProduct(String name);

  /// No description provided for @ratePromptSeller.
  ///
  /// In en, this message translates to:
  /// **'How was {name} to buy from?'**
  String ratePromptSeller(String name);

  /// No description provided for @actionMarkPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark as packed'**
  String get actionMarkPacked;

  /// No description provided for @actionHandedToCourier.
  ///
  /// In en, this message translates to:
  /// **'Handed to courier'**
  String get actionHandedToCourier;

  /// No description provided for @actionOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get actionOutForDelivery;

  /// No description provided for @actionMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get actionMarkDelivered;

  /// No description provided for @actionCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get actionCancelOrder;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get errorNotSignedIn;

  /// No description provided for @errorSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled'**
  String get errorSignInCancelled;

  /// No description provided for @errorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign you in. Try again.'**
  String get errorSignInFailed;

  /// No description provided for @errorGuestSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start a guest session'**
  String get errorGuestSessionFailed;

  /// No description provided for @errorCodeSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Try again.'**
  String get errorCodeSendFailed;

  /// No description provided for @errorCodeSendThrottled.
  ///
  /// In en, this message translates to:
  /// **'Too many codes requested. Try again in {minutes} min.'**
  String errorCodeSendThrottled(int minutes);

  /// No description provided for @errorCodeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check and retry.'**
  String get errorCodeIncorrect;

  /// No description provided for @errorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'That code expired. Request a new one.'**
  String get errorCodeExpired;

  /// No description provided for @errorRequestCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Request a code first'**
  String get errorRequestCodeFirst;

  /// No description provided for @errorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your number. Try again.'**
  String get errorVerificationFailed;

  /// No description provided for @errorPhoneOnAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'This number is already on another account.'**
  String get errorPhoneOnAnotherAccount;

  /// No description provided for @errorPhoneLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'That number did not attach to your account. Try again.'**
  String get errorPhoneLinkFailed;

  /// No description provided for @errorRecoveryEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the email'**
  String get errorRecoveryEmailFailed;

  /// No description provided for @errorPromoCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check that code'**
  String get errorPromoCheckFailed;

  /// No description provided for @errorSignInToMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages'**
  String get errorSignInToMessage;

  /// No description provided for @errorMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is too long'**
  String get errorMessageTooLong;

  /// No description provided for @errorMessagingTooFast.
  ///
  /// In en, this message translates to:
  /// **'You are sending messages too quickly'**
  String get errorMessagingTooFast;

  /// No description provided for @errorMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Message failed to send'**
  String get errorMessageFailed;

  /// No description provided for @errorVerifyPhoneToOrder.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number to place this order.'**
  String get errorVerifyPhoneToOrder;

  /// No description provided for @errorCheckoutSetupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up checkout first'**
  String get errorCheckoutSetupIncomplete;

  /// No description provided for @errorDeliveryLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a delivery location first'**
  String get errorDeliveryLocationRequired;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and retry.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Your order didn\'t go through. Nothing was charged.'**
  String get errorOrderFailed;

  /// No description provided for @errorSoldOutDuringCheckout.
  ///
  /// In en, this message translates to:
  /// **'Something sold out while you were checking out. Check your cart.'**
  String get errorSoldOutDuringCheckout;

  /// No description provided for @errorSignInToComment.
  ///
  /// In en, this message translates to:
  /// **'Sign in to comment'**
  String get errorSignInToComment;

  /// No description provided for @errorGuestCannotComment.
  ///
  /// In en, this message translates to:
  /// **'Create an account to join the conversation'**
  String get errorGuestCannotComment;

  /// No description provided for @errorCommentTooLong.
  ///
  /// In en, this message translates to:
  /// **'That comment is too long'**
  String get errorCommentTooLong;

  /// No description provided for @errorCommentsBuyersOnly.
  ///
  /// In en, this message translates to:
  /// **'Comments on this Reel are limited to people who bought the item.'**
  String get errorCommentsBuyersOnly;

  /// No description provided for @errorCommentingTooFast.
  ///
  /// In en, this message translates to:
  /// **'You are commenting very quickly. Wait {seconds}s.'**
  String errorCommentingTooFast(int seconds);

  /// No description provided for @errorCommentNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You cannot comment on this Reel'**
  String get errorCommentNotAllowed;

  /// No description provided for @errorCommentDeleteOwnOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only delete your own comments'**
  String get errorCommentDeleteOwnOnly;

  /// No description provided for @errorCommentPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post your comment'**
  String get errorCommentPostFailed;

  /// No description provided for @errorDocumentNotPublished.
  ///
  /// In en, this message translates to:
  /// **'This document has not been published yet'**
  String get errorDocumentNotPublished;

  /// No description provided for @errorDocumentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the document'**
  String get errorDocumentLoadFailed;

  /// No description provided for @errorAcceptanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record your acceptance'**
  String get errorAcceptanceFailed;

  /// No description provided for @errorDataExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare your data'**
  String get errorDataExportFailed;

  /// No description provided for @errorProductsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load products'**
  String get errorProductsLoadFailed;

  /// No description provided for @errorSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Try again.'**
  String get errorSearchFailed;

  /// No description provided for @errorSignInToSaveProducts.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save products'**
  String get errorSignInToSaveProducts;

  /// No description provided for @errorSignInToReport.
  ///
  /// In en, this message translates to:
  /// **'Sign in to report'**
  String get errorSignInToReport;

  /// No description provided for @errorReportThrottled.
  ///
  /// In en, this message translates to:
  /// **'You have reported something very recently. Try again in {seconds}s.'**
  String errorReportThrottled(int seconds);

  /// No description provided for @errorReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the report'**
  String get errorReportFailed;

  /// No description provided for @errorChooseAnOutcome.
  ///
  /// In en, this message translates to:
  /// **'Choose an outcome'**
  String get errorChooseAnOutcome;

  /// No description provided for @errorNotAModerator.
  ///
  /// In en, this message translates to:
  /// **'You are not a moderator'**
  String get errorNotAModerator;

  /// No description provided for @errorReportAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Another moderator reviewed this first. Refresh the queue.'**
  String get errorReportAlreadyReviewed;

  /// No description provided for @errorDecisionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the decision'**
  String get errorDecisionFailed;

  /// No description provided for @errorNotYourOrder.
  ///
  /// In en, this message translates to:
  /// **'This is not your order'**
  String get errorNotYourOrder;

  /// No description provided for @errorOrderAlreadyShipped.
  ///
  /// In en, this message translates to:
  /// **'This order has already left for delivery and can no longer be cancelled. Message the seller to sort it out.'**
  String get errorOrderAlreadyShipped;

  /// No description provided for @errorCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the order'**
  String get errorCancelFailed;

  /// No description provided for @errorSignInToFollow.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow'**
  String get errorSignInToFollow;

  /// No description provided for @errorCannotFollowYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot follow yourself'**
  String get errorCannotFollowYourself;

  /// No description provided for @errorFollowThrottled.
  ///
  /// In en, this message translates to:
  /// **'One moment — try again in {seconds}s'**
  String errorFollowThrottled(int seconds);

  /// No description provided for @errorSignInToSell.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sell'**
  String get errorSignInToSell;

  /// No description provided for @errorGuestCannotSell.
  ///
  /// In en, this message translates to:
  /// **'Guests cannot list products'**
  String get errorGuestCannotSell;

  /// No description provided for @errorTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the item a name'**
  String get errorTitleRequired;

  /// No description provided for @errorPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a price above zero'**
  String get errorPriceRequired;

  /// No description provided for @errorPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo'**
  String get errorPhotoRequired;

  /// No description provided for @errorTooManyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} photos'**
  String errorTooManyPhotos(int max);

  /// No description provided for @errorPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'One of those photos is too large. Keep each under {megabytes}MB.'**
  String errorPhotoTooLarge(int megabytes);

  /// No description provided for @errorPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the listing'**
  String get errorPublishFailed;

  /// No description provided for @errorUploadNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to publish. Your video is saved — try again when you are back online.'**
  String get errorUploadNeedsConnection;

  /// No description provided for @errorVideoStillProcessing.
  ///
  /// In en, this message translates to:
  /// **'Your video uploaded but is taking a while to process. It will appear on your profile once it is ready.'**
  String get errorVideoStillProcessing;

  /// No description provided for @errorPublishThrottled.
  ///
  /// In en, this message translates to:
  /// **'You have posted a lot recently. Try again in a little while.'**
  String get errorPublishThrottled;

  /// No description provided for @errorPublishNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot publish right now.'**
  String get errorPublishNotAllowed;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again.'**
  String get errorUploadFailed;

  /// No description provided for @errorReelNotFound.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find that Reel'**
  String get errorReelNotFound;

  /// No description provided for @errorSignInToLikeReels.
  ///
  /// In en, this message translates to:
  /// **'Sign in to like Reels'**
  String get errorSignInToLikeReels;

  /// No description provided for @errorSignInToSaveReels.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save Reels'**
  String get errorSignInToSaveReels;

  /// No description provided for @errorSignInToReview.
  ///
  /// In en, this message translates to:
  /// **'Sign in to review'**
  String get errorSignInToReview;

  /// No description provided for @errorSignInToRate.
  ///
  /// In en, this message translates to:
  /// **'Sign in to rate'**
  String get errorSignInToRate;

  /// No description provided for @errorRatingOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Pick a rating from 1 to 5'**
  String get errorRatingOutOfRange;

  /// No description provided for @errorEditWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'The 48-hour window to edit this review has closed.'**
  String get errorEditWindowClosed;

  /// No description provided for @errorRateAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'You can rate this once the order has been delivered.'**
  String get errorRateAfterDelivery;

  /// No description provided for @errorItemNotInOrder.
  ///
  /// In en, this message translates to:
  /// **'That item was not part of this order.'**
  String get errorItemNotInOrder;

  /// No description provided for @errorRateBuyersOnly.
  ///
  /// In en, this message translates to:
  /// **'Only buyers who received this order can rate it.'**
  String get errorRateBuyersOnly;

  /// No description provided for @errorAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You have already rated this order.'**
  String get errorAlreadyRated;

  /// No description provided for @errorReviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your rating'**
  String get errorReviewSubmitFailed;

  /// No description provided for @errorInvalidStatusTransition.
  ///
  /// In en, this message translates to:
  /// **'That order cannot move to this status. Pull to refresh.'**
  String get errorInvalidStatusTransition;

  /// No description provided for @errorBuyerCancelledOrder.
  ///
  /// In en, this message translates to:
  /// **'The buyer cancelled this order while you were updating it.'**
  String get errorBuyerCancelledOrder;

  /// No description provided for @errorOrderMovedOn.
  ///
  /// In en, this message translates to:
  /// **'This order already moved on. Pull to refresh.'**
  String get errorOrderMovedOn;

  /// No description provided for @errorOrderUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the order'**
  String get errorOrderUpdateFailed;

  /// No description provided for @legalSellerAgreement.
  ///
  /// In en, this message translates to:
  /// **'Seller Agreement'**
  String get legalSellerAgreement;

  /// No description provided for @legalContentPolicy.
  ///
  /// In en, this message translates to:
  /// **'Community Content Policy'**
  String get legalContentPolicy;

  /// No description provided for @railNotConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'{method} is not connected yet. Cash on delivery works today.'**
  String railNotConnectedYet(String method);

  /// No description provided for @reviewEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get reviewEdited;

  /// No description provided for @starCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String starCount(int count);

  /// No description provided for @ratingOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5 stars'**
  String ratingOutOfFive(String rating);

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @thisSeller.
  ///
  /// In en, this message translates to:
  /// **'this seller'**
  String get thisSeller;

  /// No description provided for @untitledReel.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledReel;

  /// No description provided for @orderFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderFallbackTitle;

  /// No description provided for @andNMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ and 1 more} other{ and {count} more}}'**
  String andNMore(int count);

  /// No description provided for @sectionWithCount.
  ///
  /// In en, this message translates to:
  /// **'{title} ({count})'**
  String sectionWithCount(String title, int count);

  /// No description provided for @quantityTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {title}'**
  String quantityTimesTitle(int quantity, String title);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String timeMinutesShort(int minutes);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String timeHoursShort(int hours);

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String timeDaysShort(int days);

  /// No description provided for @timeWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w'**
  String timeWeeksShort(int weeks);

  /// No description provided for @productCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title}, {price}'**
  String productCardSemantic(String title, String price);

  /// No description provided for @statSemantic.
  ///
  /// In en, this message translates to:
  /// **'{value} {label}'**
  String statSemantic(String value, String label);

  /// No description provided for @updateSearchStoreManually.
  ///
  /// In en, this message translates to:
  /// **'Search for WAVE in your app store to update.'**
  String get updateSearchStoreManually;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'ckb', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'ckb':
      return AppL10nCkb();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
