import 'package:flutter/material.dart';

// Import your functional pages
import 'package:flutter_fin_pwa/screens/main/dashboard_page.dart';
import 'package:flutter_fin_pwa/screens/main/transactions_page.dart';
import 'package:flutter_fin_pwa/screens/main/statistics_page.dart';
import 'package:flutter_fin_pwa/screens/main/settings_page.dart';
import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _pages = [
    DashboardPage(),
    TransactionsPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionPage()));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 0),
            _buildNavItem(Icons.list_alt_outlined, Icons.list_alt, 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.bar_chart_outlined, Icons.bar_chart, 2),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(isSelected ? selectedIcon : icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
      onPressed: () => _onItemTapped(index),
    );
  }
}