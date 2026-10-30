import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

import '../database/database_helper.dart';

class ApiService {
  static bool isOfflineMode = true;
  static const Duration timeout = Duration(seconds: 30);
  static const String adminEmail = DatabaseHelper.adminEmail;

  static Future<bool> checkBackendAvailability() async {
    try {
      await DatabaseHelper.instance.database;
      return true;
    } on sqflite.DatabaseException {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  static bool shouldUseOfflineFallback({String? url}) => true;

  static String getOfflineMessage(String fallback) => 'Offline mode: $fallback';

  static String get baseUrl => 'Local device';

  static String resolveUrl(String value) => value;

  static Map<String, dynamic> _success({int? id}) {
    final idField = id == null ? null : {'id': id};
    return {'success': true, ...?idField};
  }

  static Future<Map<String, dynamic>> getTestData() async {
    final neighbourhoods = await DatabaseHelper.instance.getNeighbourhoods();
    return {
      'success': true,
      'message': 'NeighbourConnect is using this device’s local database.',
      'database': [
        {'neighbourhoods': neighbourhoods.length},
      ],
    };
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await DatabaseHelper.instance.database;
    final existingUsers = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existingUsers.isNotEmpty) {
      throw Exception('An account with this email already exists');
    }

    final userId = await DatabaseHelper.instance.registerUser(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      phone: phone?.trim(),
    );
    return _success(id: userId);
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final user = await DatabaseHelper.instance.loginUser(
      email: email.trim(),
      password: password,
    );
    if (user == null) {
      throw Exception('Incorrect email or password on this device');
    }
    return {'success': true, 'user': user};
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final user = await DatabaseHelper.instance.getUser(userId);
    if (user == null) {
      throw Exception('User not found on this device');
    }
    return {'success': true, 'user': user};
  }

  static Future<List<dynamic>> getUsers() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('users', orderBy: 'name COLLATE NOCASE');
  }

  static Future<Map<String, dynamic>> getAdminDashboard({
    required int adminUserId,
  }) => DatabaseHelper.instance.getAdminDashboard(adminUserId);

  static Future<List<dynamic>> getNeighbourhoods() async =>
      DatabaseHelper.instance.getNeighbourhoods();

  static Future<Map<String, dynamic>> updateNeighbourhood({
    required int userId,
    required int neighbourhoodId,
  }) async {
    final updatedRows = await DatabaseHelper.instance.updateUserNeighbourhood(
      userId: userId,
      neighbourhoodId: neighbourhoodId,
    );
    if (updatedRows == 0) {
      throw Exception('Unable to update neighbourhood for this account');
    }
    final user = await DatabaseHelper.instance.getUser(userId);
    return {'success': true, 'user': user};
  }

  static Future<List<dynamic>> getPosts({
    required int neighbourhoodId,
    required int userId,
  }) async {
    final posts = await DatabaseHelper.instance.getPosts(
      neighbourhoodId: neighbourhoodId,
    );
    return Future.wait(
      posts.map((post) async {
        final postId = post['id'] as int;
        return {
          ...post,
          'liked': await DatabaseHelper.instance.isPostLiked(
            postId: postId,
            userId: userId,
          ),
          'likes_count': await DatabaseHelper.instance.getLikeCount(postId),
          'comments_count': await DatabaseHelper.instance.getCommentCount(
            postId,
          ),
        };
      }),
    );
  }

  static Future<Map<String, dynamic>> createPost({
    required int userId,
    required int neighbourhoodId,
    required String category,
    required String content,
    String? imageUrl,
  }) async {
    final postId = await DatabaseHelper.instance.createPost(
      userId: userId,
      neighbourhoodId: neighbourhoodId,
      category: category,
      content: content.trim(),
      imageUrl: imageUrl,
    );
    return _success(id: postId);
  }

  static Future<String> uploadPostImage(File image) async {
    if (!await image.exists()) {
      throw Exception('The selected image is no longer available');
    }

    final databasePath = await sqflite.getDatabasesPath();
    final imageDirectory = Directory(path.join(databasePath, 'post_images'));
    await imageDirectory.create(recursive: true);

    final extension = path.extension(image.path).toLowerCase();
    const supportedExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    };
    final savedExtension = supportedExtensions.contains(extension)
        ? extension
        : '.jpg';
    final destination = path.join(
      imageDirectory.path,
      '${DateTime.now().microsecondsSinceEpoch}$savedExtension',
    );
    await image.copy(destination);
    return destination;
  }

  static Future<Map<String, dynamic>> likePost({
    required int postId,
    required int userId,
  }) async {
    final isLiked = await DatabaseHelper.instance.isPostLiked(
      postId: postId,
      userId: userId,
    );
    if (!isLiked) {
      await DatabaseHelper.instance.toggleLike(postId: postId, userId: userId);
    }
    return _success(id: postId);
  }

  static Future<Map<String, dynamic>> unlikePost({
    required int postId,
    required int userId,
  }) async {
    final isLiked = await DatabaseHelper.instance.isPostLiked(
      postId: postId,
      userId: userId,
    );
    if (isLiked) {
      await DatabaseHelper.instance.toggleLike(postId: postId, userId: userId);
    }
    return _success(id: postId);
  }

  static Future<List<dynamic>> getComments(int postId) async =>
      DatabaseHelper.instance.getComments(postId);

  static Future<Map<String, dynamic>> addComment({
    required int postId,
    required int userId,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw Exception('Comment cannot be empty');
    }
    final commentId = await DatabaseHelper.instance.addComment(
      postId: postId,
      userId: userId,
      content: trimmedContent,
    );
    return _success(id: commentId);
  }

  static Future<List<dynamic>> getEvents(int neighbourhoodId) async =>
      DatabaseHelper.instance.getEvents(neighbourhoodId: neighbourhoodId);

  static Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    required int neighbourhoodId,
    required int organizerId,
    String? location,
    required String eventDate,
    String? imageUrl,
  }) async {
    final eventId = await DatabaseHelper.instance.addEvent(
      title: title.trim(),
      description: description,
      neighbourhoodId: neighbourhoodId,
      organizerId: organizerId,
      location: location,
      eventDate: eventDate,
      imageUrl: imageUrl,
    );
    return _success(id: eventId);
  }

  static Future<List<dynamic>> getIssues(int neighbourhoodId) async =>
      DatabaseHelper.instance.getIssues(neighbourhoodId: neighbourhoodId);

  static Future<Map<String, dynamic>> createIssue({
    required int userId,
    required int neighbourhoodId,
    required String category,
    required String title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final issueId = await DatabaseHelper.instance.addIssue(
      userId: userId,
      neighbourhoodId: neighbourhoodId,
      category: category,
      title: title.trim(),
      description: description,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
    );
    return _success(id: issueId);
  }
}
