import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EventsScreen({super.key, required this.user});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> events = [];
  bool loading = true;

  int? neighbourhoodId;

  @override
  void initState() {
    super.initState();

    neighbourhoodId = widget.user['neighbourhood_id'];

    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await DatabaseHelper.instance.getEvents(
        neighbourhoodId: neighbourhoodId,
      );

      if (!mounted) return;

      setState(() {
        events = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load events: $e')));
    }
  }

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

  Future<void> openAddEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEventScreen(user: widget.user)),
    );

    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Events',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        ),

        actions: [
          IconButton(
            onPressed: loadEvents,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddEvent,

        backgroundColor: AppColors.highlight,
        foregroundColor: AppColors.textPrimary,

        icon: const Icon(Icons.add),

        label: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : events.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadEvents,

              color: AppColors.primary,

              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),

                itemCount: events.length,

                itemBuilder: (context, index) {
                  final event = events[index];

                  return _buildEventCard(event);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              height: 90,
              width: 90,

              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(25),
              ),

              child: const Icon(
                Icons.event_outlined,
                size: 48,
                color: AppColors.highlight,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Events Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'There are no upcoming events in your neighbourhood.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: openAddEvent,

              icon: const Icon(Icons.add),

              label: const Text('Create an Event'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      elevation: 0,

      color: AppColors.card,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EventDetailScreen(event: event, user: widget.user),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    height: 58,
                    width: 58,

                    decoration: BoxDecoration(
                      color: AppColors.highlight.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: const Icon(
                      Icons.event_rounded,
                      size: 30,
                      color: AppColors.highlight,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event',

                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Organized by ${event['organizer_name'] ?? 'Unknown'}',

                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(height: 1),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    formatDate(event['event_date'] ?? ''),

                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(width: 18),

                  const Icon(
                    Icons.access_time_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    formatTime(event['event_date'] ?? ''),

                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (event['location'] != null &&
                  event['location'].toString().trim().isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 19,
                      color: AppColors.accent,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        event['location'].toString(),

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    size: 19,
                    color: AppColors.highlight,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    event['neighbourhood_name'] ?? 'Neighbourhood',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
