// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'WAVE';

  @override
  String get navReels => 'Reels';

  @override
  String get navMarketplace => 'Market';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get publish => 'Publish';

  @override
  String get buyNow => 'Buy now';

  @override
  String get makeAnOffer => 'Make an offer';

  @override
  String get offersComingSoon =>
      'Offers are coming soon. Message the seller for now.';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get viewCart => 'View cart';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyBody =>
      'Find something in the market, or watch a Reel and buy straight from it.';

  @override
  String get browseTheMarket => 'Browse the market';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get inStock => 'In stock';

  @override
  String get remove => 'Remove';

  @override
  String get total => 'Total';

  @override
  String get totalPaid => 'Total paid';

  @override
  String get orderSummary => 'Order summary';

  @override
  String get deliverTo => 'Deliver to';

  @override
  String get payWith => 'Pay with';

  @override
  String get change => 'Change';

  @override
  String get add => 'Add';

  @override
  String lowStockCount(int count) {
    return 'Only $count left';
  }

  @override
  String peopleBought(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people bought this',
      one: '1 person bought this',
      zero: 'Be the first to buy this',
    );
    return '$_temp0';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get continueAsGuest => 'Browse without an account';

  @override
  String get guestExplainer =>
      'You can look around freely. An account is needed to buy, post or message.';

  @override
  String get agreeToTerms => 'I agree to the ';

  @override
  String get andConnector => ' and ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get ageConfirmation => 'I am 13 or older';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get sendCode => 'Send code';

  @override
  String get sendNewCode => 'Send a new code';

  @override
  String get verifyAndContinue => 'Verify and continue';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get oneQuickStep => 'One quick step';

  @override
  String get phoneGateTitle => 'We need a phone number before your first order';

  @override
  String get phoneGateBody =>
      'It is how the courier reaches you, and it keeps fraudulent orders off your account. We only ask once — after this, buying takes one tap.';

  @override
  String get orderConfirmed => 'Confirmed';

  @override
  String get orderOnTheWay => 'On the way';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get yourOrders => 'Your orders';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get noOrdersBody =>
      'What you buy shows up here, with where it has got to.';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get keepIt => 'Keep it';

  @override
  String get receipt => 'Receipt';

  @override
  String get rateThisOrder => 'Rate this order';

  @override
  String get stageConfirmedBody =>
      'The seller has your order and is getting it ready. You can still cancel until it leaves.';

  @override
  String get stageOnTheWayBody =>
      'On its way to you. The courier will call the number on your account.';

  @override
  String get stageDeliveredBody => 'Delivered. Enjoy it.';

  @override
  String get trustBronze => 'Bronze Trusted';

  @override
  String get trustSilver => 'Silver Trusted';

  @override
  String get trustGold => 'Gold Trusted';

  @override
  String get trustPlatinum => 'Top Rated';

  @override
  String get trustVerifiedSeller => 'Verified seller';

  @override
  String get trustNewSeller => 'New seller';

  @override
  String get noTrackRecordBody =>
      'This seller has no completed orders yet, so there are no ratings to go on. Cash on delivery is the safest way to buy from someone new.';

  @override
  String get comments => 'Comments';

  @override
  String commentsCount(int count) {
    return '$count comments';
  }

  @override
  String get addAComment => 'Add a comment';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get noCommentsBody =>
      'Ask about size, condition or delivery — the seller can answer here.';

  @override
  String get seller => 'Seller';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get message => 'Message';

  @override
  String get report => 'Report';

  @override
  String get reportSent => 'Report sent';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get like => 'Like';

  @override
  String get reviews => 'Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get verifiedPurchase => 'Verified purchase';

  @override
  String get reviewVerifiedOnly =>
      'Only buyers who received this item can review it, so reviews here always come from a real order.';

  @override
  String get editWindowNote =>
      'You can edit this for 48 hours, then it is locked.';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get ratingBad => 'Bad';

  @override
  String get ratingNotGreat => 'Not great';

  @override
  String get ratingFine => 'Fine';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingExcellent => 'Excellent';

  @override
  String get tapAStar => 'Tap a star';

  @override
  String get newReel => 'New Reel';

  @override
  String get chooseAVideo => 'Choose a video';

  @override
  String get caption => 'Caption';

  @override
  String get linkAProduct => 'Link a product';

  @override
  String get linkAProductBody => 'Adds a Buy Now button to this Reel';

  @override
  String get listAProduct => 'List a product';

  @override
  String get whatIsIt => 'What is it?';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

  @override
  String get howMany => 'How many';

  @override
  String get cover => 'Cover';

  @override
  String get listingIsLive => 'Your listing is live';

  @override
  String get reelIsLive => 'Your Reel is live';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifOrders => 'Order updates';

  @override
  String get notifOrdersBody => 'Confirmed, on the way, delivered';

  @override
  String get notifChat => 'Messages';

  @override
  String get notifChatBody => 'When a buyer or seller replies';

  @override
  String get notifSocial => 'Likes, comments and follows';

  @override
  String get notifSocialBody => 'Activity on your Reels and profile';

  @override
  String get notifMarketing => 'Offers and announcements';

  @override
  String get notifMarketingBody => 'Occasional news about WAVE';

  @override
  String get nothingNew => 'Nothing new';

  @override
  String get retry => 'Try again';

  @override
  String get getStarted => 'Get started';

  @override
  String get errorNoConnectionBody => 'Check your connection and try again.';

  @override
  String get errorDeadLink => 'This link went nowhere';

  @override
  String get errorDeadLinkBody =>
      'The page you followed doesn\'t exist or has been removed.';

  @override
  String get searchProductsAndReels => 'Search products and Reels';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get updateRequiredTitle => 'Update WAVE to keep going';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. The update takes a moment, and your cart and orders are safe.';

  @override
  String get updateNow => 'Update now';

  @override
  String get acceptAndContinue => 'Accept and continue';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get browsingAsGuest => 'You are browsing as a guest';

  @override
  String get guestUpgradeBody =>
      'Create an account to buy, sell, save favourites and message sellers. Anything in your cart comes with you.';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get favourites => 'Favourites';

  @override
  String get savedReels => 'Saved Reels';

  @override
  String get ordersToFulfil => 'Orders to fulfil';

  @override
  String get howYouAreDoing => 'How you are doing';

  @override
  String get termsAndPolicies => 'Terms and policies';

  @override
  String get downloadYourData => 'Download your data';

  @override
  String get preparingYourData =>
      'Preparing your data — this may take a moment';

  @override
  String get deleteYourAccount => 'Delete your account';

  @override
  String get deleteYourAccountQ => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Deleted for good: your profile, Reels, listings, saved items, addresses and payment methods.\n\nKept without your name: completed orders, and the ratings and reviews you left. Sellers need their transaction records, and removing your ratings would quietly change their score for the next buyer.\n\nIf something is already on its way to you, its delivery details stay until it arrives — the courier is holding your parcel. They are erased within a day of delivery.\n\nThis cannot be undone.';

  @override
  String get keepMyAccount => 'Keep my account';

  @override
  String get delete => 'Delete';

  @override
  String get items => 'Items';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String orderedOn(String date) {
    return 'Ordered $date';
  }

  @override
  String get orderNotFound => 'We can\'t find that order';

  @override
  String get orderNotFoundBody =>
      'It may have been removed, or the link may be wrong.';

  @override
  String get cancelThisOrder => 'Cancel this order';

  @override
  String get cancelThisOrderQ => 'Cancel this order?';

  @override
  String get cancelOrderBuyerBody =>
      'The seller is told straight away and anything paid is refunded. You cannot undo this.';

  @override
  String get howDidItGo => 'How did it go?';

  @override
  String get ratingHelpsNextBuyer =>
      'Your rating is what gives this seller their badge — and what tells the next buyer whether to trust them.';

  @override
  String get ratingSubmitted => 'Thanks — your rating is in';

  @override
  String get descriptionHint =>
      'Size, condition, materials — whatever a buyer would ask before deciding';

  @override
  String coverPhotoNote(int max) {
    return 'The first photo is what buyers see in the grid. Up to $max.';
  }

  @override
  String buyersWillSee(String price) {
    return 'Buyers will see $price';
  }

  @override
  String get uploadingPhotos => 'Uploading photos…';

  @override
  String get makeAReel => 'Make a Reel';

  @override
  String get aboutThisItem => 'About this item';

  @override
  String get shareThisItem => 'Share this item';

  @override
  String get reportThisListing => 'Report this listing';

  @override
  String get productNotFound => 'We can\'t find that item';

  @override
  String get productNotFoundBody =>
      'It may have sold out or been removed by the seller.';

  @override
  String get backToTheMarket => 'Back to the market';

  @override
  String get otherActions => 'Other actions';

  @override
  String get buyerCanStillCancel =>
      'The buyer can still cancel until you hand this to a courier.';

  @override
  String get cancelOrderSellerBody =>
      'The buyer is refunded and told straight away. Cancelling orders you have already accepted affects your trust tier, so only do this if you genuinely cannot fulfil it.';

  @override
  String get nothingWaitingOnYou => 'Nothing waiting on you';

  @override
  String get nothingWaitingBody =>
      'New orders show up here the moment someone buys.';

  @override
  String get nothingInTransit => 'Nothing in transit';

  @override
  String get nothingInTransitBody =>
      'Orders you have handed to a courier appear here.';

  @override
  String get noCompletedOrders => 'No completed orders yet';

  @override
  String get noCompletedOrdersBody =>
      'Delivered and cancelled orders are kept here.';

  @override
  String get filterToDo => 'To do';

  @override
  String get filterOnTheWay => 'On the way';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get soldOut => 'Sold out';

  @override
  String get deliveryArrangedNote =>
      'Delivery is arranged with the seller after you order.';

  @override
  String get cartMultiSellerWarning =>
      'Your cart has items from more than one seller. Order them separately for now.';

  @override
  String get cartStockWarning =>
      'Some items sold out or dropped below the quantity you chose. Adjust them to continue.';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get noAddressYet => 'No address yet';

  @override
  String get savedAddress => 'Saved address';

  @override
  String get savedPaymentMethod => 'Saved payment method';

  @override
  String get codAvailableNote => 'Cash on delivery is available in your area';

  @override
  String placeOrderWithTotal(String total) {
    return 'Place order · $total';
  }

  @override
  String get signInToOrder => 'Sign in to place this order';

  @override
  String get signInToOrderBody =>
      'Guests can browse and fill a cart, but an order needs an account.';

  @override
  String get verifyYourPhone => 'Verify your phone number';

  @override
  String get verifyNow => 'Verify now';

  @override
  String get addDeliveryAddress => 'Add a delivery address';

  @override
  String get addAddressBody => 'The seller needs somewhere to send this.';

  @override
  String get addAddress => 'Add address';

  @override
  String get chooseHowToPay => 'Choose how to pay';

  @override
  String get chooseHowToPayBody =>
      'Cash on delivery is available in most areas.';

  @override
  String get choose => 'Choose';

  @override
  String get newAddress => 'New address';

  @override
  String get addANewAddress => 'Add a new address';

  @override
  String get whoIsReceiving => 'Who is receiving it';

  @override
  String get phoneForCourier => 'Phone for the courier';

  @override
  String get city => 'City';

  @override
  String get addressLine => 'Neighbourhood, street, building';

  @override
  String get landmarkOptional => 'Nearest landmark (optional)';

  @override
  String get landmarkHint => 'Opposite the blue mosque, above the pharmacy…';

  @override
  String get landmarkNote =>
      'Couriers here usually find an address by landmark and a phone call, so this helps more than it looks like it should.';

  @override
  String get saveAddress => 'Save address';

  @override
  String get chooseADifferentVideo => 'Choose a different video';

  @override
  String upToNSeconds(int seconds) {
    return 'Up to $seconds seconds';
  }

  @override
  String durationOfMax(int actual, Object max) {
    return '${actual}s of ${max}s';
  }

  @override
  String videoTooLong(int actual, Object max) {
    return 'That video is ${actual}s. Trim it to $max seconds or less and pick it again.';
  }

  @override
  String get captionHint => 'Say what it is, and why someone would want it';

  @override
  String get removeTheLink => 'Remove the link';

  @override
  String get linkedProductNote =>
      'Buyers can purchase this straight from the Reel';

  @override
  String get statsNotLoaded => 'Your numbers didn\'t load';

  @override
  String lastNDays(int days) {
    return 'Last $days days';
  }

  @override
  String get earned => 'earned';

  @override
  String get orders => 'orders';

  @override
  String get rating => 'rating';

  @override
  String get wherePeopleDropOff => 'Where people drop off';

  @override
  String get funnelExplainer =>
      'Each step shows how many carried on to the next.';

  @override
  String get funnelLowSample =>
      'These percentages are unreliable below about 100 views — treat them as a hint, not a verdict.';

  @override
  String get funnelWatched => 'Watched a Reel';

  @override
  String get funnelTapped => 'Tapped Buy Now';

  @override
  String get funnelCompleted => 'Completed the order';

  @override
  String get lowTapThroughNote =>
      'Few watchers tap Buy Now. The Reel may not be showing the product clearly, or the price may not be visible early enough.';

  @override
  String get lowCompletionNote =>
      'Most people who tap Buy Now do not finish. That is usually price, stock running out, or a first-time buyer meeting the phone verification step.';

  @override
  String get yourReels => 'Your Reels';

  @override
  String get nothingPublishedYet => 'Nothing published yet.';

  @override
  String get ordersWaitingOne => '1 order is waiting on you';

  @override
  String ordersWaitingMany(int count) {
    return '$count orders are waiting on you';
  }

  @override
  String get open => 'Open';

  @override
  String viewsAndSold(int views, Object sold) {
    return '$views views · $sold sold';
  }

  @override
  String wastedAudienceNote(int views) {
    return '$views people watched this and had nothing to buy. Link a product to it.';
  }

  @override
  String get reportThis => 'Report this';

  @override
  String get whatIsWrongWithIt => 'What is wrong with it?';

  @override
  String get alsoBlockAccount => 'Also block this account';

  @override
  String get blockExplainer => 'You will stop seeing their posts and messages';

  @override
  String get sendReport => 'Send report';

  @override
  String get reportSentBody =>
      'A moderator will look at this. We do not share what happens next, and the person reported is not told who reported them.';

  @override
  String get reasonSpam => 'Spam or scam';

  @override
  String get reasonCounterfeit => 'Counterfeit or misrepresented item';

  @override
  String get reasonProhibited => 'Prohibited item';

  @override
  String get reasonHarassment => 'Harassment or hate';

  @override
  String get reasonSexual => 'Sexual content';

  @override
  String get reasonViolence => 'Violence or dangerous acts';

  @override
  String get reasonIntellectualProperty => 'Copyright or trademark';

  @override
  String get reasonOther => 'Something else';

  @override
  String get sellerNotFound => 'We can\'t find that seller';

  @override
  String get sellerNotFoundBody => 'The account may have been removed.';

  @override
  String get reportOrBlock => 'Report or block';

  @override
  String sellingSince(String date) {
    return 'Selling since $date';
  }

  @override
  String get nothingListedRightNow => 'Nothing listed right now.';

  @override
  String get listings => 'Listings';

  @override
  String listingsCount(int count) {
    return '$count listings';
  }

  @override
  String get followers => 'followers';

  @override
  String ratingsCount(int count) {
    return '$count ratings';
  }

  @override
  String get delivered => 'delivered';

  @override
  String get goToReels => 'Go to Reels';

  @override
  String get reelsNotLoaded => 'Reels didn\'t load';

  @override
  String get noReelsYet => 'No Reels yet';

  @override
  String get noReelsBody => 'Be the first to post one.';

  @override
  String get nothingSavedYet => 'Nothing saved yet';

  @override
  String get savedReelsBody => 'Tap the bookmark on a Reel to keep it here.';

  @override
  String get watchSomeReels => 'Watch some Reels';

  @override
  String get favouritesBody =>
      'Tap the heart on anything you want to come back to.';

  @override
  String get appTagline => 'Watch, and buy what you see.';

  @override
  String get searchProducts => 'Search products';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get marketEmpty => 'The market is empty';

  @override
  String get marketEmptyBody =>
      'Nothing is listed yet. Be the first to sell something.';

  @override
  String get productsNotLoaded => 'Products didn\'t load';

  @override
  String nothingMatched(String query) {
    return 'Nothing matched \"$query\"';
  }

  @override
  String get searchPrefixNoteProducts =>
      'Search matches the start of a product name. Try a shorter or different word.';

  @override
  String get searchPrefixNoteAll =>
      'Search matches the start of a name or caption, so try the first word rather than a word from the middle.';

  @override
  String get searchHintEmpty =>
      'Search across everything for sale and every Reel.';

  @override
  String get searchHintShort => 'Keep typing — searches start at two letters.';

  @override
  String get products => 'Products';

  @override
  String get reels => 'Reels';

  @override
  String get shop => 'Shop';

  @override
  String get ordersNotLoaded => 'Your orders didn\'t load';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String receiptDocTitle(String id) {
    return 'WAVE receipt $id';
  }

  @override
  String get receiptSoldBy => 'Sold by';

  @override
  String get receiptBuyer => 'Buyer';

  @override
  String get receiptDeliveredTo => 'Delivered to';

  @override
  String get receiptStatus => 'Status';

  @override
  String get receiptItem => 'Item';

  @override
  String get receiptQty => 'Qty';

  @override
  String get receiptUnit => 'Unit';

  @override
  String get receiptDisclaimer =>
      'This is a record of a purchase made through WAVE. WAVE is a marketplace; the sale is between the buyer and the seller named above. It is not a tax invoice unless the seller has issued one separately.';

  @override
  String get yourWaveData => 'Your WAVE data';

  @override
  String get sellFromThisReel => 'Sell from this Reel';

  @override
  String get sellFromThisReelBody =>
      'Pick one of your listings. Buyers get a Buy Now button without leaving the video.';

  @override
  String get nothingListedYet => 'You have nothing listed yet.';

  @override
  String get listAProductFirst => 'List a product first';

  @override
  String get uploadAReel => 'Upload a Reel';

  @override
  String get uploadAReelBody =>
      'Up to 60 seconds. Link a product to sell from it.';

  @override
  String get listAProductBody => 'Add photos, price and stock.';

  @override
  String versionUpdated(String version, Object date) {
    return 'Version $version · updated $date';
  }

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get documentNotLoaded => 'That document didn\'t load';

  @override
  String get beforeYouStart => 'Before you start';

  @override
  String get termsChanged => 'Our terms have changed';

  @override
  String documentChanged(String title) {
    return '$title has changed';
  }

  @override
  String get acceptToUse => 'Please read and accept these to use WAVE.';

  @override
  String get readWhatChanged => 'Please read what changed before continuing.';

  @override
  String get addANote => 'Add a note (optional)';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesBody =>
      'When you message a seller about an item, the conversation shows up here.';

  @override
  String get aboutAListing => 'About a listing';

  @override
  String get view => 'View';

  @override
  String get chatEmptyPrompt =>
      'Ask about size, condition, delivery — whatever you need to know before you buy.';

  @override
  String get send => 'Send';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationsNotLoaded => 'Notifications didn\'t load';

  @override
  String get nothingNewBody =>
      'Order updates, replies and activity on your posts show up here.';

  @override
  String get notifOrdersOffWarning =>
      'Turning off order updates means we will not tell you when something you bought is on its way.';

  @override
  String get howDoYouWantToPay => 'How do you want to pay?';

  @override
  String addPaymentMethod(String method) {
    return 'Add $method';
  }

  @override
  String get cardDetailsNote =>
      'Card details are held by the payment provider, never by WAVE.';

  @override
  String get railCashOnDelivery => 'Cash on delivery';

  @override
  String get railCashOnDeliveryBody => 'Pay the courier when it arrives';

  @override
  String get railMobileWallet => 'Mobile wallet';

  @override
  String get railCard => 'Card';

  @override
  String get railBankCard => 'Bank card';

  @override
  String get railBankCardBody => 'Visa or Mastercard';

  @override
  String get lowStockShort => 'Only a few left';

  @override
  String get phoneGateShortNote =>
      'We ask once. Your number is used for delivery updates and to protect your account — after this, buying is one tap.';

  @override
  String get promoApplied =>
      'Code applied. The discount is confirmed at checkout.';

  @override
  String get stockLimitReached => 'That is all the stock available';

  @override
  String get postComment => 'Post comment';

  @override
  String get onboardingTitle1 => 'Watch. Tap. Own it.';

  @override
  String get onboardingBody1 =>
      'Every Reel can be a shop. If you like what you see, buy it without leaving the video.';

  @override
  String get onboardingTitle2 => 'Know who you are buying from';

  @override
  String get onboardingBody2 =>
      'Sellers earn their badge from real, delivered orders — not from what they say about themselves.';

  @override
  String get onboardingTitle3 => 'Sell what you make';

  @override
  String get onboardingBody3 =>
      'Post a Reel, link a product, get paid. When something sells we will let you know straight away — you can turn that off any time.';

  @override
  String get startBrowsing => 'Start browsing';

  @override
  String stepOfTotal(int current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String orderStatusSemantic(String status, Object step) {
    return 'Order status: $status, step $step of 3';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQ => 'Sign out?';

  @override
  String get signOutBody =>
      'You will stop getting notifications on this device, and nobody using it after you will see your orders.';

  @override
  String get promoCode => 'Promo code';

  @override
  String get promoCodeHint => 'Have a code?';

  @override
  String get apply => 'Apply';

  @override
  String get discount => 'Discount';

  @override
  String get promoInvalid => 'That code is not valid';

  @override
  String get promoExpired => 'That code has expired';

  @override
  String get promoUsed => 'You have already used that code';

  @override
  String get mediaAccessRationale =>
      'WAVE needs access to your videos so you can pick one to post. We only see the video you choose.';

  @override
  String get stageCancelledBody =>
      'This order was cancelled. Any payment taken is refunded to the original method.';

  @override
  String get shareThisReel => 'Share this Reel';

  @override
  String get reportThisReel => 'Report this Reel';

  @override
  String get accountSuspended => 'Your account is suspended';

  @override
  String get accountSuspendedBody =>
      'You can still see your orders and read our Content Policy, but you cannot post, sell, comment or message while the suspension is in place.';

  @override
  String get readContentPolicy => 'Read the Content Policy';

  @override
  String get recoverAccount => 'Recover your account';

  @override
  String get recoverByPhone => 'Using your phone number';

  @override
  String get recoverByPhoneBody =>
      'We will send a code to the number on the account. Entering it signs you back in.';

  @override
  String get recoverByEmail => 'Using your email';

  @override
  String get recoverByEmailBody =>
      'If you signed up with Google or Apple and no longer have that phone, use the email on the account instead.';

  @override
  String get emailAddress => 'Email address';

  @override
  String get sendRecoveryEmail => 'Send a recovery email';

  @override
  String get recoveryEmailSent =>
      'If that address has an account, a recovery email is on its way.';

  @override
  String get forgotAccess => 'Lost access to your account?';

  @override
  String get offlineBannerBody =>
      'You are offline. What you do now is saved and will sync when you\'re back.';

  @override
  String get stagePendingPaymentBody =>
      'Waiting for your payment to go through. The seller sees this order once it does — usually within a minute.';

  @override
  String get stagePaymentFailedBody =>
      'Your payment did not go through, so the seller has not been sent this order. Nothing has been charged.';

  @override
  String get paymentPending => 'Waiting for payment';

  @override
  String get promoBelowMinimum => 'That code needs a larger order';

  @override
  String get promoTooManyAttempts => 'Too many code attempts. Try again later.';

  @override
  String buyNowWithPrice(String price) {
    return 'Buy now · $price';
  }

  @override
  String get setDeliveryLocation => 'Set delivery location';

  @override
  String get dragMapToSetPin => 'Move the map to put the pin on your door.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String confirmAndBuy(String price) {
    return 'Confirm and buy · $price';
  }

  @override
  String get deliveryNote => 'Landmark or directions';

  @override
  String get deliveryNoteHint =>
      'Blue gate, second floor, opposite the pharmacy…';

  @override
  String get deliveryNoteWhy =>
      'Couriers here usually find a door by landmark and a phone call, so this helps more than the pin does.';

  @override
  String get locationPermissionDenied =>
      'Location is off, so place the pin by hand.';

  @override
  String get locationUnavailable =>
      'Couldn\'t find you. Place the pin by hand.';

  @override
  String get locationTooVague =>
      'That fix is very rough. Move the pin to your door so the courier is not guessing.';

  @override
  String get deliveryLocation => 'Delivery location';

  @override
  String get openInMaps => 'Open in maps';

  @override
  String get noLocationSet => 'No map pin on this order';

  @override
  String get approximateFix => 'Approximate — phone before setting off';

  @override
  String setDeliveryLocationWithPrice(String price) {
    return 'Set delivery location · $price';
  }

  @override
  String get statusPendingPayment => 'Waiting for payment';

  @override
  String get statusPaymentProcessing => 'Payment processing';

  @override
  String get statusPaymentFailed => 'Payment failed';

  @override
  String get statusNeedsPacking => 'New — needs packing';

  @override
  String get statusPacked => 'Packed';

  @override
  String get statusWithCourier => 'With the courier';

  @override
  String get statusOutForDelivery => 'Out for delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPriceLowToHigh => 'Price: low to high';

  @override
  String get sortPriceHighToLow => 'Price: high to low';

  @override
  String get sortTopRated => 'Top rated';

  @override
  String get uploadValidating => 'Checking your video';

  @override
  String get uploadCompressing => 'Making it smaller';

  @override
  String get uploadPreparing => 'Getting ready';

  @override
  String get uploadUploading => 'Uploading';

  @override
  String get uploadProcessing => 'Processing — you can leave this screen';

  @override
  String get uploadPublishing => 'Publishing';

  @override
  String get uploadDone => 'Published';

  @override
  String ratePromptProduct(String name) {
    return 'How is $name?';
  }

  @override
  String ratePromptSeller(String name) {
    return 'How was $name to buy from?';
  }

  @override
  String get actionMarkPacked => 'Mark as packed';

  @override
  String get actionHandedToCourier => 'Handed to courier';

  @override
  String get actionOutForDelivery => 'Out for delivery';

  @override
  String get actionMarkDelivered => 'Mark as delivered';

  @override
  String get actionCancelOrder => 'Cancel order';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorNotSignedIn => 'Sign in to continue';

  @override
  String get errorSignInCancelled => 'Sign-in cancelled';

  @override
  String get errorSignInFailed => 'Could not sign you in. Try again.';

  @override
  String get errorGuestSessionFailed => 'Could not start a guest session';

  @override
  String get errorCodeSendFailed => 'Could not send the code. Try again.';

  @override
  String errorCodeSendThrottled(int minutes) {
    return 'Too many codes requested. Try again in $minutes min.';
  }

  @override
  String get errorCodeIncorrect => 'That code is not right. Check and retry.';

  @override
  String get errorCodeExpired => 'That code expired. Request a new one.';

  @override
  String get errorRequestCodeFirst => 'Request a code first';

  @override
  String get errorVerificationFailed =>
      'Could not verify your number. Try again.';

  @override
  String get errorPhoneOnAnotherAccount =>
      'This number is already on another account.';

  @override
  String get errorPhoneLinkFailed =>
      'That number did not attach to your account. Try again.';

  @override
  String get errorRecoveryEmailFailed => 'Could not send the email';

  @override
  String get errorPromoCheckFailed => 'Could not check that code';

  @override
  String get errorSignInToMessage => 'Sign in to send messages';

  @override
  String get errorMessageTooLong => 'Message is too long';

  @override
  String get errorMessagingTooFast => 'You are sending messages too quickly';

  @override
  String get errorMessageFailed => 'Message failed to send';

  @override
  String get errorVerifyPhoneToOrder =>
      'Verify your phone number to place this order.';

  @override
  String get errorCheckoutSetupIncomplete => 'Finish setting up checkout first';

  @override
  String get errorDeliveryLocationRequired => 'Set a delivery location first';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Wait a moment and retry.';

  @override
  String get errorOrderFailed =>
      'Your order didn\'t go through. Nothing was charged.';

  @override
  String get errorSoldOutDuringCheckout =>
      'Something sold out while you were checking out. Check your cart.';

  @override
  String get errorSignInToComment => 'Sign in to comment';

  @override
  String get errorGuestCannotComment =>
      'Create an account to join the conversation';

  @override
  String get errorCommentTooLong => 'That comment is too long';

  @override
  String get errorCommentsBuyersOnly =>
      'Comments on this Reel are limited to people who bought the item.';

  @override
  String errorCommentingTooFast(int seconds) {
    return 'You are commenting very quickly. Wait ${seconds}s.';
  }

  @override
  String get errorCommentNotAllowed => 'You cannot comment on this Reel';

  @override
  String get errorCommentDeleteOwnOnly =>
      'You can only delete your own comments';

  @override
  String get errorCommentPostFailed => 'Could not post your comment';

  @override
  String get errorDocumentNotPublished =>
      'This document has not been published yet';

  @override
  String get errorDocumentLoadFailed => 'Could not load the document';

  @override
  String get errorAcceptanceFailed => 'Could not record your acceptance';

  @override
  String get errorDataExportFailed => 'Could not prepare your data';

  @override
  String get errorProductsLoadFailed => 'Could not load products';

  @override
  String get errorSearchFailed => 'Search failed. Try again.';

  @override
  String get errorSignInToSaveProducts => 'Sign in to save products';

  @override
  String get errorSignInToReport => 'Sign in to report';

  @override
  String errorReportThrottled(int seconds) {
    return 'You have reported something very recently. Try again in ${seconds}s.';
  }

  @override
  String get errorReportFailed => 'Could not send the report';

  @override
  String get errorChooseAnOutcome => 'Choose an outcome';

  @override
  String get errorNotAModerator => 'You are not a moderator';

  @override
  String get errorReportAlreadyReviewed =>
      'Another moderator reviewed this first. Refresh the queue.';

  @override
  String get errorDecisionFailed => 'Could not record the decision';

  @override
  String get errorNotYourOrder => 'This is not your order';

  @override
  String get errorOrderAlreadyShipped =>
      'This order has already left for delivery and can no longer be cancelled. Message the seller to sort it out.';

  @override
  String get errorCancelFailed => 'Could not cancel the order';

  @override
  String get errorSignInToFollow => 'Sign in to follow';

  @override
  String get errorCannotFollowYourself => 'You cannot follow yourself';

  @override
  String errorFollowThrottled(int seconds) {
    return 'One moment — try again in ${seconds}s';
  }

  @override
  String get errorSignInToSell => 'Sign in to sell';

  @override
  String get errorGuestCannotSell => 'Guests cannot list products';

  @override
  String get errorTitleRequired => 'Give the item a name';

  @override
  String get errorPriceRequired => 'Set a price above zero';

  @override
  String get errorPhotoRequired => 'Add at least one photo';

  @override
  String errorTooManyPhotos(int max) {
    return 'Up to $max photos';
  }

  @override
  String errorPhotoTooLarge(int megabytes) {
    return 'One of those photos is too large. Keep each under ${megabytes}MB.';
  }

  @override
  String get errorPublishFailed => 'Could not publish the listing';

  @override
  String get errorUploadNeedsConnection =>
      'You need a connection to publish. Your video is saved — try again when you are back online.';

  @override
  String get errorVideoStillProcessing =>
      'Your video uploaded but is taking a while to process. It will appear on your profile once it is ready.';

  @override
  String get errorPublishThrottled =>
      'You have posted a lot recently. Try again in a little while.';

  @override
  String get errorPublishNotAllowed => 'Your account cannot publish right now.';

  @override
  String get errorUploadFailed => 'Upload failed. Try again.';

  @override
  String get errorReelNotFound => 'We can\'t find that Reel';

  @override
  String get errorSignInToLikeReels => 'Sign in to like Reels';

  @override
  String get errorSignInToSaveReels => 'Sign in to save Reels';

  @override
  String get errorSignInToReview => 'Sign in to review';

  @override
  String get errorSignInToRate => 'Sign in to rate';

  @override
  String get errorRatingOutOfRange => 'Pick a rating from 1 to 5';

  @override
  String get errorEditWindowClosed =>
      'The 48-hour window to edit this review has closed.';

  @override
  String get errorRateAfterDelivery =>
      'You can rate this once the order has been delivered.';

  @override
  String get errorItemNotInOrder => 'That item was not part of this order.';

  @override
  String get errorRateBuyersOnly =>
      'Only buyers who received this order can rate it.';

  @override
  String get errorAlreadyRated => 'You have already rated this order.';

  @override
  String get errorReviewSubmitFailed => 'Could not submit your rating';

  @override
  String get errorInvalidStatusTransition =>
      'That order cannot move to this status. Pull to refresh.';

  @override
  String get errorBuyerCancelledOrder =>
      'The buyer cancelled this order while you were updating it.';

  @override
  String get errorOrderMovedOn =>
      'This order already moved on. Pull to refresh.';

  @override
  String get errorOrderUpdateFailed => 'Could not update the order';

  @override
  String get legalSellerAgreement => 'Seller Agreement';

  @override
  String get legalContentPolicy => 'Community Content Policy';

  @override
  String railNotConnectedYet(String method) {
    return '$method is not connected yet. Cash on delivery works today.';
  }

  @override
  String get reviewEdited => 'edited';

  @override
  String starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String ratingOutOfFive(String rating) {
    return '$rating out of 5 stars';
  }

  @override
  String get unlike => 'Unlike';

  @override
  String get you => 'You';

  @override
  String get someone => 'Someone';

  @override
  String get thisSeller => 'this seller';

  @override
  String get untitledReel => 'Untitled';

  @override
  String get orderFallbackTitle => 'Order';

  @override
  String andNMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' and $count more',
      one: ' and 1 more',
    );
    return '$_temp0';
  }

  @override
  String sectionWithCount(String title, int count) {
    return '$title ($count)';
  }

  @override
  String quantityTimesTitle(int quantity, String title) {
    return '$quantity × $title';
  }

  @override
  String get timeJustNow => 'now';

  @override
  String timeMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String timeHoursShort(int hours) {
    return '${hours}h';
  }

  @override
  String timeDaysShort(int days) {
    return '${days}d';
  }

  @override
  String timeWeeksShort(int weeks) {
    return '${weeks}w';
  }

  @override
  String productCardSemantic(String title, String price) {
    return '$title, $price';
  }

  @override
  String statSemantic(String value, String label) {
    return '$value $label';
  }

  @override
  String get updateSearchStoreManually =>
      'Search for WAVE in your app store to update.';

  @override
  String get systemDefault => 'System default';

  @override
  String get quantityDecrease => 'Decrease quantity';

  @override
  String get quantityIncrease => 'Increase quantity';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get pdpAddToCart => 'Add to cart';

  @override
  String get stockIn => 'In stock';

  @override
  String get stockOut => 'Out of stock';

  @override
  String stockLow(int count) {
    return 'Only $count left';
  }

  @override
  String get quantityTitle => 'Select quantity';

  @override
  String get pdpDescription => 'About this item';

  @override
  String get commonBack => 'Back';

  @override
  String get pdpSoldBy => 'Sold by';

  @override
  String pdpImageGallery(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String get cartAddedToCart => 'Added to cart';

  @override
  String get cartStockLimitReached => 'Stock limit reached';

  @override
  String get cartOutOfStock => 'Out of stock';

  @override
  String get cartPromoApplied => 'Promo applied';

  @override
  String get cartPromoInvalid => 'Invalid promo code';

  @override
  String get cartPromoExpired => 'Promo code expired';

  @override
  String get cartPromoUsed => 'Promo code already used';

  @override
  String get cartPromoBelowMinimum => 'Order below minimum for promo';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get acceptTerms => 'I accept the terms and conditions';

  @override
  String get confirmAge => 'I am 18 or older';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get enterCodeSentToPhone => 'Enter the code sent to your phone';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verify => 'Verify';

  @override
  String get changePhoneNumber => 'Change phone number';
}
