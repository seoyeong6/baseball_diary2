import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:baseball_diary2/widgets/nav_tab.dart';
import 'package:baseball_diary2/routing/app_routes.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key, required this.child});

  final Widget child;

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case AppRoutes.calendar:
        return 0;
      case AppRoutes.diary:
        return 1;
      case AppRoutes.record:
        return 2;
      case AppRoutes.statistics:
        return 3;
      case AppRoutes.settings:
        return 4;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.calendar);
        break;
      case 1:
        context.go(AppRoutes.diary);
        break;
      case 2:
        context.go(AppRoutes.record);
        break;
      case 3:
        context.go(AppRoutes.statistics);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    
    return Scaffold(
      body: child,
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
                  text: 'Calendar',
                  isSelected: currentIndex == 0,
                  icon: FontAwesomeIcons.calendar,
                  onTap: () => _onTap(context, 0),
                ),
                NavTab(
                  text: 'Diary',
                  isSelected: currentIndex == 1,
                  icon: FontAwesomeIcons.book,
                  onTap: () => _onTap(context, 1),
                ),
                NavTab(
                  text: 'Record',
                  isSelected: currentIndex == 2,
                  icon: FontAwesomeIcons.penToSquare,
                  onTap: () => _onTap(context, 2),
                ),
                NavTab(
                  text: 'Graphs',
                  isSelected: currentIndex == 3,
                  icon: FontAwesomeIcons.chartLine,
                  onTap: () => _onTap(context, 3),
                ),
                NavTab(
                  text: 'Settings',
                  isSelected: currentIndex == 4,
                  icon: FontAwesomeIcons.gear,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
