// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'The Teneen';

  @override
  String get continueButton => 'Continue';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get doneButton => 'Done';

  @override
  String get retryButton => 'Retry';

  @override
  String get skipButton => 'Skip';

  @override
  String get nextButton => 'Next';

  @override
  String get backButton => 'Back';

  @override
  String get yesButton => 'Yes';

  @override
  String get noButton => 'No';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get addButton => 'Add';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorUnauthorized => 'Session expired. Please log in again.';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get onboardingWelcomeTitle => 'Welcome to The Teneen';

  @override
  String get onboardingWelcomeSubtitle => 'Your Egyptian nutrition companion';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageSubtitle =>
      'You can change this later in settings';

  @override
  String get onboardingProfileTitle => 'Tell us about yourself';

  @override
  String get onboardingProfileSubtitle =>
      'We use this to calculate your daily goals';

  @override
  String get onboardingBodyTitle => 'Your measurements';

  @override
  String get onboardingBodySubtitle =>
      'Helps us calculate your calorie needs accurately';

  @override
  String get onboardingGoalTitle => 'What is your goal?';

  @override
  String get onboardingGoalSubtitle =>
      'We\'ll set your calorie target accordingly';

  @override
  String get onboardingGoalLose => 'Lose weight';

  @override
  String get onboardingGoalMaintain => 'Stay the same';

  @override
  String get onboardingGoalGain => 'Gain weight';

  @override
  String get onboardingActivityTitle => 'How active are you?';

  @override
  String get onboardingActivitySedentary => 'Sedentary';

  @override
  String get onboardingActivitySedentaryDesc => 'Little or no exercise';

  @override
  String get onboardingActivityLight => 'Lightly active';

  @override
  String get onboardingActivityLightDesc => 'Light exercise 1–3 days/week';

  @override
  String get onboardingActivityModerate => 'Moderately active';

  @override
  String get onboardingActivityModerateDesc =>
      'Moderate exercise 3–5 days/week';

  @override
  String get onboardingActivityVeryActive => 'Very active';

  @override
  String get onboardingActivityVeryActiveDesc => 'Hard exercise 6–7 days/week';

  @override
  String get onboardingAllSet => 'You\'re all set!';

  @override
  String get onboardingAllSetSubtitle => 'Your daily calorie goal is ready';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navScan => 'Scan';

  @override
  String get navPlans => 'Plans';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeCaloriesLeft => 'Calories left';

  @override
  String get homeCaloriesConsumed => 'Consumed';

  @override
  String get homeCaloriesBurned => 'Burned';

  @override
  String get homeGoal => 'Goal';

  @override
  String get homeMacros => 'Macros';

  @override
  String get homeProtein => 'Protein';

  @override
  String get homeCarbs => 'Carbs';

  @override
  String get homeFats => 'Fats';

  @override
  String get homeFiber => 'Fiber';

  @override
  String get homeWater => 'Water';

  @override
  String homeWaterGoal(int consumed, int goal) {
    return '${consumed}ml of ${goal}ml';
  }

  @override
  String get homeTodaysPlan => 'Today\'s meal plan';

  @override
  String get homeNoMealPlan => 'No meal plan yet';

  @override
  String get homeGeneratePlan => 'Generate a plan';

  @override
  String get homeLogMeal => 'Log a meal';

  @override
  String get homeRecentMeals => 'Recent meals';

  @override
  String get homeNoMealsLogged => 'No meals logged today';

  @override
  String get homeAddWater => 'Add water';

  @override
  String get foodSearchTitle => 'Search foods';

  @override
  String get foodSearchHint => 'Search in Arabic or English...';

  @override
  String foodSearchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get foodSearchCategories => 'Categories';

  @override
  String foodServingSize(double size, String unit) {
    return 'Serving: $size$unit';
  }

  @override
  String foodCaloriesPer(double cal) {
    return '$cal kcal';
  }

  @override
  String get foodLogButton => 'Log this food';

  @override
  String get foodLoggedSuccess => 'Food logged successfully!';

  @override
  String get foodSelectServings => 'How many servings?';

  @override
  String get categoryBreakfast => 'Breakfast';

  @override
  String get categoryLunch => 'Lunch';

  @override
  String get categoryDinner => 'Dinner';

  @override
  String get categorySnack => 'Snacks';

  @override
  String get categoryDrink => 'Drinks';

  @override
  String get categoryGrain => 'Grains';

  @override
  String get categoryProtein => 'Proteins';

  @override
  String get categoryVegetable => 'Vegetables';

  @override
  String get categoryFruit => 'Fruits';

  @override
  String get categoryCondiment => 'Condiments';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get mealTypeOther => 'Other';

  @override
  String get waterTitle => 'Water intake';

  @override
  String get waterToday => 'Today';

  @override
  String get waterGoalReached => 'Daily goal reached! 🎉';

  @override
  String waterRemainingMl(int ml) {
    return '${ml}ml remaining';
  }

  @override
  String get waterAddCustom => 'Custom amount';

  @override
  String get waterDeleteConfirm => 'Remove this water entry?';

  @override
  String get weightTitle => 'Weight progress';

  @override
  String get weightLogToday => 'Log today\'s weight';

  @override
  String weightKg(double kg) {
    return '$kg kg';
  }

  @override
  String weightDeltaLost(double kg) {
    return 'Lost ${kg}kg';
  }

  @override
  String weightDeltaGained(double kg) {
    return 'Gained ${kg}kg';
  }

  @override
  String get weightStable => 'Stable';

  @override
  String get weightTrendLosing => 'Losing';

  @override
  String get weightTrendGaining => 'Gaining';

  @override
  String get weightTrendStable => 'Stable';

  @override
  String get weightLast30Days => 'Last 30 days';

  @override
  String get weightNoHistory => 'No weight logged yet';

  @override
  String get mealPlanTitle => 'Meal plan';

  @override
  String get mealPlanThisWeek => 'This week';

  @override
  String get mealPlanGenerate => 'Generate plan';

  @override
  String get mealPlanGenerating => 'Generating your plan...';

  @override
  String get mealPlanGenerated => 'Plan generated!';

  @override
  String get mealPlanNoPlan => 'No plan yet';

  @override
  String get mealPlanMarkEaten => 'Mark as eaten';

  @override
  String get mealPlanMarkNotEaten => 'Mark as not eaten';

  @override
  String get mealPlanEaten => 'Eaten ✓';

  @override
  String get scanTitle => 'Analyze meal';

  @override
  String get scanTextTab => 'Describe meal';

  @override
  String get scanImageTab => 'Take photo';

  @override
  String get scanHint => 'e.g. KFC Zinger Medium with Pepsi';

  @override
  String get scanRestaurantHint => 'Restaurant name (optional)';

  @override
  String get scanAnalyzing => 'Analyzing your meal...';

  @override
  String get scanResult => 'Meal analysis';

  @override
  String get scanLogMeal => 'Log this meal';

  @override
  String get scanLoggedSuccess => 'Meal logged!';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePersonalInfo => 'Personal info';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileAge => 'Age';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileWeight => 'Weight (kg)';

  @override
  String get profileHeight => 'Height (cm)';

  @override
  String get profileGoal => 'Goal';

  @override
  String get profileActivity => 'Activity level';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileCalorieGoal => 'Daily calorie goal';

  @override
  String get profileWaterGoal => 'Daily water goal (ml)';

  @override
  String get profileSaved => 'Profile saved!';

  @override
  String get profileTdee => 'Your TDEE';

  @override
  String get profileTdeeDesc => 'Total Daily Energy Expenditure';

  @override
  String get profileBmr => 'BMR';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authEmail => 'Email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Your name';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLoginSuccess => 'Welcome back!';

  @override
  String get authRegisterSuccess => 'Account created!';

  @override
  String get authInvalidCredentials => 'Invalid email or password';

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String suggestionsProteinLow(int grams) {
    return 'You\'re ${grams}g of protein short today';
  }

  @override
  String get suggestionsGetFrom => 'Get it from';

  @override
  String get unitG => 'g';

  @override
  String get unitMl => 'ml';

  @override
  String get unitPiece => 'piece';

  @override
  String get unitCup => 'cup';

  @override
  String get unitTbsp => 'tbsp';

  @override
  String get unitKcal => 'kcal';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';
}
