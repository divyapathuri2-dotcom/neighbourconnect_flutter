import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _neighbourhoods = [];
  int? _selectedNeighbourhoodId;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    loadDashboard();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> loadDashboard({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getAdminDashboard(
        adminUserId: int.parse(widget.user['id'].toString()),
      );
      if (!mounted) return;

      setState(() {
        _members = (result['members'] as List)
            .map((member) => Map<String, dynamic>.from(member as Map))
            .toList();
        _events = (result['events'] as List)
            .map((event) => Map<String, dynamic>.from(event as Map))
            .toList();
        _neighbourhoods = (result['neighbourhoods'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _communityMembers {
    if (_selectedNeighbourhoodId == null) return _members;
    return _members
        .where(
          (member) =>
              member['neighbourhood_id']?.toString() ==
              _selectedNeighbourhoodId.toString(),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _communityMembers.where((member) {
      final name = member['name']?.toString().toLowerCase() ?? '';
      final email = member['email']?.toString().toLowerCase() ?? '';
      final neighbourhood =
          member['neighbourhood_name']?.toString().toLowerCase() ?? '';
      final matchesQuery =
          name.contains(query) ||
          email.contains(query) ||
          neighbourhood.contains(query);
      return matchesQuery;
    }).toList();
  }

  List<Map<String, dynamic>> get _communityEvents {
    if (_selectedNeighbourhoodId == null) return _events;
    return _events
        .where(
          (event) =>
              event['neighbourhood_id']?.toString() ==
              _selectedNeighbourhoodId.toString(),
        )
        .toList();
  }

  String get _selectedNeighbourhoodName {
    if (_selectedNeighbourhoodId == null) return 'All communities';
    for (final item in _neighbourhoods) {
      if (item['id'].toString() == _selectedNeighbourhoodId.toString()) {
        return item['name']?.toString() ?? 'Selected community';
      }
    }
    return 'Selected community';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_errorMessage != null)
            _buildError()
          else ...[
            _buildSummary(),
            const SizedBox(height: 24),
            _buildCommunityFilter(),
            const SizedBox(height: 22),
            _buildMembersSection(),
            const SizedBox(height: 24),
            _buildMeetingsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Admin dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'All communities, neighbours and meetings',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: _loading ? null : loadDashboard,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final title = _selectedNeighbourhoodName;
    final city = _selectedNeighbourhoodId == null
        ? '${_neighbourhoods.length} registered communities'
        : _neighbourhoods
                  .where(
                    (item) =>
                        item['id'].toString() ==
                        _selectedNeighbourhoodId.toString(),
                  )
                  .map((item) => item['city']?.toString() ?? '')
                  .firstOrNull ??
              '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.lavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SUPER ADMIN OVERVIEW',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Icon(
                Icons.verified_user_rounded,
                size: 17,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 5),
              Text(
                'Admin workspace',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (city.isNotEmpty)
            Text(
              city,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryMetric(
                icon: Icons.people_alt_outlined,
                value: '${_communityMembers.length}',
                label: 'Neighbours',
              ),
              _summaryMetric(
                icon: Icons.location_city_rounded,
                value: '${_neighbourhoods.length}',
                label: 'Communities',
              ),
              _summaryMetric(
                icon: Icons.event_available_outlined,
                value: '${_communityEvents.length}',
                label: 'Meetings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.78),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community scope',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _selectedNeighbourhoodId,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_city_rounded),
            labelText: 'Show data for',
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All communities'),
            ),
            ..._neighbourhoods.map(
              (item) => DropdownMenuItem<int?>(
                value: int.tryParse(item['id'].toString()),
                child: Text(
                  '${item['name'] ?? 'Community'}'
                  '${item['city'] == null ? '' : ' · ${item['city']}'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() {
            _selectedNeighbourhoodId = value;
          }),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    final members = _filteredMembers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Registered neighbours',
          count: _communityMembers.length,
          icon: Icons.people_alt_rounded,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search name, email or community',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          _emptyMessage(
            _communityMembers.isEmpty
                ? 'No registered neighbours in this community scope yet.'
                : 'No neighbours match your search.',
          )
        else
          ...members.map(_memberTile),
      ],
    );
  }

  Widget _memberTile(Map<String, dynamic> member) {
    final name = member['name']?.toString().trim() ?? '';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final phone = member['phone']?.toString().trim() ?? '';
    final email = member['email']?.toString() ?? '';
    final communityName = member['neighbourhood_name']?.toString().trim() ?? '';
    final communityCity = member['neighbourhood_city']?.toString().trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Neighbour' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  communityName.isEmpty
                      ? 'No community selected'
                      : [
                          communityName,
                          if (communityCity.isNotEmpty) communityCity,
                        ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 0,
            children: [
              TextButton.icon(
                onPressed: () => _showMemberDetails(member),
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    final createdAt = DateTime.tryParse(
      member['created_at']?.toString() ?? '',
    )?.toLocal();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                member['name']?.toString() ?? 'Community member',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow(
                Icons.email_outlined,
                'Email',
                member['email']?.toString() ?? 'Not provided',
              ),
              _detailRow(
                Icons.phone_outlined,
                'Phone',
                member['phone']?.toString().trim().isNotEmpty == true
                    ? member['phone'].toString()
                    : 'Not provided',
              ),
              _detailRow(
                Icons.location_on_outlined,
                'Neighbourhood',
                [
                      if (member['neighbourhood_name'] != null)
                        member['neighbourhood_name'].toString(),
                      if (member['neighbourhood_city'] != null)
                        member['neighbourhood_city'].toString(),
                    ].join(', ').isEmpty
                    ? 'Not selected'
                    : [
                        if (member['neighbourhood_name'] != null)
                          member['neighbourhood_name'].toString(),
                        if (member['neighbourhood_city'] != null)
                          member['neighbourhood_city'].toString(),
                      ].join(', '),
              ),
              _detailRow(
                Icons.calendar_today_outlined,
                'Joined',
                createdAt == null
                    ? 'Date not available'
                    : '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              ),
              _detailRow(
                Icons.admin_panel_settings_outlined,
                'Access role',
                'Neighbour',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 11),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Community meetings',
          count: _communityEvents.length,
          icon: Icons.event_available_rounded,
        ),
        const SizedBox(height: 12),
        if (_communityEvents.isEmpty)
          _emptyMessage('No meetings or events have been scheduled yet.')
        else
          ..._communityEvents.map(_meetingTile),
      ],
    );
  }

  Widget _meetingTile(Map<String, dynamic> event) {
    final eventDate = DateTime.tryParse(
      event['event_date']?.toString() ?? '',
    )?.toLocal();
    final dateLabel = eventDate == null
        ? 'Date not available'
        : '${eventDate.day}/${eventDate.month}/${eventDate.year} · '
              '${eventDate.hour % 12 == 0 ? 12 : eventDate.hour % 12}:'
              '${eventDate.minute.toString().padLeft(2, '0')} '
              '${eventDate.hour >= 12 ? 'PM' : 'AM'}';
    final location = event['location']?.toString().trim() ?? '';
    final organizer = event['organizer_name']?.toString().trim() ?? '';
    final community = event['neighbourhood_name']?.toString().trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event, user: widget.user),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.highlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title']?.toString() ?? 'Community meeting',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                      ),
                    ),
                    if (community.isNotEmpty ||
                        location.isNotEmpty ||
                        organizer.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (community.isNotEmpty) community,
                          if (location.isNotEmpty) location,
                          if (organizer.isNotEmpty) 'By $organizer',
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if ((event['description']?.toString().trim() ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        event['description'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }
}
