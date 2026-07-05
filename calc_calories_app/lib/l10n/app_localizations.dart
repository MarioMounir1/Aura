import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
    Locale('en'),
    Locale('ar')
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'The Teneen'**
  String get appName;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @yesButton.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesButton;

  /// No description provided for @noButton.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to The Teneen'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Egyptian nutrition companion'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings'**
  String get onboardingLanguageSubtitle;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use this to calculate your daily goals'**
  String get onboardingProfileSubtitle;

  /// No description provided for @onboardingBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your measurements'**
  String get onboardingBodyTitle;

  /// No description provided for @onboardingBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us calculate your calorie needs accurately'**
  String get onboardingBodySubtitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your goal?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll set your calorie target accordingly'**
  String get onboardingGoalSubtitle;

  /// No description provided for @onboardingGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get onboardingGoalLose;

  /// No description provided for @onboardingGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Stay the same'**
  String get onboardingGoalMaintain;

  /// No description provided for @onboardingGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get onboardingGoalGain;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get onboardingActivityTitle;

  /// No description provided for @onboardingActivitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get onboardingActivitySedentary;

  /// No description provided for @onboardingActivitySedentaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Little or no exercise'**
  String get onboardingActivitySedentaryDesc;

  /// No description provided for @onboardingActivityLight.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get onboardingActivityLight;

  /// No description provided for @onboardingActivityLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Light exercise 1–3 days/week'**
  String get onboardingActivityLightDesc;

  /// No description provided for @onboardingActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get onboardingActivityModerate;

  /// No description provided for @onboardingActivityModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Moderate exercise 3–5 days/week'**
  String get onboardingActivityModerateDesc;

  /// No description provided for @onboardingActivityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get onboardingActivityVeryActive;

  /// No description provided for @onboardingActivityVeryActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6–7 days/week'**
  String get onboardingActivityVeryActiveDesc;

  /// No description provided for @onboardingAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingAllSet;

  /// No description provided for @onboardingAllSetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily calorie goal is ready'**
  String get onboardingAllSetSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navPlans;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeCaloriesLeft.
  ///
  /// In en, this message translates to:
  /// **'Calories left'**
  String get homeCaloriesLeft;

  /// No description provided for @homeCaloriesConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get homeCaloriesConsumed;

  /// No description provided for @homeCaloriesBurned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get homeCaloriesBurned;

  /// No description provided for @homeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get homeGoal;

  /// No description provided for @homeMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get homeMacros;

  /// No description provided for @homeProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get homeProtein;

  /// No description provided for @homeCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get homeCarbs;

  /// No description provided for @homeFats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get homeFats;

  /// No description provided for @homeFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get homeFiber;

  /// No description provided for @homeWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get homeWater;

  /// No description provided for @homeWaterGoal.
  ///
  /// In en, this message translates to:
  /// **'{consumed}ml of {goal}ml'**
  String homeWaterGoal(int consumed, int goal);

  /// No description provided for @homeTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meal plan'**
  String get homeTodaysPlan;

  /// No description provided for @homeNoMealPlan.
  ///
  /// In en, this message translates to:
  /// **'No meal plan yet'**
  String get homeNoMealPlan;

  /// No description provided for @homeGeneratePlan.
  ///
  /// In en, this message translates to:
  /// **'Generate a plan'**
  String get homeGeneratePlan;

  /// No description provided for @homeLogMeal.
  ///
  /// In en, this message translates to:
  /// **'Log a meal'**
  String get homeLogMeal;

  /// No description provided for @homeRecentMeals.
  ///
  /// In en, this message translates to:
  /// **'Recent meals'**
  String get homeRecentMeals;

  /// No description provided for @homeNoMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'No meals logged today'**
  String get homeNoMealsLogged;

  /// No description provided for @homeAddWater.
  ///
  /// In en, this message translates to:
  /// **'Add water'**
  String get homeAddWater;

  /// No description provided for @foodSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get foodSearchTitle;

  /// No description provided for @foodSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in Arabic or English...'**
  String get foodSearchHint;

  /// No description provided for @foodSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String foodSearchNoResults(String query);

  /// No description provided for @foodSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get foodSearchCategories;

  /// No description provided for @foodServingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving: {size}{unit}'**
  String foodServingSize(double size, String unit);

  /// No description provided for @foodCaloriesPer.
  ///
  /// In en, this message translates to:
  /// **'{cal} kcal'**
  String foodCaloriesPer(double cal);

  /// No description provided for @foodLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log this food'**
  String get foodLogButton;

  /// No description provided for @foodLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Food logged successfully!'**
  String get foodLoggedSuccess;

  /// No description provided for @foodSelectServings.
  ///
  /// In en, this message translates to:
  /// **'How many servings?'**
  String get foodSelectServings;

  /// No description provided for @categoryBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get categoryBreakfast;

  /// No description provided for @categoryLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get categoryLunch;

  /// No description provided for @categoryDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get categoryDinner;

  /// No description provided for @categorySnack.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnack;

  /// No description provided for @categoryDrink.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get categoryDrink;

  /// No description provided for @categoryGrain.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get categoryGrain;

  /// No description provided for @categoryProtein.
  ///
  /// In en, this message translates to:
  /// **'Proteins'**
  String get categoryProtein;

  /// No description provided for @categoryVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetable;

  /// No description provided for @categoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get categoryFruit;

  /// No description provided for @categoryCondiment.
  ///
  /// In en, this message translates to:
  /// **'Condiments'**
  String get categoryCondiment;

  /// No description provided for @mealTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealTypeBreakfast;

  /// No description provided for @mealTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealTypeLunch;

  /// No description provided for @mealTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealTypeDinner;

  /// No description provided for @mealTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealTypeSnack;

  /// No description provided for @mealTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get mealTypeOther;

  /// No description provided for @waterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water intake'**
  String get waterTitle;

  /// No description provided for @waterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get waterToday;

  /// No description provided for @waterGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached! 🎉'**
  String get waterGoalReached;

  /// No description provided for @waterRemainingMl.
  ///
  /// In en, this message translates to:
  /// **'{ml}ml remaining'**
  String waterRemainingMl(int ml);

  /// No description provided for @waterAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get waterAddCustom;

  /// No description provided for @waterDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this water entry?'**
  String get waterDeleteConfirm;

  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight progress'**
  String get weightTitle;

  /// No description provided for @weightLogToday.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s weight'**
  String get weightLogToday;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String weightKg(double kg);

  /// No description provided for @weightDeltaLost.
  ///
  /// In en, this message translates to:
  /// **'Lost {kg}kg'**
  String weightDeltaLost(double kg);

  /// No description provided for @weightDeltaGained.
  ///
  /// In en, this message translates to:
  /// **'Gained {kg}kg'**
  String weightDeltaGained(double kg);

  /// No description provided for @weightStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get weightStable;

  /// No description provided for @weightTrendLosing.
  ///
  /// In en, this message translates to:
  /// **'Losing'**
  String get weightTrendLosing;

  /// No description provided for @weightTrendGaining.
  ///
  /// In en, this message translates to:
  /// **'Gaining'**
  String get weightTrendGaining;

  /// No description provided for @weightTrendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get weightTrendStable;

  /// No description provided for @weightLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get weightLast30Days;

  /// No description provided for @weightNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No weight logged yet'**
  String get weightNoHistory;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get mealPlanTitle;

  /// No description provided for @mealPlanThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get mealPlanThisWeek;

  /// No description provided for @mealPlanGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate plan'**
  String get mealPlanGenerate;

  /// No description provided for @mealPlanGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your plan...'**
  String get mealPlanGenerating;

  /// No description provided for @mealPlanGenerated.
  ///
  /// In en, this message translates to:
  /// **'Plan generated!'**
  String get mealPlanGenerated;

  /// No description provided for @mealPlanNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get mealPlanNoPlan;

  /// No description provided for @mealPlanMarkEaten.
  ///
  /// In en, this message translates to:
  /// **'Mark as eaten'**
  String get mealPlanMarkEaten;

  /// No description provided for @mealPlanMarkNotEaten.
  ///
  /// In en, this message translates to:
  /// **'Mark as not eaten'**
  String get mealPlanMarkNotEaten;

  /// No description provided for @mealPlanEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten ✓'**
  String get mealPlanEaten;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze meal'**
  String get scanTitle;

  /// No description provided for @scanTextTab.
  ///
  /// In en, this message translates to:
  /// **'Describe meal'**
  String get scanTextTab;

  /// No description provided for @scanImageTab.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanImageTab;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. KFC Zinger Medium with Pepsi'**
  String get scanHint;

  /// No description provided for @scanRestaurantHint.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name (optional)'**
  String get scanRestaurantHint;

  /// No description provided for @scanAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal...'**
  String get scanAnalyzing;

  /// No description provided for @scanResult.
  ///
  /// In en, this message translates to:
  /// **'Meal analysis'**
  String get scanResult;

  /// No description provided for @scanLogMeal.
  ///
  /// In en, this message translates to:
  /// **'Log this meal'**
  String get scanLogMeal;

  /// No description provided for @scanLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Meal logged!'**
  String get scanLoggedSuccess;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get profilePersonalInfo;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAge;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profileWeight;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileHeight;

  /// No description provided for @profileGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get profileGoal;

  /// No description provided for @profileActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get profileActivity;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal'**
  String get profileCalorieGoal;

  /// No description provided for @profileWaterGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily water goal (ml)'**
  String get profileWaterGoal;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved!'**
  String get profileSaved;

  /// No description provided for @profileTdee.
  ///
  /// In en, this message translates to:
  /// **'Your TDEE'**
  String get profileTdee;

  /// No description provided for @profileTdeeDesc.
  ///
  /// In en, this message translates to:
  /// **'Total Daily Energy Expenditure'**
  String get profileTdeeDesc;

  /// No description provided for @profileBmr.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get profileBmr;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get profileLogoutConfirm;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegister;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authName;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authLoginSuccess;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get authRegisterSuccess;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authInvalidCredentials;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @suggestionsProteinLow.
  ///
  /// In en, this message translates to:
  /// **'You\'re {grams}g of protein short today'**
  String suggestionsProteinLow(int grams);

  /// No description provided for @suggestionsGetFrom.
  ///
  /// In en, this message translates to:
  /// **'Get it from'**
  String get suggestionsGetFrom;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get unitPiece;

  /// No description provided for @unitCup.
  ///
  /// In en, this message translates to:
  /// **'cup'**
  String get unitCup;

  /// No description provided for @unitTbsp.
  ///
  /// In en, this message translates to:
  /// **'tbsp'**
  String get unitTbsp;

  /// No description provided for @unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
