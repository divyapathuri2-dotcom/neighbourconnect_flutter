import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String message = 'Testing connection...';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    try {
      final data = await ApiService.getTestData();

      if (!mounted) return;

      setState(() {
        loading = false;
        message = data['message']?.toString() ?? 'Connection successful';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Connection failed:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: loading
                ? const CircularProgressIndicator(color: AppColors.accent)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        size: 60,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: testConnection,
                        child: const Text('Test Again'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
