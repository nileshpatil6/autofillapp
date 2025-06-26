import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/mapping_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MappingProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  late MappingModel _mapping; // Renamed to avoid conflict with getter

  MappingModel get mapping => _mapping; // Public getter

  MappingProvider() {
    _mapping = MappingModel(fields: []);
    loadSaved();
  }

  Future<void> loadSaved() async {
    final jsonStr = await _storage.read(key: 'mapping');
    if (jsonStr != null) {
      try {
        _mapping = MappingModel.fromJson(json.decode(jsonStr));
      } catch (e) {
        // Handle potential decoding errors, e.g. by resetting to default
        if (kDebugMode) {
          print('Error decoding saved mapping: $e');
        }
        _mapping = MappingModel(fields: []);
      }
      notifyListeners();
    }
  }

  Future<void> save() async {
    final jsonStr = json.encode(_mapping.toJson());
    await _storage.write(key: 'mapping', value: jsonStr);
  }

  void updateField(int index, String newValue) {
    if (index >= 0 && index < _mapping.fields.length) {
      _mapping.fields[index].value = newValue;
      notifyListeners();
      save(); // Optionally save on every update
    }
  }

  void setAutoSubmit(bool v) {
    _mapping.autoSubmit = v;
    notifyListeners();
    save(); // Optionally save on change
  }

  void setFromJson(Map<String, dynamic> json) {
    try {
      _mapping = MappingModel.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting mapping from json: $e');
      }
      // Optionally, handle error, e.g. by not changing the mapping or setting a default
      _mapping = MappingModel(fields: []); // Reset to empty on error
    }
    notifyListeners();
    save(); // Save after setting new mapping
  }

  // Method to add a new field - useful for UI interaction
  void addField(String key, String value) {
    _mapping.fields.add(FieldMapping(key: key, value: value));
    notifyListeners();
    save();
  }

  // Method to remove a field - useful for UI interaction
  void removeField(int index) {
    if (index >= 0 && index < _mapping.fields.length) {
      _mapping.fields.removeAt(index);
      notifyListeners();
      save();
    }
  }
}
