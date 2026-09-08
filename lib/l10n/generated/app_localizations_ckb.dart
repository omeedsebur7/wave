// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appName => 'WAVE';

  @override
  String get navReels => 'ڕیلز';

  @override
  String get navMarketplace => 'بازاڕ';

  @override
  String get navChat => 'چات';

  @override
  String get navProfile => 'پڕۆفایل';

  @override
  String get publish => 'بڵاوکردنەوە';

  @override
  String get buyNow => 'ئێستا بیکڕە';

  @override
  String get makeAnOffer => 'نرخێک پێشنیار بکە';

  @override
  String get offersComingSoon =>
      'پێشنیاری نرخ بەم زووانە دێت. لە ئێستادا نامە بۆ فرۆشیار بنێرە.';

  @override
  String get addToCart => 'بیخە سەبەتەوە';

  @override
  String get addedToCart => 'خرایە سەبەتەوە';

  @override
  String get viewCart => 'سەبەتە ببینە';

  @override
  String get cart => 'سەبەتە';

  @override
  String get checkout => 'تەواوکردنی کڕین';

  @override
  String get cartEmpty => 'سەبەتەکەت بەتاڵە';

  @override
  String get cartEmptyBody =>
      'شتێک لە بازاڕدا بدۆزەرەوە، یان ڕیلێک ببینە و ڕاستەوخۆ لێی بکڕە.';

  @override
  String get browseTheMarket => 'بازاڕەکە بگەڕێ';

  @override
  String get outOfStock => 'نەماوە';

  @override
  String get inStock => 'بەردەستە';

  @override
  String get remove => 'لابردن';

  @override
  String get total => 'کۆی گشتی';

  @override
  String get totalPaid => 'کۆی دراوە';

  @override
  String get orderSummary => 'کورتەی داواکاری';

  @override
  String get deliverTo => 'بگەیەنە بۆ';

  @override
  String get payWith => 'پارەدان بە';

  @override
  String get change => 'گۆڕین';

  @override
  String get add => 'زیادکردن';

  @override
  String lowStockCount(int count) {
    return 'تەنها $count ماوە';
  }

  @override
  String peopleBought(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کەس ئەمەیان کڕیوە',
      one: '١ کەس ئەمەی کڕیوە',
      zero: 'یەکەم کەس بە کە ئەمە دەکڕێت',
    );
    return '$_temp0';
  }

  @override
  String get signIn => 'چوونەژوورەوە';

  @override
  String get continueWithGoogle => 'بەردەوامبە بە Google';

  @override
  String get continueWithApple => 'بەردەوامبە بە Apple';

  @override
  String get continueWithPhone => 'بەردەوامبە بە مۆبایل';

  @override
  String get continueAsGuest => 'بەبێ هەژمار بگەڕێ';

  @override
  String get guestExplainer =>
      'دەتوانیت بە ئازادی بگەڕێیت. بۆ کڕین، بڵاوکردنەوە یان نامەنێردن هەژمارت پێویستە.';

  @override
  String get agreeToTerms => 'ڕازیم بە ';

  @override
  String get andConnector => ' و ';

  @override
  String get termsOfService => 'مەرجەکانی خزمەتگوزاری';

  @override
  String get privacyPolicy => 'سیاسەتی تایبەتێتی';

  @override
  String get ageConfirmation => 'تەمەنم ١٣ ساڵ یان زیاترە';

  @override
  String get phoneNumber => 'ژمارەی مۆبایل';

  @override
  String get sendCode => 'کۆد بنێرە';

  @override
  String get sendNewCode => 'کۆدێکی نوێ بنێرە';

  @override
  String get verifyAndContinue => 'پشتڕاست بکەرەوە و بەردەوامبە';

  @override
  String get sixDigitCode => 'کۆدی ٦ ژمارەیی';

  @override
  String get oneQuickStep => 'یەک هەنگاوی خێرا';

  @override
  String get phoneGateTitle =>
      'پێش یەکەم داواکاریت پێویستمان بە ژمارەی مۆبایلە';

  @override
  String get phoneGateBody =>
      'بەمە گەیەنەر پەیوەندیت پێوە دەکات، و داواکاری ساختە لە هەژمارەکەت دوور دەخاتەوە. تەنها یەک جار داوای دەکەین — دوای ئەمە، کڕین یەک پەنجەیە.';

  @override
  String get orderConfirmed => 'پەسەندکرا';

  @override
  String get orderOnTheWay => 'لە ڕێگەدایە';

  @override
  String get orderDelivered => 'گەیەندرا';

  @override
  String get orderCancelled => 'داواکاری هەڵوەشێندرایەوە';

  @override
  String get yourOrders => 'داواکارییەکانت';

  @override
  String get noOrdersYet => 'هێشتا هیچ داواکارییەک نییە';

  @override
  String get noOrdersBody =>
      'ئەوەی دەیکڕیت لێرە دەردەکەوێت، لەگەڵ ئەوەی گەیشتووەتە کوێ.';

  @override
  String get cancelOrder => 'داواکاری هەڵوەشێنەوە';

  @override
  String get keepIt => 'بیهێڵەرەوە';

  @override
  String get receipt => 'وەرگرتن';

  @override
  String get rateThisOrder => 'هەڵسەنگاندنی ئەم داواکارییە';

  @override
  String get stageConfirmedBody =>
      'فرۆشیار داواکارییەکەتی وەرگرتووە و ئامادەی دەکات. تا نەڕۆیشتووە دەتوانیت هەڵیبوەشێنیتەوە.';

  @override
  String get stageOnTheWayBody =>
      'لە ڕێگەدایە بۆت. گەیەنەر پەیوەندی بەو ژمارەیەوە دەکات کە لە هەژمارتدایە.';

  @override
  String get stageDeliveredBody => 'گەیەندرا. خۆشی لێ ببینە.';

  @override
  String get trustBronze => 'متمانەی برۆنزی';

  @override
  String get trustSilver => 'متمانەی زیوی';

  @override
  String get trustGold => 'متمانەی زێڕین';

  @override
  String get trustPlatinum => 'باشترین هەڵسەنگاندن';

  @override
  String get trustVerifiedSeller => 'فرۆشیاری پشتڕاستکراوە';

  @override
  String get trustNewSeller => 'فرۆشیاری نوێ';

  @override
  String get noTrackRecordBody =>
      'ئەم فرۆشیارە هێشتا هیچ داواکارییەکی تەواو نەکردووە، بۆیە هیچ هەڵسەنگاندنێک نییە. پارەدان لە کاتی گەیاندن سەلامەتترین ڕێگەیە بۆ کڕین لە کەسێکی نوێ.';

  @override
  String get comments => 'لێدوانەکان';

  @override
  String commentsCount(int count) {
    return '$count لێدوان';
  }

  @override
  String get addAComment => 'لێدوانێک زیاد بکە';

  @override
  String get noCommentsYet => 'هێشتا هیچ لێدوانێک نییە';

  @override
  String get noCommentsBody =>
      'دەربارەی قەبارە، دۆخ یان گەیاندن بپرسە — فرۆشیار لێرە وەڵام دەداتەوە.';

  @override
  String get seller => 'فرۆشیار';

  @override
  String get follow => 'شوێنکەوتن';

  @override
  String get following => 'شوێنی کەوتوویت';

  @override
  String get message => 'نامە';

  @override
  String get report => 'ڕاپۆرت';

  @override
  String get reportSent => 'ڕاپۆرت نێردرا';

  @override
  String get share => 'هاوبەشکردن';

  @override
  String get save => 'پاشەکەوت';

  @override
  String get like => 'بەدڵبوون';

  @override
  String get reviews => 'هەڵسەنگاندنەکان';

  @override
  String get noReviewsYet => 'هێشتا هیچ هەڵسەنگاندنێک نییە';

  @override
  String get verifiedPurchase => 'کڕینی پشتڕاستکراوە';

  @override
  String get reviewVerifiedOnly =>
      'تەنها ئەو کڕیارانەی ئەم کاڵایەیان پێگەیشتووە دەتوانن هەڵسەنگاندنی بۆ بنووسن، بۆیە هەڵسەنگاندنەکان هەمیشە لە داواکارییەکی ڕاستەقینەوە دێن.';

  @override
  String get editWindowNote =>
      'بۆ ماوەی ٤٨ کاتژمێر دەتوانیت دەستکاری بکەیت، پاشان دادەخرێت.';

  @override
  String get submitRating => 'هەڵسەنگاندن بنێرە';

  @override
  String get ratingBad => 'خراپ';

  @override
  String get ratingNotGreat => 'باش نییە';

  @override
  String get ratingFine => 'باشە';

  @override
  String get ratingGood => 'باش';

  @override
  String get ratingExcellent => 'نایاب';

  @override
  String get tapAStar => 'ئەستێرەیەک دابگرە';

  @override
  String get newReel => 'ڕیلی نوێ';

  @override
  String get chooseAVideo => 'ڤیدیۆیەک هەڵبژێرە';

  @override
  String get caption => 'سەردێڕ';

  @override
  String get linkAProduct => 'بەرهەمێک ببەستەوە';

  @override
  String get linkAProductBody => 'دوگمەی «ئێستا بیکڕە» بۆ ئەم ڕیلە زیاد دەکات';

  @override
  String get listAProduct => 'بەرهەمێک بڵاو بکەوە';

  @override
  String get whatIsIt => 'ئەمە چییە؟';

  @override
  String get description => 'وەسف';

  @override
  String get price => 'نرخ';

  @override
  String get howMany => 'چەند دانە';

  @override
  String get cover => 'ڕووکار';

  @override
  String get listingIsLive => 'بەرهەمەکەت بڵاو بووەوە';

  @override
  String get reelIsLive => 'ڕیلەکەت بڵاو بووەوە';

  @override
  String get notifications => 'ئاگادارکردنەوەکان';

  @override
  String get notifOrders => 'نوێکارییەکانی داواکاری';

  @override
  String get notifOrdersBody => 'پەسەندکرا، لە ڕێگەدایە، گەیەندرا';

  @override
  String get notifChat => 'نامەکان';

  @override
  String get notifChatBody => 'کاتێک کڕیار یان فرۆشیار وەڵام دەداتەوە';

  @override
  String get notifSocial => 'بەدڵبوون، لێدوان و شوێنکەوتن';

  @override
  String get notifSocialBody => 'چالاکی لەسەر ڕیل و پڕۆفایلەکەت';

  @override
  String get notifMarketing => 'پێشکەشکراوەکان و ڕاگەیاندنەکان';

  @override
  String get notifMarketingBody => 'هەواڵی کاتی کاتی دەربارەی WAVE';

  @override
  String get nothingNew => 'هیچی نوێ نییە';

  @override
  String get retry => 'دووبارە هەوڵ بدەرەوە';

  @override
  String get getStarted => 'دەست پێبکە';

  @override
  String get errorNoConnectionBody =>
      'پەیوەندییەکەت بپشکنە و دووبارە هەوڵ بدەرەوە.';

  @override
  String get errorDeadLink => 'ئەم بەستەرە هیچ شوێنێکی نییە';

  @override
  String get errorDeadLinkBody =>
      'ئەو پەڕەیەی شوێنی کەوتوویت بوونی نییە یان لابراوە.';

  @override
  String get searchProductsAndReels => 'گەڕان بۆ بەرهەم و ڕیل';

  @override
  String get cancel => 'هەڵوەشاندنەوە';

  @override
  String get done => 'تەواو';

  @override
  String get next => 'دواتر';

  @override
  String get skip => 'پەڕاندن';

  @override
  String get updateRequiredTitle => 'بۆ بەردەوامبوون WAVE نوێ بکەرەوە';

  @override
  String get updateRequiredBody =>
      'ئەم وەشانە چیتر پشتگیری ناکرێت. نوێکردنەوەکە کەمێک دەخایەنێت، و سەبەتە و داواکارییەکانت پارێزراون.';

  @override
  String get updateNow => 'ئێستا نوێی بکەرەوە';

  @override
  String get acceptAndContinue => 'پەسەندی بکە و بەردەوامبە';

  @override
  String get profile => 'پڕۆفایل';

  @override
  String get settings => 'ڕێکخستنەکان';

  @override
  String get browsingAsGuest => 'وەک میوان دەگەڕێیت';

  @override
  String get guestUpgradeBody =>
      'هەژمارێک درووست بکە بۆ کڕین، فرۆشتن، پاشەکەوتکردن و نامەنێردن بۆ فرۆشیاران. هەرچی لە سەبەتەکەتدایە لەگەڵت دێت.';

  @override
  String get createAnAccount => 'هەژمارێک درووست بکە';

  @override
  String get favourites => 'دڵخوازەکان';

  @override
  String get savedReels => 'ڕیلە پاشەکەوتکراوەکان';

  @override
  String get ordersToFulfil => 'داواکارییەکان بۆ جێبەجێکردن';

  @override
  String get howYouAreDoing => 'چۆن کاردەکەیت';

  @override
  String get termsAndPolicies => 'مەرج و سیاسەتەکان';

  @override
  String get downloadYourData => 'داتاکەت دابگرە';

  @override
  String get preparingYourData =>
      'داتاکەت ئامادە دەکرێت — لەوانەیە کەمێک بخایەنێت';

  @override
  String get deleteYourAccount => 'هەژمارەکەت بسڕەوە';

  @override
  String get deleteYourAccountQ => 'هەژمارەکەت بسڕدرێتەوە؟';

  @override
  String get deleteAccountBody =>
      'بۆ هەمیشە دەسڕدرێتەوە: پڕۆفایل، ڕیلەکان، بەرهەمەکان، پاشەکەوتکراوەکان، ناونیشانەکان و شێوازەکانی پارەدان.\n\nبەبێ ناوت دەمێنێتەوە: داواکارییە تەواوکراوەکان، و ئەو هەڵسەنگاندن و ڕەخنانەی نووسیوتن. فرۆشیاران پێویستیان بە تۆماری مامەڵەکانیانە، و لابردنی هەڵسەنگاندنەکانت بێدەنگ نمرەکەیان بۆ کڕیاری داهاتوو دەگۆڕێت.\n\nئەگەر شتێک ئێستا لە ڕێگەدایە بۆت، زانیاری گەیاندنەکەی دەمێنێتەوە تا دەگات — گەیەنەر پاکێجەکەتی پێیە. لە ماوەی ڕۆژێک دوای گەیاندن دەسڕدرێنەوە.\n\nئەمە ناگەڕێتەوە.';

  @override
  String get keepMyAccount => 'هەژمارەکەم بهێڵەرەوە';

  @override
  String get delete => 'سڕینەوە';

  @override
  String get items => 'کاڵاکان';

  @override
  String orderNumber(String id) {
    return 'داواکاری #$id';
  }

  @override
  String orderedOn(String date) {
    return 'داوا کراوە لە $date';
  }

  @override
  String get orderNotFound => 'ناتوانین ئەو داواکارییە بدۆزینەوە';

  @override
  String get orderNotFoundBody => 'لەوانەیە لابرابێت، یان بەستەرەکە هەڵە بێت.';

  @override
  String get cancelThisOrder => 'ئەم داواکارییە هەڵبوەشێنەوە';

  @override
  String get cancelThisOrderQ => 'ئەم داواکارییە هەڵبوەشێتەوە؟';

  @override
  String get cancelOrderBuyerBody =>
      'دەستبەجێ بە فرۆشیار دەڵێین و هەرچی دراوە دەگەڕێتەوە. ئەمە ناگەڕێتەوە.';

  @override
  String get howDidItGo => 'چۆن بوو؟';

  @override
  String get ratingHelpsNextBuyer =>
      'هەڵسەنگاندنەکەت ئەوەیە کە نیشانەکەی ئەم فرۆشیارە دەدات — و ئەوەیە کە بە کڕیاری داهاتوو دەڵێت متمانەی پێ بکات یان نا.';

  @override
  String get ratingSubmitted => 'سوپاس — هەڵسەنگاندنەکەت تۆمار کرا';

  @override
  String get descriptionHint =>
      'قەبارە، دۆخ، کەرەستە — هەرچی کڕیارێک پێش بڕیاردان دەیپرسێت';

  @override
  String coverPhotoNote(int max) {
    return 'یەکەم وێنە ئەوەیە کە کڕیاران لە گریددا دەیبینن. تا $max دانە.';
  }

  @override
  String buyersWillSee(String price) {
    return 'کڕیاران $price دەبینن';
  }

  @override
  String get uploadingPhotos => 'وێنەکان بار دەکرێن…';

  @override
  String get makeAReel => 'ڕیلێک درووست بکە';

  @override
  String get aboutThisItem => 'دەربارەی ئەم کاڵایە';

  @override
  String get shareThisItem => 'ئەم کاڵایە هاوبەش بکە';

  @override
  String get reportThisListing => 'ڕاپۆرتی ئەم بەرهەمە بکە';

  @override
  String get productNotFound => 'ناتوانین ئەو کاڵایە بدۆزینەوە';

  @override
  String get productNotFoundBody =>
      'لەوانەیە فرۆشرابێت یان لەلایەن فرۆشیارەوە لابرابێت.';

  @override
  String get backToTheMarket => 'گەڕانەوە بۆ بازاڕ';

  @override
  String get otherActions => 'کردارەکانی تر';

  @override
  String get buyerCanStillCancel =>
      'کڕیار هێشتا دەتوانێت هەڵیبوەشێنێتەوە تا ئەوەی بیدەیت بە گەیەنەر.';

  @override
  String get cancelOrderSellerBody =>
      'پارەکە بۆ کڕیار دەگەڕێتەوە و دەستبەجێ پێی دەڵێین. هەڵوەشاندنەوەی داواکارییەکان دوای پەسەندکردنیان کاریگەری لەسەر ئاستی متمانەت دەبێت، بۆیە تەنها ئەگەر بەڕاستی ناتوانیت جێبەجێی بکەیت ئەمە بکە.';

  @override
  String get nothingWaitingOnYou => 'هیچ چاوەڕێی تۆ نییە';

  @override
  String get nothingWaitingBody =>
      'داواکارییە نوێیەکان لەو ساتەدا لێرە دەردەکەون کە کەسێک دەکڕێت.';

  @override
  String get nothingInTransit => 'هیچ لە ڕێگەدا نییە';

  @override
  String get nothingInTransitBody =>
      'ئەو داواکارییانەی دەتدوونە گەیەنەر لێرە دەردەکەون.';

  @override
  String get noCompletedOrders => 'هێشتا هیچ داواکارییەکی تەواوکراو نییە';

  @override
  String get noCompletedOrdersBody =>
      'داواکارییە گەیەندراو و هەڵوەشێندراوەکان لێرە دەپارێزرێن.';

  @override
  String get filterToDo => 'بۆ کردن';

  @override
  String get filterOnTheWay => 'لە ڕێگەدا';

  @override
  String get filterCompleted => 'تەواوبوو';

  @override
  String get soldOut => 'فرۆشرا';

  @override
  String get deliveryArrangedNote =>
      'گەیاندن دوای داواکاری لەگەڵ فرۆشیار ڕێک دەخرێت.';

  @override
  String get cartMultiSellerWarning =>
      'سەبەتەکەت کاڵای زیاتر لە یەک فرۆشیاری تێدایە. لە ئێستادا بە جیا داوایان بکە.';

  @override
  String get cartStockWarning =>
      'هەندێک کاڵا فرۆشراون یان لە بڕی هەڵبژێردراوت کەمترن. بۆ بەردەوامبوون ڕێکیان بخە.';

  @override
  String itemsCount(int count) {
    return '$count کاڵا';
  }

  @override
  String get decreaseQuantity => 'کەمکردنەوەی بڕ';

  @override
  String get increaseQuantity => 'زیادکردنی بڕ';

  @override
  String get noAddressYet => 'هێشتا ناونیشان نییە';

  @override
  String get savedAddress => 'ناونیشانی پاشەکەوتکراو';

  @override
  String get savedPaymentMethod => 'شێوازی پارەدانی پاشەکەوتکراو';

  @override
  String get codAvailableNote =>
      'پارەدان لە کاتی گەیاندن لە ناوچەکەتدا بەردەستە';

  @override
  String placeOrderWithTotal(String total) {
    return 'داواکاری بنێرە · $total';
  }

  @override
  String get signInToOrder => 'بۆ ناردنی ئەم داواکارییە بچۆ ژوورەوە';

  @override
  String get signInToOrderBody =>
      'میوانەکان دەتوانن بگەڕێن و سەبەتە پڕ بکەن، بەڵام داواکاری هەژماری پێویستە.';

  @override
  String get verifyYourPhone => 'ژمارەی مۆبایلەکەت پشتڕاست بکەرەوە';

  @override
  String get verifyNow => 'ئێستا پشتڕاست بکەرەوە';

  @override
  String get addDeliveryAddress => 'ناونیشانی گەیاندن زیاد بکە';

  @override
  String get addAddressBody => 'فرۆشیار پێویستی بە شوێنێکە بۆ ناردنی.';

  @override
  String get addAddress => 'ناونیشان زیاد بکە';

  @override
  String get chooseHowToPay => 'هەڵبژێرە چۆن پارە بدەیت';

  @override
  String get chooseHowToPayBody =>
      'پارەدان لە کاتی گەیاندن لە زۆربەی ناوچەکاندا بەردەستە.';

  @override
  String get choose => 'هەڵبژێرە';

  @override
  String get newAddress => 'ناونیشانی نوێ';

  @override
  String get addANewAddress => 'ناونیشانێکی نوێ زیاد بکە';

  @override
  String get whoIsReceiving => 'کێ وەریدەگرێت';

  @override
  String get phoneForCourier => 'مۆبایل بۆ گەیەنەر';

  @override
  String get city => 'شار';

  @override
  String get addressLine => 'گەڕەک، شەقام، بینا';

  @override
  String get landmarkOptional => 'نزیکترین نیشانە (ئارەزوومەندانە)';

  @override
  String get landmarkHint => 'بەرامبەر مزگەوتی شین، سەرەوەی دەرمانخانە…';

  @override
  String get landmarkNote =>
      'گەیەنەرەکان لێرە زۆرجار بە نیشانە و پەیوەندی تەلەفۆن ناونیشان دەدۆزنەوە، بۆیە ئەمە زیاتر یارمەتیدەرە لەوەی دەردەکەوێت.';

  @override
  String get saveAddress => 'ناونیشان پاشەکەوت بکە';

  @override
  String get chooseADifferentVideo => 'ڤیدیۆیەکی جیاواز هەڵبژێرە';

  @override
  String upToNSeconds(int seconds) {
    return 'تا $seconds چرکە';
  }

  @override
  String durationOfMax(int actual, Object max) {
    return '$actual چرکە لە $max چرکە';
  }

  @override
  String videoTooLong(int actual, Object max) {
    return 'ئەو ڤیدیۆیە $actual چرکەیە. بۆ $max چرکە یان کەمتر کورتی بکەرەوە و دووبارە هەڵیبژێرە.';
  }

  @override
  String get captionHint => 'بڵێ چییە، و بۆچی کەسێک بیەوێت';

  @override
  String get removeTheLink => 'بەستەرەکە لابە';

  @override
  String get linkedProductNote => 'کڕیاران دەتوانن ڕاستەوخۆ لە ڕیلەکەوە بیکڕن';

  @override
  String get statsNotLoaded => 'ژمارەکانت بار نەبوون';

  @override
  String lastNDays(int days) {
    return 'دوایین $days ڕۆژ';
  }

  @override
  String get earned => 'قازانج';

  @override
  String get orders => 'داواکاری';

  @override
  String get rating => 'هەڵسەنگاندن';

  @override
  String get wherePeopleDropOff => 'خەڵک لە کوێ وازدەهێنن';

  @override
  String get funnelExplainer =>
      'هەر هەنگاوێک پیشان دەدات چەند کەس بۆ هەنگاوی دواتر بەردەوام بوون.';

  @override
  String get funnelLowSample =>
      'ئەم ڕێژانە لە خوار ١٠٠ بینیندا متمانەپێکراو نین — وەک ئاماژەیەکیان لێ بڕوانە، نەک بڕیارێک.';

  @override
  String get funnelWatched => 'ڕیلێکی بینی';

  @override
  String get funnelTapped => 'دوگمەی کڕینی داگرت';

  @override
  String get funnelCompleted => 'داواکارییەکەی تەواو کرد';

  @override
  String get lowTapThroughNote =>
      'کەم بینەر دوگمەی کڕین داگرن. لەوانەیە ڕیلەکە بەرهەمەکە بە ڕوونی پیشان نەدات، یان نرخەکە بەزوویی دیار نەبێت.';

  @override
  String get lowCompletionNote =>
      'زۆربەی ئەوانەی دوگمەی کڕین دادەگرن تەواوی ناکەن. بەزۆری نرخ، تەواوبوونی کاڵا، یان کڕیارێکی یەکەم جارە کە بەر هەنگاوی پشتڕاستکردنەوەی مۆبایل دەکەوێت.';

  @override
  String get yourReels => 'ڕیلەکانت';

  @override
  String get nothingPublishedYet => 'هێشتا هیچ بڵاو نەکراوەتەوە.';

  @override
  String get ordersWaitingOne => '١ داواکاری چاوەڕێی تۆیە';

  @override
  String ordersWaitingMany(int count) {
    return '$count داواکاری چاوەڕێی تۆن';
  }

  @override
  String get open => 'کردنەوە';

  @override
  String viewsAndSold(int views, Object sold) {
    return '$views بینین · $sold فرۆشراوە';
  }

  @override
  String wastedAudienceNote(int views) {
    return '$views کەس ئەمەیان بینی و هیچیان نەبوو بیکڕن. بەرهەمێکی پێوە ببەستە.';
  }

  @override
  String get reportThis => 'ڕاپۆرتی ئەمە بکە';

  @override
  String get whatIsWrongWithIt => 'چی هەڵەیە لێی؟';

  @override
  String get alsoBlockAccount => 'هەروەها ئەم هەژمارە بلۆک بکە';

  @override
  String get blockExplainer => 'چیتر بڵاوکراوە و نامەکانیان نابینیت';

  @override
  String get sendReport => 'ڕاپۆرت بنێرە';

  @override
  String get reportSentBody =>
      'چاودێرێک سەیری ئەمە دەکات. ئەوەی دواتر ڕوودەدات بڵاوی ناکەینەوە، و بەو کەسەی ڕاپۆرت کراوە ناوترێت کێ ڕاپۆرتی کردووە.';

  @override
  String get reasonSpam => 'سپام یان فێڵ';

  @override
  String get reasonCounterfeit => 'کاڵای ساختە یان بە هەڵە وەسفکراو';

  @override
  String get reasonProhibited => 'کاڵای قەدەغەکراو';

  @override
  String get reasonHarassment => 'ئازاردان یان ڕق';

  @override
  String get reasonSexual => 'ناوەڕۆکی سێکسی';

  @override
  String get reasonViolence => 'توندوتیژی یان کرداری مەترسیدار';

  @override
  String get reasonIntellectualProperty =>
      'مافی لەبەرگرتنەوە یان نیشانەی بازرگانی';

  @override
  String get reasonOther => 'شتێکی تر';

  @override
  String get sellerNotFound => 'ناتوانین ئەو فرۆشیارە بدۆزینەوە';

  @override
  String get sellerNotFoundBody => 'لەوانەیە هەژمارەکە لابرابێت.';

  @override
  String get reportOrBlock => 'ڕاپۆرت یان بلۆک';

  @override
  String sellingSince(String date) {
    return 'فرۆشتن لە $dateـەوە';
  }

  @override
  String get nothingListedRightNow => 'لە ئێستادا هیچ بڵاو نەکراوەتەوە.';

  @override
  String get listings => 'بەرهەمەکان';

  @override
  String listingsCount(int count) {
    return '$count بەرهەم';
  }

  @override
  String get followers => 'شوێنکەوتوو';

  @override
  String ratingsCount(int count) {
    return '$count هەڵسەنگاندن';
  }

  @override
  String get delivered => 'گەیەندراو';

  @override
  String get goToReels => 'بڕۆ بۆ ڕیلز';

  @override
  String get reelsNotLoaded => 'ڕیلزەکان بار نەبوون';

  @override
  String get noReelsYet => 'هێشتا هیچ ڕیلێک نییە';

  @override
  String get noReelsBody => 'یەکەم کەس بە کە دایدەنێت.';

  @override
  String get nothingSavedYet => 'هێشتا هیچ پاشەکەوت نەکراوە';

  @override
  String get savedReelsBody => 'نیشانەکە لەسەر ڕیلێک دابگرە بۆ هێشتنەوەی لێرە.';

  @override
  String get watchSomeReels => 'چەند ڕیلێک ببینە';

  @override
  String get favouritesBody =>
      'دڵەکە دابگرە لەسەر هەر شتێک کە دەتەوێت بگەڕێیتەوە بۆی.';

  @override
  String get appTagline => 'ببینە، و ئەوەی دەیبینیت بیکڕە.';

  @override
  String get searchProducts => 'گەڕان بۆ بەرهەم';

  @override
  String get clearSearch => 'گەڕان پاک بکەرەوە';

  @override
  String get marketEmpty => 'بازاڕەکە بەتاڵە';

  @override
  String get marketEmptyBody =>
      'هێشتا هیچ بڵاو نەکراوەتەوە. یەکەم کەس بە کە شتێک دەفرۆشێت.';

  @override
  String get productsNotLoaded => 'بەرهەمەکان بار نەبوون';

  @override
  String nothingMatched(String query) {
    return 'هیچ لەگەڵ «$query» نەگونجا';
  }

  @override
  String get searchPrefixNoteProducts =>
      'گەڕان لەگەڵ سەرەتای ناوی بەرهەم دەگونجێت. وشەیەکی کورتتر یان جیاواز تاقی بکەرەوە.';

  @override
  String get searchPrefixNoteAll =>
      'گەڕان لەگەڵ سەرەتای ناو یان سەردێڕ دەگونجێت، بۆیە یەکەم وشە تاقی بکەرەوە نەک وشەیەک لە ناوەڕاست.';

  @override
  String get searchHintEmpty => 'بگەڕێ بەناو هەرچی بۆ فرۆشە و هەموو ڕیلێکدا.';

  @override
  String get searchHintShort =>
      'بەردەوامبە لە نووسین — گەڕان لە دوو پیتەوە دەست پێدەکات.';

  @override
  String get products => 'بەرهەمەکان';

  @override
  String get reels => 'ڕیلز';

  @override
  String get shop => 'کڕین';

  @override
  String get ordersNotLoaded => 'داواکارییەکانت بار نەبوون';

  @override
  String get receiptTitle => 'وەرگرتن';

  @override
  String receiptDocTitle(String id) {
    return 'وەرگرتنی WAVE $id';
  }

  @override
  String get receiptSoldBy => 'فرۆشراوە لەلایەن';

  @override
  String get receiptBuyer => 'کڕیار';

  @override
  String get receiptDeliveredTo => 'گەیەندراوە بۆ';

  @override
  String get receiptStatus => 'دۆخ';

  @override
  String get receiptItem => 'کاڵا';

  @override
  String get receiptQty => 'بڕ';

  @override
  String get receiptUnit => 'یەکە';

  @override
  String get receiptDisclaimer =>
      'ئەمە تۆماری کڕینێکە کە لە ڕێگەی WAVEـەوە کراوە. WAVE بازاڕێکە؛ فرۆشتنەکە لە نێوان کڕیار و ئەو فرۆشیارەی سەرەوەیە. ئەمە پسووڵەی باج نییە مەگەر فرۆشیار بە جیا دەریکردبێت.';

  @override
  String get yourWaveData => 'داتاکەتی WAVE';

  @override
  String get sellFromThisReel => 'لەم ڕیلەوە بفرۆشە';

  @override
  String get sellFromThisReelBody =>
      'یەکێک لە بەرهەمەکانت هەڵبژێرە. کڕیاران دوگمەی کڕین وەردەگرن بەبێ جێهێشتنی ڤیدیۆکە.';

  @override
  String get nothingListedYet => 'هێشتا هیچت بڵاو نەکردووەتەوە.';

  @override
  String get listAProductFirst => 'سەرەتا بەرهەمێک بڵاو بکەوە';

  @override
  String get uploadAReel => 'ڕیلێک بار بکە';

  @override
  String get uploadAReelBody =>
      'تا ٦٠ چرکە. بەرهەمێکی پێوە ببەستە بۆ فرۆشتنی لێوە.';

  @override
  String get listAProductBody => 'وێنە، نرخ و بڕ زیاد بکە.';

  @override
  String versionUpdated(String version, Object date) {
    return 'وەشانی $version · نوێکراوەتەوە لە $date';
  }

  @override
  String versionLabel(String version) {
    return 'وەشانی $version';
  }

  @override
  String get copied => 'کۆپی کرا';

  @override
  String get copy => 'کۆپی';

  @override
  String get documentNotLoaded => 'ئەو بەڵگەنامەیە بار نەبوو';

  @override
  String get beforeYouStart => 'پێش دەستپێکردن';

  @override
  String get termsChanged => 'مەرجەکانمان گۆڕاون';

  @override
  String documentChanged(String title) {
    return '$title گۆڕاوە';
  }

  @override
  String get acceptToUse =>
      'تکایە ئەمانە بخوێنەوە و پەسەندیان بکە بۆ بەکارهێنانی WAVE.';

  @override
  String get readWhatChanged =>
      'تکایە پێش بەردەوامبوون ئەوە بخوێنەوە کە گۆڕاوە.';

  @override
  String get addANote => 'تێبینییەک زیاد بکە (ئارەزوومەندانە)';

  @override
  String reviewsCount(int count) {
    return '$count هەڵسەنگاندن';
  }

  @override
  String get noMessagesYet => 'هێشتا هیچ نامەیەک نییە';

  @override
  String get noMessagesBody =>
      'کاتێک دەربارەی کاڵایەک نامە بۆ فرۆشیارێک دەنێریت، گفتوگۆکە لێرە دەردەکەوێت.';

  @override
  String get aboutAListing => 'دەربارەی بەرهەمێک';

  @override
  String get view => 'بینین';

  @override
  String get chatEmptyPrompt =>
      'دەربارەی قەبارە، دۆخ، گەیاندن بپرسە — هەرچی پێویستە بزانیت پێش کڕین.';

  @override
  String get send => 'ناردن';

  @override
  String get notificationSettings => 'ڕێکخستنی ئاگادارکردنەوە';

  @override
  String get notificationsNotLoaded => 'ئاگادارکردنەوەکان بار نەبوون';

  @override
  String get nothingNewBody =>
      'نوێکاریی داواکاری، وەڵامەکان و چالاکی لەسەر بڵاوکراوەکانت لێرە دەردەکەون.';

  @override
  String get notifOrdersOffWarning =>
      'کوژاندنەوەی نوێکاریی داواکاری واتای ئەوەیە پێت ناڵێین کاتێک شتێکی کڕیوت لە ڕێگەدایە.';

  @override
  String get howDoYouWantToPay => 'چۆن دەتەوێت پارە بدەیت؟';

  @override
  String addPaymentMethod(String method) {
    return '$method زیاد بکە';
  }

  @override
  String get cardDetailsNote =>
      'زانیاری کارت لەلایەن دابینکەری پارەدانەوە دەپارێزرێت، هەرگیز لەلایەن WAVEـەوە نا.';

  @override
  String get railCashOnDelivery => 'پارەدان لە کاتی گەیاندن';

  @override
  String get railCashOnDeliveryBody => 'پارە بدە بە گەیەنەر کاتێک دەگات';

  @override
  String get railMobileWallet => 'جزدانی مۆبایل';

  @override
  String get railCard => 'کارت';

  @override
  String get railBankCard => 'کارتی بانکی';

  @override
  String get railBankCardBody => 'Visa یان Mastercard';

  @override
  String get lowStockShort => 'تەنها چەند دانەیەک ماوە';

  @override
  String get phoneGateShortNote =>
      'یەک جار داوای دەکەین. ژمارەکەت بۆ نوێکاریی گەیاندن و پاراستنی هەژمارەکەت بەکاردێت — دوای ئەمە، کڕین یەک پەنجەیە.';

  @override
  String get promoApplied =>
      'کۆدەکە جێبەجێ کرا. داشکاندنەکە لە کاتی تەواوکردنی کڕین پشتڕاست دەکرێتەوە.';

  @override
  String get stockLimitReached => 'ئەمە هەموو ئەو بڕەیە کە بەردەستە';

  @override
  String get postComment => 'لێدوان بنێرە';

  @override
  String get onboardingTitle1 => 'ببینە. دابگرە. هی تۆ بێت.';

  @override
  String get onboardingBody1 =>
      'هەر ڕیلێک دەتوانێت ببێتە دوکان. ئەگەر ئەوەی دەیبینیت پێت خۆشە، بەبێ جێهێشتنی ڤیدیۆکە بیکڕە.';

  @override
  String get onboardingTitle2 => 'بزانە لە کێ دەکڕیت';

  @override
  String get onboardingBody2 =>
      'فرۆشیاران نیشانەکەیان لە داواکاری ڕاستەقینەی گەیەندراوەوە بەدەست دەهێنن — نەک لەوەی دەربارەی خۆیان دەیڵێن.';

  @override
  String get onboardingTitle3 => 'ئەوەی درووستی دەکەیت بیفرۆشە';

  @override
  String get onboardingBody3 =>
      'ڕیلێک بڵاو بکەوە، بەرهەمێکی پێوە ببەستە، پارە وەربگرە. کاتێک شتێک دەفرۆشرێت دەستبەجێ پێت دەڵێین — هەر کاتێک بتەوێت دەتوانیت بیکوژێنیتەوە.';

  @override
  String get startBrowsing => 'دەست بە گەڕان بکە';

  @override
  String stepOfTotal(int current, Object total) {
    return 'هەنگاوی $current لە $total';
  }

  @override
  String orderStatusSemantic(String status, Object step) {
    return 'دۆخی داواکاری: $status، هەنگاوی $step لە ٣';
  }

  @override
  String get signOut => 'چوونەدەرەوە';

  @override
  String get signOutQ => 'دەربچیت؟';

  @override
  String get signOutBody =>
      'چیتر ئاگادارکردنەوە لەم ئامێرەدا وەرناگریت، و هیچ کەسێک کە دوای تۆ بەکاری بهێنێت داواکارییەکانت نابینێت.';

  @override
  String get promoCode => 'کۆدی داشکاندن';

  @override
  String get promoCodeHint => 'کۆدت هەیە؟';

  @override
  String get apply => 'جێبەجێ بکە';

  @override
  String get discount => 'داشکاندن';

  @override
  String get promoInvalid => 'ئەم کۆدە دروست نییە';

  @override
  String get promoExpired => 'ئەم کۆدە بەسەرچووە';

  @override
  String get promoUsed => 'پێشتر ئەم کۆدەت بەکارهێناوە';

  @override
  String get mediaAccessRationale =>
      'WAVE پێویستی بە دەستڕاگەیشتنە بە ڤیدیۆکانت بۆ ئەوەی یەکێکیان هەڵبژێریت بۆ بڵاوکردنەوە. تەنها ئەو ڤیدیۆیە دەبینین کە هەڵیدەبژێریت.';

  @override
  String get stageCancelledBody =>
      'ئەم داواکارییە هەڵوەشێندرایەوە. هەر پارەیەکی وەرگیراو بۆ هەمان شێواز دەگەڕێتەوە.';

  @override
  String get shareThisReel => 'ئەم ڕیلە هاوبەش بکە';

  @override
  String get reportThisReel => 'ڕاپۆرتی ئەم ڕیلە بکە';

  @override
  String get accountSuspended => 'هەژمارەکەت ڕاگیراوە';

  @override
  String get accountSuspendedBody =>
      'هێشتا دەتوانیت داواکارییەکانت ببینیت و سیاسەتی ناوەڕۆکمان بخوێنیتەوە، بەڵام لە ماوەی ڕاگرتنەکەدا ناتوانیت بڵاو بکەیتەوە، بفرۆشیت، لێدوان بنووسیت یان نامە بنێریت.';

  @override
  String get readContentPolicy => 'سیاسەتی ناوەڕۆک بخوێنەوە';

  @override
  String get recoverAccount => 'گەڕاندنەوەی هەژمارەکەت';

  @override
  String get recoverByPhone => 'بە ژمارەی مۆبایلەکەت';

  @override
  String get recoverByPhoneBody =>
      'کۆدێک بۆ ئەو ژمارەیە دەنێرین کە لەسەر هەژمارەکەیە. بە نووسینی، دووبارە دەچیتەوە ژوورەوە.';

  @override
  String get recoverByEmail => 'بە ئیمەیڵەکەت';

  @override
  String get recoverByEmailBody =>
      'ئەگەر بە Google یان Apple تۆمار بوویت و ئەو مۆبایلەت نەماوە، لەبری ئەوە ئەو ئیمەیڵە بەکاربهێنە کە لەسەر هەژمارەکەیە.';

  @override
  String get emailAddress => 'ناونیشانی ئیمەیڵ';

  @override
  String get sendRecoveryEmail => 'ئیمەیڵی گەڕاندنەوە بنێرە';

  @override
  String get recoveryEmailSent =>
      'ئەگەر ئەو ناونیشانە هەژمارێکی هەبێت، ئیمەیڵی گەڕاندنەوە لە ڕێگەدایە.';

  @override
  String get forgotAccess => 'دەستڕاگەیشتنت لە هەژمارەکەت لەدەستداوە؟';

  @override
  String get offlineBannerBody =>
      'تۆ دەرهێڵیت. ئەوەی ئێستا دەیکەیت پاشەکەوت دەکرێت و کاتێک گەڕایەوە هاوکات دەکرێت.';

  @override
  String get stagePendingPaymentBody =>
      'چاوەڕێی ئەوەین کە پارەدانەکەت تەواو بێت. فرۆشیار ئەم داواکارییە دەبینێت کاتێک تەواو بوو — بەزۆری لە ماوەی خولەکێکدا.';

  @override
  String get stagePaymentFailedBody =>
      'پارەدانەکەت سەرکەوتوو نەبوو، بۆیە ئەم داواکارییە بۆ فرۆشیار نەنێردراوە. هیچ بڕێک وەرنەگیراوە.';

  @override
  String get paymentPending => 'چاوەڕێی پارەدان';

  @override
  String get promoBelowMinimum => 'ئەم کۆدە داواکارییەکی گەورەتری پێویستە';

  @override
  String get promoTooManyAttempts => 'هەوڵی زۆر بۆ کۆد. دواتر هەوڵ بدەرەوە.';

  @override
  String buyNowWithPrice(String price) {
    return 'ئێستا بیکڕە · $price';
  }

  @override
  String get setDeliveryLocation => 'شوێنی گەیاندن دیاری بکە';

  @override
  String get dragMapToSetPin =>
      'نەخشەکە بجوڵێنە تا نیشانەکە لەسەر دەرگاکەت دابنێیت.';

  @override
  String get useMyLocation => 'شوێنی من بەکاربهێنە';

  @override
  String get confirmLocation => 'شوێنەکە پشتڕاست بکەرەوە';

  @override
  String confirmAndBuy(String price) {
    return 'پشتڕاست بکەرەوە و بیکڕە · $price';
  }

  @override
  String get deliveryNote => 'نیشانە یان ڕێنمایی';

  @override
  String get deliveryNoteHint =>
      'دەرگای شین، نهۆمی دووەم، بەرامبەر دەرمانخانە…';

  @override
  String get deliveryNoteWhy =>
      'گەیەنەرەکان لێرە بەزۆری بە نیشانە و پەیوەندی تەلەفۆن دەرگا دەدۆزنەوە، بۆیە ئەمە زیاتر یارمەتیدەرە لە نیشانەکە.';

  @override
  String get locationPermissionDenied =>
      'شوێن کوژاوەتەوە، بۆیە نیشانەکە بە دەست دابنێ.';

  @override
  String get locationUnavailable =>
      'نەمانتوانی بتدۆزینەوە. نیشانەکە بە دەست دابنێ.';

  @override
  String get locationTooVague =>
      'ئەم شوێنە زۆر نادیارە. نیشانەکە بۆ سەر دەرگاکەت بجوڵێنە تا گەیەنەر نەیەتە خەمڵاندن.';

  @override
  String get deliveryLocation => 'شوێنی گەیاندن';

  @override
  String get openInMaps => 'لە نەخشەدا بیکەرەوە';

  @override
  String get noLocationSet => 'هیچ نیشانەیەکی نەخشە لەسەر ئەم داواکارییە نییە';

  @override
  String get approximateFix => 'نزیکەیە — پێش ڕۆیشتن پەیوەندی بکە';

  @override
  String setDeliveryLocationWithPrice(String price) {
    return 'شوێنی گەیاندن دیاری بکە · $price';
  }

  @override
  String get statusPendingPayment => 'چاوەڕێی پارەدان';

  @override
  String get statusPaymentProcessing => 'پارەدان لە پڕۆسێسدایە';

  @override
  String get statusPaymentFailed => 'پارەدان سەرکەوتوو نەبوو';

  @override
  String get statusNeedsPacking => 'نوێ — پێویستی بە پاکەتکردنە';

  @override
  String get statusPacked => 'پاکەت کرا';

  @override
  String get statusWithCourier => 'لای گەیەنەرە';

  @override
  String get statusOutForDelivery => 'چووە بۆ گەیاندن';

  @override
  String get statusDelivered => 'گەیەندرا';

  @override
  String get statusCancelled => 'هەڵوەشێندرایەوە';

  @override
  String get statusRefunded => 'پارە گەڕێندرایەوە';

  @override
  String get sortNewest => 'نوێترین';

  @override
  String get sortPriceLowToHigh => 'نرخ: لە کەم بۆ زۆر';

  @override
  String get sortPriceHighToLow => 'نرخ: لە زۆر بۆ کەم';

  @override
  String get sortTopRated => 'باشترین هەڵسەنگاندن';

  @override
  String get uploadValidating => 'ڤیدیۆکەت دەپشکنین';

  @override
  String get uploadCompressing => 'بچووکی دەکەینەوە';

  @override
  String get uploadPreparing => 'ئامادەکاری';

  @override
  String get uploadUploading => 'بارکردن';

  @override
  String get uploadProcessing => 'پڕۆسێسکردن — دەتوانیت ئەم پەڕەیە جێبهێڵیت';

  @override
  String get uploadPublishing => 'بڵاوکردنەوە';

  @override
  String get uploadDone => 'بڵاو کرایەوە';

  @override
  String ratePromptProduct(String name) {
    return 'ئەم $name چۆنە؟';
  }

  @override
  String ratePromptSeller(String name) {
    return 'کڕین لە $name چۆن بوو؟';
  }

  @override
  String get actionMarkPacked => 'وەک پاکەتکراو نیشانە بکە';

  @override
  String get actionHandedToCourier => 'درا بە گەیەنەر';

  @override
  String get actionOutForDelivery => 'چووە بۆ گەیاندن';

  @override
  String get actionMarkDelivered => 'وەک گەیەندراو نیشانە بکە';

  @override
  String get actionCancelOrder => 'داواکاری هەڵوەشێنەوە';

  @override
  String get errorGeneric => 'شتێک هەڵە بوو. دووبارە هەوڵ بدە.';

  @override
  String get errorNotSignedIn => 'بۆ بەردەوامبوون بچۆ ژوورەوە';

  @override
  String get errorSignInCancelled => 'چوونەژوورەوە هەڵوەشێنرایەوە';

  @override
  String get errorSignInFailed => 'نەتوانرا بچیتە ژوورەوە. دووبارە هەوڵ بدە.';

  @override
  String get errorGuestSessionFailed => 'نەتوانرا وەک میوان دەست پێ بکەیت';

  @override
  String get errorCodeSendFailed => 'نەتوانرا کۆد بنێردرێت. دووبارە هەوڵ بدە.';

  @override
  String errorCodeSendThrottled(int minutes) {
    return 'داوای کۆدی زۆرت کردووە. دوای $minutes خولەک دووبارە هەوڵ بدە.';
  }

  @override
  String get errorCodeIncorrect =>
      'ئەو کۆدە دروست نییە. بپشکنە و دووبارە هەوڵ بدە.';

  @override
  String get errorCodeExpired => 'ئەو کۆدە بەسەرچووە. داوای یەکی نوێ بکە.';

  @override
  String get errorRequestCodeFirst => 'سەرەتا داوای کۆد بکە';

  @override
  String get errorVerificationFailed =>
      'نەتوانرا ژمارەکەت پشتڕاست بکرێتەوە. دووبارە هەوڵ بدە.';

  @override
  String get errorPhoneOnAnotherAccount =>
      'ئەم ژمارەیە پێشتر لەسەر هەژماری تر تۆمارکراوە.';

  @override
  String get errorPhoneLinkFailed =>
      'ئەو ژمارەیە بە هەژمارەکەتەوە نەبەستراوە. دووبارە هەوڵ بدە.';

  @override
  String get errorRecoveryEmailFailed => 'نەتوانرا ئیمەیڵ بنێردرێت';

  @override
  String get errorPromoCheckFailed => 'نەتوانرا ئەو کۆدە بپشکنرێت';

  @override
  String get errorSignInToMessage => 'بۆ ناردنی نامە بچۆ ژوورەوە';

  @override
  String get errorMessageTooLong => 'نامەکە زۆر درێژە';

  @override
  String get errorMessagingTooFast => 'زۆر خێرا نامە دەنێریت';

  @override
  String get errorMessageFailed => 'نامەکە نەنێردرا';

  @override
  String get errorVerifyPhoneToOrder =>
      'بۆ ناردنی ئەم داواکاریە ژمارەی مۆبایلەکەت پشتڕاست بکەوە.';

  @override
  String get errorCheckoutSetupIncomplete =>
      'سەرەتا ڕێکخستنی پارەدان تەواو بکە';

  @override
  String get errorDeliveryLocationRequired => 'سەرەتا شوێنی گەیاندن دیاری بکە';

  @override
  String get errorTooManyAttempts =>
      'هەوڵی زۆر درا. کەمێک چاوەڕێ بکە و دووبارە هەوڵ بدە.';

  @override
  String get errorOrderFailed =>
      'داواکاریەکەت سەرکەوتوو نەبوو. هیچ پارەیەک نەبڕدرا.';

  @override
  String get errorSoldOutDuringCheckout =>
      'شتێک فرۆشرا لە کاتێکدا تۆ پارە دەدەیت. سەیری سەبەتەکەت بکە.';

  @override
  String get errorSignInToComment => 'بۆ لێدوان بچۆ ژوورەوە';

  @override
  String get errorGuestCannotComment =>
      'بۆ بەشداری لە گفتوگۆ هەژمارێک دروست بکە';

  @override
  String get errorCommentTooLong => 'ئەو لێدوانە زۆر درێژە';

  @override
  String get errorCommentsBuyersOnly =>
      'لێدوان لەسەر ئەم ڕیلە تەنها بۆ ئەو کەسانەیە کە شتەکەیان کڕیوە.';

  @override
  String errorCommentingTooFast(int seconds) {
    return 'زۆر خێرا لێدوان دەنێریت. $seconds چرکە چاوەڕێ بکە.';
  }

  @override
  String get errorCommentNotAllowed => 'ناتوانی لەسەر ئەم ڕیلە لێدوان بنێری';

  @override
  String get errorCommentDeleteOwnOnly => 'تەنها دەتوانی لێدوانی خۆت بسڕیتەوە';

  @override
  String get errorCommentPostFailed => 'نەتوانرا لێدوانەکەت بنێردرێت';

  @override
  String get errorDocumentNotPublished =>
      'ئەم دۆکیومێنتە تا ئێستا بڵاو نەکراوەتەوە';

  @override
  String get errorDocumentLoadFailed => 'نەتوانرا دۆکیومێنتەکە باربکرێت';

  @override
  String get errorAcceptanceFailed => 'نەتوانرا ڕەزامەندیەکەت تۆمار بکرێت';

  @override
  String get errorDataExportFailed => 'نەتوانرا داتاکانت ئامادە بکرێن';

  @override
  String get errorProductsLoadFailed => 'نەتوانرا بەرهەمەکان باربکرێن';

  @override
  String get errorSearchFailed => 'گەڕان سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get errorSignInToSaveProducts => 'بۆ پاشەکەوتکردنی بەرهەم بچۆ ژوورەوە';

  @override
  String get errorSignInToReport => 'بۆ ڕاپۆرتکردن بچۆ ژوورەوە';

  @override
  String errorReportThrottled(int seconds) {
    return 'تازە شتێکت ڕاپۆرت کردووە. دوای $seconds چرکە دووبارە هەوڵ بدە.';
  }

  @override
  String get errorReportFailed => 'نەتوانرا ڕاپۆرتەکە بنێردرێت';

  @override
  String get errorChooseAnOutcome => 'ئەنجامێک هەڵبژێرە';

  @override
  String get errorNotAModerator => 'تۆ چاودێر نیت';

  @override
  String get errorReportAlreadyReviewed =>
      'چاودێرێکی تر پێشتر ئەمە پێداچوونەوەی کردووە. ڕیزەکە نوێ بکەوە.';

  @override
  String get errorDecisionFailed => 'نەتوانرا بڕیارەکە تۆمار بکرێت';

  @override
  String get errorNotYourOrder => 'ئەمە داواکاری تۆ نییە';

  @override
  String get errorOrderAlreadyShipped =>
      'ئەم داواکاریە بۆ گەیاندن ڕۆیشتووە و ناتوانرێت هەڵوەشێنرێتەوە. نامە بۆ فرۆشیار بنێرە بۆ چارەسەرکردنی.';

  @override
  String get errorCancelFailed => 'نەتوانرا داواکاریەکە هەڵوەشێنرێتەوە';

  @override
  String get errorSignInToFollow => 'بۆ بەدواداچوون بچۆ ژوورەوە';

  @override
  String get errorCannotFollowYourself => 'ناتوانی بەدوای خۆتدا بچی';

  @override
  String errorFollowThrottled(int seconds) {
    return 'چرکەیەک — دوای $seconds چرکە دووبارە هەوڵ بدە';
  }

  @override
  String get errorSignInToSell => 'بۆ فرۆشتن بچۆ ژوورەوە';

  @override
  String get errorGuestCannotSell => 'میوان ناتوانێت بەرهەم بخاتە ڕوو';

  @override
  String get errorTitleRequired => 'ناوێک بۆ شتەکە دابنێ';

  @override
  String get errorPriceRequired => 'نرخێک لە سەروو سفر دابنێ';

  @override
  String get errorPhotoRequired => 'لانیکەم یەک وێنە زیاد بکە';

  @override
  String errorTooManyPhotos(int max) {
    return 'تا $max وێنە';
  }

  @override
  String errorPhotoTooLarge(int megabytes) {
    return 'یەکێک لەو وێنانە زۆر گەورەیە. هەریەکە لە خوار $megabytes مێگابایت بهێڵە.';
  }

  @override
  String get errorPublishFailed => 'نەتوانرا بەرهەمەکە بڵاو بکرێتەوە';

  @override
  String get errorUploadNeedsConnection =>
      'بۆ بڵاوکردنەوە پێویستت بە پەیوەندییە. ڤیدیۆکەت پاشەکەوت کراوە — کاتێک گەڕایتەوە سەر هێڵ دووبارە هەوڵ بدە.';

  @override
  String get errorVideoStillProcessing =>
      'ڤیدیۆکەت بارکرا بەڵام پرۆسێسکردنی کاتی دەوێت. کاتێک ئامادە بوو لە پرۆفایلەکەتدا دەردەکەوێت.';

  @override
  String get errorPublishThrottled =>
      'بەم دواییە زۆر بڵاوت کردووەتەوە. کەمێک دواتر دووبارە هەوڵ بدە.';

  @override
  String get errorPublishNotAllowed =>
      'هەژمارەکەت ئێستا ناتوانێت بڵاو بکاتەوە.';

  @override
  String get errorUploadFailed => 'بارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get errorReelNotFound => 'ئەو ڕیلە نەدۆزرایەوە';

  @override
  String get errorSignInToLikeReels => 'بۆ بەدڵبوونی ڕیل بچۆ ژوورەوە';

  @override
  String get errorSignInToSaveReels => 'بۆ پاشەکەوتکردنی ڕیل بچۆ ژوورەوە';

  @override
  String get errorSignInToReview => 'بۆ نووسینی پێداچوونەوە بچۆ ژوورەوە';

  @override
  String get errorSignInToRate => 'بۆ هەڵسەنگاندن بچۆ ژوورەوە';

  @override
  String get errorRatingOutOfRange => 'هەڵسەنگاندنێک لە ١ بۆ ٥ هەڵبژێرە';

  @override
  String get errorEditWindowClosed =>
      'ماوەی ٤٨ کاتژمێری دەستکاریکردنی ئەم پێداچوونەوە کۆتایی هاتووە.';

  @override
  String get errorRateAfterDelivery =>
      'کاتێک داواکاریەکە گەیشت دەتوانی هەڵسەنگاندنی بکەیت.';

  @override
  String get errorItemNotInOrder => 'ئەو شتە بەشێک لەم داواکاریە نەبووە.';

  @override
  String get errorRateBuyersOnly =>
      'تەنها ئەو کڕیارانەی ئەم داواکاریەیان پێگەیشتووە دەتوانن هەڵسەنگاندنی بکەن.';

  @override
  String get errorAlreadyRated => 'پێشتر ئەم داواکاریەت هەڵسەنگاندووە.';

  @override
  String get errorReviewSubmitFailed => 'نەتوانرا هەڵسەنگاندنەکەت بنێردرێت';

  @override
  String get errorInvalidStatusTransition =>
      'ئەو داواکاریە ناتوانێت بچێتە ئەم دۆخەوە. ڕابکێشە بۆ نوێکردنەوە.';

  @override
  String get errorBuyerCancelledOrder =>
      'کڕیار ئەم داواکاریە هەڵوەشاندەوە لە کاتێکدا تۆ نوێت دەکردەوە.';

  @override
  String get errorOrderMovedOn =>
      'ئەم داواکاریە پێشتر گوازراوەتەوە. ڕابکێشە بۆ نوێکردنەوە.';

  @override
  String get errorOrderUpdateFailed => 'نەتوانرا داواکاریەکە نوێ بکرێتەوە';

  @override
  String get legalSellerAgreement => 'ڕێککەوتنی فرۆشیار';

  @override
  String get legalContentPolicy => 'سیاسەتی ناوەڕۆکی کۆمەڵگا';

  @override
  String railNotConnectedYet(String method) {
    return '$method تا ئێستا نەبەستراوەتەوە. پارەدان لە کاتی گەیاندن ئەمڕۆ کار دەکات.';
  }

  @override
  String get reviewEdited => 'دەستکاریکراو';

  @override
  String starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ئەستێرە',
      one: '١ ئەستێرە',
    );
    return '$_temp0';
  }

  @override
  String ratingOutOfFive(String rating) {
    return '$rating لە ٥ ئەستێرە';
  }

  @override
  String get unlike => 'لابردنی بەدڵبوون';

  @override
  String get you => 'تۆ';

  @override
  String get someone => 'کەسێک';

  @override
  String get thisSeller => 'ئەم فرۆشیارە';

  @override
  String get untitledReel => 'بێ ناونیشان';

  @override
  String get orderFallbackTitle => 'داواکاری';

  @override
  String andNMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' و $countی تر',
      one: ' و ١ی تر',
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
  String get timeJustNow => 'ئێستا';

  @override
  String timeMinutesShort(int minutes) {
    return '$minutesخ';
  }

  @override
  String timeHoursShort(int hours) {
    return '$hoursک';
  }

  @override
  String timeDaysShort(int days) {
    return '$daysڕ';
  }

  @override
  String timeWeeksShort(int weeks) {
    return '$weeksه';
  }

  @override
  String productCardSemantic(String title, String price) {
    return '$title، $price';
  }

  @override
  String statSemantic(String value, String label) {
    return '$value $label';
  }

  @override
  String get updateSearchStoreManually =>
      'بۆ نوێکردنەوە لە کۆگای ئەپەکەت گەڕان بۆ WAVE بکە.';

  @override
  String get systemDefault => 'بنەڕەتی سیستەم';

  @override
  String get quantityDecrease => 'کەمکردنەوەی بڕ';

  @override
  String get quantityIncrease => 'زیادکردنی بڕ';

  @override
  String get quantityLabel => 'بڕ';

  @override
  String get subtotal => 'کۆی نرخ';

  @override
  String get pdpAddToCart => 'زیادکردن بۆ سەبەتە';

  @override
  String get stockIn => 'لە کۆگا بەردەستە';

  @override
  String get stockOut => 'لە کۆگا نەماوە';

  @override
  String stockLow(int count) {
    return 'تەنها $count دانە ماوە';
  }

  @override
  String get quantityTitle => 'هەڵبژاردنی بڕ';

  @override
  String get pdpDescription => 'دەربارەی ئەم کاڵایە';

  @override
  String get commonBack => 'گەڕانەوە';

  @override
  String get pdpSoldBy => 'فرۆشراوە لەلایەن';

  @override
  String pdpImageGallery(int index, int total) {
    return 'وێنەی $index لە $total';
  }

  @override
  String get cartAddedToCart => 'خرایە سەبەتەوە';

  @override
  String get cartStockLimitReached => 'گەیشتیتە کۆتا سنووری ستۆک';

  @override
  String get cartOutOfStock => 'لە ستۆکدا نەماوە';

  @override
  String get cartPromoApplied => 'کۆدی داشکاندن بەکارهێنرا';

  @override
  String get cartPromoInvalid => 'کۆدی داشکاندن هەڵەیە';

  @override
  String get cartPromoExpired => 'کۆدی داشکاندن بەسەرچووە';

  @override
  String get cartPromoUsed => 'ئەم کۆدە پێشتر بەکارهێنراوە';

  @override
  String get cartPromoBelowMinimum =>
      'نرخی داواکارییەکەت کەمترە لە مەرجی کۆدەکە';

  @override
  String get signInTitle => 'چوونەژوورەوە';

  @override
  String get acceptTerms => 'ڕازیبوونم بە مەرج و ڕێنماییەکان';

  @override
  String get confirmAge => 'تەمەنم سەروو ١٨ ساڵە';

  @override
  String get orContinueWith => 'یان لە ڕێگەی ئەمانەوە بەردەوام بە';

  @override
  String get enterCodeSentToPhone =>
      'ئەو کۆدەی بۆ مۆبایلەکەت نێردراوە لێرە بنووسە';

  @override
  String get verificationCode => 'کۆدی دڵنیابوونەوە';

  @override
  String get verify => 'دڵنیابوونەوە';

  @override
  String get changePhoneNumber => 'گۆڕینی ژمارەی مۆبایل';
}
