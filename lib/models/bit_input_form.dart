import 'package:flutter/material.dart';

enum InputType {
  decimal('n-bit'),
  hexadecimal('bitmap'),
  decimalArray('n-bit list');

  final String label;
  const InputType(this.label);
}

class BitInputForm {
  String value = '';
  InputType inputType = InputType.hexadecimal;
  List<bool> bits;
  final int bitCount;
  final TextEditingController controller = TextEditingController();

  BitInputForm({required this.bitCount}) : bits = List.filled(bitCount, false);

  void dispose() {
    controller.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'inputType': inputType.index,
      'bits': bits,
    };
  }

  static BitInputForm fromJson(Map<String, dynamic> json, int bitCount) {
    final form = BitInputForm(bitCount: bitCount);
    form.value = json['value'];
    form.inputType = InputType.values[json['inputType']];
    form.bits = List<bool>.from(json['bits']);
    form.controller.text = form.value;
    return form;
  }

  void toggleBit(int index) {
    if (inputType == InputType.decimal) {
      for (int i = 0; i < bits.length; i++) {
        bits[i] = (i == index) ? !bits[i] : false;
      }
    } else {
      bits[index] = !bits[index];
    }
    updateFromBits();
  }

  void updateFromBits() {
    BigInt numValue = BigInt.from(0);
    List<int> setBitPositions = [];

    for (int i = 0; i < bits.length; i++) {
      if (bits[i]) {
        numValue = numValue | (BigInt.from(1) << i);
        setBitPositions.add(i);
      }
    }

    switch (inputType) {
      case InputType.decimal:
        value = setBitPositions.length == 1 ? setBitPositions[0].toString() : '';
        controller.text = value;
        break;
      case InputType.hexadecimal:
        value = '0x${numValue.toRadixString(16).toUpperCase()}';
        controller.text = value;
        break;
      case InputType.decimalArray:
        value = setBitPositions.isEmpty ? '' : setBitPositions.join(', ');
        controller.text = value;
        break;
    }
  }

  void updateFromValue() {
    BigInt? numValue;
    switch (inputType) {
      case InputType.decimal:
        try {
          final position = int.parse(value);
          if (position >= 0 && position < bitCount) {
            numValue = BigInt.one << position;
          }
        } catch (e) {
          numValue = null;
        }
        break;
      case InputType.hexadecimal:
        numValue = BigInt.tryParse(value.replaceAll('0x', ''), radix: 16);
        break;
      case InputType.decimalArray:
        try {
          final positions = value.split(',')
              .map((e) => int.parse(e.trim()))
              .where((pos) => pos >= 0 && pos < bitCount)
              .toList();
          numValue = BigInt.zero;
          for (final pos in positions) {
            numValue = numValue! | (BigInt.one << pos);
          }
        } catch (e) {
          numValue = null;
        }
        break;
    }

    if (numValue != null) {
      for (int i = 0; i < bits.length; i++) {
        bits[i] = (numValue! >> i & BigInt.one) == BigInt.one;
      }
    }
  }
} 