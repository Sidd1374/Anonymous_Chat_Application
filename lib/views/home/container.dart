import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';

import 'homepage.dart';
import '../entry/login.dart';
import 'friends_list.dart';
import 'history.dart';
import 'profile.dart';
// import '../../views/test_1.dart';

class HomePageFrame extends StatefulWidget {
  const HomePageFrame({super.key});

  @override
  State<HomePageFrame> createState() => _HomePageFrameState();
}

class _HomePageFrameState extends State<HomePageFrame> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    FriendsList(),
    FriendsPage(),
    History(),
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
                  MaterialPageRoute(builder: (context) => ProfileLvl1()),
                );
              },
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: kBottomNavigationBarHeight + 10.h, // Adjusted height
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              borderRadius:
                  BorderRadius.circular(18.r), // Fully rounded container
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r), // Match outer radius
              child: NavigationBar(
                height: kBottomNavigationBarHeight + 5.h,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                indicatorColor: Theme.of(context)
                    .bottomNavigationBarTheme
                    .selectedItemColor,
                backgroundColor:
                    Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                destinations: <Widget>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined,
                        size: 28,
                        color: Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedIconTheme
                            ?.color),
                    selectedIcon: Icon(Icons.home,
                        size: 32,
                        color: Theme.of(context)
                            .bottomNavigationBarTheme
                            .selectedIconTheme
                            ?.color),
                    label: 'Home',
                    tooltip: 'Find Strangers to Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline,
                        size: 28,
                        color: Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedIconTheme
                            ?.color),
                    selectedIcon: Icon(Icons.people,
                        size: 32,
                        color: Theme.of(context)
                            .bottomNavigationBarTheme
                            .selectedIconTheme
                            ?.color),
                    label: 'Friends',
                    tooltip: 'Strangers Turned Friends',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined,
                        size: 28,
                        color: Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedIconTheme
                            ?.color),
                    selectedIcon: Icon(Icons.history,
                        size: 32,
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
        ),
      ),
    );
  }
}
