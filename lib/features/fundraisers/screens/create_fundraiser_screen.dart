import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/utils/app_toast.dart';

class CreateFundraiserScreen extends StatefulWidget {
  const CreateFundraiserScreen({super.key});

  @override
  State<CreateFundraiserScreen> createState() => _CreateFundraiserScreenState();
}

class _CreateFundraiserScreenState extends State<CreateFundraiserScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ApiService _api = ApiService();
  bool _isSubmitting = false;

  final List<PlatformFile> _documents = [];
  final List<XFile> _photos = [];

  Future<void> _pickDocuments() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      // Check size (limit 2MB)
      final validFiles = result.files
          .where((file) => file.size <= 2 * 1024 * 1024)
          .toList();

      if (validFiles.length < result.files.length) {
        if (mounted) {
          AppToast.warning(context, lang.getText('file_too_large'));
        }
      }

      setState(() {
        _documents.addAll(validFiles);
      });
    }
  }

  Future<void> _pickPhotos() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      // Check size
      final validImages = <XFile>[];
      for (var img in images) {
        final len = await img.length();
        if (len <= 2 * 1024 * 1024) {
          validImages.add(img);
        } else {
          if (mounted) {
            AppToast.warning(context, lang.getText('image_too_large'));
          }
        }
      }

      setState(() {
        _photos.addAll(validImages);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSubmitting = true);
      final lang = Provider.of<LanguageProvider>(context, listen: false);

      final data = _formKey.currentState!.value;
      final formData = Map<String, dynamic>.from(data);

      // Convert date to ISO string
      if (formData['deadline'] != null) {
        formData['deadline'] = (formData['deadline'] as DateTime)
            .toIso8601String();
      }

      // Note: In a real implementation, you would upload files here
      // and attach the URLs to the formData.
      // For this example, we proceed with the form data only.

      final response = await _api.post('/fundraisers', body: formData);

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (response.success) {
          AppToast.success(context, lang.getText('create_success'));
          Navigator.pop(context, true);
        } else {
          AppToast.error(
            context,
            response.message ?? lang.getText('create_failed'),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(title: Text(lang.getText('create_fundraiser_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, lang.getText('patient_details')),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'title',
                decoration: InputDecoration(
                  labelText: lang.getText('fundraiser_title_label'),
                  hintText: lang.getText('fundraiser_title_hint'),
                  border: const OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(5),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'patient_name',
                decoration: InputDecoration(
                  labelText: lang.getText('patient_name_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'hospital',
                decoration: InputDecoration(
                  labelText: lang.getText('hospital_name_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.local_hospital_outlined),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'amount_needed',
                      decoration: InputDecoration(
                        labelText: lang.getText('amount_needed_label'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
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
                      decoration: InputDecoration(
                        labelText: lang.getText('deadline_label'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: FormBuilderValidators.required(),
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: InputDecoration(
                  labelText: lang.getText('description_label'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(20),
                ]),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, lang.getText('documents_photos')),
              Text(
                lang.getText('upload_desc'),
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickDocuments,
                    icon: const Icon(Icons.upload_file),
                    label: Text(lang.getText('add_label')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(lang.getText('take_photo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_documents.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _documents.map((file) {
                    return Chip(
                      avatar: const Icon(Icons.description, size: 16),
                      label: Text(
                        file.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () {
                        setState(() {
                          _documents.remove(file);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              if (_photos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photos[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _photos.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(lang.getText('create_fundraiser_btn')),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
