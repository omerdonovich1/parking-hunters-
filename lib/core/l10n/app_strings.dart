// ignore_for_file: non_constant_identifier_names

/// All user-visible strings in one place.
/// Instantiate with [AppStrings(isHebrew: true/false)].
class AppStrings {
  final bool isHebrew;
  const AppStrings({required this.isHebrew});

  // ── General ────────────────────────────────────────────────────────────────
  String get appName        => isHebrew ? 'ציד חניה'       : 'Parking Hunter';
  String get pts            => isHebrew ? "נק'"             : 'pts';
  String get cancel         => isHebrew ? 'ביטול'           : 'Cancel';
  String get signOut        => isHebrew ? 'התנתק'           : 'Sign Out';
  String get retry          => isHebrew ? 'נסה שוב'         : 'Retry';
  String get you            => isHebrew ? 'אתה'             : 'You';

  // ── Auth ───────────────────────────────────────────────────────────────────
  String get tagline           => isHebrew ? 'צוד. דווח. צבור נקודות.'       : 'Hunt. Report. Earn Points.';
  String get continueGoogle    => isHebrew ? 'המשך עם Google'                : 'Continue with Google';
  String get continueApple     => isHebrew ? 'המשך עם Apple'                 : 'Continue with Apple';
  String get or_               => isHebrew ? 'או'                            : 'or';
  String get displayName       => isHebrew ? 'שם תצוגה'                     : 'Display Name';
  String get email             => isHebrew ? 'אימייל'                        : 'Email';
  String get password          => isHebrew ? 'סיסמה'                         : 'Password';
  String get createAccount     => isHebrew ? 'צור חשבון'                     : 'Create Account';
  String get signIn            => isHebrew ? 'כניסה'                         : 'Sign In';
  String get signUp            => isHebrew ? 'הרשמה'                         : 'Sign Up';
  String get alreadyHaveAcct   => isHebrew ? 'כבר יש לך חשבון? '             : 'Already have an account? ';
  String get noAccount         => isHebrew ? 'אין לך חשבון? '                : "Don't have an account? ";
  String get tryDemoMode       => isHebrew ? 'נסה מצב דמו — ללא התחברות'     : 'Try Demo Mode — no login required';
  String get enterYourName     => isHebrew ? 'הכנס את שמך'                   : 'Enter your name';
  String get enterValidEmail   => isHebrew ? 'הכנס אימייל תקין'              : 'Enter a valid email';
  String get minSixChars       => isHebrew ? 'מינימום 6 תווים'               : 'Min 6 characters';
  String get googleFailed      => isHebrew ? 'הכניסה עם Google נכשלה'        : 'Google sign in failed';
  String get appleFailed       => isHebrew ? 'הכניסה עם Apple נכשלה'         : 'Apple sign in failed';

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  String get navHunt    => isHebrew ? 'ציד'     : 'Hunt';
  String get navProfile => isHebrew ? 'פרופיל'  : 'Profile';
  String get navRanks   => isHebrew ? 'דירוג'   : 'Ranks';

  // ── Map filter ─────────────────────────────────────────────────────────────
  String get filterAvailable => isHebrew ? 'גבוה'   : 'High';
  String get filterSoon      => isHebrew ? 'בינוני' : 'Mid';
  String get filterLowConf   => isHebrew ? 'נמוך'   : 'Low';

  // ── Spot status labels ─────────────────────────────────────────────────────
  String get statusAvailable      => isHebrew ? 'גבוה'    : 'High';
  String get statusSoonAvailable  => isHebrew ? 'בינוני'  : 'Mid';
  String get statusLowConfidence  => isHebrew ? 'נמוך'    : 'Low';
  String get statusTaken          => isHebrew ? 'תפוס'    : 'Taken';

  // ── Spot bottom sheet ──────────────────────────────────────────────────────
  String get liveConfidence      => isHebrew ? 'ביטחון בזמן אמת'  : 'LIVE CONFIDENCE';
  String get aiScan              => isHebrew ? "סריקת AI"          : 'AI Scan';
  String get timeFactor          => isHebrew ? 'גורם זמן'          : 'Time Factor';
  String get navigate            => isHebrew ? 'נווט'              : 'Navigate';
  String get iParkHere           => isHebrew ? "!חניתי כאן  +5 נק'" : 'I Parked Here!  +5 pts';
  String get checkingLocation    => isHebrew ? 'בודק מיקום...'     : 'Checking location...';
  String get markAsTaken         => isHebrew ? 'סמן כתפוס'         : 'Mark as Taken';
  String get notThere            => isHebrew ? 'לא שם'             : 'Not There';
  String get stillFree           => isHebrew ? 'עדיין פנוי'        : 'Still Free';
  String get tapToExpand         => isHebrew ? 'לחץ להרחבה'        : 'Tap to expand';
  String get tooFarAway          => isHebrew ? 'רחוק מדי'          : 'Too far away';
  String get driveToSpotFirst    => isHebrew ? 'נסע לחנייה תחילה'  : 'Drive to the spot first';
  String get spotMarkedTaken     => isHebrew ? 'החנייה סומנה כתפוסה' : 'Spot marked as taken';
  String get thanksAccurate      => isHebrew ? 'תודה על שמירת המפה מדויקת' : 'Thanks for keeping the map accurate';
  String get enjoySpot           => isHebrew ? '!תיהנה מהחנייה'    : 'Enjoy your spot!';
  String get ptsAdded            => isHebrew ? "נוספו +5 נק' לחשבונך" : '+5 pts added to your account';
  String get locationUnavailable => isHebrew ? 'מיקום לא זמין'    : 'Location unavailable';
  String get makeGpsEnabled      => isHebrew ? 'ודא שה-GPS מופעל' : 'Make sure GPS is enabled';
  String get spotReportedGone    => isHebrew ? 'החנייה דווחה כנעלמה' : 'Spot reported as gone';
  String get confidenceLowered   => isHebrew ? 'ציון הביטחון הורד' : 'Confidence score lowered';
  String get spotConfirmed       => isHebrew ? '!החנייה אושרה'     : 'Spot confirmed!';
  String get ptsThanksIntel      => isHebrew ? "'+5 נק' — תודה על המידע" : '+5 pts — thanks for the intel';

  String tooFarSubtitle(int meters) => isHebrew
      ? "${meters}מ' — התקרב ל-50מ' לסימון כתפוס"
      : '${meters}m — get within 50m to mark as taken';

  String driveSubtitle(int meters) => isHebrew
      ? "${meters}מ' — צריך להיות בטווח 50מ'"
      : '${meters}m away — need to be within 50m';

  // ── Time formatting ────────────────────────────────────────────────────────
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return isHebrew ? 'עכשיו'                           : 'just now';
    if (diff.inMinutes < 60) return isHebrew ? "לפני ${diff.inMinutes} ד'"       : '${diff.inMinutes}m ago';
    return                          isHebrew ? "לפני ${diff.inHours} שע'"        : '${diff.inHours}h ago';
  }

  String timeRemaining(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative)      return isHebrew ? 'פג תוקף'                  : 'Expired';
    if (remaining.inSeconds < 60)  return isHebrew ? "${remaining.inSeconds} שנ' נותרו" : '${remaining.inSeconds}s left';
    if (remaining.inMinutes < 60)  return isHebrew ? "${remaining.inMinutes} ד' נותרו"  : '${remaining.inMinutes}min left';
    return isHebrew
        ? "${remaining.inHours} שע' ${remaining.inMinutes % 60} ד' נותרו"
        : '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
  }

  String reported(DateTime dt) => isHebrew
      ? 'דווח ${timeAgo(dt)}'
      : 'Reported ${timeAgo(dt)}';

  // ── Report screen ──────────────────────────────────────────────────────────
  String get stepPinLocation    => isHebrew ? 'סמן מיקום'                      : 'Pin Location';
  String get stepTakePhoto      => isHebrew ? 'צלם תמונה'                      : 'Take Photo';
  String get stepAiScan         => isHebrew ? "סריקת AI"                        : 'AI Scan';
  String get stepConfirm        => isHebrew ? 'אשר'                            : 'Confirm';
  String get stepSubWhere       => isHebrew ? 'איפה החנייה הפנויה?'             : 'Where is the free spot?';
  String get stepSubPhoto       => isHebrew ? 'צלם את מקום החנייה'              : 'Photograph the parking space';
  String get stepSubAi          => isHebrew ? 'Claude מנתח את התמונה שלך'      : 'Claude analyzes your photo';
  String get stepSubConfirm     => isHebrew ? 'שלח את הדיווח שלך'              : 'Submit your report';
  String get tapToDetectLoc     => isHebrew ? 'לחץ לזיהוי מיקום'               : 'Tap to detect location';
  String get noLocationYet      => isHebrew ? 'אין מיקום עדיין'                : 'No location yet';
  String get detectMyLocation   => isHebrew ? 'זהה את מיקומי'                  : 'Detect My Location';
  String get photoRequired      => isHebrew ? 'נדרשת תמונה'                    : 'Photo required';
  String get aiNeedsPhoto       => isHebrew ? 'AI צריך תמונה לאימות החנייה'    : 'AI needs a photo to verify the spot';
  String get gallery            => isHebrew ? 'גלריה'                          : 'Gallery';
  String get openCamera         => isHebrew ? 'פתח מצלמה'                      : 'Open Camera';
  String get retake             => isHebrew ? 'צלם שוב'                        : 'Retake';
  String get photoReady         => isHebrew ? 'תמונה מוכנה'                    : 'Photo ready';
  String get scanWithAi         => isHebrew ? "סרוק עם AI"                      : 'Scan with AI';
  String get spotIsFree         => isHebrew ? 'החנייה פנויה'                   : 'Spot is FREE';
  String get spotIsTakenLabel   => isHebrew ? 'החנייה תפוסה'                   : 'Spot is TAKEN';
  String get freeSpotConfirmed  => isHebrew ? 'חנייה פנויה אושרה'              : 'Free spot confirmed';
  String get spotAppearsTaken   => isHebrew ? 'החנייה נראית תפוסה'             : 'Spot appears taken';
  String get locationLabel      => isHebrew ? 'מיקום'                          : 'Location';
  String get expiresIn          => isHebrew ? 'פג תוקף בעוד'                   : 'Expires in';
  String get thirtyMinutes      => isHebrew ? '30 דקות'                        : '30 minutes';
  String get aiResult           => isHebrew ? "תוצאת AI"                        : 'AI Result';
  String get freeLabel          => isHebrew ? 'פנוי'                           : 'Free';
  String get takenLabel         => isHebrew ? 'תפוס'                           : 'Taken';
  String get confidenceLabel    => isHebrew ? 'ביטחון'                         : 'confidence';
  String get plusTenPoints      => isHebrew ? '+10 נקודות'                     : '+10 Points';
  String get thanksForHelping   => isHebrew ? '!תודה שעזרת לקהילה'             : 'Thank you for helping the community!';
  String get submitReport       => isHebrew ? 'שלח דיווח'                      : 'Submit Report';
  String get continueToSubmit   => isHebrew ? 'המשך לשליחה'                    : 'Continue to Submit';
  String get continue_          => isHebrew ? 'המשך'                           : 'Continue';
  String get badgeUnlocked      => isHebrew ? '!עיטור נפתח'                    : 'Badge unlocked!';

  // ── Profile ────────────────────────────────────────────────────────────────
  String get badges              => isHebrew ? 'עיטורים'                        : 'Badges';
  String get reports             => isHebrew ? 'דיווחים'                        : 'Reports';
  String get levelLabel          => isHebrew ? 'רמה'                            : 'Level';
  String get noActiveStreak      => isHebrew ? 'אין רצף פעיל'                   : 'No active streak';
  String get reportDailyStreak   => isHebrew ? 'דווח יומיומית לשמירת הרצף'     : 'Report daily to keep your streak';
  String get weeklyLeague        => isHebrew ? 'ליגה שבועית'                   : 'Weekly League';
  String get topHuntersThisWeek  => isHebrew ? 'הצידים המובילים השבוע'         : 'Top hunters this week';
  String get maximumLevel        => isHebrew ? '!הגעת לרמה המקסימלית'          : 'Maximum level reached!';
  String get thisWeekLabel       => isHebrew ? 'השבוע'                         : 'this week';

  String earnedOf(int earned, int total) =>
      isHebrew ? '$earned/$total הושגו' : '$earned/$total earned';

  String dayStreakLabel(int n) =>
      isHebrew ? 'רצף של $n ימים!' : '$n-day streak!';

  String bestStreakLabel(int n) {
    final d = isHebrew ? (n == 1 ? 'יום' : 'ימים') : (n == 1 ? 'day' : 'days');
    return isHebrew ? 'שיא: $n $d  •  $reportDailyStreak' : 'Best: $n $d  •  $reportDailyStreak';
  }

  String pointsToNextLevel(int n) =>
      isHebrew ? '$n נקודות לרמה הבאה' : '$n points to next level';

  String weeklyPts(int n) => isHebrew ? '+$n נק\'' : '+$n pts';

  // ── Leaderboard ────────────────────────────────────────────────────────────
  String get leaderboardTitle => isHebrew ? '🏆 ליגה שבועית'  : '🏆 Weekly League';
  String get thisWeekTab      => isHebrew ? 'השבוע'           : 'This Week';
  String get allTimeTab       => isHebrew ? 'כל הזמן'         : 'All Time';
  String get noHuntersYet     =>
      isHebrew ? 'אין צידים עדיין!\nהיה הראשון לדווח על חנייה.'
               : 'No hunters yet!\nBe the first to report a spot.';

  String levelAndReports(int level, int reps) =>
      isHebrew ? 'רמה $level · $reps דיווחים' : 'Level $level · $reps reports';

  String failedToLoad(String err) =>
      isHebrew ? 'טעינה נכשלה: $err' : 'Failed to load: $err';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsTitle       => isHebrew ? 'הגדרות'                               : 'Settings';
  String get sectionMap          => isHebrew ? 'מפה'                                  : 'Map';
  String get searchRadius        => isHebrew ? 'רדיוס חיפוש'                          : 'Search Radius';
  String get sectionAppearance   => isHebrew ? 'מראה'                                 : 'Appearance';
  String get systemDefault       => isHebrew ? 'ברירת מחדל של המכשיר'                 : 'System default';
  String get light               => isHebrew ? 'בהיר'                                 : 'Light';
  String get dark                => isHebrew ? 'כהה'                                  : 'Dark';
  String get sectionAccount      => isHebrew ? 'חשבון'                                : 'Account';
  String get confirmSignOut      => isHebrew ? 'האם אתה בטוח שברצונך להתנתק?'        : 'Are you sure you want to sign out?';
  String get sectionAbout        => isHebrew ? 'אודות'                                : 'About';
  String get version             => isHebrew ? 'גרסה 1.0.0 · בנייה ראשונית'          : 'Version 1.0.0 · MVP Build';
  String get privacyPolicy       => isHebrew ? 'מדיניות פרטיות'                      : 'Privacy Policy';
  String get privacySubtitle     => isHebrew ? 'נתוני המיקום שלך משמשים רק להצגת חניות קרובות' : 'Your location data is used only to show nearby spots';
  String get sectionLanguage     => isHebrew ? 'שפה'                                  : 'Language';
  String get langEnglish         => 'English';
  String get langHebrew          => 'עברית';

  String kmLabel(double radius) =>
      isHebrew ? '${radius.toStringAsFixed(1)} ק"מ' : '${radius.toStringAsFixed(1)} km';

  // ── Success animation ──────────────────────────────────────────────────────
  String get successfulHunt  => isHebrew ? 'ציד מוצלח! 🎯'        : 'Successful Hunt! 🎯';
  String get thanksForHelp   => isHebrew ? 'תודה על עזרתך לקהילה!' : 'Thanks for helping the community!';
  String pointsLabel(int n)  => isHebrew ? '+$n נקודות'            : '+$n points';

  // ── Level-up overlay ───────────────────────────────────────────────────────
  String get levelUp         => isHebrew ? '!עלית רמה'             : 'LEVEL UP!';
  String get tapToContinue   => isHebrew ? 'לחץ בכל מקום להמשך'   : 'Tap anywhere to continue';
  String levelBadge(int lvl, String title) =>
      isHebrew ? 'רמה $lvl · $title' : 'Level $lvl · $title';

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get ob1Title => isHebrew ? 'מצא חנייה מיידית'  : 'Find Parking Instantly';
  String get ob1Sub   => isHebrew
      ? 'ראה חניות בזמן אמת שדווחו על ידי נהגים אחרים בקרבתך. ירוק = פנוי עכשיו.'
      : 'See real-time parking spots reported by other drivers near you. Green means available right now.';
  String get ob2Title => isHebrew ? 'הפוך לצייד'        : 'Become a Hunter';
  String get ob2Sub   => isHebrew
      ? 'זיהית מקום פנוי? דווח בשניות. צבור נקודות, עלה ברמה ופתח עיטורים בדרך.'
      : 'Spot a free space? Report it in seconds. Earn points, level up, and unlock badges as you hunt.';
  String get ob3Title => isHebrew ? 'התקדם בליגה'       : 'Climb the League';
  String get ob3Sub   => isHebrew
      ? 'התחרה עם צידים בעירך. הטובים ביותר מובילים את לוח הדירוג השבועי ומרוויחים עיטורים בלעדיים.'
      : 'Compete with hunters in your city. The best hunters top the weekly leaderboard and earn exclusive badges.';
  String get skip         => isHebrew ? 'דלג'           : 'Skip';
  String get next         => isHebrew ? 'הבא'           : 'Next';
  String get startHunting => isHebrew ? 'התחל לצוד! 🎯' : 'Start Hunting! 🎯';
}
