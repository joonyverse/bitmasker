import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../models/bit_input_form.dart';
import '../../utils/constants.dart';
import '../../utils/storage_service.dart';
import '../../widgets/custom_dropdown.dart';
import 'widgets/bit_grid.dart';
import 'widgets/control_panel.dart';
import 'widgets/help_dialog.dart';
import 'widgets/result_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BitInputForm> inputForms = [];
  int selectedBitCount = AppConstants.defaultBitCount;
  bool _isHelpOpen = false;
  bool get _isMobile => MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  @override
  void dispose() {
    for (var form in inputForms) {
      form.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final savedState = await StorageService.loadForms();
    if (savedState['error'] == true) {
      setState(() {
        selectedBitCount = AppConstants.defaultBitCount;
        _addNewForm();
      });
    } else {
      setState(() {
        selectedBitCount = savedState['bitCount'];
        inputForms = savedState['forms'];
      });
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

  Future<void> _saveState() async {
    await StorageService.saveForms(inputForms, selectedBitCount);
  }

  bool _isOverlappingBit(int formIndex, int bitIndex) {
    if (!inputForms[formIndex].bits[bitIndex]) return false;
    return inputForms.asMap().entries.any(
          (entry) => entry.key != formIndex && entry.value.bits[bitIndex],
        );
  }

  BigInt _calculateResult() {
    if (inputForms.isEmpty) return BigInt.zero;
    return inputForms.fold(
      BigInt.zero,
      (result, form) {
        BigInt value = BigInt.zero;
        for (int i = 0; i < form.bits.length; i++) {
          if (form.bits[i]) {
            value = value | (BigInt.one << i);
          }
        }
        return result | value;
      },
    );
  }

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
            'Are you sure you want to reset all forms? This action cannot be undone.',
          ),
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
            child: const HelpDialog(),
          ),
        ),
      ),
    );
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
                  ResultView(
                    result: _calculateResult(),
                    totalBits: _getTotalSelectedBits(),
                  ),
                  SizedBox(height: _isMobile ? 12 : 16),
                  ControlPanel(
                    selectedBitCount: selectedBitCount,
                    onBitCountChanged: (value) {
                      setState(() {
                        selectedBitCount = value;
                        inputForms = inputForms
                            .map((form) =>
                                BitInputForm(bitCount: selectedBitCount)
                                  ..value = form.value)
                            .toList();
                        _saveState();
                      });
                    },
                    onAddForm: _addNewForm,
                    onReset: _showResetDialog,
                    isMobile: _isMobile,
                  ),
                  SizedBox(height: _isMobile ? 12 : 16),
                  Wrap(
                    spacing: _isMobile ? 12 : 16,
                    runSpacing: _isMobile ? 12 : 16,
                    children: List.generate(
                      inputForms.length,
                      (index) => ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppConstants.maxFormWidth,
                          minWidth: AppConstants.minFormWidth,
                        ),
                        child: _buildInputForm(index),
                      ),
                    ),
                  ),
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

  Widget _buildInputForm(int index) {
    final form = inputForms[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomDropdown<InputType>(
                  value: form.inputType,
                  items: InputType.values,
                  labelBuilder: (type) => type.label,
                  onChanged: (type) {
                    setState(() {
                      if (type != null) {
                        form.inputType = type;
                        form.value = '';
                        form.updateFromValue();
                        _saveState();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
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
                          switch (form.inputType) {
                            case InputType.hexadecimal:
                              valueToCopy = form.value;
                              break;
                            case InputType.decimal:
                            case InputType.decimalArray:
                              List<int> positions = [];
                              for (int i = 0; i < form.bits.length; i++) {
                                if (form.bits[i]) positions.add(i);
                              }
                              valueToCopy = positions.join(', ');
                              break;
                          }
                          Clipboard.setData(ClipboardData(text: valueToCopy))
                              .then((_) {
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2D63EA).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${form.bits.where((bit) => bit).length} bits',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D63EA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (inputForms.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeForm(index),
                    tooltip: 'Remove form',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            BitGrid(
              form: form,
              formIndex: index,
              onToggle: (bitIndex) {
                setState(() {
                  form.toggleBit(bitIndex);
                  _saveState();
                });
              },
              isOverlapping: _isOverlappingBit,
              isMobile: _isMobile,
            ),
          ],
        ),
      ),
    );
  }
} 