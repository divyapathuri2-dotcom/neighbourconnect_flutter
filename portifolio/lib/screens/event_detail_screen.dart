import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> user;

  const EventDetailScreen({super.key, required this.event, required this.user});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);

      return '${parsedDate.day.toString().padLeft(2, '0')}/'
          '${parsedDate.month.toString().padLeft(2, '0')}/'
          '${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }

  String formatTime(String date) {
    try {
      final parsedDate = DateTime.parse(date);

      final hour = parsedDate.hour;
      final minute = parsedDate.minute;

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return '';
    }
  }

  bool get isOrganizer {
    return widget.event['organizer_id'] == widget.user['id'];
  }

  Future<void> deleteEvent() async {
    final shouldDelete = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),

          content: const Text('Are you sure you want to delete this event?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final db = await DatabaseHelper.instance.database;

      await db.delete(
        'events',
        where: 'id = ?',
        whereArgs: [widget.event['id']],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event deleted')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Event Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          if (isOrganizer)
            IconButton(
              onPressed: deleteEvent,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.secondary,
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: double.infinity,
              height: 190,

              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.event_rounded,
                size: 80,
                color: AppColors.accent,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              event['title'] ?? 'Untitled Event',

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            _buildInfoCard(
              icon: Icons.calendar_month_outlined,
              title: 'Date',
              value: formatDate(event['event_date'] ?? ''),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.access_time_rounded,
              title: 'Time',
              value: formatTime(event['event_date'] ?? ''),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: event['location'] ?? 'Location not specified',
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.home_outlined,
              title: 'Neighbourhood',
              value: event['neighbourhood_name'] ?? 'Neighbourhood',
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Organizer',
              value: event['organizer_name'] ?? 'Unknown',
            ),

            const SizedBox(height: 25),

            const Text(
              'About this event',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: AppColors.card,

                borderRadius: BorderRadius.circular(16),
              ),

              child: Text(
                event['description'] != null &&
                        event['description'].toString().trim().isNotEmpty
                    ? event['description'].toString()
                    : 'No description provided.',

                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (isOrganizer)
              SizedBox(
                width: double.infinity,
                height: 52,

                child: OutlinedButton.icon(
                  onPressed: deleteEvent,

                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.secondary,
                  ),

                  label: const Text(
                    'Delete Event',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondary),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,

            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: AppColors.accent),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
