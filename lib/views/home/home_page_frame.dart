import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';

import 'home_page.dart';
import '../entry/login_page.dart';
import 'friends_page.dart';
import 'history_page.dart';
// import '../../views/test_1.dart';

class HomePageFrame extends StatefulWidget {
  const HomePageFrame({super.key});

  @override
  State<HomePageFrame> createState() => _HomePageFrameState();
}

class _HomePageFrameState extends State<HomePageFrame> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
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
    final appTheme = context.watch<AppTheme>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  appTheme.currentLogoPath,
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
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            indicatorColor:
                Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            destinations: <Widget>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedIconTheme
                        ?.color),
                selectedIcon: Icon(Icons.home,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .selectedIconTheme
                        ?.color),
                label: 'Home',
                tooltip: 'Find Someone to Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedIconTheme
                        ?.color),
                selectedIcon: Icon(Icons.people,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .selectedIconTheme
                        ?.color),
                label: 'Friends',
                tooltip: 'Strangers Turned Friends',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedIconTheme
                        ?.color),
                selectedIcon: Icon(Icons.history,
                    color: Theme.of(context)
                        .bottomNavigationBarTheme
                        .selectedIconTheme
                        ?.color),
                label: 'History',
                tooltip: 'Strangers You Met',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
