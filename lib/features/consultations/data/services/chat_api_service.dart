import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ChatApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getChatRooms() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/rooms/');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to load chat rooms: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> initiateChat({
    required String midwifeId,
    required String initialMessage,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/rooms/');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'midwife': midwifeId,
        'initial_message': initialMessage,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate chat: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getMessageHistory(String roomId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/messages/');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  static Future<void> markMessagesAsRead(String roomId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/read/');
    final headers = await _getHeaders();

    await http.post(url, headers: headers);
  }

  static Future<void> acceptChat(String roomId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chat/rooms/$roomId/accept/');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to accept chat: ${response.statusCode}');
    }
  }

  static Future<void> rejectChat(String roomId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chat/rooms/$roomId/reject/');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to reject chat: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> uploadAttachment(String roomId, PlatformFile file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/attachments/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    var request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final mimeTypeData = lookupMimeType(file.name, headerBytes: file.bytes)?.split('/');
    
    if (kIsWeb) {
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachment', // Use 'attachment' instead of 'file' in case that's what the model expects
            file.bytes!,
            filename: file.name,
            contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
          ),
        );
      } else {
        throw Exception('File has no bytes on web');
      }
    } else {
      if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment', // Use 'attachment' instead of 'file'
            file.path!,
            contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
          ),
        );
      } else if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachment', // Use 'attachment' instead of 'file'
            file.bytes!,
            filename: file.name,
            contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
          ),
        );
      } else {
        throw Exception('File has no path and no bytes');
      }
    }

    // Since we are creating a message directly, we must include the required message fields.
    request.fields['content'] = file.name; // Use file name as content
    request.fields['message_type'] = 'FILE';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to upload attachment: ${response.statusCode} - $responseBody');
    }
  }
}
