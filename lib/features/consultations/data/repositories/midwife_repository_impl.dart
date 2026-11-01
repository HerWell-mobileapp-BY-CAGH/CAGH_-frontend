import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/domain/repositories/midwife_repository.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/midwife_dashboard.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MidwifeRepositoryImpl implements MidwifeRepository {
  final MidwifeApiService _apiService;

  MidwifeRepositoryImpl(this._apiService);

  Future<MidwifeProfile> _applyLocalOverrides(MidwifeProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCustom = prefs.getString('midwife_profile_custom_saved');
      if (rawCustom != null && rawCustom.isNotEmpty) {
        final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
        final cF = custom['first_name']?.toString() ?? '';
        final cL = custom['last_name']?.toString() ?? '';
        final cBio = custom['bio']?.toString() ?? '';
        final cTitle = custom['title']?.toString() ?? custom['specialty']?.toString() ?? '';
        final cExp = custom['experience_years'];

        final updatedFirstName = cF.isNotEmpty ? cF : profile.firstName;
        final updatedLastName = cL.isNotEmpty ? cL : profile.lastName;
        final updatedBio = cBio.isNotEmpty ? cBio : profile.bio;
        final updatedSpecialty = cTitle.isNotEmpty ? cTitle : profile.specialty;
        final updatedExp = (cExp != null && cExp is int) ? cExp : profile.experienceYears;

        return profile.copyWith(
          firstName: updatedFirstName,
          lastName: updatedLastName,
          bio: updatedBio,
          specialty: updatedSpecialty,
          experienceYears: updatedExp,
        );
      }
    } catch (e) {
      AppLogger.d('MidwifeRepositoryImpl._applyLocalOverrides error: $e');
    }
    return profile;
  }

  Future<MidwifeProfile?> _buildFallbackMyProfile() async {
    try {
      final userData = await AuthService.getUserData();
      final prefs = await SharedPreferences.getInstance();
      final rawCustom = prefs.getString('midwife_profile_custom_saved');
      final custom = (rawCustom != null && rawCustom.isNotEmpty)
          ? jsonDecode(rawCustom) as Map<String, dynamic>
          : <String, dynamic>{};

      final fName = custom['first_name']?.toString() ?? userData['first_name']?.toString() ?? '';
      final lName = custom['last_name']?.toString() ?? userData['last_name']?.toString() ?? '';
      final bio = custom['bio']?.toString() ?? userData['bio']?.toString() ?? '';
      final title = custom['title']?.toString() ?? custom['specialty']?.toString() ?? userData['specialty']?.toString() ?? 'Certified Health Professional';
      final exp = custom['experience_years'] is int ? (custom['experience_years'] as int) : 0;

      return MidwifeProfile(
        id: (userData['id'] ?? 'me').toString(),
        userId: (userData['id'] ?? userData['user_id'] ?? '').toString(),
        username: (userData['username'] ?? '').toString(),
        firstName: fName.isNotEmpty ? fName : 'Midwife',
        lastName: lName,
        email: (userData['email'] ?? '').toString(),
        hospitalId: '',
        hospitalName: 'General Health Center',
        hospitalAddress: '',
        specialty: title,
        experienceYears: exp,
        languages: ['Amharic', 'English'],
        bio: bio,
        offeredConsultationTypes: ['In-Person', 'Voice Call'],
        ratingAverage: 5.0,
        ratingCount: 0,
        isFavorite: false,
        isAcceptingBookings: true,
        consultationFee: '0.00',
        verificationStatus: 'APPROVED',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MidwifeProfile>> getMidwives({String? search}) async {
    final response = await _apiService.getMidwives(search: search);
    final list = response.map((json) => MidwifeProfile.fromJson(Map<String, dynamic>.from(json as Map))).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCustom = prefs.getString('midwife_profile_custom_saved');
      if (rawCustom != null && rawCustom.isNotEmpty) {
        final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
        final savedId = custom['id']?.toString() ?? '';
        final savedUserId = custom['user_id']?.toString() ?? '';
        final savedEmail = custom['email']?.toString().toLowerCase() ?? '';
        final savedPhone = custom['phone_number']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

        final userData = await AuthService.getUserData();
        final myUserId = (userData['id'] ?? userData['user_id'] ?? '').toString();
        final myEmail = (userData['email'] ?? '').toString().toLowerCase();

        for (int i = 0; i < list.length; i++) {
          final mw = list[i];
          final matchesSaved = (savedId.isNotEmpty && mw.id == savedId) ||
              (savedUserId.isNotEmpty && mw.userId == savedUserId) ||
              (savedEmail.isNotEmpty && mw.email.toLowerCase() == savedEmail) ||
              (savedPhone.isNotEmpty && mw.username.replaceAll(RegExp(r'\D'), '') == savedPhone);

          final isCurrentMidwife = (myUserId.isNotEmpty && mw.userId == myUserId) ||
              (myEmail.isNotEmpty && mw.email.toLowerCase() == myEmail);

          final isDefaultPlaceholder = mw.fullName.toLowerCase().contains('midwife me') ||
              mw.firstName.toLowerCase() == 'midwife' ||
              (mw.firstName.toLowerCase() == 'midwife' && mw.lastName.toLowerCase() == 'me');

          if (matchesSaved || isCurrentMidwife || (isDefaultPlaceholder && (list.length == 1 || savedUserId.isNotEmpty))) {
            list[i] = await _applyLocalOverrides(mw);
          }
        }
      }
    } catch (_) {}

    return list;
  }

  @override
  Future<MidwifeProfile> getMidwifeProfile(String midwifeId) async {
    final response = await _apiService.getMidwifeProfile(midwifeId);
    final profile = MidwifeProfile.fromJson(Map<String, dynamic>.from(response as Map));
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCustom = prefs.getString('midwife_profile_custom_saved');
      if (rawCustom != null && rawCustom.isNotEmpty) {
        final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
        final savedId = custom['id']?.toString() ?? '';
        final savedUserId = custom['user_id']?.toString() ?? '';
        final savedEmail = custom['email']?.toString().toLowerCase() ?? '';
        final savedPhone = custom['phone_number']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

        final userData = await AuthService.getUserData();
        final myUserId = (userData['id'] ?? userData['user_id'] ?? '').toString();
        final myEmail = (userData['email'] ?? '').toString().toLowerCase();

        final matchesSaved = (savedId.isNotEmpty && (profile.id == savedId || midwifeId == savedId)) ||
            (savedUserId.isNotEmpty && profile.userId == savedUserId) ||
            (savedEmail.isNotEmpty && profile.email.toLowerCase() == savedEmail) ||
            (savedPhone.isNotEmpty && profile.username.replaceAll(RegExp(r'\D'), '') == savedPhone);

        final isCurrentMidwife = (myUserId.isNotEmpty && profile.userId == myUserId) ||
            (myEmail.isNotEmpty && profile.email.toLowerCase() == myEmail);

        final isDefaultPlaceholder = profile.fullName.toLowerCase().contains('midwife me') ||
            profile.firstName.toLowerCase() == 'midwife';

        if (matchesSaved || isCurrentMidwife || isDefaultPlaceholder) {
          return await _applyLocalOverrides(profile);
        }
      }
    } catch (_) {}
    return profile;
  }

  @override
  Future<MidwifeProfile?> getMyProfile() async {
    try {
      final response = await _apiService.getMyProfile();
      if (response == null) {
        return await _buildFallbackMyProfile();
      }
      final profile = MidwifeProfile.fromJson(Map<String, dynamic>.from(response as Map));
      return await _applyLocalOverrides(profile);
    } catch (e) {
      AppLogger.d('MidwifeRepositoryImpl.getMyProfile: $e');
      return await _buildFallbackMyProfile();
    }
  }

  @override
  Future<MidwifeProfile> createMyProfile(Map<String, dynamic> data) async {
    final response = await _apiService.createMyProfile(data);
    final profile = MidwifeProfile.fromJson(Map<String, dynamic>.from(response as Map));
    return await _applyLocalOverrides(profile);
  }

  @override
  Future<MidwifeProfile> toggleFavorite(String midwifeId) async {
    final response = await _apiService.toggleFavorite(midwifeId);
    return MidwifeProfile.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<MidwifeProfile> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateMyProfile(data);
    final profile = MidwifeProfile.fromJson(Map<String, dynamic>.from(response as Map));
    return await _applyLocalOverrides(profile);
  }

  @override
  Future<MidwifeDashboard> getDashboard() async {
    final response = await _apiService.getDashboard();
    return MidwifeDashboard.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<List<BlockedDate>> getBlockedDates() async {
    final response = await _apiService.getBlockedDates();
    return response
        .map((json) => BlockedDate.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  @override
  Future<BlockedDate> addBlockedDate(String date, String reason) async {
    final response = await _apiService.addBlockedDate(date, reason);
    return BlockedDate.fromJson(response);
  }

  @override
  Future<void> deleteBlockedDate(String id) async {
    await _apiService.deleteBlockedDate(id);
  }
}
