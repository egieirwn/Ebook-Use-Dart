import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ebook/provider/auth_provider.dart';
import 'package:ebook/screen/favorite.dart';
import 'package:ebook/screen/home.dart';
import 'package:ebook/screen/profile.dart';
import 'package:ebook/screen/searching.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _favoritesTick = 0;
  int _searchTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        auth.loadCurrentUser();
      }
    });
  }

  void _onDestinationSelected(int value) {
    setState(() {
      if (value == 1) _searchTick++;
      if (value == 2) _favoritesTick++;
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final pages = [
      HomePage(
        isAdmin: isAdmin,
        onOpenSearch: () => _onDestinationSelected(1),
      ),
      SearchPage(key: ValueKey(_searchTick)),
      FavoriteBookPage(key: ValueKey(_favoritesTick)),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
