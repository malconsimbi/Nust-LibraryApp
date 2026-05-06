import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../models/models.dart';

class ApiService {
  static String get baseUrl => EnvConfig.apiBaseUrl;

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      throw Exception('Request failed: ${response.statusCode} - ${body['error'] ?? response.body}');
    }
    return json.decode(response.body);
  }

  Future<dynamic> _post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body ?? <String, dynamic>{}),
    );
    if (response.statusCode >= 400) {
      final resBody = json.decode(response.body);
      throw Exception('Request failed: ${response.statusCode} - ${resBody['error'] ?? response.body}');
    }
    return json.decode(response.body);
  }

  Future<HomePayload> getHomePayload() async {
    final data = await _get('/home');
    return HomePayload.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PdfDocument>> getFeaturedPdfs() async {
    final data = await _get('/pdfs/featured/list');
    return (data as List<dynamic>).map((item) => PdfDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Category>> getCategories() async {
    final data = await _get('/categories');
    return (data as List<dynamic>).map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PdfDocument>> searchPdfs({
    String? query,
    String? categoryId,
    String? sort,
  }) async {
    final body = await _get(
      '/pdfs',
      query: {
        if (query != null && query.isNotEmpty) 'search': query,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
    );
    final list = (body['data'] as List<dynamic>? ?? const []);
    return list.map((item) => PdfDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SearchPayload> getSearchPayload({String? query, String? categoryId}) async {
    final data = await _get(
      '/search',
      query: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      },
    );
    return SearchPayload.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PdfDocument> getPdfDetails(String id) async {
    final data = await _get('/pdfs/$id');
    return PdfDocument.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<String> getDownloadUrl(String id) async {
    final data = await _post('/pdfs/$id/download');
    return data['file_url'].toString();
  }

  Future<List<BookmarkItem>> getBookmarks(String userId) async {
    final data = await _get('/bookmarks/$userId');
    return (data as List<dynamic>).map((item) => BookmarkItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleBookmark(String userId, String pdfId) async {
    final data = await _post('/bookmarks', body: {'user_id': userId, 'pdf_id': pdfId});
    return data['saved'] as bool? ?? false;
  }

  Future<bool> checkBookmark(String userId, String pdfId) async {
    try {
      final data = await _get('/bookmarks/$userId/check/$pdfId');
      return data['saved'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<PdfDocument>> getUserUploads(String userId) async {
    final data = await _get('/uploads/$userId');
    return (data as List<dynamic>).map((item) => PdfDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createUpload(Map<String, dynamic> payload) async {
    await _post('/uploads', body: payload);
  }

  Future<Map<String, dynamic>> uploadFile(List<int> bytes, String fileName, {String? folder, String? bucket}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/storage/upload'));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));
    if (folder != null) request.fields['folder'] = folder;
    if (bucket != null) request.fields['bucket'] = bucket;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      final resBody = json.decode(response.body);
      throw Exception('Upload failed: ${response.statusCode} - ${resBody['error'] ?? response.body}');
    }

    return json.decode(response.body);
  }

  Future<List<Map<String, dynamic>>> getModerationQueue() async {
    final data = await _get('/moderation/queue');
    return (data as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getDownloads(String userId) async {
    final data = await _get('/downloads/$userId');
    return (data as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Review>> getReviews(String documentId) async {
    final data = await _get('/ratings/$documentId');
    return (data as List<dynamic>).map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> submitReview(Map<String, dynamic> payload) async {
    await _post('/ratings', body: payload);
  }

  Future<void> flagDocument(Map<String, dynamic> payload) async {
    await _post('/flags', body: payload);
  }

  Future<AdminDashboardPayload> getAdminDashboard() async {
    final data = await _get('/admin/dashboard');
    return AdminDashboardPayload.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PdfDocument>> getAdminDocuments() async {
    final data = await _get('/admin/documents');
    return (data as List<dynamic>).map((item) => PdfDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final data = await _get('/admin/users');
    return (data as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final data = await _get('/admin/analytics');
    return Map<String, dynamic>.from(data as Map);
  }

  // Onboarding

  Future<List<Map<String, dynamic>>> getFaculties() async {
    final data = await _get('/onboarding/faculties');
    return (data as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getPrograms(String facultyId) async {
    final data = await _get('/onboarding/programs', query: {'faculty_id': facultyId});
    return (data as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> submitOnboardingCompletion({
    required String userId,
    required String facultyId,
    required String programId,
    required String year,
    required String feedback,
  }) async {
    await _post('/onboarding/complete', body: {
      'user_id': userId,
      'faculty_id': facultyId,
      'program_id': programId,
      'year': year,
      'feedback': feedback,
    });
  }

  Future<void> deleteDocument(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/pdfs/$id'));
    if (response.statusCode >= 400) {
      final resBody = json.decode(response.body);
      throw Exception('Delete failed: ${response.statusCode} - ${resBody['error'] ?? response.body}');
    }
  }

  Future<void> updateDocument(String id, Map<String, dynamic> payload) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/pdfs/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (response.statusCode >= 400) {
      final resBody = json.decode(response.body);
      throw Exception('Update failed: ${response.statusCode} - ${resBody['error'] ?? response.body}');
    }
  }
}
