import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  bool get isAr => locale.languageCode == 'ar';

  String _t(String en, String ar) => isAr ? ar : en;

  // ── General ──────────────────────────────────────────────────────────────
  String get appName => 'Nesta';
  String get save => _t('Save', 'حفظ');
  String get cancel => _t('Cancel', 'إلغاء');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get error => _t('Error', 'خطأ');
  String get loading => _t('Loading...', 'جارٍ التحميل...');
  String get seeAll => _t('See all', 'عرض الكل');
  String get add => _t('Add', 'إضافة');
  String get notes => _t('Notes', 'ملاحظات');
  String get status => _t('Status', 'الحالة');
  String get name => _t('Name', 'الاسم');
  String get date => _t('Date', 'التاريخ');
  String get live => _t('Live', 'مباشر');
  String get allClear => _t('All Clear', 'كل شيء سليم');
  String get fullScreen => _t('Full Screen', 'ملء الشاشة');
  String get history => _t('History', 'السجل');
  String get yearsOld => _t('years old', 'سنة');
  String get optional => _t('optional', 'اختياري');
  String get today => _t('Today', 'اليوم');
  String get yesterday => _t('Yesterday', 'أمس');
  String get measured => _t('Measured', 'تم القياس');

  // ── Auth ─────────────────────────────────────────────────────────────────
  String get welcomeBack => _t('Welcome Back', 'مرحباً بعودتك');
  String get signInToAccount => _t('Sign in to your account', 'سجّل دخولك إلى حسابك');
  String get email => _t('Email', 'البريد الإلكتروني');
  String get password => _t('Password', 'كلمة المرور');
  String get signIn => _t('Sign In', 'تسجيل الدخول');
  String get signUp => _t('Sign Up', 'إنشاء حساب');
  String get noAccount => _t("Don't have an account? ", 'ليس لديك حساب؟ ');
  String get hasAccount => _t('Already have an account? ', 'لديك حساب بالفعل؟ ');
  String get createAccount => _t('Create Account', 'إنشاء حساب');
  String get joinToday => _t('Join Nesta today', 'انضم إلى نيستا اليوم');
  String get fullName => _t('Full Name', 'الاسم الكامل');
  String get yourHealthCompanion => _t('Your Health Companion', 'رفيقك الصحي');

  // Validators
  String get emailRequired => _t('Email is required', 'البريد الإلكتروني مطلوب');
  String get emailInvalid => _t('Enter a valid email', 'أدخل بريداً إلكترونياً صحيحاً');
  String get passwordRequired => _t('Password is required', 'كلمة المرور مطلوبة');
  String get passwordMin => _t('Minimum 6 characters', 'الحد الأدنى 6 أحرف');
  String get nameRequired => _t('Name is required', 'الاسم مطلوب');

  // ── Home ─────────────────────────────────────────────────────────────────
  String get goodMorning => _t('Good Morning', 'صباح الخير');
  String get goodAfternoon => _t('Good Afternoon', 'مساء الخير');
  String get goodEvening => _t('Good Evening', 'مساء النور');
  String get yourHealthOurCare => _t('Your health, our care', 'صحتك، رعايتنا');
  String get doctorDashboard => _t('Doctor Dashboard', 'لوحة الطبيب');
  String get errorLoadingProfile => _t('Error loading profile', 'خطأ في تحميل الملف الشخصي');
  String get myBabies => _t('My Babies', 'أطفالي');
  String get myElders => _t('My Elders', 'كبار سني');
  String get schedule => _t('Schedule', 'المواعيد');
  String get doctors => _t('Doctors', 'الأطباء');
  String get upcoming => _t('Upcoming', 'القادمة');
  String get upcomingAppointments => _t('Upcoming Appointments', 'المواعيد القادمة');
  String get noUpcomingAppointments => _t('No upcoming appointments', 'لا توجد مواعيد قادمة');
  String get tapToSchedule => _t('Tap + to schedule one', 'اضغط + لجدولة موعد');
  String get noBabiesAdded => _t('No babies added yet. Tap + to add one.', 'لم تتم إضافة أطفال بعد. اضغط + للإضافة.');
  String get noEldersAdded => _t('No elders added yet. Tap + to add one.', 'لم تتم إضافة كبار سن بعد. اضغط + للإضافة.');
  String get viewConversations => _t('View Conversations', 'عرض المحادثات');
  String get viewAndRespondDoctors => _t('View and respond to patient conversations in the Chat tab.', 'عرض محادثات المرضى والرد عليها من تبويب الدردشة.');

  // ── Nav ──────────────────────────────────────────────────────────────────
  String get navHome => _t('Home', 'الرئيسية');
  String get navAppointments => _t('Appointments', 'المواعيد');
  String get navChat => _t('Chat', 'الدردشة');
  String get navShop => _t('Shop', 'المتجر');

  // ── Babies ───────────────────────────────────────────────────────────────
  String get myBabiesTitle => _t('My Babies', 'أطفالي');
  String get noBabiesYet => _t('No babies yet', 'لا يوجد أطفال بعد');
  String get noBabiesSubtitle => _t('Add your first baby to start tracking their health', 'أضف طفلك الأول لبدء متابعة صحته');
  String get addBaby => _t('Add Baby', 'إضافة طفل');
  String get babyName => _t('Baby Name *', 'اسم الطفل *');
  String get dateOfBirth => _t('Date of Birth *', 'تاريخ الميلاد *');
  String get gender => _t('Gender', 'الجنس');
  String get male => _t('Male', 'ذكر');
  String get female => _t('Female', 'أنثى');
  String get weightAtBirth => _t('Weight at Birth (kg)', 'الوزن عند الولادة (كغ)');
  String get lengthAtBirth => _t('Length at Birth (cm)', 'الطول عند الولادة (سم)');
  String get headCircumference => _t('Head Circumference (cm)', 'محيط الرأس (سم)');
  String get congenitalProblems => _t('Congenital Problems (optional)', 'مشاكل خلقية (اختياري)');
  String get babyAddedSuccess => _t('Baby added successfully!', 'تمت إضافة الطفل بنجاح!');
  String get selectDOB => _t('Please select date of birth', 'الرجاء تحديد تاريخ الميلاد');
  String get babyNotFound => _t('Baby not found', 'لم يتم العثور على الطفل');

  // Baby detail features
  String get growthChart => _t('Growth Chart', 'مخطط النمو');
  String get vaccinations => _t('Vaccinations', 'التطعيمات');
  String get dailyRoutine => _t('Daily Routine', 'الروتين اليومي');
  String get medicines => _t('Medicines', 'الأدوية');
  String get alerts => _t('Alerts', 'التنبيهات');
  String get monitoring => _t('Monitoring', 'المراقبة');

  // Growth
  String get addGrowthRecord => _t('Add Growth Record', 'إضافة سجل نمو');
  String get selectDate => _t('Select Date *', 'اختر التاريخ *');
  String get weightKg => _t('Weight (kg)', 'الوزن (كغ)');
  String get lengthCm => _t('Length (cm)', 'الطول (سم)');
  String get saveRecord => _t('Save Record', 'حفظ السجل');
  String get recordAdded => _t('Record added!', 'تمت إضافة السجل!');
  String get noGrowthRecords => _t('No growth records', 'لا توجد سجلات نمو');
  String get addFirstGrowth => _t('Add the first growth measurement', 'أضف أول قياس للنمو');
  String get records => _t('Records', 'السجلات');

  // Vaccines
  String get addVaccination => _t('Add Vaccination', 'إضافة تطعيم');
  String get vaccineName => _t('Vaccine Name *', 'اسم اللقاح *');
  String get dose => _t('Dose (e.g. 1st)', 'الجرعة (مثال: الأولى)');
  String get setVaccineDate => _t('Set Vaccine Date', 'تحديد تاريخ التطعيم');
  String get setDueDate => _t('Set Due Date', 'تحديد تاريخ الاستحقاق');
  String get vaccinationAdded => _t('Vaccination added!', 'تمت إضافة التطعيم!');
  String get noVaccinations => _t('No vaccinations recorded', 'لا توجد تطعيمات مسجلة');
  String get trackVaccinations => _t("Track your baby's vaccination schedule", 'تابع جدول تطعيمات طفلك');
  String get statusUpcoming => _t('upcoming', 'قادم');
  String get statusCompleted => _t('completed', 'مكتمل');
  String get statusMissed => _t('missed', 'فائت');
  String get doseLabel => _t('Dose: ', 'الجرعة: ');
  String get dueLabel => _t('Due: ', 'الموعد: ');
  String get givenLabel => _t('Given: ', 'أُعطي في: ');

  // Routine
  String get logActivity => _t('Log Activity', 'تسجيل نشاط');
  String get activityType => _t('Activity Type', 'نوع النشاط');
  String get activityFeeding => _t('feeding', 'رضاعة');
  String get activitySleep => _t('sleep', 'نوم');
  String get activityDiaper => _t('diaper', 'حفاضة');
  String get activityOther => _t('other', 'أخرى');
  String get details => _t('Details (optional)', 'تفاصيل (اختياري)');
  String get activityLogged => _t('Activity logged!', 'تم تسجيل النشاط!');
  String get noActivities => _t('No activities logged', 'لا توجد أنشطة مسجلة');
  String get startLogging => _t("Start logging your baby's daily routine", 'ابدأ بتسجيل الروتين اليومي لطفلك');

  // Medicines
  String get addMedicine => _t('Add Medicine', 'إضافة دواء');
  String get medicineName => _t('Medicine Name *', 'اسم الدواء *');
  String get dosage => _t('Dosage', 'الجرعة');
  String get frequency => _t('Frequency', 'التكرار');
  String get timeOfDay => _t('Time of Day', 'وقت اليوم');
  String get reason => _t('Reason', 'السبب');
  String get medicineAdded => _t('Medicine added!', 'تمت إضافة الدواء!');
  String get noMedicines => _t('No medicines recorded', 'لا توجد أدوية مسجلة');
  String get trackMedicines => _t("Track your baby's medications", 'تابع أدوية طفلك');
  String get dosageLabel => _t('Dosage: ', 'الجرعة: ');

  // Alerts
  String get noAlerts => _t('No alerts', 'لا توجد تنبيهات');
  String get babyAlertsSubtitle => _t('Baby monitoring alerts will appear here', 'ستظهر تنبيهات مراقبة الطفل هنا');
  String get elderAlertsSubtitle => _t('Elder monitoring alerts will appear here', 'ستظهر تنبيهات مراقبة المسن هنا');
  String get alertDetected => _t('Alert detected', 'تم اكتشاف تنبيه');
  String get activityDetected => _t('Activity detected', 'تم اكتشاف نشاط');

  // ── Elders ───────────────────────────────────────────────────────────────
  String get myEldersTitle => _t('My Elders', 'كبار سني');
  String get noEldersYet => _t('No elders yet', 'لا يوجد كبار سن بعد');
  String get noEldersSubtitle => _t('Add an elder to start monitoring their health', 'أضف مسناً لبدء مراقبة صحته');
  String get addElder => _t('Add Elder', 'إضافة مسن');
  String get elderAddedSuccess => _t('Elder added successfully!', 'تمت إضافة المسن بنجاح!');
  String get elderNotFound => _t('Elder not found', 'لم يتم العثور على المسن');
  String get bloodType => _t('Blood Type', 'فصيلة الدم');
  String get phoneNumber => _t('Phone Number', 'رقم الهاتف');
  String get homeAddress => _t('Home Address', 'العنوان');

  // Elder features
  String get vitals => _t('Vitals', 'العلامات الحيوية');
  String get medications => _t('Medications', 'الأدوية');
  String get healthRecords => _t('Health Records', 'السجلات الصحية');
  String get safetyInfo => _t('Safety Info', 'معلومات الأمان');

  // Vitals
  String get logVitals => _t('Log Vitals', 'تسجيل العلامات الحيوية');
  String get bpSystolic => _t('BP Systolic', 'ضغط الدم الانقباضي');
  String get bpDiastolic => _t('BP Diastolic', 'ضغط الدم الانبساطي');
  String get heartRate => _t('Heart Rate (bpm)', 'معدل ضربات القلب (نبضة/د)');
  String get temperature => _t('Temp (°C)', 'الحرارة (°م)');
  String get bloodSugar => _t('Blood Sugar (mg/dL)', 'سكر الدم (ملغ/دل)');
  String get o2Sat => _t('O2 Sat (%)', 'تشبع الأكسجين (%)');
  String get weightKgLabel => _t('Weight (kg)', 'الوزن (كغ)');
  String get saveVitals => _t('Save Vitals', 'حفظ العلامات الحيوية');
  String get vitalsRecorded => _t('Vitals recorded!', 'تم تسجيل العلامات الحيوية!');
  String get noVitals => _t('No vitals recorded', 'لا توجد علامات حيوية مسجلة');
  String get logFirstVitals => _t('Log the first vital signs', 'سجّل أول علامات حيوية');
  String get latestReadings => _t('Latest Readings', 'أحدث القراءات');
  String get bloodPressure => _t('Blood Pressure', 'ضغط الدم');
  String get heartRateLabel => _t('Heart Rate', 'معدل القلب');
  String get temperatureLabel => _t('Temperature', 'الحرارة');
  String get o2Saturation => _t('O2 Saturation', 'تشبع O2');
  String get bloodSugarLabel => _t('Blood Sugar', 'سكر الدم');
  String get weightLabel => _t('Weight', 'الوزن');
  String get measuredAt => _t('Measured: ', 'تم القياس: ');

  // Medications (elder)
  String get addMedication => _t('Add Medication', 'إضافة دواء');
  String get duration => _t('Duration', 'المدة');
  String get instructions => _t('Instructions', 'التعليمات');
  String get medicationAdded => _t('Medication added!', 'تمت إضافة الدواء!');
  String get noMedications => _t('No medications', 'لا توجد أدوية');
  String get addMedicationsForElder => _t('Add medications for this elder', 'أضف أدوية لهذا المسن');

  // Health Records
  String get addHealthRecord => _t('Add Health Record', 'إضافة سجل صحي');
  String get conditionName => _t('Condition / Record Name *', 'الحالة / اسم السجل *');
  String get recordType => _t('Type (e.g. Chronic, Acute)', 'النوع (مثال: مزمن، حاد)');
  String get severity => _t('Severity', 'الشدة');
  String get severityMild => _t('mild', 'خفيف');
  String get severityModerate => _t('moderate', 'متوسط');
  String get severitySevere => _t('severe', 'شديد');
  String get statusActive => _t('active', 'نشط');
  String get statusResolved => _t('resolved', 'محلول');
  String get statusMonitoring => _t('monitoring', 'مراقبة');
  String get setDateBtn => _t('Set Date', 'تحديد التاريخ');
  String get recordAddedSuccess => _t('Record added!', 'تمت إضافة السجل!');
  String get noHealthRecords => _t('No health records', 'لا توجد سجلات صحية');
  String get addHealthConditions => _t('Add health conditions and medical records', 'أضف الحالات الصحية والسجلات الطبية');
  String get general => _t('General', 'عام');

  // Safety Info
  String get primaryContact => _t('Primary Emergency Contact', 'جهة الاتصال الأولى للطوارئ');
  String get secondaryContact => _t('Secondary Emergency Contact', 'جهة الاتصال الثانية للطوارئ');
  String get relationship => _t('Relationship', 'صلة القرابة');
  String get additionalInfo => _t('Additional Information', 'معلومات إضافية');
  String get safetyNotes => _t('Safety notes, medical alerts...', 'ملاحظات الأمان، التنبيهات الطبية...');
  String get saveSafetyInfo => _t('Save Safety Info', 'حفظ معلومات الأمان');
  String get safetyInfoSaved => _t('Safety info saved!', 'تم حفظ معلومات الأمان!');

  // ── Appointments ─────────────────────────────────────────────────────────
  String get appointmentsTitle => _t('Appointments', 'المواعيد');
  String get tabUpcoming => _t('Upcoming', 'القادمة');
  String get tabCompleted => _t('Completed', 'المكتملة');
  String get tabCancelled => _t('Cancelled', 'الملغاة');
  String get newAppointment => _t('New', 'جديد');
  String get noUpcoming => _t('No upcoming appointments', 'لا توجد مواعيد قادمة');
  String get noUpcomingSubtitle => _t('Tap "New" to schedule one', 'اضغط "جديد" لجدولة موعد');
  String get noCompleted => _t('No completed appointments', 'لا توجد مواعيد مكتملة');
  String get noCompletedSubtitle => _t('Completed appointments will appear here', 'ستظهر المواعيد المكتملة هنا');
  String get noCancelled => _t('No cancelled appointments', 'لا توجد مواعيد ملغاة');
  String get noCancelledSubtitle => _t('Cancelled appointments will appear here', 'ستظهر المواعيد الملغاة هنا');
  String get addAppointment => _t('Add Appointment', 'إضافة موعد');
  String get patientType => _t('Patient Type', 'نوع المريض');
  String get baby => _t('Baby', 'طفل');
  String get elder => _t('Elder', 'مسن');
  String get selectPatient => _t('Select Patient', 'اختر المريض');
  String get selectPatientError => _t('Please select a patient', 'الرجاء اختيار المريض');
  String get appointmentType => _t('Appointment Type', 'نوع الموعد');
  String get appointmentTypeHint => _t('e.g. Check-up, Vaccination', 'مثال: فحص دوري، تطعيم');
  String get appointmentTypeRequired => _t('Please enter appointment type', 'الرجاء إدخال نوع الموعد');
  String get selectDateTime => _t('Select Date & Time *', 'اختر التاريخ والوقت *');
  String get scheduleAppointment => _t('Schedule Appointment', 'جدولة الموعد');
  String get generalConsultation => _t('General Consultation', 'استشارة عامة');

  // ── Chat ─────────────────────────────────────────────────────────────────
  String get messagesTitle => _t('Messages', 'الرسائل');
  String get findDoctor => _t('Find a Doctor', 'ابحث عن طبيب');
  String get noConversations => _t('No conversations yet', 'لا توجد محادثات بعد');
  String get startConversation => _t('Start a conversation with a doctor', 'ابدأ محادثة مع طبيب');
  String get noMessages => _t('No messages yet', 'لا توجد رسائل بعد');
  String get sayHello => _t('Say hello! 👋', 'قل مرحباً! 👋');
  String get typeMessage => _t('Type a message...', 'اكتب رسالة...');
  String get doctor => _t('Doctor', 'الطبيب');

  // ── Shop ─────────────────────────────────────────────────────────────────
  String get shopTitle => _t('Shop', 'المتجر');
  String get allCategories => _t('All', 'الكل');
  String get noProducts => _t('No products available', 'لا توجد منتجات متاحة');
  String get checkBackLater => _t('Check back later', 'تحقق لاحقاً');
  String get addedToCart => _t('Added to cart!', 'تمت الإضافة إلى السلة!');
  String get myCart => _t('My Cart', 'سلتي');
  String get cartEmpty => _t('Cart is empty', 'السلة فارغة');
  String get addFromShop => _t('Add products from the shop', 'أضف منتجات من المتجر');
  String get total => _t('Total', 'الإجمالي');
  String get orderPlaced => _t('Order placed! 🎉', 'تم تقديم الطلب! 🎉');
  String get placeOrder => _t('Place Order', 'تقديم الطلب');

  // ── Doctors ──────────────────────────────────────────────────────────────
  String get findDoctorTitle => _t('Find a Doctor', 'ابحث عن طبيب');
  String get noDoctors => _t('No doctors available', 'لا يوجد أطباء متاحون');
  String get noDoctorsSubtitle => _t('Doctors will appear here once registered', 'سيظهر الأطباء هنا بعد التسجيل');
  String get yrsExp => _t('yrs exp', 'سنة خبرة');
  String get responseRate => _t('% response', '% استجابة');
  String get message => _t('Message', 'رسالة');

  // ── Monitoring ───────────────────────────────────────────────────────────
  String get liveFeed => _t('Live Feed', 'البث المباشر');
  String get safetyAlerts => _t('Safety Alerts', 'تنبيهات الأمان');
  String get dailyVitals => _t('Daily Vitals', 'العلامات اليومية');
  String get heartRateTracking => _t('Heart Rate Tracking', 'تتبع معدل القلب');
  String get elderCameraFeed => _t('Elder Camera Feed', 'كاميرا المسن');
  String get babyCameraFeed => _t('Baby Camera Feed', 'كاميرا الطفل');
  String get livingRoom => _t('Living Room', 'غرفة المعيشة');
  String get noAlertsDetected => _t('No alerts detected', 'لم يتم اكتشاف تنبيهات');
  String get connectBabyMonitor => _t('Connect a baby monitor device to see live vitals', 'اربط جهاز مراقبة الطفل لرؤية العلامات المباشرة');
  String get hrReading => _t('Heart Rate', 'معدل القلب');
  String get spO2 => _t('SpO2', 'تشبع O2');
  String get resting => _t('Resting', 'راحة');
  String get normal => _t('Normal', 'طبيعي');
  String get elevated => _t('Elevated', 'مرتفع');
  String get high => _t('High', 'عالٍ');
  String get peak => _t('Peak', 'ذروة');
  String get good => _t('Good', 'جيد');
  String get low => _t('Low', 'منخفض');
  String get critical => _t('Critical', 'حرج');
  String get h24 => _t('24h', '24س');
  String get week => _t('Week', 'أسبوع');
  String get liveTrendFor => _t('LIVE TREND FOR', 'الاتجاه المباشر لـ');
  String get restingRange => _t('Resting (50-70 BPM)', 'راحة (50-70)');
  String get normalRange => _t('Normal (71-100 BPM)', 'طبيعي (71-100)');
  String get elevatedRange => _t('Elevated (101-130 BPM)', 'مرتفع (101-130)');
  String get highRange => _t('High (131-160 BPM)', 'عالٍ (131-160)');
  String get peakRange => _t('Peak (161+ BPM)', 'ذروة (+161)');
  String get noVitalsForChart => _t('No data for chart', 'لا توجد بيانات للمخطط');
  String get noHeartRateData => _t('No heart rate data', 'لا توجد بيانات معدل القلب');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
