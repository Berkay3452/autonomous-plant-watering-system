import 'package:flutter/material.dart';

/// Gezinme çubuğundaki bir sekme.
class NavTab {
  const NavTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Tasarımdaki yüzen, hap biçimli alt gezinme çubuğu. Her iki temada da
/// beyazdır; seçili sekme açık yeşil hapla işaretlenir.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _bg = Colors.white;
  static const _selectedBg = Color(0xFFE6F3BF);
  static const _selectedFg = Color(0xFF2B7337);
  static const _fg = Color(0xFF4F6B55);

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [BoxShadow(color: Color(0x26123D1C), blurRadius: 20, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selectedIndex,
                    button: true,
                    label: tabs[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: i == selectedIndex ? _selectedBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              i == selectedIndex ? tabs[i].selectedIcon : tabs[i].icon,
                              size: 24,
                              color: i == selectedIndex ? _selectedFg : _fg,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              tabs[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle?.copyWith(
                                fontSize: 11.5,
                                color: i == selectedIndex ? _selectedFg : _fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
