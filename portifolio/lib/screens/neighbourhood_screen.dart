import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';

class NeighbourhoodScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const NeighbourhoodScreen({super.key, required this.user});

  @override
  State<NeighbourhoodScreen> createState() => _NeighbourhoodScreenState();
}

class _NeighbourhoodScreenState extends State<NeighbourhoodScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> neighbourhoods = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNeighbourhoods();
  }

  // ============================================================
  // LOAD NEIGHBOURHOODS
  // ============================================================

  Future<void> loadNeighbourhoods([String search = '']) async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final result = await DatabaseHelper.instance.getNeighbourhoods(
        search: search.trim(),
      );

      if (!mounted) return;

      setState(() {
        neighbourhoods = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        neighbourhoods = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load neighbourhoods: $e')),
      );
    }
  }

  // ============================================================
  // SELECT NEIGHBOURHOOD
  // ============================================================

  Future<void> selectNeighbourhood(Map<String, dynamic> neighbourhood) async {
    final userId = widget.user['id'];
    final neighbourhoodId = neighbourhood['id'];

    if (userId == null || neighbourhoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select neighbourhood.')),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.updateUserNeighbourhood(
        userId: userId is int ? userId : int.parse(userId.toString()),
        neighbourhoodId: neighbourhoodId is int
            ? neighbourhoodId
            : int.parse(neighbourhoodId.toString()),
      );

      final updatedUser = await DatabaseHelper.instance.getUser(
        userId is int ? userId : int.parse(userId.toString()),
      );

      if (!mounted) return;

      if (updatedUser != null) {
        Navigator.pop(context, updatedUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Neighbourhood selected, but user could not be refreshed.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select neighbourhood: $e')),
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshNeighbourhoods() async {
    await loadNeighbourhoods(searchController.text);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentNeighbourhoodId = widget.user['neighbourhood_id'];

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Choose Neighbourhood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================
          Padding(
            padding: const EdgeInsets.all(20),

            child: TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {});
                loadNeighbourhoods(value);
              },

              decoration: InputDecoration(
                hintText: 'Search neighbourhood...',

                prefixIcon: const Icon(Icons.search_rounded),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          searchController.clear();

                          setState(() {});

                          loadNeighbourhoods();
                        },
                      )
                    : null,

                filled: true,

                fillColor: AppColors.surface,

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 15,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // RESULT COUNT
          // ======================================================
          if (!loading && neighbourhoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Row(
                children: [
                  Text(
                    '${neighbourhoods.length} neighbourhood'
                    '${neighbourhoods.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ======================================================
          // LIST
          // ======================================================
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : neighbourhoods.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.primary,

                    onRefresh: refreshNeighbourhoods,

                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 100),

                      itemCount: neighbourhoods.length,

                      itemBuilder: (context, index) {
                        final item = neighbourhoods[index];

                        return _buildNeighbourhoodCard(
                          item,
                          currentNeighbourhoodId,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final searching = searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.location_off_outlined,

              size: 70,

              color: AppColors.accent,
            ),

            const SizedBox(height: 15),

            Text(
              searching ? 'No neighbourhoods found' : 'No neighbourhoods saved',

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              searching
                  ? 'Try another neighbourhood name or city.'
                  : 'Create a neighbourhood first from the Explore page.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            if (searching) ...[
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  searchController.clear();

                  setState(() {});

                  loadNeighbourhoods();
                },

                icon: const Icon(Icons.clear),

                label: const Text('Clear Search'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,

                  foregroundColor: AppColors.textPrimary,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NEIGHBOURHOOD CARD
  // ============================================================

  Widget _buildNeighbourhoodCard(
    Map<String, dynamic> item,
    dynamic currentNeighbourhoodId,
  ) {
    final id = item['id'];

    final name = item['name']?.toString() ?? 'Neighbourhood';

    final city = item['city']?.toString() ?? '';

    final description = item['description']?.toString() ?? '';

    final selected = _sameId(currentNeighbourhoodId, id);

    return Card(
      elevation: 0,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          selectNeighbourhood(item);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================
              Container(
                width: 55,
                height: 55,

                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.mint,

                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  Icons.location_on_rounded,

                  color: selected ? AppColors.textPrimary : AppColors.primary,

                  size: 28,
                ),
              ),

              const SizedBox(width: 15),

              // ==================================================
              // DETAILS
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontWeight: FontWeight.bold,

                              fontSize: 17,
                            ),
                          ),
                        ),

                        if (selected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: AppColors.mint,

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              'Joined',

                              style: TextStyle(
                                color: AppColors.primary,

                                fontSize: 11,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_city_outlined,

                          size: 15,

                          color: AppColors.textSecondary,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            city,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: AppColors.textSecondary,

                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),

                      Text(
                        description,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: AppColors.textSecondary,

                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW / CHECK
              // ==================================================
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,

                color: selected ? AppColors.accent : AppColors.textSecondary,

                size: selected ? 25 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAFE ID COMPARISON
  // ============================================================

  bool _sameId(dynamic first, dynamic second) {
    if (first == null || second == null) {
      return false;
    }

    return int.tryParse(first.toString()) == int.tryParse(second.toString());
  }
}
