import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/shared/models/midwife_dashboard.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';

abstract class MidwifeRepository {
  /// Fetch all midwife profiles
  Future<List<MidwifeProfile>> getMidwives({String? search});

  /// Fetch a specific midwife profile
  Future<MidwifeProfile> getMidwifeProfile(String midwifeId);

  /// Fetch the logged-in midwife's profile
  Future<MidwifeProfile?> getMyProfile();

  /// Create the logged-in midwife's profile
  Future<MidwifeProfile> createMyProfile(Map<String, dynamic> data);

  /// Update the logged-in midwife's profile
  Future<MidwifeProfile> updateMyProfile(Map<String, dynamic> data);

  /// Toggle favorite status for a midwife
  Future<MidwifeProfile> toggleFavorite(String midwifeId);

  /// Fetch dashboard data
  Future<MidwifeDashboard> getDashboard();

  /// Fetch blocked dates
  Future<List<BlockedDate>> getBlockedDates();

  /// Add a blocked date
  Future<BlockedDate> addBlockedDate(String date, String reason);

  /// Delete a blocked date
  Future<void> deleteBlockedDate(String id);
}
