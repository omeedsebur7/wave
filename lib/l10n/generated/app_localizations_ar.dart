// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'WAVE';

  @override
  String get navReels => 'الريلز';

  @override
  String get navMarketplace => 'السوق';

  @override
  String get navChat => 'الدردشة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get publish => 'نشر';

  @override
  String get buyNow => 'اشترِ الآن';

  @override
  String get makeAnOffer => 'قدّم عرضاً';

  @override
  String get offersComingSoon =>
      'العروض قادمة قريباً. راسل البائع في الوقت الحالي.';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get addedToCart => 'أُضيف إلى السلة';

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get cart => 'السلة';

  @override
  String get checkout => 'إتمام الشراء';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get cartEmptyBody =>
      'اعثر على شيء في السوق، أو شاهد ريلاً واشترِ منه مباشرة.';

  @override
  String get browseTheMarket => 'تصفّح السوق';

  @override
  String get outOfStock => 'نفدت الكمية';

  @override
  String get inStock => 'متوفّر';

  @override
  String get remove => 'إزالة';

  @override
  String get total => 'المجموع';

  @override
  String get totalPaid => 'المبلغ المدفوع';

  @override
  String get orderSummary => 'ملخّص الطلب';

  @override
  String get deliverTo => 'التوصيل إلى';

  @override
  String get payWith => 'الدفع بواسطة';

  @override
  String get change => 'تغيير';

  @override
  String get add => 'إضافة';

  @override
  String lowStockCount(int count) {
    return 'بقي $count فقط';
  }

  @override
  String peopleBought(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اشتراه $count شخصاً',
      one: 'اشتراه شخص واحد',
      zero: 'كن أول من يشتريه',
    );
    return '$_temp0';
  }

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get continueWithApple => 'المتابعة بحساب Apple';

  @override
  String get continueWithPhone => 'المتابعة برقم الهاتف';

  @override
  String get continueAsGuest => 'التصفّح بدون حساب';

  @override
  String get guestExplainer =>
      'يمكنك التصفّح بحرية. الحساب مطلوب للشراء أو النشر أو المراسلة.';

  @override
  String get agreeToTerms => 'أوافق على ';

  @override
  String get andConnector => ' و';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get ageConfirmation => 'عمري ١٣ سنة أو أكثر';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get sendNewCode => 'إرسال رمز جديد';

  @override
  String get verifyAndContinue => 'تأكيد ومتابعة';

  @override
  String get sixDigitCode => 'رمز من ٦ أرقام';

  @override
  String get oneQuickStep => 'خطوة سريعة واحدة';

  @override
  String get phoneGateTitle => 'نحتاج رقم هاتف قبل طلبك الأول';

  @override
  String get phoneGateBody =>
      'به يصل إليك المندوب، وبه نحمي حسابك من الطلبات الاحتيالية. نسأل مرة واحدة فقط — بعدها يصبح الشراء بضغطة واحدة.';

  @override
  String get orderConfirmed => 'تم التأكيد';

  @override
  String get orderOnTheWay => 'في الطريق';

  @override
  String get orderDelivered => 'تم التسليم';

  @override
  String get orderCancelled => 'أُلغي الطلب';

  @override
  String get yourOrders => 'طلباتك';

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد';

  @override
  String get noOrdersBody => 'ما تشتريه يظهر هنا، مع موضعه الحالي.';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get keepIt => 'الإبقاء عليه';

  @override
  String get receipt => 'الإيصال';

  @override
  String get rateThisOrder => 'قيّم هذا الطلب';

  @override
  String get stageConfirmedBody =>
      'استلم البائع طلبك ويجهّزه. يمكنك الإلغاء حتى يغادر.';

  @override
  String get stageOnTheWayBody =>
      'في طريقه إليك. سيتصل المندوب بالرقم المسجّل في حسابك.';

  @override
  String get stageDeliveredBody => 'تم التسليم. بالهناء.';

  @override
  String get trustBronze => 'موثوق برونزي';

  @override
  String get trustSilver => 'موثوق فضي';

  @override
  String get trustGold => 'موثوق ذهبي';

  @override
  String get trustPlatinum => 'الأعلى تقييماً';

  @override
  String get trustVerifiedSeller => 'بائع موثّق';

  @override
  String get trustNewSeller => 'بائع جديد';

  @override
  String get noTrackRecordBody =>
      'لم يُكمل هذا البائع أي طلب بعد، فلا توجد تقييمات يُستند إليها. الدفع عند الاستلام أأمن وسيلة للشراء من شخص جديد.';

  @override
  String get comments => 'التعليقات';

  @override
  String commentsCount(int count) {
    return '$count تعليق';
  }

  @override
  String get addAComment => 'أضف تعليقاً';

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد';

  @override
  String get noCommentsBody =>
      'اسأل عن المقاس أو الحالة أو التوصيل — يستطيع البائع الرد هنا.';

  @override
  String get seller => 'البائع';

  @override
  String get follow => 'متابعة';

  @override
  String get following => 'تتابعه';

  @override
  String get message => 'رسالة';

  @override
  String get report => 'إبلاغ';

  @override
  String get reportSent => 'أُرسل البلاغ';

  @override
  String get share => 'مشاركة';

  @override
  String get save => 'حفظ';

  @override
  String get like => 'إعجاب';

  @override
  String get reviews => 'التقييمات';

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد';

  @override
  String get verifiedPurchase => 'شراء موثّق';

  @override
  String get reviewVerifiedOnly =>
      'يستطيع التقييم فقط من استلم هذا المنتج، لذلك تأتي التقييمات هنا دائماً من طلب حقيقي.';

  @override
  String get editWindowNote => 'يمكنك التعديل خلال ٤٨ ساعة، ثم يُقفل.';

  @override
  String get submitRating => 'إرسال التقييم';

  @override
  String get ratingBad => 'سيّئ';

  @override
  String get ratingNotGreat => 'ليس جيداً';

  @override
  String get ratingFine => 'مقبول';

  @override
  String get ratingGood => 'جيد';

  @override
  String get ratingExcellent => 'ممتاز';

  @override
  String get tapAStar => 'اختر نجمة';

  @override
  String get newReel => 'ريل جديد';

  @override
  String get chooseAVideo => 'اختر فيديو';

  @override
  String get caption => 'الوصف';

  @override
  String get linkAProduct => 'اربط منتجاً';

  @override
  String get linkAProductBody => 'يضيف زر «اشترِ الآن» إلى هذا الريل';

  @override
  String get listAProduct => 'اعرض منتجاً';

  @override
  String get whatIsIt => 'ما هو؟';

  @override
  String get description => 'الوصف';

  @override
  String get price => 'السعر';

  @override
  String get howMany => 'الكمية';

  @override
  String get cover => 'الغلاف';

  @override
  String get listingIsLive => 'أصبح منتجك منشوراً';

  @override
  String get reelIsLive => 'أصبح ريلك منشوراً';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notifOrders => 'تحديثات الطلبات';

  @override
  String get notifOrdersBody => 'تم التأكيد، في الطريق، تم التسليم';

  @override
  String get notifChat => 'الرسائل';

  @override
  String get notifChatBody => 'عند رد مشترٍ أو بائع';

  @override
  String get notifSocial => 'الإعجابات والتعليقات والمتابعات';

  @override
  String get notifSocialBody => 'النشاط على ريلاتك وملفك';

  @override
  String get notifMarketing => 'العروض والإعلانات';

  @override
  String get notifMarketingBody => 'أخبار متفرقة عن WAVE';

  @override
  String get nothingNew => 'لا جديد';

  @override
  String get retry => 'حاول مجدداً';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get errorNoConnectionBody => 'تحقّق من اتصالك وحاول مجدداً.';

  @override
  String get errorDeadLink => 'هذا الرابط لا يؤدي إلى شيء';

  @override
  String get errorDeadLinkBody => 'الصفحة التي اتبعتها غير موجودة أو أُزيلت.';

  @override
  String get searchProductsAndReels => 'ابحث في المنتجات والريلز';

  @override
  String get cancel => 'إلغاء';

  @override
  String get done => 'تم';

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطٍ';

  @override
  String get updateRequiredTitle => 'حدّث WAVE للمتابعة';

  @override
  String get updateRequiredBody =>
      'هذه النسخة لم تعد مدعومة. التحديث يستغرق لحظات، وسلتك وطلباتك بأمان.';

  @override
  String get updateNow => 'حدّث الآن';

  @override
  String get acceptAndContinue => 'أوافق وأتابع';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get browsingAsGuest => 'أنت تتصفّح كضيف';

  @override
  String get guestUpgradeBody =>
      'أنشئ حساباً للشراء والبيع وحفظ المفضّلة ومراسلة البائعين. كل ما في سلتك يأتي معك.';

  @override
  String get createAnAccount => 'أنشئ حساباً';

  @override
  String get favourites => 'المفضّلة';

  @override
  String get savedReels => 'الريلز المحفوظة';

  @override
  String get ordersToFulfil => 'طلبات بانتظار التنفيذ';

  @override
  String get howYouAreDoing => 'كيف تسير أمورك';

  @override
  String get termsAndPolicies => 'الشروط والسياسات';

  @override
  String get downloadYourData => 'نزّل بياناتك';

  @override
  String get preparingYourData => 'نجهّز بياناتك — قد يستغرق ذلك لحظات';

  @override
  String get deleteYourAccount => 'احذف حسابك';

  @override
  String get deleteYourAccountQ => 'حذف حسابك؟';

  @override
  String get deleteAccountBody =>
      'يُحذف نهائياً: ملفك الشخصي وريلاتك ومنتجاتك ومحفوظاتك وعناوينك ووسائل دفعك.\n\nيبقى بدون اسمك: الطلبات المكتملة، والتقييمات والمراجعات التي كتبتها. البائعون يحتاجون سجلات معاملاتهم، وحذف تقييماتك سيغيّر درجاتهم بصمت أمام المشتري التالي.\n\nإن كان هناك شيء في طريقه إليك، تبقى بيانات توصيله حتى يصل — فالمندوب يحمل طردك. وتُمحى خلال يوم من التسليم.\n\nلا يمكن التراجع عن هذا.';

  @override
  String get keepMyAccount => 'الإبقاء على حسابي';

  @override
  String get delete => 'حذف';

  @override
  String get items => 'المنتجات';

  @override
  String orderNumber(String id) {
    return 'طلب #$id';
  }

  @override
  String orderedOn(String date) {
    return 'طُلب في $date';
  }

  @override
  String get orderNotFound => 'لا نستطيع إيجاد ذلك الطلب';

  @override
  String get orderNotFoundBody => 'ربما أُزيل، أو أن الرابط غير صحيح.';

  @override
  String get cancelThisOrder => 'إلغاء هذا الطلب';

  @override
  String get cancelThisOrderQ => 'إلغاء هذا الطلب؟';

  @override
  String get cancelOrderBuyerBody =>
      'يُبلَّغ البائع فوراً ويُعاد أي مبلغ مدفوع. لا يمكن التراجع.';

  @override
  String get howDidItGo => 'كيف كانت التجربة؟';

  @override
  String get ratingHelpsNextBuyer =>
      'تقييمك هو ما يمنح هذا البائع شارته — وما يخبر المشتري التالي إن كان جديراً بالثقة.';

  @override
  String get ratingSubmitted => 'شكراً — سُجّل تقييمك';

  @override
  String get descriptionHint =>
      'المقاس، الحالة، الخامات — كل ما قد يسأل عنه المشتري قبل القرار';

  @override
  String coverPhotoNote(int max) {
    return 'الصورة الأولى هي ما يراه المشترون في الشبكة. حتى $max صور.';
  }

  @override
  String buyersWillSee(String price) {
    return 'سيرى المشترون $price';
  }

  @override
  String get uploadingPhotos => 'جارٍ رفع الصور…';

  @override
  String get makeAReel => 'اصنع ريلاً';

  @override
  String get aboutThisItem => 'عن هذا المنتج';

  @override
  String get shareThisItem => 'شارك هذا المنتج';

  @override
  String get reportThisListing => 'أبلغ عن هذا المنتج';

  @override
  String get productNotFound => 'لا نستطيع إيجاد ذلك المنتج';

  @override
  String get productNotFoundBody => 'ربما نفد أو أزاله البائع.';

  @override
  String get backToTheMarket => 'العودة إلى السوق';

  @override
  String get otherActions => 'إجراءات أخرى';

  @override
  String get buyerCanStillCancel =>
      'يستطيع المشتري الإلغاء حتى تسلّمه إلى مندوب.';

  @override
  String get cancelOrderSellerBody =>
      'يُعاد المبلغ للمشتري ويُبلَّغ فوراً. إلغاء طلبات قبلتها يؤثر على مستوى ثقتك، فلا تفعل ذلك إلا إن كنت عاجزاً فعلاً عن تنفيذه.';

  @override
  String get nothingWaitingOnYou => 'لا شيء بانتظارك';

  @override
  String get nothingWaitingBody => 'الطلبات الجديدة تظهر هنا لحظة الشراء.';

  @override
  String get nothingInTransit => 'لا شيء في الطريق';

  @override
  String get nothingInTransitBody => 'الطلبات التي سلّمتها لمندوب تظهر هنا.';

  @override
  String get noCompletedOrders => 'لا توجد طلبات مكتملة بعد';

  @override
  String get noCompletedOrdersBody => 'الطلبات المسلَّمة والملغاة تُحفظ هنا.';

  @override
  String get filterToDo => 'للتنفيذ';

  @override
  String get filterOnTheWay => 'في الطريق';

  @override
  String get filterCompleted => 'مكتملة';

  @override
  String get soldOut => 'نفد';

  @override
  String get deliveryArrangedNote => 'يُرتَّب التوصيل مع البائع بعد الطلب.';

  @override
  String get cartMultiSellerWarning =>
      'سلتك تحتوي منتجات من أكثر من بائع. اطلبها بشكل منفصل حالياً.';

  @override
  String get cartStockWarning =>
      'نفدت بعض المنتجات أو قلّت عن الكمية التي اخترتها. عدّلها للمتابعة.';

  @override
  String itemsCount(int count) {
    return '$count منتج';
  }

  @override
  String get decreaseQuantity => 'إنقاص الكمية';

  @override
  String get increaseQuantity => 'زيادة الكمية';

  @override
  String get noAddressYet => 'لا يوجد عنوان بعد';

  @override
  String get savedAddress => 'عنوان محفوظ';

  @override
  String get savedPaymentMethod => 'وسيلة دفع محفوظة';

  @override
  String get codAvailableNote => 'الدفع عند الاستلام متاح في منطقتك';

  @override
  String placeOrderWithTotal(String total) {
    return 'إرسال الطلب · $total';
  }

  @override
  String get signInToOrder => 'سجّل الدخول لإرسال هذا الطلب';

  @override
  String get signInToOrderBody =>
      'يستطيع الضيوف التصفّح وملء السلة، لكن الطلب يحتاج حساباً.';

  @override
  String get verifyYourPhone => 'أكّد رقم هاتفك';

  @override
  String get verifyNow => 'أكّد الآن';

  @override
  String get addDeliveryAddress => 'أضف عنوان توصيل';

  @override
  String get addAddressBody => 'يحتاج البائع مكاناً يرسل إليه.';

  @override
  String get addAddress => 'أضف عنواناً';

  @override
  String get chooseHowToPay => 'اختر طريقة الدفع';

  @override
  String get chooseHowToPayBody => 'الدفع عند الاستلام متاح في معظم المناطق.';

  @override
  String get choose => 'اختر';

  @override
  String get newAddress => 'عنوان جديد';

  @override
  String get addANewAddress => 'أضف عنواناً جديداً';

  @override
  String get whoIsReceiving => 'من سيستلمه';

  @override
  String get phoneForCourier => 'هاتف للمندوب';

  @override
  String get city => 'المدينة';

  @override
  String get addressLine => 'الحي، الشارع، البناية';

  @override
  String get landmarkOptional => 'أقرب معلَم (اختياري)';

  @override
  String get landmarkHint => 'مقابل الجامع الأزرق، فوق الصيدلية…';

  @override
  String get landmarkNote =>
      'المندوبون هنا يجدون العنوان عادةً بالمعلَم واتصال هاتفي، لذا يساعد هذا أكثر مما يبدو.';

  @override
  String get saveAddress => 'احفظ العنوان';

  @override
  String get chooseADifferentVideo => 'اختر فيديو مختلفاً';

  @override
  String upToNSeconds(int seconds) {
    return 'حتى $seconds ثانية';
  }

  @override
  String durationOfMax(int actual, int max) {
    return '$actual ثانية من $max';
  }

  @override
  String videoTooLong(int actual, int max) {
    return 'مدة الفيديو $actual ثانية. اقتصّه إلى $max ثانية أو أقل ثم اختره مجدداً.';
  }

  @override
  String get captionHint => 'قل ما هو، ولماذا قد يرغب به أحد';

  @override
  String get removeTheLink => 'أزل الربط';

  @override
  String get linkedProductNote => 'يستطيع المشترون شراءه مباشرة من الريل';

  @override
  String get statsNotLoaded => 'لم تُحمَّل أرقامك';

  @override
  String lastNDays(int days) {
    return 'آخر $days يوماً';
  }

  @override
  String get earned => 'الأرباح';

  @override
  String get orders => 'الطلبات';

  @override
  String get rating => 'التقييم';

  @override
  String get wherePeopleDropOff => 'أين ينسحب الناس';

  @override
  String get funnelExplainer => 'كل خطوة تبيّن كم واصلوا إلى التي تليها.';

  @override
  String get funnelLowSample =>
      'هذه النسب غير موثوقة تحت ١٠٠ مشاهدة تقريباً — اعتبرها إشارة لا حكماً.';

  @override
  String get funnelWatched => 'شاهدوا ريلاً';

  @override
  String get funnelTapped => 'ضغطوا اشترِ الآن';

  @override
  String get funnelCompleted => 'أتمّوا الطلب';

  @override
  String get lowTapThroughNote =>
      'قليلون يضغطون «اشترِ الآن». قد لا يعرض الريل المنتج بوضوح، أو لا يظهر السعر مبكراً بما يكفي.';

  @override
  String get lowCompletionNote =>
      'معظم من يضغط «اشترِ الآن» لا يُكمل. السبب عادةً السعر، أو نفاد الكمية، أو مشترٍ لأول مرة يصل إلى خطوة تأكيد الهاتف.';

  @override
  String get yourReels => 'ريلاتك';

  @override
  String get nothingPublishedYet => 'لم يُنشر شيء بعد.';

  @override
  String get ordersWaitingOne => 'طلب واحد بانتظارك';

  @override
  String ordersWaitingMany(int count) {
    return '$count طلبات بانتظارك';
  }

  @override
  String get open => 'فتح';

  @override
  String viewsAndSold(int views, int sold) {
    return '$views مشاهدة · بيع $sold';
  }

  @override
  String wastedAudienceNote(int views) {
    return 'شاهده $views شخصاً ولم يجدوا ما يشترونه. اربط به منتجاً.';
  }

  @override
  String get reportThis => 'أبلغ عن هذا';

  @override
  String get whatIsWrongWithIt => 'ما الخطأ فيه؟';

  @override
  String get alsoBlockAccount => 'احظر هذا الحساب أيضاً';

  @override
  String get blockExplainer => 'لن ترى منشوراتهم ورسائلهم بعد الآن';

  @override
  String get sendReport => 'إرسال البلاغ';

  @override
  String get reportSentBody =>
      'سيطّلع عليه مشرف. لا نشارك ما يحدث بعد ذلك، ولا يُخبَر المُبلَّغ عنه بهوية المُبلِّغ.';

  @override
  String get reasonSpam => 'إزعاج أو احتيال';

  @override
  String get reasonCounterfeit => 'منتج مقلّد أو موصوف خطأً';

  @override
  String get reasonProhibited => 'منتج محظور';

  @override
  String get reasonHarassment => 'تحرّش أو كراهية';

  @override
  String get reasonSexual => 'محتوى جنسي';

  @override
  String get reasonViolence => 'عنف أو أفعال خطرة';

  @override
  String get reasonIntellectualProperty => 'حقوق نشر أو علامة تجارية';

  @override
  String get reasonOther => 'شيء آخر';

  @override
  String get sellerNotFound => 'لا نستطيع إيجاد ذلك البائع';

  @override
  String get sellerNotFoundBody => 'ربما أُزيل الحساب.';

  @override
  String get reportOrBlock => 'إبلاغ أو حظر';

  @override
  String sellingSince(String date) {
    return 'يبيع منذ $date';
  }

  @override
  String get nothingListedRightNow => 'لا يوجد معروض حالياً.';

  @override
  String get listings => 'المعروضات';

  @override
  String listingsCount(int count) {
    return '$count معروضاً';
  }

  @override
  String get followers => 'متابعين';

  @override
  String ratingsCount(int count) {
    return '$count تقييماً';
  }

  @override
  String get delivered => 'مُسلَّم';

  @override
  String get goToReels => 'اذهب إلى الريلز';

  @override
  String get reelsNotLoaded => 'لم تُحمَّل الريلز';

  @override
  String get noReelsYet => 'لا توجد ريلز بعد';

  @override
  String get noReelsBody => 'كن أول من ينشر واحداً.';

  @override
  String get nothingSavedYet => 'لم يُحفظ شيء بعد';

  @override
  String get savedReelsBody => 'اضغط علامة الحفظ على ريل لتبقيه هنا.';

  @override
  String get watchSomeReels => 'شاهد بعض الريلز';

  @override
  String get favouritesBody => 'اضغط القلب على أي شيء تريد العودة إليه.';

  @override
  String get appTagline => 'شاهد، واشترِ ما تراه.';

  @override
  String get searchProducts => 'ابحث في المنتجات';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get marketEmpty => 'السوق فارغ';

  @override
  String get marketEmptyBody => 'لم يُعرض شيء بعد. كن أول من يبيع.';

  @override
  String get productsNotLoaded => 'لم تُحمَّل المنتجات';

  @override
  String nothingMatched(String query) {
    return 'لا نتائج لـ «$query»';
  }

  @override
  String get searchPrefixNoteProducts =>
      'يطابق البحث بداية اسم المنتج. جرّب كلمة أقصر أو مختلفة.';

  @override
  String get searchPrefixNoteAll =>
      'يطابق البحث بداية الاسم أو الوصف، فجرّب الكلمة الأولى لا كلمة من الوسط.';

  @override
  String get searchHintEmpty => 'ابحث في كل المعروض للبيع وكل ريل.';

  @override
  String get searchHintShort => 'واصل الكتابة — يبدأ البحث من حرفين.';

  @override
  String get products => 'المنتجات';

  @override
  String get reels => 'الريلز';

  @override
  String get shop => 'تسوّق';

  @override
  String get ordersNotLoaded => 'لم تُحمَّل طلباتك';

  @override
  String get receiptTitle => 'إيصال';

  @override
  String receiptDocTitle(String id) {
    return 'إيصال WAVE $id';
  }

  @override
  String get receiptSoldBy => 'البائع';

  @override
  String get receiptBuyer => 'المشتري';

  @override
  String get receiptDeliveredTo => 'سُلّم إلى';

  @override
  String get receiptStatus => 'الحالة';

  @override
  String get receiptItem => 'المنتج';

  @override
  String get receiptQty => 'الكمية';

  @override
  String get receiptUnit => 'سعر الوحدة';

  @override
  String get receiptDisclaimer =>
      'هذا سجل لعملية شراء تمّت عبر WAVE. WAVE سوق إلكتروني؛ والبيع بين المشتري والبائع المذكور أعلاه. وهو ليس فاتورة ضريبية ما لم يصدرها البائع بشكل منفصل.';

  @override
  String get yourWaveData => 'بياناتك في WAVE';

  @override
  String get sellFromThisReel => 'بِع من هذا الريل';

  @override
  String get sellFromThisReelBody =>
      'اختر أحد معروضاتك. يحصل المشترون على زر «اشترِ الآن» دون مغادرة الفيديو.';

  @override
  String get nothingListedYet => 'لم تعرض شيئاً بعد.';

  @override
  String get listAProductFirst => 'اعرض منتجاً أولاً';

  @override
  String get uploadAReel => 'ارفع ريلاً';

  @override
  String get uploadAReelBody => 'حتى ٦٠ ثانية. اربط منتجاً لتبيع منه.';

  @override
  String get listAProductBody => 'أضف الصور والسعر والكمية.';

  @override
  String versionUpdated(String version, String date) {
    return 'الإصدار $version · حُدّث في $date';
  }

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String get copied => 'نُسخ';

  @override
  String get copy => 'نسخ';

  @override
  String get documentNotLoaded => 'لم تُحمَّل تلك الوثيقة';

  @override
  String get beforeYouStart => 'قبل أن تبدأ';

  @override
  String get termsChanged => 'تغيّرت شروطنا';

  @override
  String documentChanged(String title) {
    return 'تغيّرت $title';
  }

  @override
  String get acceptToUse => 'يُرجى قراءة هذه والموافقة عليها لاستخدام WAVE.';

  @override
  String get readWhatChanged => 'يُرجى قراءة ما تغيّر قبل المتابعة.';

  @override
  String get addANote => 'أضف ملاحظة (اختياري)';

  @override
  String reviewsCount(int count) {
    return '$count تقييماً';
  }

  @override
  String get noMessagesYet => 'لا رسائل بعد';

  @override
  String get noMessagesBody => 'عندما تراسل بائعاً عن منتج، تظهر المحادثة هنا.';

  @override
  String get aboutAListing => 'بخصوص معروض';

  @override
  String get view => 'عرض';

  @override
  String get chatEmptyPrompt =>
      'اسأل عن المقاس أو الحالة أو التوصيل — كل ما تحتاج معرفته قبل الشراء.';

  @override
  String get send => 'إرسال';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationsNotLoaded => 'لم تُحمَّل الإشعارات';

  @override
  String get nothingNewBody =>
      'تحديثات الطلبات والردود والنشاط على منشوراتك تظهر هنا.';

  @override
  String get notifOrdersOffWarning =>
      'إيقاف تحديثات الطلبات يعني أننا لن نخبرك عندما يكون ما اشتريته في الطريق.';

  @override
  String get howDoYouWantToPay => 'كيف تريد الدفع؟';

  @override
  String addPaymentMethod(String method) {
    return 'أضف $method';
  }

  @override
  String get cardDetailsNote =>
      'بيانات البطاقة محفوظة لدى مزوّد الدفع، وليس لدى WAVE إطلاقاً.';

  @override
  String get railCashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get railCashOnDeliveryBody => 'ادفع للمندوب عند الوصول';

  @override
  String get railMobileWallet => 'محفظة إلكترونية';

  @override
  String get railCard => 'بطاقة';

  @override
  String get railBankCard => 'بطاقة بنكية';

  @override
  String get railBankCardBody => 'Visa أو Mastercard';

  @override
  String get lowStockShort => 'بقي القليل فقط';

  @override
  String get phoneGateShortNote =>
      'نسأل مرة واحدة. يُستخدم رقمك لتحديثات التوصيل ولحماية حسابك — بعدها يصبح الشراء بضغطة واحدة.';

  @override
  String get promoApplied => 'طُبّق الرمز. يُؤكَّد الخصم عند إتمام الشراء.';

  @override
  String get stockLimitReached => 'هذه كل الكمية المتوفرة';

  @override
  String get postComment => 'انشر التعليق';

  @override
  String get onboardingTitle1 => 'شاهد. اضغط. امتلكه.';

  @override
  String get onboardingBody1 =>
      'كل ريل يمكن أن يكون متجراً. إن أعجبك ما ترى، اشترِه دون مغادرة الفيديو.';

  @override
  String get onboardingTitle2 => 'اعرف ممّن تشتري';

  @override
  String get onboardingBody2 =>
      'يكسب البائعون شاراتهم من طلبات حقيقية مُسلَّمة — لا مما يقولونه عن أنفسهم.';

  @override
  String get onboardingTitle3 => 'بِع ما تصنعه';

  @override
  String get onboardingBody3 =>
      'انشر ريلاً، اربط منتجاً، واقبض. عندما يُباع شيء نخبرك فوراً — ويمكنك إيقاف ذلك متى شئت.';

  @override
  String get startBrowsing => 'ابدأ التصفّح';

  @override
  String stepOfTotal(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String orderStatusSemantic(String status, int step) {
    return 'حالة الطلب: $status، الخطوة $step من ٣';
  }

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutQ => 'تسجيل الخروج؟';

  @override
  String get signOutBody =>
      'لن تصلك إشعارات على هذا الجهاز، ولن يرى طلباتك من يستخدمه بعدك.';

  @override
  String get promoCode => 'رمز الخصم';

  @override
  String get promoCodeHint => 'لديك رمز؟';

  @override
  String get apply => 'تطبيق';

  @override
  String get discount => 'الخصم';

  @override
  String get promoInvalid => 'هذا الرمز غير صالح';

  @override
  String get promoExpired => 'انتهت صلاحية هذا الرمز';

  @override
  String get promoUsed => 'استخدمت هذا الرمز من قبل';

  @override
  String get mediaAccessRationale =>
      'يحتاج WAVE الوصول إلى مقاطعك لتختار واحداً للنشر. لا نرى سوى الفيديو الذي تختاره.';

  @override
  String get stageCancelledBody =>
      'أُلغي هذا الطلب. أي مبلغ مدفوع يُعاد إلى وسيلة الدفع نفسها.';

  @override
  String get shareThisReel => 'شارك هذا الريل';

  @override
  String get reportThisReel => 'أبلغ عن هذا الريل';

  @override
  String get accountSuspended => 'حسابك موقوف';

  @override
  String get accountSuspendedBody =>
      'لا يزال بإمكانك رؤية طلباتك وقراءة سياسة المحتوى، لكن لا يمكنك النشر أو البيع أو التعليق أو المراسلة أثناء الإيقاف.';

  @override
  String get readContentPolicy => 'اقرأ سياسة المحتوى';

  @override
  String get recoverAccount => 'استعادة حسابك';

  @override
  String get recoverByPhone => 'باستخدام رقم هاتفك';

  @override
  String get recoverByPhoneBody =>
      'سنرسل رمزاً إلى الرقم المسجّل في الحساب. بإدخاله تعود إلى حسابك.';

  @override
  String get recoverByEmail => 'باستخدام بريدك';

  @override
  String get recoverByEmailBody =>
      'إن سجّلت بحساب Google أو Apple ولم يعد لديك ذلك الهاتف، استخدم البريد المسجّل في الحساب بدلاً منه.';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get sendRecoveryEmail => 'أرسل بريد استعادة';

  @override
  String get recoveryEmailSent =>
      'إن كان لذلك العنوان حساب، فبريد الاستعادة في طريقه.';

  @override
  String get forgotAccess => 'فقدت الوصول إلى حسابك؟';

  @override
  String get offlineBannerBody =>
      'أنت غير متصل. ما تفعله الآن محفوظ وسيُزامَن عند عودة الاتصال.';

  @override
  String get stagePendingPaymentBody =>
      'بانتظار إتمام الدفع. يرى البائع هذا الطلب بمجرد أن يتم — عادةً خلال دقيقة.';

  @override
  String get stagePaymentFailedBody =>
      'لم يتم الدفع، لذلك لم يُرسل هذا الطلب إلى البائع. ولم يُخصم أي مبلغ.';

  @override
  String get paymentPending => 'بانتظار الدفع';

  @override
  String get promoBelowMinimum => 'يحتاج هذا الرمز إلى طلب أكبر';

  @override
  String get promoTooManyAttempts => 'محاولات كثيرة للرمز. حاول لاحقاً.';

  @override
  String buyNowWithPrice(String price) {
    return 'اشترِ الآن · $price';
  }

  @override
  String get setDeliveryLocation => 'حدّد موقع التوصيل';

  @override
  String get dragMapToSetPin => 'حرّك الخريطة لتضع الدبوس على بابك.';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String confirmAndBuy(String price) {
    return 'أكّد واشترِ · $price';
  }

  @override
  String get deliveryNote => 'معلَم أو إرشادات';

  @override
  String get deliveryNoteHint => 'بوابة زرقاء، الطابق الثاني، مقابل الصيدلية…';

  @override
  String get deliveryNoteWhy =>
      'يجد المندوبون هنا الباب عادةً بالمعلَم واتصال هاتفي، لذا يساعد هذا أكثر من الدبوس.';

  @override
  String get locationPermissionDenied => 'الموقع مغلق، لذا ضع الدبوس يدوياً.';

  @override
  String get locationUnavailable => 'تعذّر تحديد موقعك. ضع الدبوس يدوياً.';

  @override
  String get locationTooVague =>
      'هذا التحديد تقريبي جداً. حرّك الدبوس إلى بابك حتى لا يخمّن المندوب.';

  @override
  String get deliveryLocation => 'موقع التسليم';

  @override
  String get openInMaps => 'افتح في الخرائط';

  @override
  String get noLocationSet => 'لا يوجد دبوس خريطة على هذا الطلب';

  @override
  String get approximateFix => 'تقريبي — اتصل قبل الانطلاق';

  @override
  String setDeliveryLocationWithPrice(String price) {
    return 'حدّد موقع التوصيل · $price';
  }

  @override
  String get statusPendingPayment => 'بانتظار الدفع';

  @override
  String get statusPaymentProcessing => 'جارٍ معالجة الدفع';

  @override
  String get statusPaymentFailed => 'فشل الدفع';

  @override
  String get statusNeedsPacking => 'جديد — يحتاج تجهيزاً';

  @override
  String get statusPacked => 'تم التجهيز';

  @override
  String get statusWithCourier => 'مع المندوب';

  @override
  String get statusOutForDelivery => 'خرج للتوصيل';

  @override
  String get statusDelivered => 'تم التسليم';

  @override
  String get statusCancelled => 'أُلغي';

  @override
  String get statusRefunded => 'أُعيد المبلغ';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get sortPriceLowToHigh => 'السعر: من الأقل للأعلى';

  @override
  String get sortPriceHighToLow => 'السعر: من الأعلى للأقل';

  @override
  String get sortTopRated => 'الأعلى تقييماً';

  @override
  String get uploadValidating => 'نتحقّق من الفيديو';

  @override
  String get uploadCompressing => 'نضغط الحجم';

  @override
  String get uploadPreparing => 'جارٍ التحضير';

  @override
  String get uploadUploading => 'جارٍ الرفع';

  @override
  String get uploadProcessing => 'جارٍ المعالجة — يمكنك مغادرة هذه الشاشة';

  @override
  String get uploadPublishing => 'جارٍ النشر';

  @override
  String get uploadDone => 'تم النشر';

  @override
  String ratePromptProduct(String name) {
    return 'كيف هو $name؟';
  }

  @override
  String ratePromptSeller(String name) {
    return 'كيف كانت تجربة الشراء من $name؟';
  }

  @override
  String get actionMarkPacked => 'تحديد كمُجهَّز';

  @override
  String get actionHandedToCourier => 'سُلّم للمندوب';

  @override
  String get actionOutForDelivery => 'خرج للتوصيل';

  @override
  String get actionMarkDelivered => 'تحديد كمُسلَّم';

  @override
  String get actionCancelOrder => 'إلغاء الطلب';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorNotSignedIn => 'سجّل الدخول للمتابعة';

  @override
  String get errorSignInCancelled => 'تم إلغاء تسجيل الدخول';

  @override
  String get errorSignInFailed => 'لم نتمكن من تسجيل دخولك. حاول مرة أخرى.';

  @override
  String get errorGuestSessionFailed => 'لم نتمكن من بدء جلسة زائر';

  @override
  String get errorCodeSendFailed => 'لم نتمكن من إرسال الرمز. حاول مرة أخرى.';

  @override
  String errorCodeSendThrottled(int minutes) {
    return 'طلبت رموزاً كثيرة. حاول مرة أخرى بعد $minutes دقيقة.';
  }

  @override
  String get errorCodeIncorrect => 'هذا الرمز غير صحيح. تحقق وأعد المحاولة.';

  @override
  String get errorCodeExpired => 'انتهت صلاحية هذا الرمز. اطلب رمزاً جديداً.';

  @override
  String get errorRequestCodeFirst => 'اطلب رمزاً أولاً';

  @override
  String get errorVerificationFailed =>
      'لم نتمكن من التحقق من رقمك. حاول مرة أخرى.';

  @override
  String get errorPhoneOnAnotherAccount =>
      'هذا الرقم مسجَّل بالفعل على حساب آخر.';

  @override
  String get errorPhoneLinkFailed =>
      'لم يُربط هذا الرقم بحسابك. حاول مرة أخرى.';

  @override
  String get errorRecoveryEmailFailed => 'لم نتمكن من إرسال البريد الإلكتروني';

  @override
  String get errorPromoCheckFailed => 'لم نتمكن من التحقق من هذا الرمز';

  @override
  String get errorSignInToMessage => 'سجّل الدخول لإرسال الرسائل';

  @override
  String get errorMessageTooLong => 'الرسالة طويلة جداً';

  @override
  String get errorMessagingTooFast => 'ترسل الرسائل بسرعة كبيرة';

  @override
  String get errorMessageFailed => 'تعذّر إرسال الرسالة';

  @override
  String get errorVerifyPhoneToOrder => 'وثّق رقم هاتفك لإتمام هذا الطلب.';

  @override
  String get errorCheckoutSetupIncomplete => 'أكمل إعداد الدفع أولاً';

  @override
  String get errorDeliveryLocationRequired => 'حدّد موقع التوصيل أولاً';

  @override
  String get errorTooManyAttempts =>
      'محاولات كثيرة. انتظر قليلاً وأعد المحاولة.';

  @override
  String get errorOrderFailed => 'لم يكتمل طلبك. لم يُخصم أي مبلغ.';

  @override
  String get errorSoldOutDuringCheckout =>
      'نُفد أحد العناصر أثناء إتمامك للدفع. راجع سلتك.';

  @override
  String get errorSignInToComment => 'سجّل الدخول للتعليق';

  @override
  String get errorGuestCannotComment => 'أنشئ حساباً للمشاركة في المحادثة';

  @override
  String get errorCommentTooLong => 'هذا التعليق طويل جداً';

  @override
  String get errorCommentsBuyersOnly =>
      'التعليقات على هذا المقطع مخصّصة لمن اشترى العنصر.';

  @override
  String errorCommentingTooFast(int seconds) {
    return 'تعلّق بسرعة كبيرة. انتظر $seconds ثانية.';
  }

  @override
  String get errorCommentNotAllowed => 'لا يمكنك التعليق على هذا المقطع';

  @override
  String get errorCommentDeleteOwnOnly => 'يمكنك حذف تعليقاتك فقط';

  @override
  String get errorCommentPostFailed => 'لم نتمكن من نشر تعليقك';

  @override
  String get errorDocumentNotPublished => 'لم يُنشر هذا المستند بعد';

  @override
  String get errorDocumentLoadFailed => 'لم نتمكن من تحميل المستند';

  @override
  String get errorAcceptanceFailed => 'لم نتمكن من تسجيل موافقتك';

  @override
  String get errorDataExportFailed => 'لم نتمكن من تحضير بياناتك';

  @override
  String get errorProductsLoadFailed => 'لم نتمكن من تحميل المنتجات';

  @override
  String get errorSearchFailed => 'فشل البحث. حاول مرة أخرى.';

  @override
  String get errorSignInToSaveProducts => 'سجّل الدخول لحفظ المنتجات';

  @override
  String get errorSignInToReport => 'سجّل الدخول للإبلاغ';

  @override
  String errorReportThrottled(int seconds) {
    return 'أبلغت عن شيء قبل قليل. حاول مرة أخرى بعد $seconds ثانية.';
  }

  @override
  String get errorReportFailed => 'لم نتمكن من إرسال البلاغ';

  @override
  String get errorChooseAnOutcome => 'اختر نتيجة';

  @override
  String get errorNotAModerator => 'أنت لست مشرفاً';

  @override
  String get errorReportAlreadyReviewed =>
      'راجع هذا مشرف آخر قبلك. حدّث القائمة.';

  @override
  String get errorDecisionFailed => 'لم نتمكن من تسجيل القرار';

  @override
  String get errorNotYourOrder => 'هذا ليس طلبك';

  @override
  String get errorOrderAlreadyShipped =>
      'خرج هذا الطلب للتوصيل ولم يعد بالإمكان إلغاؤه. راسل البائع لتسوية الأمر.';

  @override
  String get errorCancelFailed => 'لم نتمكن من إلغاء الطلب';

  @override
  String get errorSignInToFollow => 'سجّل الدخول للمتابعة';

  @override
  String get errorCannotFollowYourself => 'لا يمكنك متابعة نفسك';

  @override
  String errorFollowThrottled(int seconds) {
    return 'لحظة — حاول مرة أخرى بعد $seconds ثانية';
  }

  @override
  String get errorSignInToSell => 'سجّل الدخول للبيع';

  @override
  String get errorGuestCannotSell => 'لا يمكن للزائر عرض منتجات';

  @override
  String get errorTitleRequired => 'أعطِ العنصر اسماً';

  @override
  String get errorPriceRequired => 'حدّد سعراً أكبر من صفر';

  @override
  String get errorPhotoRequired => 'أضف صورة واحدة على الأقل';

  @override
  String errorTooManyPhotos(int max) {
    return 'حتى $max صورة';
  }

  @override
  String errorPhotoTooLarge(int megabytes) {
    return 'إحدى تلك الصور كبيرة جداً. اجعل كل صورة أقل من $megabytes ميغابايت.';
  }

  @override
  String get errorPublishFailed => 'لم نتمكن من نشر العرض';

  @override
  String get errorUploadNeedsConnection =>
      'تحتاج إلى اتصال للنشر. تم حفظ الفيديو — حاول مرة أخرى عند عودة الاتصال.';

  @override
  String get errorVideoStillProcessing =>
      'تم رفع الفيديو لكن معالجته تستغرق وقتاً. سيظهر في ملفك الشخصي عند جهوزه.';

  @override
  String get errorPublishThrottled =>
      'نشرت الكثير مؤخراً. حاول مرة أخرى بعد قليل.';

  @override
  String get errorPublishNotAllowed => 'لا يمكن لحسابك النشر حالياً.';

  @override
  String get errorUploadFailed => 'فشل الرفع. حاول مرة أخرى.';

  @override
  String get errorReelNotFound => 'لم نجد هذا المقطع';

  @override
  String get errorSignInToLikeReels => 'سجّل الدخول للإعجاب بالمقاطع';

  @override
  String get errorSignInToSaveReels => 'سجّل الدخول لحفظ المقاطع';

  @override
  String get errorSignInToReview => 'سجّل الدخول لكتابة مراجعة';

  @override
  String get errorSignInToRate => 'سجّل الدخول للتقييم';

  @override
  String get errorRatingOutOfRange => 'اختر تقييماً من ١ إلى ٥';

  @override
  String get errorEditWindowClosed =>
      'انتهت مدة الـ٤٨ ساعة المتاحة لتعديل هذه المراجعة.';

  @override
  String get errorRateAfterDelivery => 'يمكنك التقييم بعد تسليم الطلب.';

  @override
  String get errorItemNotInOrder => 'هذا العنصر لم يكن جزءاً من هذا الطلب.';

  @override
  String get errorRateBuyersOnly =>
      'يمكن للمشترين الذين استلموا هذا الطلب فقط تقييمه.';

  @override
  String get errorAlreadyRated => 'لقد قيّمت هذا الطلب بالفعل.';

  @override
  String get errorReviewSubmitFailed => 'لم نتمكن من إرسال تقييمك';

  @override
  String get errorInvalidStatusTransition =>
      'لا يمكن نقل هذا الطلب إلى هذه الحالة. اسحب للتحديث.';

  @override
  String get errorBuyerCancelledOrder =>
      'ألغى المشتري هذا الطلب أثناء تحديثك له.';

  @override
  String get errorOrderMovedOn => 'انتقل هذا الطلب بالفعل. اسحب للتحديث.';

  @override
  String get errorOrderUpdateFailed => 'لم نتمكن من تحديث الطلب';

  @override
  String get legalSellerAgreement => 'اتفاقية البائع';

  @override
  String get legalContentPolicy => 'سياسة محتوى المجتمع';

  @override
  String railNotConnectedYet(String method) {
    return '$method غير مُفعَّل بعد. الدفع عند التسليم متاح اليوم.';
  }

  @override
  String get reviewEdited => 'مُعدَّل';

  @override
  String starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجوم',
      one: 'نجمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String ratingOutOfFive(String rating) {
    return '$rating من ٥ نجوم';
  }

  @override
  String get unlike => 'إلغاء الإعجاب';

  @override
  String get you => 'أنت';

  @override
  String get someone => 'شخص ما';

  @override
  String get thisSeller => 'هذا البائع';

  @override
  String get untitledReel => 'بلا عنوان';

  @override
  String get orderFallbackTitle => 'طلب';

  @override
  String andNMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' و$count عناصر أخرى',
      one: ' وعنصر آخر',
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
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesShort(int minutes) {
    return '$minutesد';
  }

  @override
  String timeHoursShort(int hours) {
    return '$hoursس';
  }

  @override
  String timeDaysShort(int days) {
    return '$daysي';
  }

  @override
  String timeWeeksShort(int weeks) {
    return '$weeksأ';
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
      'ابحث عن WAVE في متجر التطبيقات للتحديث.';

  @override
  String get systemDefault => 'الإعداد الافتراضي للنظام';
}
