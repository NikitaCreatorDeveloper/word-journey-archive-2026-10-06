import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../features/match_flow_lab/match_flow_lab_screen.dart';

import 'airy_components.dart';
import 'design_tokens.dart';
import 'motion_preferences.dart';

import '../features/profile/cefr_profile.dart';
import '../features/profile/level_selector_screen.dart';
import '../features/topics/categories_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/progress/progress_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tabMotion = AnimationController(
    vsync: this,
    duration: AppMotion.page,
    value: 1,
  );
  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _tabMotion.duration = motionDuration(context, AppMotion.page, calmMs: 220);
    _tabMotion.forward(from: 0);
  }

  @override
  void dispose() {
    _tabMotion.dispose();
    super.dispose();
  }

  late int _selectedIndex = widget.initialIndex;
  static const _titles = ['Категории', 'Повторение', 'Прогресс'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_titles[_selectedIndex]),
      actions: [
        if (kDebugMode)
          IconButton(
            key: const ValueKey('open-match-flow-lab'),
            enableFeedback: false,
            tooltip: 'Match Flow Lab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const MatchFlowLabScreen(),
              ),
            ),
            icon: const Icon(Icons.science_outlined),
          ),
        if (_selectedIndex != 0)
          TextButton(
            key: const ValueKey('open-level-settings'),
            onPressed: () => Navigator.push(
              context,
              AiryPageRoute<void>(
                builder: (_) => const LevelSelectorScreen(settings: true),
              ),
            ),
            child: Text(ProfileScope.levelOf(context).shortLabel),
          ),
        IconButton(
          tooltip: 'Настройки',
          onPressed: () => Navigator.push(
            context,
            AiryPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: FadeTransition(
        opacity: Tween<double>(begin: .7, end: 1).animate(_tabMotion),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .01), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: _tabMotion, curve: Curves.easeOutCubic),
              ),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              TickerMode(
                enabled: _selectedIndex == 0,
                child: CategoriesScreen(onReview: () => _select(1)),
              ),
              TickerMode(
                enabled: _selectedIndex == 1,
                child: const ReviewScreen(),
              ),
              TickerMode(
                enabled: _selectedIndex == 2,
                child: const ProgressScreen(),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppSurfaces.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppSurfaces.outline(context).withValues(alpha: .35),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        backgroundColor: Colors.transparent,
        animationDuration: motionDuration(
          context,
          AppMotion.selection,
          calmMs: 160,
        ),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: _navIcon(context, Icons.grid_view),
            label: 'Категории',
          ),
          NavigationDestination(
            icon: const Icon(Icons.replay),
            selectedIcon: _navIcon(context, Icons.replay),
            label: 'Повторение',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: _navIcon(context, Icons.insights),
            label: 'Прогресс',
          ),
        ],
      ),
    ),
  );
  Widget _navIcon(BuildContext context, IconData icon) => Container(
    width: 58,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: AppSurfaces.dark(context)
            ? const [Color(0xFF5044AD), Color(0xFF342D79)]
            : const [Color(0xFFE6DFFF), Color(0xFFD2C5FC)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppShadows.glow(AppColors.accentSecondary, strength: .12),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
  );
}
