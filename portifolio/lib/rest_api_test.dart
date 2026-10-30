import 'package:flutter/material.dart';
import 'services/api_service.dart';

class RestApiTestPage extends StatefulWidget {
  const RestApiTestPage({super.key});

  @override
  State<RestApiTestPage> createState() => _RestApiTestPageState();
}

class _RestApiTestPageState extends State<RestApiTestPage> {
  List<dynamic> neighbourhoods = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchNeighbourhoods();
  }

  Future<void> fetchNeighbourhoods() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await ApiService.getNeighbourhoods();

      setState(() {
        neighbourhoods = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Test'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchNeighbourhoods,
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: fetchNeighbourhoods,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : neighbourhoods.isEmpty
                    ? const Center(
                        child: Text(
                          'No neighbourhoods found',
                        ),
                      )
                    : ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        itemCount: neighbourhoods.length,
                        itemBuilder: (context, index) {
                          final neighbourhood =
                              neighbourhoods[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.location_city,
                                ),
                              ),
                              title: Text(
                                neighbourhood['name']
                                        ?.toString() ??
                                    'Unknown',
                              ),
                              subtitle: Text(
                                '${neighbourhood['city'] ?? ''}\n'
                                '${neighbourhood['description'] ?? ''}',
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}