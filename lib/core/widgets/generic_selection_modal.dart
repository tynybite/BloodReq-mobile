import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class GenericSelectionModal<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Function(T) onSelect;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item, String query) searchMatcher;
  final String searchHint;

  const GenericSelectionModal({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    required this.itemBuilder,
    required this.searchMatcher,
    this.searchHint = 'Search...',
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required Function(T) onSelect,
    required Widget Function(BuildContext context, T item) itemBuilder,
    required bool Function(T item, String query) searchMatcher,
    String searchHint = 'Search...',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GenericSelectionModal<T>(
          title: title,
          items: items,
          onSelect: onSelect,
          itemBuilder: itemBuilder,
          searchMatcher: searchMatcher,
          searchHint: searchHint,
        ),
      ),
    );
  }

  @override
  State<GenericSelectionModal<T>> createState() =>
      _GenericSelectionModalState<T>();
}

class _GenericSelectionModalState<T> extends State<GenericSelectionModal<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.searchMatcher(item, query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: context.cardShadow,
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.textSecondary),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(color: context.textTertiary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.surfaceVariantBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              style: TextStyle(color: context.textPrimary),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return InkWell(
                        onTap: () {
                          widget.onSelect(item);
                          Navigator.pop(context);
                        },
                        child: widget.itemBuilder(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
