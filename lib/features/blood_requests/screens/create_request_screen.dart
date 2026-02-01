import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/step_indicator.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _pageController = PageController();

  // Controllers
  final _patientNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  int _currentStep = 0;
  String _selectedBloodGroup = 'O+';
  String _selectedUrgency = 'urgent';
  String _selectedCity = 'Dhaka';
  DateTime _selectedDate = DateTime.now();
  File? _medicalReport;
  bool _isLoading = false;
  bool _loadingCities = false;
  List<Map<String, dynamic>> _cities = [];

  // Hospital search
  bool _loadingHospitals = false;
  List<Map<String, dynamic>> _hospitals = [];
  bool _showHospitalSuggestions = false;
  String? _lastSelectedHospital;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _prefillContact();
    _hospitalController.addListener(_onHospitalTextChanged);
  }

  void _prefillContact() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.phoneNumber != null) {
      _contactController.text = user!.phoneNumber!;
    }
  }

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

  Future<void> _loadCities() async {
    setState(() => _loadingCities = true);

    final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.cities);
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        final data = response.data as Map<String, dynamic>;
        final citiesList = data['cities'] as List<dynamic>?;
        if (citiesList != null) {
          _cities = citiesList.map((e) => e as Map<String, dynamic>).toList();
          if (_cities.isNotEmpty) {
            _selectedCity = _cities.first['name'] ?? 'Dhaka';
          }
        }
      });
    }

    setState(() => _loadingCities = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _medicalReport = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _hospitalController.removeListener(_onHospitalTextChanged);
    _patientNameController.dispose();
    _hospitalController.dispose();
    _contactController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_patientNameController.text.trim().isEmpty) {
      _showError('Please enter patient name');
      return false;
    }
    if (_contactController.text.trim().isEmpty) {
      _showError('Please enter contact number');
      return false;
    }
    final units = int.tryParse(_unitsController.text);
    if (units == null || units < 1) {
      _showError('Please enter valid units');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_hospitalController.text.trim().isEmpty) {
      _showError('Please enter hospital name');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && _validateStep1()) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = 0);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_validateStep2()) return;

    setState(() => _isLoading = true);

    final response = await _api.post(
      ApiEndpoints.bloodRequests,
      body: {
        'patient_name': _patientNameController.text.trim(),
        'blood_group': _selectedBloodGroup,
        'units': int.tryParse(_unitsController.text) ?? 1,
        'hospital': _hospitalController.text.trim(),
        'city': _selectedCity,
        'contact_number': _contactController.text.trim(),
        'urgency': _selectedUrgency,
        'notes': _notesController.text.trim(),
        'required_date': _selectedDate.toIso8601String(),
      },
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blood request created! Pending admin approval.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/requests');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to create request'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: const Text('Request Blood'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentStep + 1} of 2',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: StepIndicator(currentStep: _currentStep),
          ),

          // Pages
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(isDark), _buildStep2(isDark)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 1: Patient + Blood + Urgency
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Patient Info
          _SectionCard(
            icon: Icons.person_outline,
            title: 'Patient Information',
            isDark: isDark,
            child: Column(
              children: [
                _buildTextField(
                  controller: _patientNameController,
                  label: 'Patient Name',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Blood Requirements
          _SectionCard(
            icon: Icons.water_drop_outlined,
            title: 'Blood Requirements',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Blood Group',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBloodGroupGrid(isDark),
                const SizedBox(height: 20),
                _buildUnitsSelector(isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Urgency & Date
          _SectionCard(
            icon: Icons.access_time,
            title: 'Urgency & Date',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUrgencyChips(isDark),
                const SizedBox(height: 20),
                _buildDatePicker(isDark),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'NEXT: LOCATION',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2: Location + Documents + Submit
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Location
          _SectionCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            isDark: isDark,
            child: Column(
              children: [
                _buildCityDropdown(isDark),
                const SizedBox(height: 16),
                _buildHospitalField(isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Additional Details
          _SectionCard(
            icon: Icons.notes_outlined,
            title: 'Additional Details (Optional)',
            isDark: isDark,
            child: Column(
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes for donors',
                  icon: Icons.edit_note,
                  maxLines: 3,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildDocumentUpload(isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Card
          _buildSummaryCard(isDark),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SUBMIT REQUEST',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // ─────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ─────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBloodGroupGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: AppConstants.bloodGroups.length,
      itemBuilder: (context, index) {
        final group = AppConstants.bloodGroups[index];
        final isSelected = group == _selectedBloodGroup;

        return GestureDetector(
          onTap: () => setState(() => _selectedBloodGroup = group),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                group,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitsSelector(bool isDark) {
    final units = int.tryParse(_unitsController.text) ?? 1;

    return Row(
      children: [
        Text(
          'Units Required',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: units > 1
                    ? () => setState(
                        () => _unitsController.text = (units - 1).toString(),
                      )
                    : null,
                icon: Icon(
                  Icons.remove,
                  color: units > 1 ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  units.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: units < 10
                    ? () => setState(
                        () => _unitsController.text = (units + 1).toString(),
                      )
                    : null,
                icon: Icon(
                  Icons.add,
                  color: units < 10
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyChips(bool isDark) {
    const urgencies = [
      {
        'label': 'Critical',
        'value': 'critical',
        'color': AppColors.urgencyCritical,
      },
      {'label': 'Urgent', 'value': 'urgent', 'color': AppColors.urgencyUrgent},
      {
        'label': 'Planned',
        'value': 'planned',
        'color': AppColors.urgencyPlanned,
      },
    ];

    return Row(
      children: urgencies.map((u) {
        final isSelected = _selectedUrgency == u['value'];
        final color = u['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: u != urgencies.last ? 10 : 0),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedUrgency = u['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  u['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required By',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _cities.any((c) => c['name'] == _selectedCity)
          ? _selectedCity
          : null,
      decoration: InputDecoration(
        labelText: 'City',
        prefixIcon: const Icon(Icons.location_city, size: 22),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _loadingCities
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
      items: _cities.isEmpty
          ? [const DropdownMenuItem(value: 'Dhaka', child: Text('Dhaka'))]
          : _cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c['name'] as String,
                    child: Text(c['name'] as String),
                  ),
                )
                .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedCity = v);
      },
    );
  }

  Widget _buildHospitalField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _hospitalController,
          decoration: InputDecoration(
            labelText: 'Hospital / Location',
            prefixIcon: const Icon(Icons.local_hospital_outlined, size: 22),
            filled: true,
            fillColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildDocumentUpload(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: _medicalReport != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _medicalReport!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _medicalReport = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: 32,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload Rx / Report',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Request Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Patient', value: _patientNameController.text),
          _SummaryRow(
            label: 'Blood',
            value: '$_selectedBloodGroup • ${_unitsController.text} units',
          ),
          _SummaryRow(
            label: 'Urgency',
            value:
                _selectedUrgency[0].toUpperCase() +
                _selectedUrgency.substring(1),
          ),
          _SummaryRow(
            label: 'Date',
            value: DateFormat('MMM d, yyyy').format(_selectedDate),
          ),
          if (_hospitalController.text.isNotEmpty)
            _SummaryRow(label: 'Hospital', value: _hospitalController.text),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
