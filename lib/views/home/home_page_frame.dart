import 'package:flutter/material.dart';
import 'home_page.dart';
import '../entry/login_page.dart';
import 'friends_page.dart';
import 'history_page.dart';

class HomePageFrame extends StatefulWidget {
  const HomePageFrame({super.key});

  @override
  State<HomePageFrame> createState() => _HomePageFrameState();
}

class _HomePageFrameState extends State<HomePageFrame> {
  int _selectedIndex = 0; // Track selected index

  static  final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    FriendsPage(),
    HistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo/app_logo.png',
                  height: 35,
                  width: 35,
                ),
                const SizedBox(width: 10),
                Text(
                  "VEIL",
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),

      body: _widgetOptions.elementAt(_selectedIndex), // Display selected widget
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex, // Highlight selected item
        selectedItemColor: Theme.of(context).primaryColor, // Highlight color
        onTap: _onItemTapped,
      ),
    );
  }
}