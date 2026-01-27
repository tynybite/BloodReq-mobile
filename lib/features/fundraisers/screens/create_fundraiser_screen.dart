import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';

class CreateFundraiserScreen extends StatefulWidget {
  const CreateFundraiserScreen({super.key});

  @override
  State<CreateFundraiserScreen> createState() => _CreateFundraiserScreenState();
}

class _CreateFundraiserScreenState extends State<CreateFundraiserScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ApiService _api = ApiService();
  bool _isSubmitting = false;

  final List<File> _selectedFiles = [];
  final List<String> _fileNames = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      if (await pickedFile.length() > 2 * 1024 * 1024) {
        if (mounted) _showError('Image too large (max 2MB)');
        return;
      }
      setState(() {
        _selectedFiles.add(File(pickedFile.path));
        _fileNames.add(pickedFile.name);
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (await file.length() > 2 * 1024 * 1024) {
        if (mounted) _showError('File too large (max 2MB)');
        return;
      }
      setState(() {
        _selectedFiles.add(file);
        _fileNames.add(result.files.single.name);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSubmitting = true);

      try {
        final formData = _formKey.currentState!.value;

        // Convert files to Base64
        final List<Map<String, String>> documents = [];
        for (int i = 0; i < _selectedFiles.length; i++) {
          final file = _selectedFiles[i];
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = file.path.split('.').last.toLowerCase();
          final mimeType = extension == 'pdf'
              ? 'application/pdf'
              : 'image/$extension';

          documents.add({
            'url': 'data:$mimeType;base64,$base64String',
            'type': mimeType,
            'name': _fileNames[i],
          });
        }

        final payload = {
          'title': formData['title'],
          'patient_name': formData['patient_name'],
          'hospital': formData['hospital'],
          'amount_needed':
              int.tryParse(formData['amount_needed'].toString()) ?? 0,
          'description': formData['description'],
          'deadline': formData['deadline']?.toIso8601String(),
          'documents': documents,
        };

        final response = await _api.post<dynamic>(
          '/fundraisers',
          body: payload,
        );

        if (mounted) {
          if (response.success) {
            context.pop(); // Go back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fundraiser created successfully!')),
            );
          } else {
            _showError(response.message ?? 'Failed to create fundraiser');
          }
        }
      } catch (e) {
        if (mounted) _showError('An error occurred: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Fundraiser')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Patient Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              FormBuilderTextField(
                name: 'title',
                decoration: const InputDecoration(
                  labelText: 'Fundraiser Title',
                  hintText: 'e.g. Urgent Surgery for...',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(5),
                ]),
              ),
              const SizedBox(height: 16),

              FormBuilderTextField(
                name: 'patient_name',
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),

              FormBuilderTextField(
                name: 'hospital',
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'amount_needed',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Needed',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(100),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: 'deadline',
                      inputType: InputType.date,
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      format: DateFormat("yyyy-MM-dd"),
                      firstDate: DateTime.now(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              FormBuilderTextField(
                name: 'description',
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (Medical Condition, Story)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Document Upload Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Documents / Photos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'camera') _pickImage(ImageSource.camera);
                      if (value == 'gallery') _pickImage(ImageSource.gallery);
                      if (value == 'file') _pickDocument();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'camera',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, size: 18),
                            SizedBox(width: 8),
                            Text('Take Photo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'gallery',
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, size: 18),
                            SizedBox(width: 8),
                            Text('Gallery'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'file',
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, size: 18),
                            SizedBox(width: 8),
                            Text('PDF Document'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_selectedFiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload medical reports or photos (Max 2MB)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final name = _fileNames[index];
                    final isPdf = name.toLowerCase().endsWith('.pdf');
                    return ListTile(
                      tileColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.image,
                        color: isPdf ? Colors.red : Colors.blue,
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Fundraiser',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
