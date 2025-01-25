import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
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
    final width = MediaQuery.of(context).size.width;
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
        padding: const EdgeInsets.only(left: 8.0,right: 8.0,bottom: 4.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25), // Curves all edges
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'friends',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                selectedLabelStyle: TextStyle(color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor),
                unselectedLabelStyle: TextStyle(color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor),
                showUnselectedLabels: false,
                showSelectedLabels: false,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: (width / _widgetOptions.length) * _selectedIndex +
                  (width / _widgetOptions.length - width / 4.5) / 2,
              bottom: 8,
              child: Container(
                width: width / 4,
                height: 42,
                decoration: BoxDecoration(
                  // color: Theme.of(context).primaryColor,
                  color: appTheme.containerColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Icon(
                    _selectedIndex == 0
                        ? Icons.home
                        : _selectedIndex == 1
                        ? Icons.people
                        : Icons.history,
                    color: Theme.of(context).bottomNavigationBarTheme.selectedIconTheme?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
