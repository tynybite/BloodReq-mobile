import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _contactController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String _selectedUrgency = 'urgent';
  String _selectedCity = 'Dhaka';

  bool _isLoading = false;
  bool _loadingCities = false;
  List<Map<String, dynamic>> _cities = [];

  // Hospital search
  bool _loadingHospitals = false;
  List<Map<String, dynamic>> _hospitals = [];
  bool _showHospitalSuggestions = false;

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
    // Get API key from constants
    const apiKey = GoogleMapsConfig.apiKey;

    // If no API key, just allow manual entry
    if (apiKey.isEmpty) {
      setState(() {
        _loadingHospitals = false;
        _showHospitalSuggestions = false;
      });
      return;
    }

    setState(() => _loadingHospitals = true);

    try {
      // Use Google Places Autocomplete API directly
      final searchQuery = '$query hospital $_selectedCity';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(searchQuery)}'
        '&types=hospital|health|doctor'
        '&key=$apiKey',
      );

      final response = await ApiService().httpGet(url);

      if (response != null && mounted) {
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
      // On error, allow manual entry
      setState(() {
        _loadingHospitals = false;
        _showHospitalSuggestions = false;
      });
    }
  }

  Future<void> _loadCities() async {
    setState(() => _loadingCities = true);

    final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.cities);

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

  @override
  void dispose() {
    _hospitalController.removeListener(_onHospitalTextChanged);
    _patientNameController.dispose();
    _hospitalController.dispose();
    _contactController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

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
      },
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Blood request created successfully! Pending admin approval.',
          ),
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
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Blood Group Selection
            Text(
              'Blood Group Needed',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
                      color: isSelected ? AppColors.primary : context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        group,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Urgency Selection
            Text(
              'Urgency Level',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _UrgencyChip(
                  label: 'Critical',
                  value: 'critical',
                  selectedValue: _selectedUrgency,
                  color: AppColors.urgencyCritical,
                  onTap: () => setState(() => _selectedUrgency = 'critical'),
                ),
                const SizedBox(width: 10),
                _UrgencyChip(
                  label: 'Urgent',
                  value: 'urgent',
                  selectedValue: _selectedUrgency,
                  color: AppColors.urgencyUrgent,
                  onTap: () => setState(() => _selectedUrgency = 'urgent'),
                ),
                const SizedBox(width: 10),
                _UrgencyChip(
                  label: 'Planned',
                  value: 'planned',
                  selectedValue: _selectedUrgency,
                  color: AppColors.urgencyPlanned,
                  onTap: () => setState(() => _selectedUrgency = 'planned'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Patient Name
            TextFormField(
              controller: _patientNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Hospital with Search
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _hospitalController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Hospital / Location',
                    prefixIcon: const Icon(Icons.local_hospital_outlined),
                    hintText: 'Search hospital...',
                    suffixIcon: _loadingHospitals
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onTap: () {
                    if (_hospitalController.text.length >= 2) {
                      setState(() => _showHospitalSuggestions = true);
                    }
                  },
                ),
                // Hospital suggestions dropdown
                if (_showHospitalSuggestions && _hospitals.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                            color: AppColors.primary,
                            size: 20,
                          ),
                          title: Text(
                            hospital['name'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: hospital['address'] != null
                              ? Text(
                                  hospital['address'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            _hospitalController.text = hospital['name'] ?? '';
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
            ),
            const SizedBox(height: 16),

            // City
            DropdownButtonFormField<String>(
              value: _cities.any((c) => c['name'] == _selectedCity)
                  ? _selectedCity
                  : null,
              decoration: InputDecoration(
                labelText: 'City',
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: _loadingCities
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _cities.isEmpty
                  ? [
                      const DropdownMenuItem(
                        value: 'Dhaka',
                        child: Text('Dhaka'),
                      ),
                    ]
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
            ),
            const SizedBox(height: 16),

            // Contact & Units Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Units',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      final units = int.tryParse(v!);
                      if (units == null || units < 1) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Text(
              'Your request will be reviewed by our team and published once approved.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
