import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String adminEmail = 'divya@gmail.com';

  static sqflite.Database? _database;

  DatabaseHelper._init();

  // ============================================================
  // DATABASE
  // ============================================================

  Future<sqflite.Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<sqflite.Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ffi.sqfliteFfiInit();
      sqflite.databaseFactory = ffi.databaseFactoryFfi;
    }

    final databasePath = await sqflite.getDatabasesPath();

    final path = join(databasePath, 'neighbourconnect.db');

    print('==================================================');
    print('NeighbourConnect SQLite Database');
    print('Database path: $path');
    print('==================================================');

    return await sqflite.openDatabase(
      path,
      version: 8,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDatabase(sqflite.Database db, int version) async {
    // ------------------------------------------------------------
    // USERS
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT,
        profile_image TEXT,
        neighbourhood_id INTEGER,
        role TEXT NOT NULL DEFAULT 'member',
        account_status TEXT NOT NULL DEFAULT 'approved',
        verification_status TEXT NOT NULL DEFAULT 'approved',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ------------------------------------------------------------
    // NEIGHBOURHOODS
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE neighbourhoods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ------------------------------------------------------------
    // POSTS
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        neighbourhood_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ------------------------------------------------------------
    // COMMENTS
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ------------------------------------------------------------
    // POST LIKES
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE post_likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(post_id, user_id)
      )
    ''');

    // ------------------------------------------------------------
    // EVENTS
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        neighbourhood_id INTEGER NOT NULL,
        organizer_id INTEGER NOT NULL,
        location TEXT,
        event_date TEXT NOT NULL,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ------------------------------------------------------------
    // ISSUES
    // ------------------------------------------------------------

    await db.execute('''
      CREATE TABLE issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        neighbourhood_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT DEFAULT 'Open',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ============================================================
    // DEFAULT NEIGHBOURHOODS
    // ============================================================

    await db.insert('neighbourhoods', {
      'name': 'Green Valley',
      'city': 'Chennai',
      'description': 'A friendly residential neighbourhood.',
    });

    await db.insert('neighbourhoods', {
      'name': 'Lake View',
      'city': 'Chennai',
      'description': 'A peaceful neighbourhood near the lake.',
    });

    await db.insert('neighbourhoods', {
      'name': 'Sunrise Colony',
      'city': 'Chennai',
      'description': 'A growing community with active residents.',
    });

    await db.insert('neighbourhoods', {
      'name': 'Garden City',
      'city': 'Bangalore',
      'description': 'A beautiful and active neighbourhood.',
    });

    await db.insert('neighbourhoods', {
      'name': 'Tech Park Area',
      'city': 'Bangalore',
      'description': 'A modern neighbourhood near technology parks.',
    });

    print('Database created successfully.');
    print('Default neighbourhoods inserted.');
  }

  // ============================================================
  // DATABASE UPGRADE
  // ============================================================

  Future<void> _upgradeDatabase(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'member'",
      );
    }

    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN verification_status TEXT NOT NULL DEFAULT 'pending'",
      );
      await db.update('users', {
        'role': 'member',
        'verification_status': 'pending',
      });
      await db.update(
        'users',
        {'role': 'admin', 'verification_status': 'approved'},
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [adminEmail],
      );
    }

    if (oldVersion < 5) {
      await db.update(
        'users',
        {'role': 'member'},
        where: 'role = ?',
        whereArgs: ['admin'],
      );
      await db.update(
        'users',
        {'role': 'super_admin', 'verification_status': 'approved'},
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [adminEmail],
      );
    }

    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN account_status TEXT NOT NULL DEFAULT 'pending'",
      );
      await db.update(
        'users',
        {'role': 'super_admin', 'account_status': 'approved'},
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [adminEmail],
      );
    }

    if (oldVersion < 7) {
      await db.update(
        'users',
        {'role': 'member'},
        where: "role IN (?, ?) OR (role = ? AND email != ? COLLATE NOCASE)",
        whereArgs: ['community_admin', 'admin', 'super_admin', adminEmail],
      );
      await db.update(
        'users',
        {
          'role': 'super_admin',
          'account_status': 'approved',
          'verification_status': 'approved',
        },
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [adminEmail],
      );
      await db.execute(
        'UPDATE users SET verification_status = account_status '
        'WHERE role != ?',
        ['super_admin'],
      );
    }

    if (oldVersion < 8) {
      await db.update(
        'users',
        {'account_status': 'approved', 'verification_status': 'approved'},
        where: 'role != ?',
        whereArgs: ['super_admin'],
      );
    }

    if (oldVersion < 2) {
      final count = await db.rawQuery(
        'SELECT COUNT(*) as count FROM neighbourhoods',
      );

      final number = (count.first['count'] as int?) ?? 0;

      if (number == 0) {
        await db.insert('neighbourhoods', {
          'name': 'Green Valley',
          'city': 'Chennai',
          'description': 'A friendly residential neighbourhood.',
        });

        await db.insert('neighbourhoods', {
          'name': 'Lake View',
          'city': 'Chennai',
          'description': 'A peaceful neighbourhood near the lake.',
        });

        await db.insert('neighbourhoods', {
          'name': 'Sunrise Colony',
          'city': 'Chennai',
          'description': 'A growing community with active residents.',
        });

        await db.insert('neighbourhoods', {
          'name': 'Garden City',
          'city': 'Bangalore',
          'description': 'A beautiful and active neighbourhood.',
        });

        await db.insert('neighbourhoods', {
          'name': 'Tech Park Area',
          'city': 'Bangalore',
          'description': 'A modern neighbourhood near technology parks.',
        });

        print('Neighbourhoods added during database upgrade.');
      }
    }
  }

  // ============================================================
  // USERS
  // ============================================================

  Future<int> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final db = await database;

    return db.transaction((transaction) async {
      return transaction.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': email.toLowerCase() == adminEmail ? 'super_admin' : 'member',
        'account_status': 'approved',
        'verification_status': 'approved',
      });
    });
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );

    if (result.isEmpty) {
      print('Login failed for: $email');
      return null;
    }

    final user = Map<String, dynamic>.from(result.first);
    if (email.toLowerCase() == adminEmail) {
      await db.update(
        'users',
        {
          'role': 'super_admin',
          'account_status': 'approved',
          'verification_status': 'approved',
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );
      user['role'] = 'super_admin';
      user['verification_status'] = 'approved';
    }

    return user;
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<Map<String, dynamic>> getAdminDashboard(int adminUserId) async {
    final db = await database;
    final adminResults = await db.query(
      'users',
      columns: ['role', 'neighbourhood_id'],
      where: 'id = ?',
      whereArgs: [adminUserId],
      limit: 1,
    );

    if (adminResults.isEmpty) {
      throw Exception('Admin access required');
    }
    if (adminResults.first['role'] != 'super_admin') {
      throw Exception('Admin access required');
    }

    final members = await db.rawQuery(
      '''
      SELECT
        users.id,
        users.name,
        users.email,
        users.phone,
        users.profile_image,
        users.neighbourhood_id,
        users.created_at,
        users.account_status,
        users.verification_status,
        users.role,
        neighbourhoods.name AS neighbourhood_name,
        neighbourhoods.city AS neighbourhood_city
      FROM users
      LEFT JOIN neighbourhoods
        ON users.neighbourhood_id = neighbourhoods.id
      WHERE users.role != ?
      ORDER BY users.name COLLATE NOCASE
    ''',
      ['super_admin'],
    );
    final neighbourhoods = await getNeighbourhoods();

    return {
      'members': members,
      'neighbourhoods': neighbourhoods,
      'events': await getEvents(),
      'scope': 'super_admin',
    };
  }

  Future<int> updateUser({
    required int userId,
    required String name,
    String? phone,
  }) async {
    final db = await database;

    return await db.update(
      'users',
      {'name': name, 'phone': phone},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // NEIGHBOURHOODS
  // ============================================================

  Future<List<Map<String, dynamic>>> getNeighbourhoods({
    String search = '',
  }) async {
    final db = await database;

    final text = search.trim();

    if (text.isEmpty) {
      return await db.query('neighbourhoods', orderBy: 'name ASC');
    }

    return await db.query(
      'neighbourhoods',
      where: 'name LIKE ? OR city LIKE ?',
      whereArgs: ['%$text%', '%$text%'],
      orderBy: 'name ASC',
    );
  }

  Future<int> addNeighbourhood({
    required String name,
    required String city,
    String? description,
  }) async {
    final db = await database;

    return await db.insert('neighbourhoods', {
      'name': name,
      'city': city,
      'description': description,
    });
  }

  Future<Map<String, dynamic>?> getNeighbourhood(int id) async {
    final db = await database;

    final result = await db.query(
      'neighbourhoods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateUserNeighbourhood({
    required int userId,
    required int neighbourhoodId,
  }) async {
    final db = await database;
    final user = await db.query(
      'users',
      columns: ['role', 'neighbourhood_id'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (user.isEmpty) return 0;
    return await db.update(
      'users',
      {'neighbourhood_id': neighbourhoodId},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // POSTS
  // ============================================================

  Future<int> createPost({
    required int userId,
    required int neighbourhoodId,
    required String category,
    required String content,
    String? imageUrl,
  }) async {
    final db = await database;

    return await db.insert('posts', {
      'user_id': userId,
      'neighbourhood_id': neighbourhoodId,
      'category': category,
      'content': content,
      'image_url': imageUrl,
    });
  }

  Future<int> addPost({
    required int userId,
    required int neighbourhoodId,
    required String category,
    required String content,
    String? imageUrl,
  }) async {
    return createPost(
      userId: userId,
      neighbourhoodId: neighbourhoodId,
      category: category,
      content: content,
      imageUrl: imageUrl,
    );
  }

  Future<List<Map<String, dynamic>>> getPosts({int? neighbourhoodId}) async {
    final db = await database;

    String query = '''
      SELECT
        posts.id,
        posts.user_id,
        posts.neighbourhood_id,
        posts.category,
        posts.content,
        posts.image_url,
        posts.created_at,
        users.name,
        users.email,
        users.profile_image
      FROM posts
      INNER JOIN users
        ON posts.user_id = users.id
    ''';

    final List<dynamic> arguments = [];

    if (neighbourhoodId != null) {
      query += '''
        WHERE posts.neighbourhood_id = ?
      ''';

      arguments.add(neighbourhoodId);
    }

    query += '''
      ORDER BY posts.id DESC
    ''';

    return await db.rawQuery(query, arguments);
  }

  Future<Map<String, dynamic>?> getPost(int postId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        posts.*,
        users.name,
        users.email,
        users.profile_image
      FROM posts
      INNER JOIN users
        ON posts.user_id = users.id
      WHERE posts.id = ?
      LIMIT 1
      ''',
      [postId],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getUserPosts(int userId) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT
        posts.*,
        users.name
      FROM posts
      INNER JOIN users
        ON posts.user_id = users.id
      WHERE posts.user_id = ?
      ORDER BY posts.id DESC
      ''',
      [userId],
    );
  }

  // ============================================================
  // LIKES
  // ============================================================

  Future<bool> toggleLike({required int postId, required int userId}) async {
    final db = await database;

    final existing = await db.query(
      'post_likes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'post_likes',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
      );

      return false;
    }

    await db.insert('post_likes', {'post_id': postId, 'user_id': userId});

    return true;
  }

  Future<int> getLikeCount(int postId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM post_likes
      WHERE post_id = ?
      ''',
      [postId],
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as int?) ?? 0;
  }

  Future<bool> isPostLiked({required int postId, required int userId}) async {
    final db = await database;

    final result = await db.query(
      'post_likes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Future<int> addComment({
    required int postId,
    required int userId,
    required String content,
  }) async {
    final db = await database;

    return await db.insert('comments', {
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT
        comments.id,
        comments.post_id,
        comments.user_id,
        comments.content,
        comments.created_at,
        users.name,
        users.profile_image
      FROM comments
      INNER JOIN users
        ON comments.user_id = users.id
      WHERE comments.post_id = ?
      ORDER BY comments.id ASC
      ''',
      [postId],
    );
  }

  Future<int> getCommentCount(int postId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM comments
      WHERE post_id = ?
      ''',
      [postId],
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // EVENTS
  // ============================================================

  Future<int> addEvent({
    required String title,
    String? description,
    required int neighbourhoodId,
    required int organizerId,
    String? location,
    required String eventDate,
    String? imageUrl,
  }) async {
    final db = await database;

    return await db.insert('events', {
      'title': title,
      'description': description,
      'neighbourhood_id': neighbourhoodId,
      'organizer_id': organizerId,
      'location': location,
      'event_date': eventDate,
      'image_url': imageUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getEvents({int? neighbourhoodId}) async {
    final db = await database;

    if (neighbourhoodId != null) {
      return await db.rawQuery(
        '''
        SELECT
          events.*,
          users.name AS organizer_name,
          neighbourhoods.name AS neighbourhood_name
        FROM events
        INNER JOIN users
          ON events.organizer_id = users.id
        INNER JOIN neighbourhoods
          ON events.neighbourhood_id = neighbourhoods.id
        WHERE events.neighbourhood_id = ?
        ORDER BY events.event_date ASC
        ''',
        [neighbourhoodId],
      );
    }

    return await db.rawQuery('''
      SELECT
        events.*,
        users.name AS organizer_name,
        neighbourhoods.name AS neighbourhood_name
      FROM events
      INNER JOIN users
        ON events.organizer_id = users.id
      INNER JOIN neighbourhoods
        ON events.neighbourhood_id = neighbourhoods.id
      ORDER BY events.event_date ASC
      ''');
  }

  Future<List<Map<String, dynamic>>> getUserEvents(int userId) async {
    final db = await database;

    return await db.query(
      'events',
      where: 'organizer_id = ?',
      whereArgs: [userId],
      orderBy: 'event_date ASC',
    );
  }

  // ============================================================
  // ISSUES
  // ============================================================

  Future<int> addIssue({
    required int userId,
    required int neighbourhoodId,
    required String category,
    required String title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;

    return await db.insert('issues', {
      'user_id': userId,
      'neighbourhood_id': neighbourhoodId,
      'category': category,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getIssues({int? neighbourhoodId}) async {
    final db = await database;

    if (neighbourhoodId != null) {
      return await db.query(
        'issues',
        where: 'neighbourhood_id = ?',
        whereArgs: [neighbourhoodId],
        orderBy: 'id DESC',
      );
    }

    return await db.query('issues', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getUserIssues(int userId) async {
    final db = await database;

    return await db.query(
      'issues',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateIssueStatus({
    required int issueId,
    required String status,
  }) async {
    final db = await database;

    return await db.update(
      'issues',
      {'status': status},
      where: 'id = ?',
      whereArgs: [issueId],
    );
  }

  // ============================================================
  // DATABASE DEBUG / RECORDS
  // ============================================================

  Future<void> printDatabaseRecords() async {
    final db = await database;

    print('');
    print('==================================================');
    print('        NEIGHBOURCONNECT DATABASE');
    print('==================================================');

    // ------------------------------------------------------------
    // USERS
    // ------------------------------------------------------------

    final users = await db.query('users');

    print('');
    print('---------------- USERS ----------------');
    print('Total users: ${users.length}');

    for (final user in users) {
      print(user);
    }

    // ------------------------------------------------------------
    // NEIGHBOURHOODS
    // ------------------------------------------------------------

    final neighbourhoods = await db.query('neighbourhoods');

    print('');
    print('------------ NEIGHBOURHOODS ------------');
    print('Total neighbourhoods: ${neighbourhoods.length}');

    for (final neighbourhood in neighbourhoods) {
      print(neighbourhood);
    }

    // ------------------------------------------------------------
    // POSTS
    // ------------------------------------------------------------

    final posts = await db.query('posts');

    print('');
    print('---------------- POSTS ----------------');
    print('Total posts: ${posts.length}');

    for (final post in posts) {
      print(post);
    }

    // ------------------------------------------------------------
    // COMMENTS
    // ------------------------------------------------------------

    final comments = await db.query('comments');

    print('');
    print('--------------- COMMENTS ---------------');
    print('Total comments: ${comments.length}');

    for (final comment in comments) {
      print(comment);
    }

    // ------------------------------------------------------------
    // LIKES
    // ------------------------------------------------------------

    final likes = await db.query('post_likes');

    print('');
    print('------------- POST LIKES ---------------');
    print('Total likes: ${likes.length}');

    for (final like in likes) {
      print(like);
    }

    // ------------------------------------------------------------
    // EVENTS
    // ------------------------------------------------------------

    final events = await db.query('events');

    print('');
    print('---------------- EVENTS ----------------');
    print('Total events: ${events.length}');

    for (final event in events) {
      print(event);
    }

    // ------------------------------------------------------------
    // ISSUES
    // ------------------------------------------------------------

    final issues = await db.query('issues');

    print('');
    print('---------------- ISSUES ----------------');
    print('Total issues: ${issues.length}');

    for (final issue in issues) {
      print(issue);
    }

    print('');
    print('==================================================');
    print('       DATABASE CONNECTION SUCCESSFUL');
    print('==================================================');
    print('');
  }

  // ============================================================
  // DATABASE CLOSE
  // ============================================================

  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;

    print('Database closed.');
  }
}
