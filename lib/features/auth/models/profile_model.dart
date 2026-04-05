class ProfileModel {
  final String id;
  final String fullName;
  final String role;
  final String? doctorSpecialization;
  final double? doctorRating;
  final int? doctorYearsExperience;
  final double? doctorResponseRate;
  final String? doctorBio;
  final List<String>? doctorTags;
  final String? doctorAvailabilityLabel;
  final String? doctorAudience;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.doctorSpecialization,
    this.doctorRating,
    this.doctorYearsExperience,
    this.doctorResponseRate,
    this.doctorBio,
    this.doctorTags,
    this.doctorAvailabilityLabel,
    this.doctorAudience,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      doctorSpecialization: json['doctor_specialization'] as String?,
      doctorRating: (json['doctor_rating'] as num?)?.toDouble(),
      doctorYearsExperience: json['doctor_years_experience'] as int?,
      doctorResponseRate: (json['doctor_response_rate'] as num?)?.toDouble(),
      doctorBio: json['doctor_bio'] as String?,
      doctorTags: (json['doctor_tags'] as List<dynamic>?)?.cast<String>(),
      doctorAvailabilityLabel: json['doctor_availability_label'] as String?,
      doctorAudience: json['doctor_audience'] as String?,
    );
  }
}
