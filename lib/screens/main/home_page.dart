import 'package:flutter/material.dart';

import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';
import 'package:flutter_fin_pwa/screens/main/dashboard_page.dart';
import 'package:flutter_fin_pwa/screens/main/settings_page.dart';
import 'package:flutter_fin_pwa/screens/main/statistics_page.dart';
import 'package:flutter_fin_pwa/screens/main/transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    TransactionsPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      // --- TOOLTIP ADDED TO FAB ---
      floatingActionButton: Tooltip(
        message: 'Add Transaction',
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddTransactionPage()));
          },
          child: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, pageIndex: 0, label: 'Dashboard'),
            _buildNavItem(icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, pageIndex: 1, label: 'Transactions'),
            
            const SizedBox(width: 48),
            
            _buildNavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, pageIndex: 2, label: 'Statistics'),
            _buildNavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, pageIndex: 3, label: 'Settings'),
          ],
        ),
      ),
    );
  }

  // --- UPDATED HELPER TO WRAP IconButton WITH Tooltip ---
  Widget _buildNavItem({required IconData icon, required IconData selectedIcon, required int pageIndex, required String label}) {
    final bool isSelected = _selectedIndex == pageIndex;
    return Tooltip(
      message: label,
      child: IconButton(
        iconSize: 28,
        icon: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade600,
        ),
        onPressed: () => _onItemTapped(pageIndex),
      ),
    );
  }
}