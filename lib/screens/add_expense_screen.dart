import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/expense.dart';
import '../controllers/expense_controller.dart';
import '../services/currency_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isIncome = false; // New: Track if this is income or expense

  // Voice recording
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _voiceNotePath;
  Duration _recordDuration = Duration.zero;
  bool _recorderInitialized = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  String? _imagePath;

  final List<String> _categories = [
    'food',
    'transport',
    'bills',
    'entertainment',
    'shopping',
    'healthcare',
    'education',
    'other',
  ];

  final List<String> _incomeCategories = [
    'salary',
    'business',
    'investment',
    'freelance',
    'gift',
    'bonus',
    'other_income',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[0];
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      setState(() => _recorderInitialized = true);
    } catch (e) {
      print('Failed to initialize recorder: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) {
      Get.snackbar(
        'error'.tr,
        'Recorder not initialized',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (await _checkMicrophonePermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';

        await _audioRecorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
          _voiceNotePath = filePath;
        });

        // Update duration every second
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (_isRecording) {
            setState(() {
              _recordDuration += const Duration(seconds: 1);
            });
            return true;
          }
          return false;
        });
      } else {
        Get.snackbar(
          'Permission Denied',
          'Microphone permission is required to record voice notes',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      Get.snackbar(
        'Success',
        'Voice note recorded successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to stop recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _playVoiceNote() async {
    if (_voiceNotePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_voiceNotePath!));
        setState(() => _isPlaying = true);

        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to play voice note: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteVoiceNote() async {
    if (_voiceNotePath != null) {
      try {
        final file = File(_voiceNotePath!);
        if (await file.exists()) {
          await file.delete();
        }
        setState(() {
          _voiceNotePath = null;
          _recordDuration = Duration.zero;
        });

        Get.snackbar(
          'Deleted',
          'Voice note deleted',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete voice note: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_image_memo'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('camera'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    // Check if recording is in progress
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('stop_recording_first'.tr),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final controller = Get.find<ExpenseController>();

        // Parse amount and make it negative if it's income
        double amount = double.parse(_amountController.text.trim());
        if (_isIncome) {
          amount = -amount.abs(); // Negative for income
        }

        // Create Expense object
        final expense = Expense(
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          voiceNotePath: _voiceNotePath,
          imagePath: _imagePath,
        );

        // Save using controller
        await controller.addExpense(expense);

        // Refresh expenses list for real-time update
        await controller.fetchExpenses();

        // Navigate to home screen and show success message
        Get.offAllNamed('/home');

        Get.snackbar(
          'success'.tr,
          _isIncome ? 'income_saved'.tr : 'expense_saved_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        // Show error message using GetX
        Get.snackbar(
          'error'.tr,
          '${_isIncome ? 'error_saving_income'.tr : 'error_saving_expense'.tr}: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'add_income'.tr : 'add_expense'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Income/Expense Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isIncome = false;
                            _selectedCategory = _categories[0];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isIncome
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: !_isIncome
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'expense'.tr,
                                style: TextStyle(
                                  color: !_isIncome
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isIncome = true;
                            _selectedCategory = _incomeCategories[0];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isIncome
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: _isIncome
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'income'.tr,
                                style: TextStyle(
                                  color: _isIncome
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'title'.tr,
                  hintText: 'enter_expense_title'.tr,
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'please_enter_title'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  hintText: 'enter_amount'.tr,
                  prefixIcon: Obx(() {
                    final currencyService = CurrencyService.instance;
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        currencyService.selectedCurrencySymbol.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'please_enter_amount'.tr;
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'valid_amount_required'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'category'.tr,
                  prefixIcon: const Icon(Icons.category),
                  border: const OutlineInputBorder(),
                ),
                items: (_isIncome ? _incomeCategories : _categories).map((
                  String category,
                ) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category.tr),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'date'.tr,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Field (Optional)
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'note_optional'.tr,
                  hintText: 'add_additional_notes'.tr,
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Voice Note Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'voice_note_optional'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_voiceNotePath == null && !_isRecording)
                      ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.mic),
                        label: Text('record_voice_note'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (_isRecording)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${'recording'.tr}... ${_formatDuration(_recordDuration)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop),
                            label: Text('stop_recording'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'voice_note_recorded'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${'duration'.tr}: ${_formatDuration(_recordDuration)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _playVoiceNote,
                                icon: Icon(
                                  _isPlaying ? Icons.stop : Icons.play_arrow,
                                ),
                                label: Text(_isPlaying ? 'stop'.tr : 'play'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _deleteVoiceNote,
                                icon: const Icon(Icons.delete),
                                label: Text('delete'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Image Memo Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'image_memo_optional'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_imagePath == null)
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text('add_image'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showImageSourceDialog,
                                    icon: const Icon(Icons.edit),
                                    label: Text('change_image'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _imagePath = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: Text('remove'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'save_expense'.tr,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
