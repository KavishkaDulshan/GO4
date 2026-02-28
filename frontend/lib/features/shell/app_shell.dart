import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/',        icon: Icons.camera_alt_rounded,      outlinedIcon: Icons.camera_alt_outlined,     label: 'Scan'),
    (path: '/map',     icon: Icons.explore_rounded,         outlinedIcon: Icons.explore_outlined,        label: 'Map'),
    (path: '/history', icon: Icons.history_rounded,         outlinedIcon: Icons.history,                 label: 'History'),
    (path: '/profile', icon: Icons.person_rounded,          outlinedIcon: Icons.person_outline_rounded,  label: 'Profile'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => t.path == location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIdx = _selectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: selectedIdx,
        bottomPadding: bottomPadding,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i].path);
        },
        tabs: _tabs,
      ),
    );
  }
}

// ─── Floating nav bar container ───────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int    selectedIndex;
  final double bottomPadding;
  final void   Function(int) onTap;
  final List<({String path, IconData icon, IconData outlinedIcon, String label})> tabs;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.bottomPadding,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 0.5px separator
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.07)),
          Container(
            color:   AppTheme.surface,
            padding: EdgeInsets.only(
              top:    10,
              bottom: bottomPadding + 10,
              left:   8,
              right:  8,
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                return Expanded(
                  child: GestureDetector(
                    onTap:    () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: _NavItem(
                      icon:         tabs[i].icon,
                      outlinedIcon: tabs[i].outlinedIcon,
                      label:        tabs[i].label,
                      selected:     i == selectedIndex,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single nav item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String   label;
  final bool     selected;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:    const Duration(milliseconds: 220),
      curve:       Curves.easeOutCubic,
      margin:      const EdgeInsets.symmetric(horizontal: 4),
      padding:     selected
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
          : const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:      MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              selected ? icon : outlinedIcon,
              key:   ValueKey(selected),
              size:  22,
              color: selected ? AppTheme.primary : Colors.white38,
            ),
          ),
          // Label slides in when selected
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve:    Curves.easeOutCubic,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color:         AppTheme.primary,
                        fontSize:      13,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
