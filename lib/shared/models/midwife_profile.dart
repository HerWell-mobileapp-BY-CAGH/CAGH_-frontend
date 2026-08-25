class MidwifeProfile {
  final String id;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  
  final String hospitalId;
  final String hospitalName;
  final String hospitalAddress;

  final String specialty;
  final int experienceYears;
  final List<String> languages;
  final String bio;
  final List<String> offeredConsultationTypes;
  final double ratingAverage;
  final int ratingCount;
  final bool isFavorite;
  final bool isAcceptingBookings;
  final String consultationFee;
  final String verificationStatus;

  // Computed property
  String get fullName => '$firstName $lastName';

  MidwifeProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.specialty,
    required this.experienceYears,
    required this.languages,
    required this.bio,
    required this.offeredConsultationTypes,
    required this.ratingAverage,
    required this.ratingCount,
    required this.isFavorite,
    required this.isAcceptingBookings,
    required this.consultationFee,
    required this.verificationStatus,
  });

  factory MidwifeProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final userProfile = user['profile'] ?? {};
    final hospital = json['hospital'] ?? {};

    return MidwifeProfile(
      id: json['id'] ?? '',
      userId: user['id'] ?? '',
      username: user['username'] ?? '',
      firstName: userProfile['first_name'] ?? user['first_name'] ?? '',
      lastName: userProfile['last_name'] ?? user['last_name'] ?? '',
      email: user['email'] ?? '',
      avatarUrl: userProfile['profile_image'] ?? user['avatar_url'],
      
      hospitalId: hospital['id'] ?? '',
      hospitalName: hospital['name'] ?? '',
      hospitalAddress: hospital['address'] ?? '',

      specialty: json['specialty'] ?? '',
      experienceYears: json['years_of_experience'] ?? json['experience_years'] ?? userProfile['years_of_experience'] ?? userProfile['experience_years'] ?? 0,
      languages: (json['languages'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
      bio: json['bio'] ?? '',
      offeredConsultationTypes: json['offered_consultation_types'] != null 
          ? List<String>.from(json['offered_consultation_types']) 
          : [],
      ratingAverage: double.tryParse(json['rating_average']?.toString() ?? '0') ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      isAcceptingBookings: json['is_accepting_bookings'] ?? false,
      consultationFee: json['consultation_fee'] ?? '0.00',
      verificationStatus: json['verification_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': {
        'id': userId,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'avatar_url': avatarUrl,
      },
      'hospital': {
        'id': hospitalId,
        'name': hospitalName,
        'address': hospitalAddress,
      },
      'specialty': specialty,
      'experience_years': experienceYears,
      'languages': languages.join(', '),
      'bio': bio,
      'offered_consultation_types': offeredConsultationTypes,
      'rating_average': ratingAverage.toStringAsFixed(2),
      'rating_count': ratingCount,
      'is_favorite': isFavorite,
      'is_accepting_bookings': isAcceptingBookings,
      'consultation_fee': consultationFee,
      'verification_status': verificationStatus,
    };
  }
}
