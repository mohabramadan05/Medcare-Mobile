class AppointmentModel {
  final String id;
  final String? patientType;
  final String? babyId;
  final String? elderId;
  final DateTime appointmentAt;
  final String? appointmentType;
  final String? notes;
  final String? createdBy;
  final String status;

  // ✅ NEW (no breaking change)
  final String? babyName;
  final String? elderName;

  const AppointmentModel({
    required this.id,
    this.patientType,
    this.babyId,
    this.elderId,
    required this.appointmentAt,
    this.appointmentType,
    this.notes,
    this.createdBy,
    required this.status,
    this.babyName,
    this.elderName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      patientType: json['patient_type'] as String?,
      babyId: json['baby_id'] as String?,
      elderId: json['elder_id'] as String?,
      appointmentAt: DateTime.parse(json['appointment_at'] as String),
      appointmentType: json['appointment_type'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      status: json['status'] as String? ?? 'upcoming',

      // ✅ SAFE parsing (no crash if null)
      babyName: json['baby']?['name'],
      elderName: json['elder']?['full_name'],
    );
  }

  // ✅ Helper ONLY (no UI break)
  String get patientName {
    if (patientType == 'baby') return babyName ?? 'Baby';
    if (patientType == 'elder') return elderName ?? 'Elder';
    return 'Patient';
  }
}