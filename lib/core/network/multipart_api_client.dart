import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:logging/logging.dart';

class MultipartApiClient {
  static final _log = Logger('MultipartApiClient');

  /// Uploads a single file and fields to the specified endpoint.
  static Future<http.StreamedResponse> uploadFile({
    required String endpoint,
    required String method, // 'POST' or 'PATCH'
    required File file,
    required String fileFieldName,
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    _log.info('Uploading file to: $url via $method');

    final request = http.MultipartRequest(method, url);

    // Add authorization header
    final token = await AuthService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add normal string fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add the file
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mediaType = MediaType.parse(mimeType);
    
    final multipartFile = await http.MultipartFile.fromPath(
      fileFieldName,
      file.path,
      contentType: mediaType,
    );
    
    request.files.add(multipartFile);

    try {
      final response = await request.send();
      _log.info('Upload response status: ${response.statusCode}');
      return response;
    } catch (e) {
      _log.severe('Error uploading file', e);
      rethrow;
    }
  }
}
