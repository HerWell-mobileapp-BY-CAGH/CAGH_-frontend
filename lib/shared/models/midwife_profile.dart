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
    // Extract genuine qualification, title, or non-default specialty
    String extractedSpecialty = '';

    // 1. Check qualifications list from backend
    if (json['qualifications'] is List && (json['qualifications'] as List).isNotEmpty) {
      final firstQ = (json['qualifications'] as List).first;
      if (firstQ is Map && firstQ['title'] != null && firstQ['title'].toString().trim().isNotEmpty) {
        extractedSpecialty = firstQ['title'].toString().trim();
      } else if (firstQ is String && firstQ.trim().isNotEmpty) {
        extractedSpecialty = firstQ.trim();
      }
    }

    // 2. Check expertises list from backend
    if (extractedSpecialty.isEmpty && json['expertises'] is List && (json['expertises'] as List).isNotEmpty) {
      final firstE = (json['expertises'] as List).first;
      if (firstE is Map && firstE['name'] != null && firstE['name'].toString().trim().isNotEmpty) {
        extractedSpecialty = firstE['name'].toString().trim();
      } else if (firstE is String && firstE.trim().isNotEmpty) {
        extractedSpecialty = firstE.trim();
      }
    }

    // 3. Check explicit qualification, title, or professional_title
    if (extractedSpecialty.isEmpty) {
      final titleCandidates = [
        json['qualification'],
        json['title'],
        json['professional_title'],
        userProfile['qualification'],
        userProfile['title'],
        userProfile['professional_title'],
      ];
      for (final t in titleCandidates) {
        if (t != null && t.toString().trim().isNotEmpty && t.toString().trim().toLowerCase() != 'null') {
          extractedSpecialty = t.toString().trim();
          break;
        }
      }
    }

    // 4. Check explicit specialty from backend (suppress generic placeholder "Maternal Health Specialist")
    if (extractedSpecialty.isEmpty) {
      final rawSpec = (json['specialty'] ?? userProfile['specialty'])?.toString().trim() ?? '';
      if (rawSpec.isNotEmpty &&
          rawSpec.toLowerCase() != 'null' &&
          rawSpec.toLowerCase() != 'maternal health specialist' &&
          rawSpec.toLowerCase() != 'maternal health') {
        extractedSpecialty = rawSpec;
      }
    }

    // 5. Final sanitation: completely blank if only the placeholder was provided
    if (extractedSpecialty.toLowerCase() == 'maternal health specialist' ||
        extractedSpecialty.toLowerCase() == 'maternal health' ||
        extractedSpecialty.toLowerCase() == 'null') {
      extractedSpecialty = '';
    }

    return MidwifeProfile(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: user['username']?.toString() ?? json['username']?.toString() ?? '',
      firstName: fName.isNotEmpty ? fName : (fullName.isNotEmpty ? fullName : 'Midwife'),
      lastName: lName,
      email: user['email']?.toString() ?? json['email']?.toString() ?? '',
      avatarUrl: (userProfile['profile_image'] ?? user['avatar_url'] ?? json['avatar_url'])?.toString(),
      
      hospitalId: hospital['id']?.toString() ?? json['hospital_id']?.toString() ?? '',
      hospitalName: (hospital['name'] ??
              json['hospital_name'] ??
              json['hospital_affiliation'] ??
              json['health_center'] ??
              json['workplace'] ??
              json['clinic'] ??
              userProfile['hospital_affiliation'] ??
              userProfile['hospital_name'] ??
              userProfile['health_center'] ??
              userProfile['hospital'] ??
              (json['hospital'] is String ? json['hospital'] : '') ??
              '')
          .toString()
          .trim(),
      hospitalAddress: hospital['address']?.toString() ?? json['hospital_address']?.toString() ?? '',

      specialty: extractedSpecialty,
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
