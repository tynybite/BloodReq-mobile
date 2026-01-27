import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/scroll_control_provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/fundraiser_card.dart';

class FundraisersScreen extends StatefulWidget {
  const FundraisersScreen({super.key});

  @override
  State<FundraisersScreen> createState() => _FundraisersScreenState();
}

class _FundraisersScreenState extends State<FundraisersScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _fundraisers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFundraisers();
  }

  Future<void> _loadFundraisers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>('/fundraisers');

    if (response.success && response.data != null) {
      List<dynamic> fundList;

      // Handle response - could be List or Map with data property
      if (response.data is List) {
        fundList = response.data as List;
      } else if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        fundList = (mapData['data'] ?? mapData['fundraisers'] ?? []) as List;
      } else {
        fundList = [];
      }

      setState(() {
        _fundraisers = fundList.map((e) => e as Map<String, dynamic>).toList();
      });
    } else {
      setState(() => _error = response.message ?? 'Failed to load fundraisers');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadFundraisers,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final scrollProvider = Provider.of<ScrollControlProvider>(
              context,
              listen: false,
            );
            if (notification.direction == ScrollDirection.reverse) {
              scrollProvider.hideBottomNav();
            } else if (notification.direction == ScrollDirection.forward) {
              scrollProvider.showBottomNav();
            }
            return true;
          },
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFundraisers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fundraisers.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Fundraisers'),
            backgroundColor: context.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No fundraisers available',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for campaigns',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Fundraisers'),
          backgroundColor: context.scaffoldBg,
          surfaceTintColor: Colors.transparent,
          floating: true,
          snap: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final fund = _fundraisers[index];
              return FundraiserCard(
                    fundraiser: fund,
                    onTap: () => context.push('/fundraiser/${fund['id']}'),
                  )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0);
            }, childCount: _fundraisers.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}
