import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedTabBar extends StatefulWidget {
  final List<String> widgetOptions;
  final ValueChanged<int> onTabChange;

  const AnimatedTabBar({
    super.key,
    required this.widgetOptions,
    required this.onTabChange,
  });

  @override
  State<AnimatedTabBar> createState() => _AnimatedTabBarState();
}

class _AnimatedTabBarState extends State<AnimatedTabBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(widget.widgetOptions.length, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                  widget.onTabChange(index); // Notify parent of tab change
                });
              },
              child: SizedBox(
                width: width / widget.widgetOptions.length, // Equal width for each tab
                height: 50.h, // Adjust height as needed
                child: Center(
                  child: Text(widget.widgetOptions[index]), // Use the provided list
                ),
              ),
            );
          }),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          left: (width / widget.widgetOptions.length) * _selectedIndex, // Simplified left calculation
          bottom: 6.h,
          child: Container(
            width: width / widget.widgetOptions.length, // Match tab width
            height: 40.h,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, // Or your appTheme.containerColor
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Text("home"),
          ),
        ),
      ],
    );
  }
}

// Example usage:
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  int _currentIndex = 0;
  final List<String> _widgetOptions = ['Home', 'Friends', 'History'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(children: [
        AnimatedTabBar(widgetOptions: _widgetOptions, onTabChange: (index) {
          setState(() {
            _currentIndex=index;
          });
        }),
        Text(_widgetOptions[_currentIndex])
      ]),
    );
  }
}