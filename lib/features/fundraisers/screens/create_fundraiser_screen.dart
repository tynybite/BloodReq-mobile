import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
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

  // Hospital/location search
  final _hospitalController = TextEditingController();
  final _locationController = TextEditingController();
  bool _loadingHospitals = false;
  List<Map<String, dynamic>> _hospitals = [];
  bool _showHospitalSuggestions = false;
  String? _lastSelectedHospital;

  // City search
  String _selectedCity = 'Dhaka';
  bool _loadingCities = false;
  List<Map<String, dynamic>> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
    _hospitalController.addListener(_onHospitalTextChanged);
  }

  @override
  void dispose() {
    _hospitalController.removeListener(_onHospitalTextChanged);
    _hospitalController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── City Loading ───
  Future<void> _loadCities() async {
    setState(() => _loadingCities = true);

    // Use the user's registered country so we fetch the correct cities
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final country = user?.country ?? 'BD';

    final response = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.cities,
      queryParams: {'country': country},
    );
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        final data = response.data as Map<String, dynamic>;
        final citiesList = data['cities'] as List<dynamic>?;
        if (citiesList != null) {
          _cities = citiesList.map((e) => e as Map<String, dynamic>).toList();
          if (_cities.isNotEmpty) {
            _selectedCity = _cities.first['name'] ?? '';
          }
        }
      });
    }
    setState(() => _loadingCities = false);
  }

  // ─── Hospital Search (Google Places API) ───
  void _onHospitalTextChanged() {
    if (_lastSelectedHospital != null &&
        _hospitalController.text == _lastSelectedHospital) {
      return;
    }
    _lastSelectedHospital = null;

    final query = _hospitalController.text;
    if (query.length >= 3) {
      _searchHospitals(query);
    } else {
      setState(() {
        _hospitals = [];
        _showHospitalSuggestions = false;
      });
    }
  }

  Future<void> _searchHospitals(String query) async {
    const apiKey = GoogleMapsConfig.apiKey;
    if (apiKey.isEmpty) {
      setState(() {
        _loadingHospitals = false;
        _showHospitalSuggestions = false;
      });
      return;
    }

    setState(() => _loadingHospitals = true);

    try {
      final searchQuery = '$query hospital $_selectedCity';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(searchQuery)}'
        '&types=hospital|health|doctor'
        '&key=$apiKey',
      );

      final response = await ApiService().httpGet(url);
      if (!mounted) return;

      if (_lastSelectedHospital != null &&
          _hospitalController.text == _lastSelectedHospital) {
        setState(() => _loadingHospitals = false);
        return;
      }

      if (response != null) {
        final predictions = response['predictions'] as List<dynamic>? ?? [];
        setState(() {
          _hospitals = predictions
              .take(5)
              .map(
                (p) => {
                  'name':
                      (p['structured_formatting']?['main_text'] ??
                              p['description'])
                          as String,
                  'address':
                      (p['structured_formatting']?['secondary_text'] ?? '')
                          as String,
                  'place_id': p['place_id'] as String,
                },
              )
              .toList();
          _showHospitalSuggestions = _hospitals.isNotEmpty;
          _loadingHospitals = false;
        });
      } else {
        setState(() {
          _loadingHospitals = false;
          _showHospitalSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingHospitals = false;
          _showHospitalSuggestions = false;
        });
      }
    }
  }

  // ─── City Search Sheet ───
  void _showCitySearchSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CitySearchSheet(
        cities: _cities,
        selectedCity: _selectedCity,
        isDark: isDark,
        onSelect: (city) {
          setState(() => _selectedCity = city);
          // Also update the location field in the form
          _locationController.text = city;
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _pickDocuments() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
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
      final lang = Provider.of<LanguageProvider>(context, listen: false);

      // Require at least one document or photo
      if (_documents.isEmpty && _photos.isEmpty) {
        if (mounted) {
          AppToast.error(
            context,
            'Please upload at least one document or photo',
          );
        }
        return;
      }

      setState(() => _isSubmitting = true);

      // Upload all documents and photos first
      final List<Map<String, dynamic>> uploadedDocs = [];

      for (final doc in _documents) {
        if (doc.path != null) {
          final url = await _api.uploadFile(
            doc.path!,
            folder: 'fundraiser-documents',
          );
          if (url != null) {
            uploadedDocs.add({
              'url': url,
              'type': doc.extension ?? 'unknown',
              'name': doc.name,
            });
          }
        }
      }

      for (final photo in _photos) {
        final url = await _api.uploadFile(
          photo.path,
          folder: 'fundraiser-documents',
        );
        if (url != null) {
          uploadedDocs.add({'url': url, 'type': 'image', 'name': photo.name});
        }
      }

      // If none uploaded successfully, show error
      if (uploadedDocs.isEmpty && mounted) {
        setState(() => _isSubmitting = false);
        AppToast.error(
          context,
          'Failed to upload documents. Please try again.',
        );
        return;
      }

      final data = _formKey.currentState!.value;
      final formData = Map<String, dynamic>.from(data);

      // Add hospital and location from our controllers
      formData['hospital'] = _hospitalController.text;
      formData['location'] = _selectedCity;
      formData['documents'] = uploadedDocs;

      if (formData['deadline'] != null) {
        formData['deadline'] = (formData['deadline'] as DateTime)
            .toIso8601String();
      }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

              // Hospital search with Google Places API
              _buildHospitalSearchField(isDark),
              const SizedBox(height: 16),

              // City search & select
              _buildCitySelector(isDark),
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
                      valueTransformer: (val) =>
                          val != null ? num.tryParse(val.toString()) : null,
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

  // ─── Hospital Search Field with Suggestions ───
  Widget _buildHospitalSearchField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _hospitalController,
          decoration: InputDecoration(
            labelText: 'Hospital / Location',
            prefixIcon: const Icon(Icons.local_hospital_outlined, size: 22),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: _loadingHospitals
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onTap: () {
            if (_hospitalController.text.length >= 2) {
              setState(() => _showHospitalSuggestions = true);
            }
          },
        ),
        if (_showHospitalSuggestions && _hospitals.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.md,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hospitals.length > 5 ? 5 : _hospitals.length,
              itemBuilder: (context, index) {
                final hospital = _hospitals[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.local_hospital,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    hospital['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    hospital['address'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final name = hospital['name'] ?? '';
                    _lastSelectedHospital = name;
                    _hospitalController.text = name;
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _showHospitalSuggestions = false;
                      _hospitals = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // ─── City Selector (tap to open search sheet) ───
  Widget _buildCitySelector(bool isDark) {
    return GestureDetector(
      onTap: () => _showCitySearchSheet(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.location_city, color: AppColors.textTertiary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'City / Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCity,
                    style: TextStyle(fontSize: 16, color: context.textPrimary),
                  ),
                ],
              ),
            ),
            if (_loadingCities)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          ],
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

// ─────────────────────────────────────────────────────────────
// City Search Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _CitySearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> cities;
  final String selectedCity;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _CitySearchSheet({
    required this.cities,
    required this.selectedCity,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.cities;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.cities;
      } else {
        _filtered = widget.cities
            .where((c) => (c['name'] as String).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.location_city, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Select City',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: const Icon(Icons.search, size: 22),
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Divider(height: 1),
          // City list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No cities found',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final city = _filtered[index]['name'] as String;
                      final isSelected = city == widget.selectedCity;
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        title: Text(
                          city,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : context.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 22,
                              )
                            : null,
                        onTap: () => widget.onSelect(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
