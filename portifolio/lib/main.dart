import 'package:flutter/material.dart';

void main() {
  runApp(const NeighbourConnectApp());
}

class NeighbourConnectApp extends StatelessWidget {
  const NeighbourConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeighbourConnect',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5FEF),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.campaign_rounded,
      'title': 'Community',
    },
    {
      'icon': Icons.volunteer_activism_rounded,
      'title': 'Help',
    },
    {
      'icon': Icons.event_rounded,
      'title': 'Events',
    },
    {
      'icon': Icons.search_rounded,
      'title': 'Lost & Found',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ─────────────────────────────
            // HEADER
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  10,
                ),
                child: Row(
                  children: [

                    // Profile
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE5E7FF),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF5B5FEF),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Greeting
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Rahul Kumar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────
            // LOCATION CARD
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5B5FEF),
                        Color(0xFF777AF4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your neighbourhood',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Green Valley Community',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────────────────────
            // SEARCH
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Search your neighbourhood...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────────────────────
            // CATEGORIES
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.indigo.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _categoryCard(
                      categories[index]['icon'],
                      categories[index]['title'],
                    );
                  },
                ),
              ),
            ),

            // ─────────────────────────────
            // FEED TITLE
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  14,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Latest updates',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.tune_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────
            // POSTS
            // ─────────────────────────────

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _postCard(
                      name: 'Ananya Sharma',
                      time: '12 min ago',
                      category: 'Help',
                      message:
                          'Does anyone know a reliable electrician around our area?',
                      likes: '18',
                      comments: '6',
                    ),

                    _postCard(
                      name: 'Vikram Singh',
                      time: '1 hr ago',
                      category: 'Event',
                      message:
                          'Community clean-up drive this Sunday at 7:00 AM. Everyone is welcome!',
                      likes: '32',
                      comments: '11',
                    ),

                    _postCard(
                      name: 'Priya Kumar',
                      time: '2 hrs ago',
                      category: 'Lost & Found',
                      message:
                          'Found a set of keys near the community park. Please message me if they belong to you.',
                      likes: '14',
                      comments: '4',
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),

      // ─────────────────────────────
      // CREATE BUTTON
      // ─────────────────────────────

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createPostSheet(context);
        },
        backgroundColor: const Color(0xFF5B5FEF),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),

      // ─────────────────────────────
      // NAVIGATION
      // ─────────────────────────────

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // CATEGORY CARD
  // ─────────────────────────────

  Widget _categoryCard(
    IconData icon,
    String title,
  ) {
    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEEFF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5B5FEF),
              size: 23,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // POST CARD
  // ─────────────────────────────

  Widget _postCard({
    required String name,
    required String time,
    required String category,
    required String message,
    required String likes,
    required String comments,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFE7E8FF),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF5B5FEF),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
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
                  color: const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF5B5FEF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF424242),
            ),
          ),

          const SizedBox(height: 16),

          Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),

          const SizedBox(height: 8),

          Row(
            children: [

              _actionButton(
                Icons.favorite_border_rounded,
                likes,
              ),

              const SizedBox(width: 18),

              _actionButton(
                Icons.chat_bubble_outline_rounded,
                comments,
              ),

              const Spacer(),

              const Icon(
                Icons.bookmark_border_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String count,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          count,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────
  // CREATE POST SHEET
  // ─────────────────────────────

  void _createPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'Create something',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _createOption(
                Icons.edit_note_rounded,
                'Create a post',
              ),

              _createOption(
                Icons.volunteer_activism_rounded,
                'Ask for help',
              ),

              _createOption(
                Icons.event_rounded,
                'Create an event',
              ),

              _createOption(
                Icons.report_problem_outlined,
                'Report an issue',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _createOption(
    IconData icon,
    String title,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF5B5FEF),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
      ),
      onTap: () {},
    );
  }
}