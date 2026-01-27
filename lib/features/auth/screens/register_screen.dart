import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/language_config.dart';
import '../../../core/config/country_config.dart';
import '../widgets/country_selector_modal.dart';
import '../../../core/widgets/generic_selection_modal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  final _api = ApiService();
  int _currentStep = 0;

  // Form data
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String? _selectedCountry; // For Location Step
  String? _selectedCity; // For Location Step
  String _selectedCountryFlag = '🇧🇩'; // Default to BD or update on selection

  // New Phone Country State
  CountryOption _phoneCountry = CountryConfig.getOption('US');

  bool _isPasswordVisible = false;
  bool _isLoading = false;

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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingLocations = true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.countries,
      );

      if (response.success && response.data != null) {
        setState(() {
          final data = response.data as Map<String, dynamic>;
          // Handle 'countries' key from backend
          if (data.containsKey('countries')) {
            _countries = (data['countries'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          } else if (data['data'] is List) {
            // Fallback if data itself is the list (older format)
            _countries = (data['data'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }

          if (_countries.isNotEmpty) {
            final first = _countries.first;
            _selectedCountry = first['name'] ?? 'Bangladesh';

            // Resolve flag for initial selection
            final code = first['code'] as String? ?? 'BD';
            final config = CountryConfig.countries.firstWhere(
              (c) => c.code == code || c.name == _selectedCountry,
              orElse: () => CountryConfig.countries.firstWhere(
                (c) => c.code == 'BD',
                orElse: () => CountryConfig.countries[0],
              ),
            );
            _selectedCountryFlag = config.flag;

            if (_selectedCountry != null) {
              _loadCities(_selectedCountry!);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }

    setState(() => _loadingLocations = false);
  }

  Future<void> _loadCities(String country) async {
    setState(() => _loadingLocations = true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.cities,
        queryParams: {'country': country},
      );

      if (response.success && response.data != null) {
        setState(() {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('cities')) {
            _cities = (data['cities'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          } else if (data['data'] is List) {
            _cities = (data['data'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }

          if (_cities.isNotEmpty) {
            _selectedCity = _cities.first['name'] ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
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

  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountrySelectorModal(
        onSelect: (country) {
          setState(() => _phoneCountry = country);
        },
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lang = context.read<LanguageProvider>();

    // Validate location
    if (_selectedCountry == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.getText('select_location_error')),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Combine dial code and phone number
    final fullPhoneNumber =
        '${_phoneCountry.dialCode}${_phoneController.text.trim()}';

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phoneNumber: fullPhoneNumber,
      bloodGroup: _selectedBloodGroup,
      country: _selectedCountry!,
      city: _selectedCity!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      if (authProvider.isAuthenticated) {
        if (mounted) context.go('/home');
      } else {
        // Email verification required
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email'),
              backgroundColor: AppColors.primary,
            ),
          );
          context.push(
            '/otp-verification',
            extra: _emailController.text.trim(),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? lang.getText('reg_failed')),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // 1. Blob Pattern
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
            child: CustomPaint(painter: _BlobPainter(color: AppColors.primary)),
          ),

          // 2. Main Layout
          Column(
            children: [
              // HEADER SECTION
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Back + Language
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (_currentStep > 0) {
                                _previousStep();
                              } else {
                                context.go('/login');
                              }
                            },
                          ),
                          // Language Switcher
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: PopupMenuButton<Locale>(
                              offset: const Offset(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tooltip: 'Select Language',
                              initialValue: lang.currentLocale,
                              onSelected: (locale) =>
                                  lang.changeLanguage(locale),
                              itemBuilder: (context) =>
                                  LanguageConfig.options.map((option) {
                                    return PopupMenuItem(
                                      value: Locale(option.code),
                                      child: Row(
                                        children: [
                                          Text(
                                            option.flag,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(option.name),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${LanguageConfig.getOption(lang.currentLocale.languageCode).flag} ${lang.currentLocale.languageCode.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          lang.getText('create_account'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step Indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(
                              'Step ${_currentStep + 1} of 3',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_currentStep + 1) / 3,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.12),

              // FORM SECTION (Bottom Sheet)
              Expanded(
                child:
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
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
                    ).animate().slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final lang = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('basic_info'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.getText('basic_info_subtitle'),
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: lang.getText('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return lang.getText('enter_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: lang.getText('email'),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return lang.getText('enter_email');
                }
                if (!value.contains('@')) {
                  return lang.getText('valid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number with Country Code
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText('phone_number'),
                  style: TextStyle(color: context.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Selector
                    GestureDetector(
                      onTap: _showCountrySelector,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _phoneCountry.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _phoneCountry.dialCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Phone Input
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '1234567890',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return lang.getText('enter_phone');
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: lang.getText('password'),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return lang.getText('enter_password');
                }
                if (value.length < 6) {
                  return lang.getText('password_length');
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  lang.getText('continue'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodInfoStep() {
    final bloodGroups = AppConstants.bloodGroups;
    final lang = context.watch<LanguageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('blood_info'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.getText('blood_group_q'),
            style: TextStyle(color: context.textSecondary),
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
                        : context.surfaceVariantBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : context.borderColor,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      group,
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.textPrimary,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                lang.getText('continue'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    final lang = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('your_location'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.getText('location_subtitle'),
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 32),

            // Country Selector
            InkWell(
              onTap: () {
                GenericSelectionModal.show<Map<String, dynamic>>(
                  context: context,
                  title: lang.getText('select_country'),
                  items: _countries,
                  searchHint: lang.getText('search_country'),
                  onSelect: (country) {
                    final countryName = country['name'] as String;
                    final countryCode = country['code'] as String?;

                    // Resolve flag
                    final configCountry = CountryConfig.countries.firstWhere(
                      (c) => c.code == countryCode || c.name == countryName,
                      orElse: () => CountryConfig.countries.firstWhere(
                        (c) => c.code == 'BD',
                        orElse: () => CountryConfig.countries[0],
                      ),
                    );

                    setState(() {
                      _selectedCountry = countryName;
                      _selectedCountryFlag = configCountry.flag;
                      _selectedCity = null; // Reset city on country change
                    });
                    _loadCities(countryName);
                  },
                  itemBuilder: (context, country) {
                    // Try to find flag from config
                    final countryCode = country['code'] as String?;
                    final countryName = country['name'] as String;

                    final configCountry = CountryConfig.countries.firstWhere(
                      (c) => c.code == countryCode || c.name == countryName,
                      orElse: () => CountryConfig.countries.firstWhere(
                        (c) => c.code == 'BD',
                        orElse: () => CountryConfig.countries[0],
                      ),
                    );

                    final flag = configCountry.flag;

                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        countryName,
                        style: TextStyle(color: context.textPrimary),
                      ),
                      trailing: countryName == _selectedCountry
                          ? Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                    );
                  },
                  searchMatcher: (country, query) {
                    final name = (country['name'] as String).toLowerCase();
                    final code =
                        (country['code'] as String?)?.toLowerCase() ?? '';
                    return name.contains(query) || code.contains(query);
                  },
                );
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: lang.getText('country'),
                  prefixIcon: const Icon(Icons.public),
                  // Show loading or dropdown arrow
                  suffixIcon: _loadingLocations
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedCountry != null) ...[
                      Text(
                        _selectedCountryFlag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _selectedCountry ?? lang.getText('select_country'),
                        style: TextStyle(
                          color: _selectedCountry != null
                              ? context.textPrimary
                              : context.textTertiary,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // City Selector
            InkWell(
              onTap: _selectedCountry == null
                  ? null
                  : () {
                      GenericSelectionModal.show<Map<String, dynamic>>(
                        context: context,
                        title: lang.getText('select_city'),
                        items: _cities,
                        searchHint: lang.getText('search_city'),
                        onSelect: (city) {
                          setState(
                            () => _selectedCity = city['name'] as String,
                          );
                        },
                        itemBuilder: (context, city) {
                          final cityName = city['name'] as String;
                          return ListTile(
                            leading: Text(
                              _selectedCountryFlag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(
                              cityName,
                              style: TextStyle(color: context.textPrimary),
                            ),
                            trailing: cityName == _selectedCity
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                          );
                        },
                        searchMatcher: (city, query) {
                          final name = (city['name'] as String).toLowerCase();
                          return name.contains(query);
                        },
                      );
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: lang.getText('city'),
                  prefixIcon: const Icon(Icons.location_city),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                child: Text(
                  _selectedCity ?? lang.getText('select_city'),
                  style: TextStyle(
                    color: _selectedCity != null
                        ? context.textPrimary
                        : context.textTertiary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        lang.getText('create_account'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                lang.getText('terms_privacy'),
                style: TextStyle(color: context.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;

  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Start top-left
    path.lineTo(0, size.height * 0.75);

    // Smooth bezier curve for organic blob feel
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.6,
      size.height * 0.85,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.75,
      size.width,
      size.height * 0.9,
    );

    // End top-right
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
