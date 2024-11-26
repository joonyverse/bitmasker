import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bit_input_form.dart';

class StorageService {
  static const String _storageKey = 'saved_forms';
  static const String _bitCountKey = 'bit_count';

  static Future<void> saveForms(List<BitInputForm> forms, int bitCount) async {
    final prefs = await SharedPreferences.getInstance();
    final formsData = forms.map((form) => form.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(formsData));
    await prefs.setInt(_bitCountKey, bitCount);
  }

  static Future<Map<String, dynamic>> loadForms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBitCount = prefs.getInt(_bitCountKey);
    final savedFormsString = prefs.getString(_storageKey);

    if (savedBitCount != null && savedFormsString != null) {
      try {
        final savedForms = jsonDecode(savedFormsString) as List;
        return {
          'bitCount': savedBitCount,
          'forms': savedForms.map((formData) => 
            BitInputForm.fromJson(formData, savedBitCount)).toList(),
        };
      } catch (e) {
        return {'error': true};
      }
    }
    return {'error': true};
  }
} 