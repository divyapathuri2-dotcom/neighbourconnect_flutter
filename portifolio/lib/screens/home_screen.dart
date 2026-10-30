import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'admin_portal_screens.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = AppColors.primary;
  static const Color background = AppColors.background;

  // ============================================================
  // DATA
  // ============================================================

  Map<String, dynamic>? user;
  Map<String, dynamic>? neighbourhood;

  List<dynamic> neighbourhoods = [];
  List<dynamic> posts = [];
  List<dynamic> events = [];
  List<dynamic> issues = [];

  bool loading = true;
  bool loadingPosts = false;
  bool loadingEvents = false;
  bool loadingIssues = false;
  bool checkingApprovalStatus = false;
  bool postsLoadFailed = false;
  String? approvalStatusMessage;
  bool approvalStatusCheckFailed = false;
  final Set<int> likingPostIds = {};

  int selectedTab = 0;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final postController = TextEditingController();
  final postImageController = TextEditingController();
  File? selectedPostImage;
  bool creatingPost = false;

  final eventTitleController = TextEditingController();
  final eventDescriptionController = TextEditingController();
  final eventLocationController = TextEditingController();

  final issueTitleController = TextEditingController();
  final issueDescriptionController = TextEditingController();

  final commentController = TextEditingController();

  String selectedPostCategory = 'Community';
  String selectedIssueCategory = 'General';

  DateTime? selectedEventDate;

  bool canAccessCommunity(Map<String, dynamic> account) {
    return true;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadHome();
  }

  // ============================================================
  // LOAD HOME
  // ============================================================

  Future<void> loadHome() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final profile = await ApiService.getUserProfile(widget.userId);

      if (!mounted) return;

      final profileUser = Map<String, dynamic>.from(profile['user'] ?? {});

      setState(() {
        user = profileUser;
        if (selectedTab > 3) {
          selectedTab = 0;
        }
      });

      final neighbourhoodId = profileUser['neighbourhood_id'];

      final allNeighbourhoods = await ApiService.getNeighbourhoods();

      if (!mounted) return;

      Map<String, dynamic>? selectedNeighbourhood;

      if (neighbourhoodId != null) {
        for (final item in allNeighbourhoods) {
          if (item['id'].toString() == neighbourhoodId.toString()) {
            selectedNeighbourhood = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      setState(() {
        neighbourhoods = allNeighbourhoods;
        neighbourhood = selectedNeighbourhood;
      });

      final hasCommunityAccess = canAccessCommunity(profileUser);
      if (neighbourhood != null && hasCommunityAccess) {
        await Future.wait([loadPosts(), loadEvents(), loadIssues()]);
      }
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to load data: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _checkApprovalStatus() async {
    if (checkingApprovalStatus) return;

    setState(() {
      checkingApprovalStatus = true;
      approvalStatusMessage = null;
      approvalStatusCheckFailed = false;
    });

    try {
      final result = await ApiService.getUserProfile(widget.userId);
      if (!mounted) return;

      final refreshedUser = Map<String, dynamic>.from(result['user'] ?? {});
      setState(() => user = refreshedUser);

      if (canAccessCommunity(refreshedUser)) {
        if (neighbourhood != null) {
          await Future.wait([loadPosts(), loadEvents(), loadIssues()]);
        }
        if (!mounted) return;
        showMessage(
          'Your account is approved. Community access is now active.',
        );
      } else {
        final status = refreshedUser['account_status']?.toString() ?? 'pending';
        setState(() {
          approvalStatusMessage = status == 'rejected'
              ? 'Your registration was not approved. Contact the project administrator if you think this is a mistake.'
              : 'Your registration is still waiting for Super Admin approval.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        approvalStatusCheckFailed = true;
        approvalStatusMessage =
            'We could not check your status. Please try again.';
      });
      showMessage(
        'Could not check approval status: ${cleanError(error)}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => checkingApprovalStatus = false);
    }
  }

  // ============================================================
  // LOAD POSTS
  // ============================================================

  Future<void> loadPosts() async {
    if (neighbourhood == null) return;

    if (mounted) {
      setState(() {
        loadingPosts = true;
      });
    }

    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      final result = await ApiService.getPosts(
        neighbourhoodId: neighbourhoodId,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        posts = result;
        postsLoadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        postsLoadFailed = true;
      });
      showMessage('Failed to load posts: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() {
          loadingPosts = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD EVENTS
  // ============================================================

  Future<void> loadEvents() async {
    if (neighbourhood == null) return;

    if (mounted) {
      setState(() {
        loadingEvents = true;
      });
    }

    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      final result = await ApiService.getEvents(neighbourhoodId);

      if (!mounted) return;

      setState(() {
        events = result;
      });
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to load events: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() {
          loadingEvents = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD ISSUES
  // ============================================================

  Future<void> loadIssues() async {
    if (neighbourhood == null) return;

    if (mounted) {
      setState(() {
        loadingIssues = true;
      });
    }

    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      final result = await ApiService.getIssues(neighbourhoodId);

      if (!mounted) return;

      setState(() {
        issues = result;
      });
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to load issues: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() {
          loadingIssues = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE NEIGHBOURHOOD
  // ============================================================

  Future<void> changeNeighbourhood(Map<String, dynamic> selected) async {
    try {
      final neighbourhoodId = int.tryParse(selected['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      await ApiService.updateNeighbourhood(
        userId: widget.userId,
        neighbourhoodId: neighbourhoodId,
      );

      if (!mounted) return;

      setState(() {
        neighbourhood = selected;
        user?['neighbourhood_id'] = selected['id'];
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });

      showMessage('Neighbourhood updated successfully');

      if (user != null && canAccessCommunity(user!)) {
        await Future.wait([loadPosts(), loadEvents(), loadIssues()]);
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Failed to update neighbourhood: ${cleanError(e)}',
        error: true,
      );
    }
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> createPost() async {
    if (creatingPost) return;

    final content = postController.text.trim();

    if (content.isEmpty) {
      showMessage('Please enter some content', error: true);
      return;
    }

    if (neighbourhood == null) {
      showMessage('Please select a neighbourhood first', error: true);
      return;
    }

    setState(() => creatingPost = true);
    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      final imageUrl = selectedPostImage != null
          ? await ApiService.uploadPostImage(selectedPostImage!)
          : postImageController.text.trim();

      await ApiService.createPost(
        userId: widget.userId,
        neighbourhoodId: neighbourhoodId,
        category: selectedPostCategory,
        content: content,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
      );

      if (!mounted) return;

      Navigator.pop(context);

      postController.clear();
      postImageController.clear();
      selectedPostImage = null;

      showMessage('Post created successfully');

      await loadPosts();
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to create post: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) setState(() => creatingPost = false);
    }
  }

  Future<void> pickPostImage(
    void Function(void Function()) updateDialog,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;
      selectedPostImage = File(path);
      updateDialog(() {});
    } catch (e) {
      if (mounted) {
        showMessage('Unable to select image: ${cleanError(e)}', error: true);
      }
    }
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  String? resolveImageUrl(dynamic value) {
    if (value == null) {
      return null;
    }

    final originalUrl = value.toString().trim();
    if (originalUrl.isEmpty || originalUrl.toLowerCase() == 'null') {
      return null;
    }

    final uri = Uri.tryParse(originalUrl);
    if (uri?.hasScheme == true &&
        (uri!.scheme == 'http' || uri.scheme == 'https')) {
      debugPrint('Ignoring online-only image "$originalUrl" in offline mode');
      return null;
    }

    if (uri?.scheme == 'file') {
      return uri!.toFilePath();
    }
    return originalUrl;
  }

  String? getImageUrl(dynamic post) {
    final value = post['image_url'] ?? post['image'] ?? post['imageUrl'];
    return resolveImageUrl(value);
  }

  // ============================================================
  // LIKE / UNLIKE
  // ============================================================

  Future<void> toggleLike(dynamic post) async {
    final postId = int.tryParse(post['id'].toString());

    if (postId == null) {
      showMessage('Invalid post ID', error: true);
      return;
    }

    if (likingPostIds.contains(postId)) return;

    final currentlyLiked = getPostLiked(post);

    setState(() => likingPostIds.add(postId));
    try {
      if (currentlyLiked) {
        await ApiService.unlikePost(postId: postId, userId: widget.userId);
      } else {
        await ApiService.likePost(postId: postId, userId: widget.userId);
      }

      // Refresh from server.
      await loadPosts();
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to update like: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) setState(() => likingPostIds.remove(postId));
    }
  }

  String formatPostTime(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // CHECK LIKE
  // ============================================================

  bool getPostLiked(dynamic post) {
    final value =
        post['liked'] ??
        post['is_liked'] ??
        post['user_liked'] ??
        post['has_liked'] ??
        false;

    if (value is bool) {
      return value;
    }

    final text = value.toString().toLowerCase();

    return text == '1' || text == 'true' || text == 'yes';
  }

  // ============================================================
  // LIKE COUNT
  // ============================================================

  int getLikeCount(dynamic post) {
    final value =
        post['likes_count'] ?? post['like_count'] ?? post['likes'] ?? 0;

    if (value is List) {
      return value.length;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // COMMENT COUNT
  // ============================================================

  int getCommentCount(dynamic post) {
    final value =
        post['comments_count'] ??
        post['comment_count'] ??
        post['comments'] ??
        0;

    if (value is List) {
      return value.length;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Future<void> showComments(dynamic post) async {
    final postId = int.tryParse(post['id'].toString());

    if (postId == null) {
      showMessage('Invalid post ID', error: true);
      return;
    }

    commentController.clear();

    List<dynamic> comments = [];

    bool loadingComments = true;
    bool sendingComment = false;

    try {
      final result = await ApiService.getComments(postId);
      comments = result;
    } catch (e) {
      if (mounted) {
        showMessage('Failed to load comments: ${cleanError(e)}', error: true);
      }

      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> refreshComments() async {
              try {
                setSheetState(() {
                  loadingComments = true;
                });

                final result = await ApiService.getComments(postId);

                setSheetState(() {
                  comments = result;
                  loadingComments = false;
                });
              } catch (e) {
                setSheetState(() {
                  loadingComments = false;
                });

                if (mounted) {
                  showMessage(
                    'Failed to load comments: ${cleanError(e)}',
                    error: true,
                  );
                }
              }
            }

            Future<void> addNewComment() async {
              final text = commentController.text.trim();

              if (text.isEmpty) {
                return;
              }

              if (sendingComment) {
                return;
              }

              setSheetState(() {
                sendingComment = true;
              });

              try {
                await ApiService.addComment(
                  postId: postId,
                  userId: widget.userId,
                  content: text,
                );

                commentController.clear();

                await refreshComments();

                setSheetState(() {
                  sendingComment = false;
                });

                if (mounted) {
                  await loadPosts();
                }
              } catch (e) {
                setSheetState(() {
                  sendingComment = false;
                });

                if (mounted) {
                  showMessage(
                    'Failed to add comment: ${cleanError(e)}',
                    error: true,
                  );
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 15,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      // HANDLE
                      Container(
                        height: 5,
                        width: 45,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // HEADER
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: refreshComments,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // COMMENTS
                      Expanded(
                        child: loadingComments
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: primary,
                                ),
                              )
                            : comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 55,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No comments yet',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Be the first to comment.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];

                                  final name =
                                      comment['user_name'] ??
                                      comment['name'] ??
                                      comment['username'] ??
                                      'Neighbour';

                                  final content =
                                      comment['content'] ??
                                      comment['comment'] ??
                                      '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: primary,
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                content.toString(),
                                                style: const TextStyle(
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 10),

                      // COMMENT INPUT
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => addNewComment(),
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primary,
                            child: sendingComment
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: addNewComment,
                                    icon: const Icon(
                                      Icons.send,
                                      color: AppColors.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CREATE EVENT
  // ============================================================

  Future<void> createEvent() async {
    final title = eventTitleController.text.trim();

    if (title.isEmpty) {
      showMessage('Please enter an event title', error: true);
      return;
    }

    if (selectedEventDate == null) {
      showMessage('Please select an event date', error: true);
      return;
    }

    if (neighbourhood == null) {
      showMessage('Please select a neighbourhood first', error: true);
      return;
    }

    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      await ApiService.createEvent(
        title: title,
        description: eventDescriptionController.text.trim().isEmpty
            ? null
            : eventDescriptionController.text.trim(),
        neighbourhoodId: neighbourhoodId,
        organizerId: widget.userId,
        location: eventLocationController.text.trim().isEmpty
            ? null
            : eventLocationController.text.trim(),
        eventDate: selectedEventDate!.toIso8601String(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      clearEventFields();

      showMessage('Event created successfully');

      await loadEvents();
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to create event: ${cleanError(e)}', error: true);
    }
  }

  // ============================================================
  // CREATE ISSUE
  // ============================================================

  Future<void> createIssue() async {
    final title = issueTitleController.text.trim();

    if (title.isEmpty) {
      showMessage('Please enter an issue title', error: true);
      return;
    }

    if (neighbourhood == null) {
      showMessage('Please select a neighbourhood first', error: true);
      return;
    }

    try {
      final neighbourhoodId = int.tryParse(neighbourhood!['id'].toString());

      if (neighbourhoodId == null) {
        throw Exception('Invalid neighbourhood ID');
      }

      await ApiService.createIssue(
        userId: widget.userId,
        neighbourhoodId: neighbourhoodId,
        category: selectedIssueCategory,
        title: title,
        description: issueDescriptionController.text.trim().isEmpty
            ? null
            : issueDescriptionController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      clearIssueFields();

      showMessage('Issue reported successfully');

      await loadIssues();
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to report issue: ${cleanError(e)}', error: true);
    }
  }

  // ============================================================
  // CLEAR FIELDS
  // ============================================================

  void clearEventFields() {
    eventTitleController.clear();
    eventDescriptionController.clear();
    eventLocationController.clear();
    selectedEventDate = null;
  }

  void clearIssueFields() {
    issueTitleController.clear();
    issueDescriptionController.clear();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.success,
        ),
      );
  }

  // ============================================================
  // ERROR
  // ============================================================

  String cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ============================================================
  // NEIGHBOURHOOD DIALOG
  // ============================================================

  void showNeighbourhoodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your neighbourhood',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select the neighbourhood you live in.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 20),

                if (neighbourhoods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No neighbourhoods available')),
                  ),

                ...neighbourhoods.map((item) {
                  final isSelected =
                      neighbourhood != null &&
                      neighbourhood!['id'].toString() == item['id'].toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isSelected
                          ? primary.withValues(alpha: 0.22)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(15),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.location_on, color: primary),
                        ),
                        title: Text(
                          item['name']?.toString() ?? 'Neighbourhood',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item['city']?.toString() ?? ''),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: primary)
                            : null,
                        onTap: () {
                          changeNeighbourhood(Map<String, dynamic>.from(item));
                        },
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CREATE POST DIALOG
  // ============================================================

  void showCreatePostDialog() {
    postController.clear();
    postImageController.clear();
    selectedPostImage = null;
    var showImageUrl = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            title: const Text('Create Post'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedPostCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          const [
                                'Community',
                                'Announcement',
                                'Help',
                                'Lost & Found',
                                'Recommendation',
                              ]
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPostCategory = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: postController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'What do you want to share?',
                        hintText: 'Write something for your neighbours...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add a photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (selectedPostImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.file(
                              selectedPostImage!,
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 190,
                                  width: double.infinity,
                                  color: AppColors.card,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Unable to preview this image',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Remove photo',
                                  onPressed: creatingPost
                                      ? null
                                      : () => setDialogState(() {
                                          selectedPostImage = null;
                                        }),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: creatingPost
                              ? null
                              : () => pickPostImage(setDialogState),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Change photo'),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.accent,
                              size: 34,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Share a moment with your community',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPG, PNG or GIF',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: creatingPost
                                  ? null
                                  : () => pickPostImage(setDialogState),
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: const Text('Choose from computer'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    TextButton.icon(
                      onPressed: creatingPost
                          ? null
                          : () => setDialogState(() {
                              showImageUrl = !showImageUrl;
                            }),
                      icon: Icon(
                        showImageUrl
                            ? Icons.keyboard_arrow_up
                            : Icons.link_outlined,
                        size: 18,
                      ),
                      label: Text(
                        showImageUrl
                            ? 'Hide image URL'
                            : 'Use an image URL instead',
                      ),
                    ),

                    if (showImageUrl) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: postImageController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: Icon(Icons.image_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  selectedPostImage = null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: creatingPost ? null : createPost,
                child: creatingPost
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CREATE EVENT DIALOG
  // ============================================================

  void showCreateEventDialog() {
    clearEventFields();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Event'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Event title',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: eventDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: eventLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedEventDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Event date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          selectedEventDate == null
                              ? 'Select date'
                              : formatDate(selectedEventDate!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: createEvent,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REPORT ISSUE DIALOG
  // ============================================================

  void showCreateIssueDialog() {
    clearIssueFields();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Report an Issue'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedIssueCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const [
                            'General',
                            'Road',
                            'Street Light',
                            'Water',
                            'Garbage',
                            'Noise',
                            'Safety',
                            'Other',
                          ]
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedIssueCategory = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: issueTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Issue title',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: issueDescriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the problem...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: createIssue,
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void showProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 15, 24, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 25),

                CircleAvatar(
                  radius: 45,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, size: 50, color: primary),
                ),

                const SizedBox(height: 15),

                Text(
                  user?['name']?.toString() ?? 'User',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  user?['email']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 25),

                profileRow(
                  Icons.phone_outlined,
                  'Phone',
                  user?['phone']?.toString() ?? 'Not provided',
                ),

                profileRow(
                  Icons.location_on_outlined,
                  'Neighbourhood',
                  neighbourhood?['name']?.toString() ?? 'Not selected',
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      logout();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Widget profileRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (user != null && !canAccessCommunity(user!)) {
      return _buildMemberApprovalScreen();
    }

    if (user?['role'] == 'super_admin') {
      return SuperAdminScreen(user: user!);
    }

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NeighbourConnect',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              'Hello, ${user?['name'] ?? 'Neighbour'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: loadHome,
          ),

          IconButton(
            tooltip: 'Profile',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.22),
              child: Text(
                (user?['name']?.toString().trim().isNotEmpty ?? false)
                    ? user!['name'].toString().trim()[0].toUpperCase()
                    : 'N',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onPressed: showProfile,
          ),
        ],
      ),

      body: IndexedStack(
        index: selectedTab,
        children: [
          buildHomeTab(),
          buildEventsTab(),
          buildIssuesTab(),
          buildProfileTab(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lavender,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event, color: AppColors.primary),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem, color: AppColors.primary),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),

      floatingActionButton: selectedTab == 1
          ? FloatingActionButton.extended(
              backgroundColor: primary,
              foregroundColor: AppColors.textPrimary,
              onPressed: showCreateEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : selectedTab == 2
          ? FloatingActionButton.extended(
              backgroundColor: primary,
              foregroundColor: AppColors.textPrimary,
              onPressed: showCreateIssueDialog,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  Widget _buildMemberApprovalScreen() {
    final accountStatus = user?['account_status']?.toString() ?? 'pending';
    final accountRejected = accountStatus == 'rejected';
    final rejected = accountRejected;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Account review'),
        actions: [
          IconButton(
            tooltip: 'Check approval status',
            onPressed: checkingApprovalStatus ? null : _checkApprovalStatus,
            icon: checkingApprovalStatus
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: (rejected ? AppColors.error : AppColors.highlight)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rejected
                        ? Icons.do_not_disturb_on_rounded
                        : Icons.hourglass_top_rounded,
                    color: rejected ? AppColors.error : AppColors.highlight,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  rejected ? 'Registration not approved' : 'Awaiting review',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  rejected
                      ? 'Your registration was not approved. Please contact '
                            'the project administrator.'
                      : 'Your registration is waiting for Super Admin '
                            'review. Your community features will unlock as '
                            'soon as your account is approved.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?['email']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            rejected
                                ? Icons.cancel_outlined
                                : Icons.pending_actions_rounded,
                            color: rejected
                                ? AppColors.error
                                : AppColors.highlight,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Registration status',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (rejected
                                          ? AppColors.error
                                          : AppColors.highlight)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              rejected ? 'Not approved' : 'Pending',
                              style: TextStyle(
                                color: rejected
                                    ? AppColors.error
                                    : AppColors.highlight,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (approvalStatusMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          approvalStatusMessage!,
                          style: TextStyle(
                            color: approvalStatusCheckFailed
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!rejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Status is checked on this device. Approval '
                            'changes made on another phone will not appear '
                            'unless the app uses shared online storage.'
                            '${neighbourhood == null ? '' : '\nSelected community: ${neighbourhood!['name']}'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: showNeighbourhoodDialog,
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      neighbourhood == null
                          ? 'Choose community'
                          : 'Change community',
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkingApprovalStatus
                        ? null
                        : _checkApprovalStatus,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: checkingApprovalStatus
                        ? const SizedBox(
                            height: 21,
                            width: 21,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sync_rounded),
                              SizedBox(width: 9),
                              Text('Check approval status'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOME TAB
  // ============================================================

  Widget buildHomeTab() {
    return RefreshIndicator(
      color: primary,
      onRefresh: loadHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          buildNeighbourhoodCard(),
          const SizedBox(height: 14),
          buildPostComposer(),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Around the neighbourhood',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Latest community posts',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh posts',
                onPressed: loadPosts,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loadingPosts)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator(color: primary)),
            )
          else if (postsLoadFailed)
            emptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load posts',
              message: 'Check your connection and try again.',
              onRetry: loadPosts,
            )
          else if (posts.isEmpty)
            emptyState(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              message: 'Be the first neighbour to create a post.',
            )
          else
            ...posts.map((post) => buildPostCard(post)),
        ],
      ),
    );
  }

  Widget buildPostComposer() {
    final name = user?['name']?.toString().trim() ?? '';
    final initial = name.isEmpty ? 'N' : name[0].toUpperCase();

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: showCreatePostDialog,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.22),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Text(
                    'Share something with your neighbours...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.add_a_photo_outlined, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEIGHBOURHOOD CARD
  // ============================================================

  Widget buildNeighbourhoodCard() {
    final name = neighbourhood?['name']?.toString() ?? 'No neighbourhood';
    final city =
        neighbourhood?['city']?.toString() ?? 'Select your neighbourhood';

    return GestureDetector(
      onTap: showNeighbourhoodDialog,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.lavender],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.textPrimary,
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR NEIGHBOURHOOD',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.card, AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color:
                    (title == 'Events'
                            ? AppColors.highlight
                            : AppColors.secondary)
                        .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: title == 'Events'
                    ? AppColors.highlight
                    : AppColors.secondary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POST CARD
  // ============================================================

  Widget buildPostCard(dynamic post) {
    final userName =
        post['user_name']?.toString() ??
        post['name']?.toString() ??
        'Neighbour';

    final category = post['category']?.toString() ?? 'Community';

    final content = post['content']?.toString() ?? '';

    final imageUrl = getImageUrl(post);
    final profileImage = resolveImageUrl(post['profile_image']);

    final liked = getPostLiked(post);

    final likes = getLikeCount(post);

    final comments = getCommentCount(post);
    final postTime = formatPostTime(
      post['created_at'] ?? post['createdAt'] ?? post['timestamp'],
    );
    final postId = int.tryParse(post['id'].toString());
    final likeInProgress = postId != null && likingPostIds.contains(postId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: 0.24),
                child: profileImage != null && profileImage.isNotEmpty
                    ? ClipOval(
                        child: Image.file(
                          File(profileImage),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Failed to load profile image "$profileImage": $error',
                            );
                            return const Icon(
                              Icons.person,
                              color: AppColors.accent,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.person, color: AppColors.accent),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (postTime.isNotEmpty)
                          Text(
                            postTime,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            ],
          ),

          const SizedBox(height: 17),

          // CONTENT
          if (content.isNotEmpty)
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),

          // IMAGE
          if (imageUrl != null) ...[
            const SizedBox(height: 15),

            AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(imageUrl),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Failed to load post image "$imageUrl": $error');
                    return Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Unable to load image',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 15),

          const Divider(height: 1),

          const SizedBox(height: 8),

          // LIKE / COMMENT
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: likeInProgress ? null : () => toggleLike(post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: liked ? 1.12 : 1,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Text(
                          '$likes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: liked
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(width: 5),

                        const Text('Like'),
                      ],
                    ),
                  ),
                ),
              ),

              Container(height: 30, width: 1, color: AppColors.outline),

              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => showComments(post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.accent,
                          size: 21,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          '$comments',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(width: 5),

                        const Text('Comment'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVENTS TAB
  // ============================================================

  Widget buildEventsTab() {
    return RefreshIndicator(
      color: primary,
      onRefresh: loadEvents,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: [
          const Text(
            'Community Events',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 7),

          Text(
            neighbourhood == null
                ? 'Select a neighbourhood first'
                : 'Events in ${neighbourhood!['name']}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 25),

          if (loadingEvents)
            const Center(child: CircularProgressIndicator(color: primary))
          else if (events.isEmpty)
            emptyState(
              icon: Icons.event_outlined,
              title: 'No events yet',
              message: 'Create an event for your neighbours.',
            )
          else
            ...events.map((event) => buildEventCard(event)),
        ],
      ),
    );
  }

  // ============================================================
  // EVENT CARD
  // ============================================================

  Widget buildEventCard(dynamic event) {
    final eventDate = DateTime.tryParse(
      event['event_date']?.toString() ?? '',
    )?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.event, color: primary, size: 30),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  event['title']?.toString() ?? 'Event',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (event['description'] != null &&
              event['description'].toString().isNotEmpty)
            Text(event['description'].toString()),

          const SizedBox(height: 12),

          if (event['location'] != null &&
              event['location'].toString().isNotEmpty)
            infoLine(Icons.location_on_outlined, event['location'].toString()),

          if (event['event_date'] != null)
            infoLine(
              Icons.calendar_today_outlined,
              eventDate == null
                  ? event['event_date'].toString()
                  : '${eventDate.day}/${eventDate.month}/${eventDate.year} '
                        '${eventDate.hour.toString().padLeft(2, '0')}:'
                        '${eventDate.minute.toString().padLeft(2, '0')}',
            ),

          if (event['organizer_name'] != null &&
              event['organizer_name'].toString().isNotEmpty)
            infoLine(
              Icons.person_outline_rounded,
              'Organized by ${event['organizer_name']}',
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ISSUES TAB
  // ============================================================

  Widget buildIssuesTab() {
    return RefreshIndicator(
      color: primary,
      onRefresh: loadIssues,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: [
          const Text(
            'Community Issues',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 7),

          Text(
            neighbourhood == null
                ? 'Select a neighbourhood first'
                : 'Issues reported in ${neighbourhood!['name']}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 25),

          if (loadingIssues)
            const Center(child: CircularProgressIndicator(color: primary))
          else if (issues.isEmpty)
            emptyState(
              icon: Icons.report_problem_outlined,
              title: 'No issues reported',
              message: 'Report a problem in your neighbourhood.',
            )
          else
            ...issues.map((issue) => buildIssueCard(issue)),
        ],
      ),
    );
  }

  // ============================================================
  // ISSUE CARD
  // ============================================================

  Widget buildIssueCard(dynamic issue) {
    final status = issue['status']?.toString() ?? 'Open';

    final isOpen = status.toLowerCase() == 'open';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.report_problem,
                  color: AppColors.highlight,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue['title']?.toString() ?? 'Issue',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      issue['category']?.toString() ?? 'General',
                      style: const TextStyle(color: primary),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.highlight.withValues(alpha: 0.18)
                      : AppColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? AppColors.highlight : AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          if (issue['description'] != null &&
              issue['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              issue['description'].toString(),
              style: const TextStyle(height: 1.4),
            ),
          ],

          if (getImageUrl(issue) case final imageUrl?) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(imageUrl),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Failed to load issue image "$imageUrl": $error');
                  return Container(
                    height: 180,
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ],

          if (issue['latitude'] != null && issue['longitude'] != null) ...[
            const SizedBox(height: 12),
            infoLine(
              Icons.place_outlined,
              '${issue['latitude']}, ${issue['longitude']}',
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE TAB
  // ============================================================

  Widget buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
      children: [
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.24),
            child: const Icon(
              Icons.person,
              size: 58,
              color: AppColors.secondary,
            ),
          ),
        ),

        const SizedBox(height: 15),

        Center(
          child: Text(
            user?['name']?.toString() ?? 'User',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 5),

        Center(
          child: Text(
            user?['email']?.toString() ?? '',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),

        const SizedBox(height: 30),

        profileCard(
          Icons.person_outline,
          'Full Name',
          user?['name']?.toString() ?? 'Not available',
        ),

        profileCard(
          Icons.email_outlined,
          'Email',
          user?['email']?.toString() ?? 'Not available',
        ),

        profileCard(
          Icons.phone_outlined,
          'Phone',
          user?['phone']?.toString() ?? 'Not provided',
        ),

        profileCard(
          Icons.location_on_outlined,
          'Neighbourhood',
          neighbourhood?['name']?.toString() ?? 'Not selected',
        ),

        if (user?['role'] == 'super_admin')
          profileCard(
            Icons.admin_panel_settings_outlined,
            'Access role',
            'Super Admin · All communities',
          ),

        const SizedBox(height: 20),

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget profileCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: primary),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO LINE
  // ============================================================

  Widget infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 55, color: primary.withValues(alpha: 0.45)),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    postController.dispose();
    postImageController.dispose();

    eventTitleController.dispose();
    eventDescriptionController.dispose();
    eventLocationController.dispose();

    issueTitleController.dispose();
    issueDescriptionController.dispose();

    commentController.dispose();

    super.dispose();
  }
}
