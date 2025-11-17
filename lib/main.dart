import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Path Picker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FilePickerPage(),
    );
  }
}

class FilePickerPage extends StatefulWidget {
  const FilePickerPage({super.key});

  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  List<String> selectedFilePaths = [];
  bool permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      
      if (androidVersion >= 30) {
        // Android 11+ requires MANAGE_EXTERNAL_STORAGE
        var status = await Permission.manageExternalStorage.status;
        
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        
        setState(() {
          permissionGranted = status.isGranted;
        });
        
        if (!status.isGranted) {
          _showPermissionDialog();
        }
      } else {
        // Android 10 and below
        var status = await Permission.storage.status;
        
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        
        setState(() {
          permissionGranted = status.isGranted;
        });
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        var androidInfo = await Future.value(30); // Default to 30 (Android 11)
        return androidInfo;
      }
    } catch (e) {
      return 30;
    }
    return 30;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs access to all files to function properly. '
          'Please grant "All files access" permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        String? filePath = result.files.first.path;
        
        if (filePath != null) {
          setState(() {
            selectedFilePaths.add(filePath);
          });
          
          // Automatically copy to clipboard
          await Clipboard.setData(ClipboardData(text: filePath));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File path copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      selectedFilePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Card - File Picker
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Dropdown (static)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ALL FILES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Choose Button
                      ElevatedButton(
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'CHOOSE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // File List
              Expanded(
                child: selectedFilePaths.isEmpty
                    ? Center(
                        child: Text(
                          'No files selected',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedFilePaths.length,
                        itemBuilder: (context, index) {
                          final filePath = selectedFilePaths[index];
                          return Card(
                            elevation: 2,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // File Path
                                  Expanded(
                                    child: Text(
                                      filePath,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Copy Button
                                  InkWell(
                                    onTap: () => _copyToClipboard(filePath),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.content_copy,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  // Delete Button
                                  InkWell(
                                    onTap: () => _removeFile(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}