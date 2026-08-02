import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _loading = false;
  String? _message;
  Color? _messageColor;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ConfigService.getSavedUrl());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      // Basic validation
      if (_urlController.text.isEmpty) {
        setState(() {
          _message = '❌ URL cannot be empty';
          _messageColor = Colors.red;
          _loading = false;
        });
        return;
      }

      if (!_urlController.text.startsWith('http')) {
        setState(() {
          _message = '❌ URL must start with http:// or https://';
          _messageColor = Colors.red;
          _loading = false;
        });
        return;
      }

      // Test connection to backend
      try {
        final response = await http.get(
          Uri.parse('${_urlController.text}/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Connection timeout - Backend not reachable'),
        );
        
        // If we get any response (even 404 or 405), the server is reachable
        if (response.statusCode >= 200) {
          // Save the URL
          await ConfigService.setBaseUrl(_urlController.text);

          if (mounted) {
            setState(() {
              _message = '✅ Connected! URL updated to:\n${_urlController.text}';
              _messageColor = Colors.green;
              _loading = false;
            });
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _message = '❌ Cannot reach backend at this URL.\nError: ${e.toString()}';
            _messageColor = Colors.red;
            _loading = false;
          });
        }
        return;
      }

      // Fallback: Save without verification
      await ConfigService.setBaseUrl(_urlController.text);

      if (mounted) {
        setState(() {
          _message = '✅ Settings saved! URL updated to:\n${_urlController.text}';
          _messageColor = Colors.green;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = '❌ Error: ${e.toString()}';
          _messageColor = Colors.red;
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetToDefault() async {
    await ConfigService.resetToDefault();
    _urlController.text = ConfigService.getSavedUrl();
    
    if (mounted) {
      setState(() {
        _message = '✅ Reset to default URL';
        _messageColor = Colors.green;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Backend Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your backend server IP/URL to connect from different networks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Current URL Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current URL:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ConfigService.getSavedUrl(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Field
            Text(
              'Backend URL',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:5000',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              enabled: !_loading,
            ),
            const SizedBox(height: 8),
            Text(
              'Examples:\n• Local: http://192.168.9.142:5000\n• Hostname: http://your-server.local:5000',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Status Message
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _messageColor?.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _messageColor ?? Colors.grey),
                ),
                child: Text(
                  _message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _messageColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _testConnection,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save & Apply'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _resetToDefault,
                child: const Text('Reset to Default'),
              ),
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tips:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Find your laptop IP: On Linux/Mac, run: ifconfig | grep "inet "\n\n2. Make sure backend is running on port 5000\n\n3. Update this whenever you change networks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
