import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  final _api = ApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedBloodGroup = 'O+';
  String _selectedCountry = 'Bangladesh';
  String _selectedCity = 'Dhaka';

  // Location data
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingLocations = true);

    final response = await _api.get<List<dynamic>>(ApiEndpoints.countries);

    if (response.success && response.data != null) {
      setState(() {
        _countries = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (_countries.isNotEmpty) {
          _selectedCountry = _countries.first['name'] ?? 'Bangladesh';
          _loadCities(_selectedCountry);
        }
      });
    }

    setState(() => _loadingLocations = false);
  }

  Future<void> _loadCities(String country) async {
    setState(() => _loadingLocations = true);

    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.cities,
      queryParams: {'country': country},
    );

    if (response.success && response.data != null) {
      setState(() {
        _cities = (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (_cities.isNotEmpty) {
          _selectedCity = _cities.first['name'] ?? '';
        }
      });
    }

    setState(() => _loadingLocations = false);
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      country: _selectedCountry,
      city: _selectedCity,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      if (authProvider.isAuthenticated) {
        context.go('/home');
      } else {
        // Email verification required
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your email to verify your account'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text('Create Account'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentStep + 1}/3',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),

          // Form Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildBloodInfoStep(),
                _buildLocationStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us a little about yourself',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+880 1XXX-XXXXXX',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _nextStep();
                  }
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodInfoStep() {
    final bloodGroups = AppConstants.bloodGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'What\'s your blood group?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: bloodGroups.length,
            itemBuilder: (context, index) {
              final group = bloodGroups[index];
              final isSelected = group == _selectedBloodGroup;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedBloodGroup = group);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
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
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Location',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us find nearby donors and requests',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Country Dropdown
          DropdownButtonFormField<String>(
            value: _countries.any((c) => c['name'] == _selectedCountry)
                ? _selectedCountry
                : null,
            decoration: InputDecoration(
              labelText: 'Country',
              prefixIcon: const Icon(Icons.public),
              suffixIcon: _loadingLocations
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            items: _countries.isEmpty
                ? [
                    const DropdownMenuItem(
                      value: 'Bangladesh',
                      child: Text('Bangladesh'),
                    ),
                  ]
                : _countries
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['name'] as String,
                          child: Text(c['name'] as String),
                        ),
                      )
                      .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCountry = value);
                _loadCities(value);
              }
            },
          ),
          const SizedBox(height: 16),

          // City Dropdown
          DropdownButtonFormField<String>(
            value: _cities.any((c) => c['name'] == _selectedCity)
                ? _selectedCity
                : null,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city),
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
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCity = value);
              }
            },
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'By signing up, you agree to our Terms & Privacy Policy',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
