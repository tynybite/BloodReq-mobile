import 'package:flutter/material.dart';
import '../../../core/config/country_config.dart';
import '../../../core/constants/app_theme.dart';

class CountrySelectorModal extends StatefulWidget {
  final Function(CountryOption) onSelect;

  const CountrySelectorModal({super.key, required this.onSelect});

  @override
  State<CountrySelectorModal> createState() => _CountrySelectorModalState();
}

class _CountrySelectorModalState extends State<CountrySelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryOption> _filteredCountries = CountryConfig.countries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = CountryConfig.countries.where((country) {
        return country.name.toLowerCase().contains(query) ||
            country.dialCode.contains(query) ||
            country.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country or code',
                hintStyle: TextStyle(color: context.textTertiary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.surfaceVariantBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: TextStyle(color: context.textPrimary),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCountries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(color: context.textPrimary),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
