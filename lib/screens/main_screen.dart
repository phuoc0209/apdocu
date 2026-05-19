import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../utils/language_provider.dart';
import 'admin/admin_screen.dart';
import 'chat/chat_list_screen.dart';
import 'home/home_screen.dart';
import 'product/product_list_screen.dart';
import 'profile/account_screen.dart';
import 'search/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadMessages = 0;
  bool _isAdmin = false;

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  StreamSubscription<List<ChatModel>>? _chatSubscription;
  StreamSubscription<UserModel?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Keep badge state synced with authentication and chat updates.
    _authSubscription =
        _authService.authStateChanges.listen((user) {
      _chatSubscription?.cancel();

      if (user == null) {
        if (mounted) {
          _updateAdminState(
            false,
            beforeSetState: () {
              _unreadMessages = 0;
            },
          );
        }
        return;
      }

      // TODO: Fix ChatService to work with new backend or disable chat for now
      /*
      _chatSubscription = _chatService.getUserChats(user.uid).listen((chats) {
        final unread = chats.fold<int>(
          0,
          (total, chat) => total + (chat.unreadCount[user.uid] ?? 0),
        );

        if (mounted && unread != _unreadMessages) {
          setState(() => _unreadMessages = unread);
        }
      });
      */

      _loadAdminState(user.uid);
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navEntries = _navEntries;
    final navItems = navEntries.map((entry) => entry.item).toList(growable: false);
    final navScreens = navEntries.map((entry) => entry.screen).toList(growable: false);

    int effectiveIndex = _currentIndex;
    if (navScreens.isNotEmpty && effectiveIndex >= navScreens.length) {
      effectiveIndex = navScreens.length - 1;
      if (effectiveIndex != _currentIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentIndex = effectiveIndex);
          }
        });
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: effectiveIndex,
        children: navScreens,
      ),
      bottomNavigationBar:
          _buildBottomNavigationBar(context, navItems, effectiveIndex),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    List<_NavItemData> navItems,
    int activeIndex,
  ) {
    const activeColor = Color(0xFF6C63FF);
    const inactiveColor = Color(0xFF8E92B7);
    final chatIndex = navItems.indexWhere((item) => item.key == 'messages');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = activeIndex == index;

                return Expanded(
                  child: _NavigationButton(
                    item: item,
                    isSelected: isSelected,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    badgeCount:
                        index == chatIndex ? _unreadMessages : 0,
                    onTap: () {
                      if (_currentIndex != index) {
                        setState(() => _currentIndex = index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAdminState(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      final isAdmin = userData?.isAdmin ?? false;
      if (!mounted) return;
      _updateAdminState(isAdmin);
    } catch (e) {
      debugPrint('Load admin state error: $e');
    }
  }

  void _updateAdminState(bool isAdmin, {VoidCallback? beforeSetState}) {
    final previousEntries = _navEntries;
    final previousLabel = (_currentIndex < previousEntries.length)
        ? previousEntries[_currentIndex].item.key
        : null;

    setState(() {
      beforeSetState?.call();
      _isAdmin = isAdmin;
      final newEntries = _navEntries;
      int newIndex = 0;
      if (previousLabel != null) {
        final idx = newEntries.indexWhere(
          (entry) => entry.item.key == previousLabel,
        );
        if (idx != -1) {
          newIndex = idx;
        }
      }

      if (newEntries.isNotEmpty) {
        if (newIndex >= newEntries.length) {
          newIndex = newEntries.length - 1;
        }
        _currentIndex = newIndex;
      } else {
        _currentIndex = 0;
      }
    });
  }

  List<_NavEntry> get _navEntries {
    final lp = LanguageProvider();

    final entries = <_NavEntry>[
      const _NavEntry(
        screen: HomeScreen(),
        item: _NavItemData(
          key: 'home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
      ),
      const _NavEntry(
        screen: SearchScreen(),
        item: _NavItemData(
          key: 'search',
          icon: Icons.search_outlined,
          activeIcon: Icons.search,
        ),
      ),
      const _NavEntry(
        screen: ProductListScreen(),
        item: _NavItemData(
          key: 'products',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        ),
      ),
      const _NavEntry(
        screen: ChatListScreen(),
        item: _NavItemData(
          key: 'messages',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble_rounded,
        ),
      ),
    ];

    if (_isAdmin) {
      entries.add(
        const _NavEntry(
          screen: AdminScreen(),
          item: _NavItemData(
            key: 'admin_panel',
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
          ),
        ),
      );
    }

    entries.add(
      const _NavEntry(
        screen: AccountScreen(),
        item: _NavItemData(
          key: 'account',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ),
    );

    return entries;
  }
}

class _NavItemData {
  const _NavItemData({
    required this.key,
    required this.icon,
    required this.activeIcon,
  });

  final String key;
  final IconData icon;
  final IconData activeIcon;
}

class _NavEntry {
  const _NavEntry({
    required this.screen,
    required this.item,
  });

  final Widget screen;
  final _NavItemData item;
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.badgeCount,
    required this.onTap,
  });

  final _NavItemData item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lp = LanguageProvider();
    final label = lp.translate(item.key);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: isSelected ? 14 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 26,
                    color: isSelected ? Colors.white : inactiveColor,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -12,
                      top: -10,
                      child: _Badge(
                        count: badgeCount,
                        activeColor: activeColor,
                        isHighlighted: isSelected,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.count,
    required this.activeColor,
    required this.isHighlighted,
  });

  final int count;
  final Color activeColor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.white : activeColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? activeColor : Colors.white,
          width: 2,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: isHighlighted ? activeColor : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
