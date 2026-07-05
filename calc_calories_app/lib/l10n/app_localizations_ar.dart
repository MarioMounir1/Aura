// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'التنين';

  @override
  String get continueButton => 'متابعة';

  @override
  String get saveButton => 'حفظ';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get deleteButton => 'حذف';

  @override
  String get editButton => 'تعديل';

  @override
  String get doneButton => 'تم';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get skipButton => 'تخطي';

  @override
  String get nextButton => 'التالي';

  @override
  String get backButton => 'رجوع';

  @override
  String get yesButton => 'نعم';

  @override
  String get noButton => 'لا';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get addButton => 'إضافة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get errorUnauthorized => 'انتهت الجلسة. من فضلك سجل دخولك مجددًا.';

  @override
  String get noDataYet => 'لا توجد بيانات بعد';

  @override
  String get onboardingWelcomeTitle => 'أهلاً بك في التنين';

  @override
  String get onboardingWelcomeSubtitle => 'رفيقك المصري للتغذية الصحية';

  @override
  String get onboardingLanguageTitle => 'اختر لغتك';

  @override
  String get onboardingLanguageSubtitle => 'يمكنك تغييرها لاحقًا من الإعدادات';

  @override
  String get onboardingProfileTitle => 'أخبرنا عن نفسك';

  @override
  String get onboardingProfileSubtitle =>
      'نستخدم هذه المعلومات لحساب أهدافك اليومية';

  @override
  String get onboardingBodyTitle => 'مقاساتك';

  @override
  String get onboardingBodySubtitle =>
      'تساعدنا على حساب احتياجاتك من السعرات بدقة';

  @override
  String get onboardingGoalTitle => 'ما هو هدفك؟';

  @override
  String get onboardingGoalSubtitle => 'سنحدد هدفك من السعرات وفقًا لذلك';

  @override
  String get onboardingGoalLose => 'إنقاص الوزن';

  @override
  String get onboardingGoalMaintain => 'الحفاظ على الوزن';

  @override
  String get onboardingGoalGain => 'زيادة الوزن';

  @override
  String get onboardingActivityTitle => 'ما مستوى نشاطك؟';

  @override
  String get onboardingActivitySedentary => 'خامل';

  @override
  String get onboardingActivitySedentaryDesc => 'لا يوجد تمرين أو نادرًا';

  @override
  String get onboardingActivityLight => 'نشاط خفيف';

  @override
  String get onboardingActivityLightDesc => 'تمرين خفيف 1–3 أيام في الأسبوع';

  @override
  String get onboardingActivityModerate => 'نشاط متوسط';

  @override
  String get onboardingActivityModerateDesc =>
      'تمرين متوسط 3–5 أيام في الأسبوع';

  @override
  String get onboardingActivityVeryActive => 'نشاط عالي';

  @override
  String get onboardingActivityVeryActiveDesc =>
      'تمرين مكثف 6–7 أيام في الأسبوع';

  @override
  String get onboardingAllSet => 'كل شيء جاهز!';

  @override
  String get onboardingAllSetSubtitle => 'هدفك اليومي من السعرات الحرارية جاهز';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSearch => 'بحث';

  @override
  String get navScan => 'تحليل';

  @override
  String get navPlans => 'خطط';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'مساء الخير';

  @override
  String get homeGreetingEvening => 'مساء النور';

  @override
  String get homeCaloriesLeft => 'سعرات متبقية';

  @override
  String get homeCaloriesConsumed => 'المستهلك';

  @override
  String get homeCaloriesBurned => 'المحروق';

  @override
  String get homeGoal => 'الهدف';

  @override
  String get homeMacros => 'المغذيات';

  @override
  String get homeProtein => 'بروتين';

  @override
  String get homeCarbs => 'كربوهيدرات';

  @override
  String get homeFats => 'دهون';

  @override
  String get homeFiber => 'ألياف';

  @override
  String get homeWater => 'الماء';

  @override
  String homeWaterGoal(int consumed, int goal) {
    return '$consumedمل من $goalمل';
  }

  @override
  String get homeTodaysPlan => 'خطة وجباتك اليوم';

  @override
  String get homeNoMealPlan => 'لا توجد خطة وجبات بعد';

  @override
  String get homeGeneratePlan => 'إنشاء خطة';

  @override
  String get homeLogMeal => 'تسجيل وجبة';

  @override
  String get homeRecentMeals => 'آخر الوجبات';

  @override
  String get homeNoMealsLogged => 'لم يتم تسجيل وجبات اليوم';

  @override
  String get homeAddWater => 'إضافة ماء';

  @override
  String get foodSearchTitle => 'ابحث عن أكل';

  @override
  String get foodSearchHint => 'ابحث بالعربي أو الإنجليزي...';

  @override
  String foodSearchNoResults(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get foodSearchCategories => 'التصنيفات';

  @override
  String foodServingSize(double size, String unit) {
    return 'الحصة: $size$unit';
  }

  @override
  String foodCaloriesPer(double cal) {
    return '$cal سعرة';
  }

  @override
  String get foodLogButton => 'تسجيل هذا الأكل';

  @override
  String get foodLoggedSuccess => 'تم تسجيل الأكل!';

  @override
  String get foodSelectServings => 'كم حصة؟';

  @override
  String get categoryBreakfast => 'فطور';

  @override
  String get categoryLunch => 'غداء';

  @override
  String get categoryDinner => 'عشاء';

  @override
  String get categorySnack => 'وجبات خفيفة';

  @override
  String get categoryDrink => 'مشروبات';

  @override
  String get categoryGrain => 'حبوب ونشويات';

  @override
  String get categoryProtein => 'بروتينات';

  @override
  String get categoryVegetable => 'خضروات';

  @override
  String get categoryFruit => 'فواكه';

  @override
  String get categoryCondiment => 'توابل وزيوت';

  @override
  String get mealTypeBreakfast => 'فطور';

  @override
  String get mealTypeLunch => 'غداء';

  @override
  String get mealTypeDinner => 'عشاء';

  @override
  String get mealTypeSnack => 'خفيفة';

  @override
  String get mealTypeOther => 'أخرى';

  @override
  String get waterTitle => 'شرب الماء';

  @override
  String get waterToday => 'اليوم';

  @override
  String get waterGoalReached => 'وصلت لهدفك اليومي! 🎉';

  @override
  String waterRemainingMl(int ml) {
    return 'متبقي $mlمل';
  }

  @override
  String get waterAddCustom => 'كمية مخصصة';

  @override
  String get waterDeleteConfirm => 'هل تريد حذف هذا الإدخال؟';

  @override
  String get weightTitle => 'تتبع الوزن';

  @override
  String get weightLogToday => 'سجّل وزنك اليوم';

  @override
  String weightKg(double kg) {
    return '$kg كجم';
  }

  @override
  String weightDeltaLost(double kg) {
    return 'فقدت $kgكجم';
  }

  @override
  String weightDeltaGained(double kg) {
    return 'اكتسبت $kgكجم';
  }

  @override
  String get weightStable => 'مستقر';

  @override
  String get weightTrendLosing => 'في تراجع';

  @override
  String get weightTrendGaining => 'في ارتفاع';

  @override
  String get weightTrendStable => 'مستقر';

  @override
  String get weightLast30Days => 'آخر 30 يوم';

  @override
  String get weightNoHistory => 'لم يتم تسجيل وزن بعد';

  @override
  String get mealPlanTitle => 'خطة الوجبات';

  @override
  String get mealPlanThisWeek => 'هذا الأسبوع';

  @override
  String get mealPlanGenerate => 'إنشاء خطة';

  @override
  String get mealPlanGenerating => 'جاري إنشاء خطتك...';

  @override
  String get mealPlanGenerated => 'تم إنشاء الخطة!';

  @override
  String get mealPlanNoPlan => 'لا توجد خطة بعد';

  @override
  String get mealPlanMarkEaten => 'تم تناوله';

  @override
  String get mealPlanMarkNotEaten => 'لم يتم تناوله';

  @override
  String get mealPlanEaten => 'تم ✓';

  @override
  String get scanTitle => 'تحليل الوجبة';

  @override
  String get scanTextTab => 'وصف الوجبة';

  @override
  String get scanImageTab => 'التقاط صورة';

  @override
  String get scanHint => 'مثال: كنتاكي زنجر ميديوم مع بيبسي';

  @override
  String get scanRestaurantHint => 'اسم المطعم (اختياري)';

  @override
  String get scanAnalyzing => 'جاري تحليل وجبتك...';

  @override
  String get scanResult => 'نتيجة التحليل';

  @override
  String get scanLogMeal => 'تسجيل هذه الوجبة';

  @override
  String get scanLoggedSuccess => 'تم تسجيل الوجبة!';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profilePersonalInfo => 'المعلومات الشخصية';

  @override
  String get profileName => 'الاسم';

  @override
  String get profileEmail => 'البريد الإلكتروني';

  @override
  String get profileAge => 'العمر';

  @override
  String get profileGender => 'الجنس';

  @override
  String get profileGenderMale => 'ذكر';

  @override
  String get profileGenderFemale => 'أنثى';

  @override
  String get profileWeight => 'الوزن (كجم)';

  @override
  String get profileHeight => 'الطول (سم)';

  @override
  String get profileGoal => 'الهدف';

  @override
  String get profileActivity => 'مستوى النشاط';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileCalorieGoal => 'هدف السعرات اليومي';

  @override
  String get profileWaterGoal => 'هدف الماء اليومي (مل)';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي!';

  @override
  String get profileTdee => 'معدل حرق السعرات';

  @override
  String get profileTdeeDesc => 'إجمالي استهلاك الطاقة اليومي';

  @override
  String get profileBmr => 'معدل الأيض الأساسي';

  @override
  String get profileLogout => 'تسجيل الخروج';

  @override
  String get profileLogoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authRegister => 'إنشاء حساب';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authName => 'اسمك';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authLoginSuccess => 'مرحبًا بعودتك!';

  @override
  String get authRegisterSuccess => 'تم إنشاء الحساب!';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get suggestionsTitle => 'اقتراحات';

  @override
  String suggestionsProteinLow(int grams) {
    return 'تحتاج $gramsجم بروتين إضافي اليوم';
  }

  @override
  String get suggestionsGetFrom => 'يمكنك الحصول عليه من';

  @override
  String get unitG => 'جم';

  @override
  String get unitMl => 'مل';

  @override
  String get unitPiece => 'حبة';

  @override
  String get unitCup => 'كوب';

  @override
  String get unitTbsp => 'ملعقة';

  @override
  String get unitKcal => 'سعرة';

  @override
  String get dayMonday => 'الاثنين';

  @override
  String get dayTuesday => 'الثلاثاء';

  @override
  String get dayWednesday => 'الأربعاء';

  @override
  String get dayThursday => 'الخميس';

  @override
  String get dayFriday => 'الجمعة';

  @override
  String get daySaturday => 'السبت';

  @override
  String get daySunday => 'الأحد';

  @override
  String get dayToday => 'اليوم';

  @override
  String get dayYesterday => 'أمس';
}
