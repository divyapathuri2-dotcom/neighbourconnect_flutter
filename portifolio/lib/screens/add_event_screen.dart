import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AddEventScreen({super.key, required this.user});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  List<Map<String, dynamic>> neighbourhoods = [];

  int? selectedNeighbourhoodId;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool loading = false;
  bool loadingNeighbourhoods = true;

  @override
  void initState() {
    super.initState();

    loadNeighbourhoods();
  }

  Future<void> loadNeighbourhoods() async {
    try {
      final result = await DatabaseHelper.instance.getNeighbourhoods();

      if (!mounted) return;

      setState(() {
        neighbourhoods = result;
        loadingNeighbourhoods = false;

        final userNeighbourhood = widget.user['neighbourhood_id'];

        if (userNeighbourhood != null) {
          final exists = result.any((item) => item['id'] == userNeighbourhood);

          if (exists) {
            selectedNeighbourhoodId = userNeighbourhood;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingNeighbourhoods = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load neighbourhoods: $e')),
      );
    }
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,

      initialDate: now,

      firstDate: now,

      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> selectTime() async {
    final result = await showTimePicker(
      context: context,

      initialTime: TimeOfDay.now(),
    );

    if (result != null) {
      setState(() {
        selectedTime = result;
      });
    }
  }

  String get formattedDate {
    if (selectedDate == null) {
      return 'Select date';
    }

    return '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';
  }

  String get formattedTime {
    if (selectedTime == null) {
      return 'Select time';
    }

    return selectedTime!.format(context);
  }

  Future<void> createEvent() async {
    if (titleController.text.trim().isEmpty) {
      showMessage('Please enter an event title');
      return;
    }

    if (selectedNeighbourhoodId == null) {
      showMessage('Please select a neighbourhood');
      return;
    }

    if (selectedDate == null) {
      showMessage('Please select an event date');
      return;
    }

    if (selectedTime == null) {
      showMessage('Please select an event time');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final eventDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      await DatabaseHelper.instance.addEvent(
        title: titleController.text.trim(),

        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),

        neighbourhoodId: selectedNeighbourhoodId!,

        organizerId: widget.user['id'] as int,

        location: locationController.text.trim().isEmpty
            ? null
            : locationController.text.trim(),

        eventDate: eventDateTime.toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              _buildLabel('Event Title'),

              _buildTextField(
                controller: titleController,
                hint: 'Enter event title',
                icon: Icons.event_outlined,
              ),

              const SizedBox(height: 20),

              _buildLabel('Description'),

              _buildTextField(
                controller: descriptionController,
                hint: 'Describe your event',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              _buildLabel('Neighbourhood'),

              loadingNeighbourhoods
                  ? Container(
                      height: 55,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: DropdownButtonFormField<int>(
                        initialValue: selectedNeighbourhoodId,

                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.home_outlined),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),

                        hint: const Text('Select neighbourhood'),

                        items: neighbourhoods.map((neighbourhood) {
                          return DropdownMenuItem<int>(
                            value: neighbourhood['id'] as int,

                            child: Text(
                              '${neighbourhood['name']} - ${neighbourhood['city']}',
                            ),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedNeighbourhoodId = value;
                          });
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              _buildLabel('Location'),

              _buildTextField(
                controller: locationController,
                hint: 'Enter event location',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 20),

              _buildLabel('Event Date'),

              _buildPicker(
                icon: Icons.calendar_month_outlined,
                text: formattedDate,
                onTap: selectDate,
              ),

              const SizedBox(height: 16),

              _buildLabel('Event Time'),

              _buildPicker(
                icon: Icons.access_time_rounded,
                text: formattedTime,
                onTap: selectTime,
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,

                child: ElevatedButton(
                  onPressed: loading ? null : createEvent,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,

                    foregroundColor: AppColors.textPrimary,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,

                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        text,

        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,

      maxLines: maxLines,

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon),

        filled: true,
        fillColor: AppColors.surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPicker({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(
        height: 55,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        decoration: BoxDecoration(
          color: AppColors.card,

          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),

            const SizedBox(width: 12),

            Text(
              text,

              style: TextStyle(
                color: text.startsWith('Select')
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,

                fontSize: 15,
              ),
            ),

            const Spacer(),

            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
