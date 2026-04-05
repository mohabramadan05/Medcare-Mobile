class ElderModel {
  final String id;
  final String patientCode;
  final String fullName;
  final int? age;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final String? phoneNumber;
  final String? homeAddress;
  final String? createdBy;

  const ElderModel({
    required this.id,
    required this.patientCode,
    required this.fullName,
    this.age,
    this.dateOfBirth,
    this.bloodType,
    this.phoneNumber,
    this.homeAddress,
    this.createdBy,
  });

  factory ElderModel.fromJson(Map<String, dynamic> json) {
    return ElderModel(
      id: json['id'] as String,
      patientCode: json['patient_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      age: json['age'] as int?,
      dateOfBirth:
          json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      bloodType: json['blood_type'] as String?,
      phoneNumber: json['phone_number'] as String?,
      homeAddress: json['home_address'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }
}

class ElderVitalsModel {
  final String id;
  final String elderId;
  final DateTime measuredAt;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? temperatureC;
  final double? bloodSugarMgdl;
  final double? oxygenSaturationPercent;
  final double? weightKg;
  final String? notes;

  const ElderVitalsModel({
    required this.id,
    required this.elderId,
    required this.measuredAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperatureC,
    this.bloodSugarMgdl,
    this.oxygenSaturationPercent,
    this.weightKg,
    this.notes,
  });

  factory ElderVitalsModel.fromJson(Map<String, dynamic> json) {
    return ElderVitalsModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
      heartRate: json['heart_rate'] as int?,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      bloodSugarMgdl: (json['blood_sugar_mgdl'] as num?)?.toDouble(),
      oxygenSaturationPercent:
          (json['oxygen_saturation_percent'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class ElderMedicationModel {
  final String id;
  final String elderId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? timeOfDay;
  final String? duration;
  final String? instructions;

  const ElderMedicationModel({
    required this.id,
    required this.elderId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.timeOfDay,
    this.duration,
    this.instructions,
  });

  factory ElderMedicationModel.fromJson(Map<String, dynamic> json) {
    return ElderMedicationModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      medicineName: json['medicine_name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      duration: json['duration'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
}

class ElderHealthRecordModel {
  final String id;
  final String elderId;
  final String? recordType;
  final String name;
  final DateTime? recordDate;
  final String? severity;
  final String? status;
  final String? notes;

  const ElderHealthRecordModel({
    required this.id,
    required this.elderId,
    this.recordType,
    required this.name,
    this.recordDate,
    this.severity,
    this.status,
    this.notes,
  });

  factory ElderHealthRecordModel.fromJson(Map<String, dynamic> json) {
    return ElderHealthRecordModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      recordType: json['record_type'] as String?,
      name: json['name'] as String? ?? '',
      recordDate:
          json['record_date'] != null ? DateTime.tryParse(json['record_date']) : null,
      severity: json['severity'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class ElderAlertModel {
  final String id;
  final String elderId;
  final DateTime alertTime;
  final String? detectedObject;
  final String? photoPath;

  const ElderAlertModel({
    required this.id,
    required this.elderId,
    required this.alertTime,
    this.detectedObject,
    this.photoPath,
  });

  factory ElderAlertModel.fromJson(Map<String, dynamic> json) {
    return ElderAlertModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      alertTime: DateTime.parse(json['alert_time'] as String),
      detectedObject: json['detected_object'] as String?,
      photoPath: json['photo_path'] as String?,
    );
  }
}

class ElderSafetyInfoModel {
  final String elderId;
  final String? primaryContactName;
  final String? primaryContactPhone;
  final String? primaryContactRelationship;
  final String? secondaryContactName;
  final String? secondaryContactPhone;
  final String? secondaryContactRelationship;
  final String? additionalSafetyInformation;

  const ElderSafetyInfoModel({
    required this.elderId,
    this.primaryContactName,
    this.primaryContactPhone,
    this.primaryContactRelationship,
    this.secondaryContactName,
    this.secondaryContactPhone,
    this.secondaryContactRelationship,
    this.additionalSafetyInformation,
  });

  factory ElderSafetyInfoModel.fromJson(Map<String, dynamic> json) {
    return ElderSafetyInfoModel(
      elderId: json['elder_id'] as String,
      primaryContactName: json['primary_contact_name'] as String?,
      primaryContactPhone: json['primary_contact_phone'] as String?,
      primaryContactRelationship:
          json['primary_contact_relationship'] as String?,
      secondaryContactName: json['secondary_contact_name'] as String?,
      secondaryContactPhone: json['secondary_contact_phone'] as String?,
      secondaryContactRelationship:
          json['secondary_contact_relationship'] as String?,
      additionalSafetyInformation:
          json['additional_safety_information'] as String?,
    );
  }
}
