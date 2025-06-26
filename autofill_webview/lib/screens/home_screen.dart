import 'dart:convert'; // For json.decode
import 'dart:io'; // For File operations if using FilePicker result.files.single.path

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/mapping_provider.dart';
import 'webview_screen.dart';
// Assuming flutter_json_view is for displaying JSON, might not be directly used here for editing
// import 'package:flutter_json_view/flutter_json_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndLoadJson(MappingProvider prov) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.bytes != null) {
        final String fileContent = String.fromCharCodes(result.files.single.bytes!);
        final Map<String, dynamic> map = json.decode(fileContent);
        prov.setFromJson(map);
        // prov.save(); // save is called within setFromJson in the provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON file loaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected or file is empty.')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading JSON file: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading JSON: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer for more granular rebuilds or just Provider.of if the whole widget rebuilds often
    final prov = Provider.of<MappingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AutoFill WebView Config'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              await prov.save();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mapping saved!')),
              );
            },
            tooltip: 'Save Mapping Manually',
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter URL to Autofill',
                hintText: 'https://example.com/form',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.file_upload),
              label: Text('Load JSON Mapping File'),
              onPressed: () => _pickAndLoadJson(prov),
            ),
            SizedBox(height: 10),
            Text('Field Mappings:', style: Theme.of(context).textTheme.titleMedium),
            Expanded(
              child: prov.mapping.fields.isEmpty
                  ? Center(child: Text('No fields loaded. Load a JSON file or add fields manually (if UI supported).'))
                  : ListView.builder(
                      itemCount: prov.mapping.fields.length,
                      itemBuilder: (_, i) {
                        final field = prov.mapping.fields[i];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(field.key, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: TextFormField(
                              initialValue: field.value,
                              onChanged: (v) => prov.updateField(i, v),
                              decoration: InputDecoration(labelText: 'Value'),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                prov.removeField(i);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Field "${field.key}" removed.')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 10),
            SwitchListTile(
              title: Text('Enable Auto-Submit Form'),
              value: prov.mapping.autoSubmit,
              onChanged: (val) {
                prov.setAutoSubmit(val);
                // prov.save(); // save is called within setAutoSubmit
              },
              secondary: Icon(Icons.send_and_archive),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_browser),
              label: Text('Open WebView & Fill Form'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
              onPressed: () {
                if (_urlController.text.isEmpty || !Uri.tryParse(_urlController.text)!.isAbsolute) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid URL.')),
                  );
                  return;
                }
                // Ensure latest changes to text fields are saved before navigating
                FocusScope.of(context).unfocus(); // unfocus to trigger onChanged for last edited field
                prov.save(); // Explicitly save before navigating

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebviewScreen(url: _urlController.text),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
