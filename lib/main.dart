import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bit toggle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D63EA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D63EA)),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// 입력 타입을 정의하는 enum
enum InputType {
  decimal('n-bit'),
  hexadecimal('bitmap'),
  decimalArray('n-bit list');

  final String label;
  const InputType(this.label);
}

// 각 입력 폼의 상태를 관리하는 클래스
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

  void updateFromValue() {
    BigInt? numValue;
    switch (inputType) {
      case InputType.decimal:
        // 10진수도 위치 기반으로 처리
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
          final positions = value
              .split(',')
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
      for (int i = 0; i < bitCount; i++) {
        bits[i] = (numValue! >> i & BigInt.one) == BigInt.one;
      }
    }
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
        value =
            setBitPositions.length == 1 ? setBitPositions[0].toString() : '';
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

  void toggleBit(int index) {
    if (inputType == InputType.decimal) {
      // decimal 타입일 경우 다른 비트들을 모두 0으로 만들고 해당 비트만 토글
      for (int i = 0; i < bits.length; i++) {
        bits[i] = (i == index) ? !bits[i] : false;
      }
    } else {
      // 다른 타입일 경우 해당 비트만 토글
      bits[index] = !bits[index];
    }
    updateFromBits();
  }

  int get selectedBitCount {
    return bits.where((bit) => bit).length;
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
}

class _MyHomePageState extends State<MyHomePage> {
  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  List<BitInputForm> inputForms = [];
  int selectedBitCount = 64; // 기본값 64비트로 변경
  final List<int> availableBitCounts = [32, 64, 128];

  static const String _storageKey = 'saved_forms';
  static const String _bitCountKey = 'bit_count';

  // 도움말 다이얼로그 상태 추가
  bool _isHelpOpen = false;

  // 모바일 여부 확인
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  // 입력폼의 제약조건 계산
  BoxConstraints _getFormConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return BoxConstraints(
        maxWidth: width - 48, // 패딩 고려
        minWidth: width - 48,
      );
    }
    return const BoxConstraints(
      maxWidth: 700,
      minWidth: 400,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  // 상태 저장 메서드
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final formsData = inputForms.map((form) => form.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(formsData));
    await prefs.setInt(_bitCountKey, selectedBitCount);
  }

  // 상태 불러오기 메서드
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBitCount = prefs.getInt(_bitCountKey);
    if (savedBitCount != null) {
      selectedBitCount = savedBitCount;
    }

    final savedFormsString = prefs.getString(_storageKey);
    if (savedFormsString != null) {
      try {
        final savedForms = jsonDecode(savedFormsString) as List;
        setState(() {
          inputForms = savedForms
              .map((formData) =>
                  BitInputForm.fromJson(formData, selectedBitCount))
              .toList();
        });
      } catch (e) {
        // 저장된 데이터가 없거나 오류가 있는 경우 기본 폼 생성
        _addNewForm();
      }
    } else {
      _addNewForm();
    }
  }

  void _addNewForm() {
    setState(() {
      inputForms.add(BitInputForm(bitCount: selectedBitCount));
      _saveState();
    });
  }

  void _removeForm(int index) {
    setState(() {
      inputForms.removeAt(index);
      _saveState();
    });
  }

  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D63EA), Color(0xFF4C8DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getTotalSelectedBits()} bits',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '0x${_calculateResult().toRadixString(16).toUpperCase()}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _isMobile
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ModernDropdownButton<int>(
                          value: selectedBitCount,
                          items: availableBitCounts,
                          prefix: 'Total Bits:',
                          labelBuilder: (value) => '$value',
                          onChanged: (value) {
                            setState(() {
                              selectedBitCount = value!;
                              inputForms = inputForms
                                  .map((form) =>
                                      BitInputForm(bitCount: selectedBitCount)
                                        ..value = form.value)
                                  .toList();
                              _saveState();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _showResetDialog(),
                        tooltip: 'Reset all forms',
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addNewForm,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Form'),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  ModernDropdownButton<int>(
                    value: selectedBitCount,
                    items: availableBitCounts,
                    prefix: 'Total Bits:',
                    labelBuilder: (value) => '$value',
                    onChanged: (value) {
                      setState(() {
                        selectedBitCount = value!;
                        inputForms = inputForms
                            .map((form) =>
                                BitInputForm(bitCount: selectedBitCount)
                                  ..value = form.value)
                            .toList();
                        _saveState();
                      });
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _showResetDialog(),
                    tooltip: 'Reset all forms',
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _addNewForm,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Form'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInputForm(int index) {
    final form = inputForms[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ModernDropdownButton<InputType>(
                  value: form.inputType,
                  items: InputType.values,
                  labelBuilder: (type) => type.label,
                  onChanged: (type) {
                    setState(() {
                      form.inputType = type!;
                      form.value = '';
                      form.updateFromValue();
                      _saveState();
                    });
                  },
                ),
                IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 80,
                      maxWidth: 400,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: TextField(
                            controller: form.controller,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              hintText: form.inputType == InputType.hexadecimal
                                  ? 'ex: 0xf'
                                  : 'ex: 5',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  String valueToCopy = '';
                                  BigInt value = _getBigIntFromBits(form.bits);

                                  // 현재 입력 타입에 따라 복사할 값 결정
                                  switch (form.inputType) {
                                    case InputType.hexadecimal:
                                      valueToCopy =
                                          '0x${value.toRadixString(16).toUpperCase()}';
                                      break;
                                    case InputType.decimal:
                                    case InputType.decimalArray:
                                      List<int> positions = [];
                                      for (int i = 0;
                                          i < form.bits.length;
                                          i++) {
                                        if (form.bits[i]) positions.add(i);
                                      }
                                      valueToCopy = positions.join(', ');
                                      break;
                                  }

                                  // 클립보드에 복사
                                  Clipboard.setData(
                                          ClipboardData(text: valueToCopy))
                                      .then((_) {
                                    // 복사 완료 피드백
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Copied: $valueToCopy'),
                                        behavior: SnackBarBehavior.floating,
                                        width: 200,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  });
                                },
                                tooltip: 'Copy value',
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                form.value = value;
                                form.updateFromValue();
                                _saveState();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2D63EA).withOpacity(0.2)),
                  ),
                  child: Text(
                    '${form.selectedBitCount} bits',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D63EA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed:
                      inputForms.length > 1 ? () => _removeForm(index) : null,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 비트 토글 그리드
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildBitToggleGrid(form, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitToggleGrid(BitInputForm form, int formIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int row = 0; row < (form.bitCount / 16).ceil(); row++) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '[${form.bitCount - 1 - row * 16}]',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                ...List.generate(
                  min(16, form.bitCount - row * 16),
                  (col) {
                    final bitIndex = form.bitCount - 1 - (row * 16 + col);
                    // 4비트마다 여백 추가
                    if (col > 0 && col % 4 == 0) {
                      return Row(
                        children: [
                          const SizedBox(width: 8),
                          _buildBitToggle(form, formIndex, row, col),
                        ],
                      );
                    }
                    return _buildBitToggle(form, formIndex, row, col);
                  },
                ),
              ],
            ),
            if (row < (form.bitCount / 16).ceil() - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBitToggle(BitInputForm form, int formIndex, int row, int col) {
    final bitIndex = form.bitCount - 1 - (row * 16 + col);
    final isOverlapping = _isOverlappingBit(formIndex, bitIndex);
    final isSelected = form.bits[bitIndex];

    return Column(
      children: [
        Text(
          '$bitIndex',
          style: TextStyle(
            fontSize: _isMobile ? 9 : 10,
            color: Colors.grey.shade600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            form.toggleBit(bitIndex);
            _saveState();
          }),
          // 모바일에서 더 큰 터치 영역
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: _isMobile ? const EdgeInsets.all(4) : EdgeInsets.zero,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(2),
              width: _isMobile ? 32 : 28,
              height: _isMobile ? 32 : 28,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? (isOverlapping
                          ? Colors.red.shade400
                          : const Color(0xFF2D63EA))
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? (isOverlapping
                        ? Colors.red.shade50
                        : const Color(0xFFEEF3FF))
                    : Colors.white,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: isOverlapping
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF2D63EA).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isSelected ? '1' : '0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isOverlapping
                            ? Colors.red.shade700
                            : const Color(0xFF2D63EA))
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BigInt _calculateResult() {
    if (inputForms.isEmpty) return BigInt.zero;

    return inputForms.fold(
        BigInt.zero, (result, form) => result | _getBigIntFromBits(form.bits));
  }

  BigInt _getBigIntFromBits(List<bool> bits) {
    BigInt value = BigInt.zero;
    for (int i = 0; i < bits.length; i++) {
      if (bits[i]) {
        value = value | (BigInt.one << i);
      }
    }
    return value;
  }

  @override
  void dispose() {
    for (var form in inputForms) {
      form.dispose();
    }
    super.dispose();
  }

  // 비트가 겹치는지 확인하는 메서드
  bool _isOverlappingBit(int formIndex, int bitIndex) {
    bool currentBit = inputForms[formIndex].bits[bitIndex];
    if (!currentBit) return false;

    for (int i = 0; i < inputForms.length; i++) {
      if (i != formIndex && inputForms[i].bits[bitIndex]) {
        return true;
      }
    }
    return false;
  }

  void _toggleHelp() {
    if (_isHelpOpen) {
      Navigator.of(context).pop();
      _isHelpOpen = false;
    } else {
      _showHelp();
    }
  }

  void _showHelp() {
    _isHelpOpen = true;
    showDialog(
      context: context,
      builder: (context) => CallbackShortcuts(
        // 다이얼로그에도 단축키 추가
        bindings: {
          SingleActivator(
            LogicalKeyboardKey.slash,
            control: !_isMacOS,
            meta: _isMacOS,
          ): () {
            Navigator.of(context).pop();
            _isHelpOpen = false;
          },
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            onPopInvokedWithResult: (didPop, result) {
              _isHelpOpen = false;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D63EA),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text(
                              'Help & Tutorial',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHelpSection(
                              'Input Types',
                              [
                                'bitmap: Enter hexadecimal value (e.g., 0xf)',
                                'n-bit: Enter single bit position (e.g., 5)',
                                'n-bit list: Enter multiple bit positions (e.g., 1, 3, 5)',
                              ],
                            ),
                            _buildHelpSection(
                              'Bit Toggle Grid',
                              [
                                'Click on bits to toggle them on/off',
                                'Red highlight indicates overlapping bits',
                                'Bits are grouped by 4 for better readability',
                                'Numbers above bits show their positions',
                              ],
                            ),
                            _buildHelpSection(
                              'Features',
                              [
                                'Add multiple input forms using "Add Form"',
                                'Copy values using the copy button',
                                'Reset all forms using the reset button',
                                'Change total bits (32/64/128) as needed',
                                'Forms are automatically saved',
                              ],
                            ),
                            _buildHelpSection(
                              'Result',
                              [
                                'Shows combined result of all forms using OR operation',
                                'Displays total number of set bits',
                                'Result is shown in hexadecimal format',
                              ],
                            ),
                            if (kIsWeb)
                              _buildHelpSection(
                                'Keyboard Shortcuts',
                                [
                                  'Ctrl/Cmd + /: Open this help dialog',
                                  'Esc: Close dialog',
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  // 리셋 다이얼로그를 별도 메서드로 분리
  void _showResetDialog() {
    if (_isMobile) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset All Forms',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to reset all forms? This action cannot be undone.',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          inputForms.clear();
                          _addNewForm();
                          _saveState();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset All Forms'),
          content: const Text(
              'Are you sure you want to reset all forms? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  inputForms.clear();
                  _addNewForm();
                  _saveState();
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          SingleActivator(
            LogicalKeyboardKey.slash,
            control: !_isMacOS,
            meta: _isMacOS,
          ): _toggleHelp,
        },
        child: Focus(
          autofocus: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(_isMobile ? 16.0 : 24.0),
              child: Column(
                children: [
                  _buildResultCard(),
                  SizedBox(height: _isMobile ? 12 : 16),
                  _buildControlsRow(),
                  SizedBox(height: _isMobile ? 12 : 16),
                  Wrap(
                    spacing: _isMobile ? 12 : 16,
                    runSpacing: _isMobile ? 12 : 16,
                    children: List.generate(
                      inputForms.length,
                      (index) => ConstrainedBox(
                        constraints: _getFormConstraints(context),
                        child: IntrinsicHeight(
                          child: _buildInputForm(index),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _isMobile ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleHelp,
        tooltip: 'Help (Ctrl/Cmd + /)',
        child: const Icon(Icons.help_outline),
      ),
    );
  }

  // 전체 선택된 비트 수를 계산하는 메서드
  int _getTotalSelectedBits() {
    BigInt result = _calculateResult();
    int count = 0;
    for (int i = 0; i < selectedBitCount; i++) {
      if ((result >> i & BigInt.one) == BigInt.one) {
        count++;
      }
    }
    return count;
  }
}

// 커스텀 드롭다운 버튼 위젯 추가
class ModernDropdownButton<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;
  final String? prefix;

  const ModernDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefix != null) ...[
                    Text(
                      prefix!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    labelBuilder(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
