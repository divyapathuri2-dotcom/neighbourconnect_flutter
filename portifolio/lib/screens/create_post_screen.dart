import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreatePostScreen({super.key, required this.user});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final contentController = TextEditingController();

  String selectedCategory = 'Community';

  bool loading = false;

  File? selectedImage;

  final List<String> categories = [
    'Community',
    'Help',
    'Announcement',
    'Lost & Found',
    'Recommendation',
    'Safety',
  ];

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickImage() async {
    if (loading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null) return;

      final path = result.files.single.path;

      if (path == null || path.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access selected image')),
        );

        return;
      }

      setState(() {
        selectedImage = File(path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to select image: $e')));
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void removeImage() {
    if (loading) return;

    setState(() {
      selectedImage = null;
    });
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> createPost() async {
    final content = contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    if (content.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post cannot exceed 500 characters')),
      );
      return;
    }

    final userId = widget.user['id'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information is missing')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final neighbourhoodId = widget.user['neighbourhood_id'] ?? 1;

      final imageUrl = selectedImage == null
          ? null
          : await ApiService.uploadPostImage(selectedImage!);

      await ApiService.createPost(
        userId: userId as int,
        neighbourhoodId: neighbourhoodId as int,
        category: selectedCategory,
        content: content,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create post: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name']?.toString() ?? 'Neighbour';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: loading
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // USER HEADER
              // ==================================================
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,

                      backgroundColor: AppColors.mint,

                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',

                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            name,

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          const Text(
                            'Share with your neighbourhood',

                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CATEGORY
              // ==================================================
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                decoration: BoxDecoration(
                  color: AppColors.surface,

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: AppColors.outline),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,

                    isExpanded: true,

                    icon: const Icon(Icons.keyboard_arrow_down_rounded),

                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,

                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(category),
                              color: AppColors.primary,
                              size: 21,
                            ),

                            const SizedBox(width: 10),

                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),

                    onChanged: loading
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              selectedCategory = value;
                            });
                          },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CONTENT
              // ==================================================
              const Text(
                'What do you want to share?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: TextField(
                  controller: contentController,
                  maxLines: 8,
                  minLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Write something for your neighbours...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: contentController,
                builder: (context, value, child) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${value.text.length}/500',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // IMAGE SECTION
              const Text(
                'Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (selectedImage == null)
                GestureDetector(
                  onTap: loading ? null : pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.outline, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.accent,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add a Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Click to choose an image',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Image.file(
                            selectedImage!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Remove photo',
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: removeImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Photo selected',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: loading ? null : pickImage,
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // ==================================================
              // NEIGHBOURHOOD
              // ==================================================
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.card,

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.18),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Neighbourhood',

                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            widget.user['neighbourhood_name']?.toString() ??
                                'Your current neighbourhood',

                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.check_circle, color: AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // PUBLISH
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: loading ? null : createPost,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,

                    foregroundColor: AppColors.textPrimary,

                    disabledBackgroundColor: AppColors.outline,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    elevation: 0,
                  ),

                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,

                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,

                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Icon(Icons.send_rounded),

                            SizedBox(width: 8),

                            Text(
                              'Publish Post',

                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Help':
        return Icons.help_outline_rounded;

      case 'Announcement':
        return Icons.campaign_outlined;

      case 'Lost & Found':
        return Icons.search_rounded;

      case 'Recommendation':
        return Icons.star_outline_rounded;

      case 'Safety':
        return Icons.shield_outlined;

      case 'Community':
      default:
        return Icons.people_outline_rounded;
    }
  }
}
