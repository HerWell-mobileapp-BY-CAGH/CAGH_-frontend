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
  String get fullName {
    final raw = '$firstName $lastName'.trim();
    if (raw.isEmpty) return 'Midwife';
    return raw.split(' ').where((s) => s.isNotEmpty).map((s) => '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}').join(' ');
  }

  bool get supportsVoiceCall =>
      offeredConsultationTypes.any((t) => t.toLowerCase().contains('voice'));

  bool get supportsInPerson =>
      offeredConsultationTypes.any((t) => t.toLowerCase().contains('in-person') || t.toLowerCase().contains('in_person'));

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
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : <String, dynamic>{};
    final userProfile = user['profile'] is Map 
        ? Map<String, dynamic>.from(user['profile'] as Map) 
        : (json['profile'] is Map ? Map<String, dynamic>.from(json['profile'] as Map) : <String, dynamic>{});
    final hospital = json['hospital'] is Map ? Map<String, dynamic>.from(json['hospital'] as Map) : <String, dynamic>{};

    String fName = (userProfile['first_name'] ?? user['first_name'] ?? json['first_name'] ?? '').toString().trim();
    String lName = (userProfile['last_name'] ?? user['last_name'] ?? json['last_name'] ?? '').toString().trim();
    final fullName = (json['full_name'] ?? user['full_name'] ?? userProfile['full_name'] ?? '').toString().trim();
    if (fName.isEmpty && lName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      fName = parts.isNotEmpty ? parts.first : '';
      lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final rawStatus = json['verification_status']?.toString() ?? '';
    final status = rawStatus.isNotEmpty ? rawStatus : 'APPROVED';

    final rawTypes = json['offered_consultation_types'];
    final consultTypes = (rawTypes is List && rawTypes.isNotEmpty)
        ? rawTypes.map((e) => e.toString()).toList()
        : ['In-Person', 'Voice Call'];

    return MidwifeProfile(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: user['username']?.toString() ?? json['username']?.toString() ?? '',
      firstName: fName.isNotEmpty ? fName : (fullName.isNotEmpty ? fullName : 'Midwife'),
      lastName: lName,
      email: user['email']?.toString() ?? json['email']?.toString() ?? '',
      avatarUrl: (userProfile['profile_image'] ?? user['avatar_url'] ?? json['avatar_url'])?.toString(),
      
      hospitalId: hospital['id']?.toString() ?? json['hospital_id']?.toString() ?? '',
      hospitalName: hospital['name']?.toString() ?? json['hospital_name']?.toString() ?? (json['hospital'] is String ? json['hospital'].toString() : ''),
      hospitalAddress: hospital['address']?.toString() ?? json['hospital_address']?.toString() ?? '',

      specialty: json['specialty']?.toString() ?? 'Maternal Health Specialist',
      experienceYears: int.tryParse((json['years_of_experience'] ?? json['experience_years'] ?? userProfile['years_of_experience'] ?? userProfile['experience_years'])?.toString() ?? '') ?? 0,
      languages: json['languages'] is List
          ? (json['languages'] as List).map((e) => e.toString()).toList()
          : ((json['languages'] as String?)?.split(',').map((e) => e.trim()).toList() ?? ['Amharic', 'English']),
      bio: json['bio']?.toString() ?? '',
      offeredConsultationTypes: consultTypes,
      ratingAverage: double.tryParse(json['rating_average']?.toString() ?? '5.0') ?? 5.0,
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
      isFavorite: json['is_favorite'] == true,
      isAcceptingBookings: json['is_accepting_bookings'] != false,
      consultationFee: json['consultation_fee']?.toString() ?? '0.00',
      verificationStatus: status,
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
