import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:baseball_diary2/widgets/nav_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final screens = [
    Center(child: Text('Home')),
    Center(child: Text('Diary')),
    Center(child: Text('Record')),
    Center(child: Text('Graphs')),
    Center(child: Text('Settings')),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Offstage(
            offstage: _selectedIndex != 0,
            child: screens[_selectedIndex],
          ),
          Offstage(
            offstage: _selectedIndex != 1,
            child: screens[_selectedIndex],
          ),
          Offstage(
            offstage: _selectedIndex != 2,
            child: screens[_selectedIndex],
          ),
          Offstage(
            offstage: _selectedIndex != 3,
            child: screens[_selectedIndex],
          ),
          Offstage(
            offstage: _selectedIndex != 4,
            child: screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: BottomAppBar(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NavTab(
                  text: 'Home',
                  isSelected: _selectedIndex == 0,
                  icon: FontAwesomeIcons.house,
                  onTap: () => _onTap(0),
                ),
                NavTab(
                  text: 'Diary',
                  isSelected: _selectedIndex == 1,
                  icon: FontAwesomeIcons.book,
                  onTap: () => _onTap(1),
                ),
                NavTab(
                  text: 'Record',
                  isSelected: _selectedIndex == 2,
                  icon: FontAwesomeIcons.penToSquare,
                  onTap: () => _onTap(2),
                ),
                NavTab(
                  text: 'Graphs',
                  isSelected: _selectedIndex == 3,
                  icon: FontAwesomeIcons.chartLine,
                  onTap: () => _onTap(3),
                ),
                NavTab(
                  text: 'Settings',
                  isSelected: _selectedIndex == 4,
                  icon: FontAwesomeIcons.gear,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
