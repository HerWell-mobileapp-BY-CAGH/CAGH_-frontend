import 'package:cagh_frontend/features/consultations/domain/repositories/midwife_repository.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/midwife_dashboard.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';

class MidwifeRepositoryImpl implements MidwifeRepository {
  final MidwifeApiService _apiService;

  MidwifeRepositoryImpl(this._apiService);

  @override
  Future<List<MidwifeProfile>> getMidwives({String? search}) async {
    final response = await _apiService.getMidwives(search: search);
    return response.map((json) => MidwifeProfile.fromJson(json)).toList();
  }

  @override
  Future<MidwifeProfile> getMidwifeProfile(String midwifeId) async {
    final response = await _apiService.getMidwifeProfile(midwifeId);
    return MidwifeProfile.fromJson(response);
  }

  @override
  Future<MidwifeProfile> getMyProfile() async {
    final response = await _apiService.getMyProfile();
    return MidwifeProfile.fromJson(response);
  }

  @override
  Future<MidwifeProfile> toggleFavorite(String midwifeId) async {
    final response = await _apiService.toggleFavorite(midwifeId);
    return MidwifeProfile.fromJson(response);
  }

  @override
  Future<MidwifeProfile> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateMyProfile(data);
    return MidwifeProfile.fromJson(response);
  }

  @override
  Future<MidwifeDashboard> getDashboard() async {
    final response = await _apiService.getDashboard();
    return MidwifeDashboard.fromJson(response);
  }

  @override
  Future<List<BlockedDate>> getBlockedDates() async {
    final response = await _apiService.getBlockedDates();
    return response.map((json) => BlockedDate.fromJson(json)).toList();
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
