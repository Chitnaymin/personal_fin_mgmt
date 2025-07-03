import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';
import 'package:flutter_fin_pwa/screens/main/dashboard_page.dart';
import 'package:flutter_fin_pwa/screens/main/settings_page.dart';
import 'package:flutter_fin_pwa/screens/main/transactions_page.dart';
import 'package:flutter/material.dart';

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
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionPage()));
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: const Icon(Icons.dashboard), onPressed: () => _onItemTapped(0), color: _selectedIndex == 0 ? Theme.of(context).primaryColor : Colors.grey),
            IconButton(icon: const Icon(Icons.list_alt), onPressed: () => _onItemTapped(1), color: _selectedIndex == 1 ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 40), // The space for the FAB
            IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => _onItemTapped(1), color: _selectedIndex == 1 ? Theme.of(context).primaryColor : Colors.grey), // Placeholder
            IconButton(icon: const Icon(Icons.settings), onPressed: () => _onItemTapped(2), color: _selectedIndex == 2 ? Theme.of(context).primaryColor : Colors.grey),
          ],
        ),
      ),
    );
  }
}