class BabyModel {
  final String id;
  final String patientCode;
  final String name;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? congenitalProblems;
  final double? weightAtBirth;
  final double? lengthAtBirth;
  final double? headCircumference;
  final String? createdBy;
  final DateTime? createdAt;

  const BabyModel({
    required this.id,
    required this.patientCode,
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.congenitalProblems,
    this.weightAtBirth,
    this.lengthAtBirth,
    this.headCircumference,
    this.createdBy,
    this.createdAt,
  });

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] as String,
      patientCode: json['patient_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dateOfBirth:
          json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      gender: json['gender'] as String?,
      congenitalProblems: json['congenital_problems'] as String?,
      weightAtBirth: (json['weight_at_birth'] as num?)?.toDouble(),
      lengthAtBirth: (json['length_at_birth'] as num?)?.toDouble(),
      headCircumference: (json['head_circumference'] as num?)?.toDouble(),
      createdBy: json['created_by'] as String?,
      createdAt:
          json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  int get ageInMonths {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    return (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
  }

  String get ageLabel {
    final months = ageInMonths;
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years year${years > 1 ? "s" : ""}';
    return '$years yr $rem mo';
  }
}

class BabyGrowthModel {
  final String id;
  final String babyId;
  final DateTime recordDate;
  final double? weightKg;
  final double? lengthCm;
  final String? createdBy;

  const BabyGrowthModel({
    required this.id,
    required this.babyId,
    required this.recordDate,
    this.weightKg,
    this.lengthCm,
    this.createdBy,
  });

  factory BabyGrowthModel.fromJson(Map<String, dynamic> json) {
    return BabyGrowthModel(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      lengthCm: (json['length_cm'] as num?)?.toDouble(),
      createdBy: json['created_by'] as String?,
    );
  }
}

class BabyVaccinationModel {
  final String id;
  final String babyId;
  final String vaccineName;
  final DateTime? vaccineDate;
  final DateTime? dueDate;
  final String? dose;
  final String status;
  final String? notes;

  const BabyVaccinationModel({
    required this.id,
    required this.babyId,
    required this.vaccineName,
    this.vaccineDate,
    this.dueDate,
    this.dose,
    required this.status,
    this.notes,
  });

  factory BabyVaccinationModel.fromJson(Map<String, dynamic> json) {
    return BabyVaccinationModel(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      vaccineName: json['vaccine_name'] as String? ?? '',
      vaccineDate:
          json['vaccine_date'] != null ? DateTime.tryParse(json['vaccine_date']) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      dose: json['dose'] as String?,
      status: json['status'] as String? ?? 'upcoming',
      notes: json['notes'] as String?,
    );
  }
}

class BabyMedicineModel {
  final String id;
  final String babyId;
  final String medicineName;
  final String? dosage;
  final String? timeOfDay;
  final String? frequency;
  final String? reason;
  final String? notes;

  const BabyMedicineModel({
    required this.id,
    required this.babyId,
    required this.medicineName,
    this.dosage,
    this.timeOfDay,
    this.frequency,
    this.reason,
    this.notes,
  });

  factory BabyMedicineModel.fromJson(Map<String, dynamic> json) {
    return BabyMedicineModel(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      medicineName: json['medicine_name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      frequency: json['frequency'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class BabyRoutineModel {
  final String id;
  final String babyId;
  final DateTime activityTime;
  final String activityType;
  final String? details;

  const BabyRoutineModel({
    required this.id,
    required this.babyId,
    required this.activityTime,
    required this.activityType,
    this.details,
  });

  factory BabyRoutineModel.fromJson(Map<String, dynamic> json) {
    return BabyRoutineModel(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      activityTime: DateTime.parse(json['activity_time'] as String),
      activityType: json['activity_type'] as String? ?? 'other',
      details: json['details'] as String?,
    );
  }
}

/// Latest environmental reading pushed by the room sensor into the
/// `baby_sensor_readings` Supabase table. Rows are keyed by [patientCode]
/// (e.g. "B-0001"); the most recent row by `created_at` is what we display.
class BabySensorReading {
  final String id;
  final String patientCode;
  final double? roomTemperature;
  final double? humidity;
  final double? gasLevel;
  final double? smokeLevel;
  final String? alertText;
  final DateTime? measuredAt;
  final DateTime? createdAt;

  const BabySensorReading({
    required this.id,
    required this.patientCode,
    this.roomTemperature,
    this.humidity,
    this.gasLevel,
    this.smokeLevel,
    this.alertText,
    this.measuredAt,
    this.createdAt,
  });

  factory BabySensorReading.fromJson(Map<String, dynamic> json) {
    return BabySensorReading(
      id: json['id'] as String,
      patientCode: json['patient_code'] as String? ?? '',
      roomTemperature: (json['room_temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      gasLevel: (json['gas_level'] as num?)?.toDouble(),
      smokeLevel: (json['smoke_level'] as num?)?.toDouble(),
      alertText: json['alert_text'] as String?,
      measuredAt: json['measured_at'] != null
          ? DateTime.tryParse(json['measured_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Latest wearable-band reading from the `band_readings` Supabase table.
/// Rows are keyed by [patientCode] (e.g. "B-0001"); the most recent row by
/// `created_at` drives the Daily Vitals card.
class BandReading {
  final String id;
  final String patientCode;
  final int? heartRate;
  final int? spo2;
  final String? alertText;
  final String? locationLink;
  final DateTime? measuredAt;
  final DateTime? createdAt;

  const BandReading({
    required this.id,
    required this.patientCode,
    this.heartRate,
    this.spo2,
    this.alertText,
    this.locationLink,
    this.measuredAt,
    this.createdAt,
  });

  factory BandReading.fromJson(Map<String, dynamic> json) {
    return BandReading(
      id: json['id'] as String,
      patientCode: json['patient_code'] as String? ?? '',
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      spo2: (json['spo2'] as num?)?.toInt(),
      alertText: json['alert_text'] as String?,
      locationLink: json['location_link'] as String?,
      measuredAt: json['measured_at'] != null
          ? DateTime.tryParse(json['measured_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class BabyAlertModel {
  final String id;
  final String babyId;
  final DateTime alertTime;
  final String? detectedObject;
  final String? photoPath;

  const BabyAlertModel({
    required this.id,
    required this.babyId,
    required this.alertTime,
    this.detectedObject,
    this.photoPath,
  });

  factory BabyAlertModel.fromJson(Map<String, dynamic> json) {
    return BabyAlertModel(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      alertTime: DateTime.parse(json['alert_time'] as String),
      detectedObject: json['detected_object'] as String?,
      photoPath: json['photo_path'] as String?,
    );
  }
}
