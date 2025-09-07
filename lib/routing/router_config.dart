import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:baseball_diary2/routing/app_routes.dart';
import 'package:baseball_diary2/services/auth_service.dart';
import 'package:baseball_diary2/services/team_selection_helper.dart';
import 'package:baseball_diary2/screens/auth/auth_screen.dart';
import 'package:baseball_diary2/screens/team_selection_screen.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';
import 'package:baseball_diary2/screens/calendar_screen.dart';
import 'package:baseball_diary2/screens/diary_list_screen.dart';
import 'package:baseball_diary2/screens/record_screen.dart';
import 'package:baseball_diary2/screens/statistics_screen.dart';
import 'package:baseball_diary2/screens/settings_screen.dart';

/// GoRouter 전역 키 (네비게이션 컨텍스트에서 사용)
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 앱의 라우터 설정
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.auth,  // auth로 변경
  refreshListenable: AuthService(),  // AuthService 변경 시 리프레시
  redirect: (BuildContext context, GoRouterState state) async {
    try {
      final authService = context.read<AuthService>();
      final location = state.matchedLocation;
      
      print('Router redirect: location=$location, isLoading=${authService.isLoading}, isAuthenticated=${authService.isAuthenticated}');
      
      // 로딩 중일 때는 현재 위치 유지
      if (authService.isLoading) {
        print('Auth service is loading, staying at current location');
        return null;
      }
      
      // 인증되지 않은 경우 로그인 페이지로
      if (!authService.isAuthenticated) {
        if (location != AppRoutes.auth) {
          print('Not authenticated, redirecting to auth');
          return AppRoutes.auth;
        }
        print('Already at auth page');
        return null;
      }
      
      // 인증된 상태에서 auth 페이지에 있으면 팀 선택 확인
      if (authService.isAuthenticated) {
        if (location == AppRoutes.auth) {
          print('Authenticated but at auth page, checking team selection');
          final hasSelectedTeam = await TeamSelectionHelper.hasSelectedTeam();
          if (!hasSelectedTeam) {
            print('No team selected, redirecting to team selection');
            return AppRoutes.teamSelection;
          }
          print('Team selected, redirecting to calendar');
          return AppRoutes.calendar;
        }
        
        // 다른 페이지에서도 팀 선택 상태 확인
        if (location != AppRoutes.teamSelection) {
          final hasSelectedTeam = await TeamSelectionHelper.hasSelectedTeam();
          if (!hasSelectedTeam) {
            print('No team selected, redirecting to team selection');
            return AppRoutes.teamSelection;
          }
        }
      }
      
      print('No redirect needed');
      return null;
    } catch (e) {
      print('Router redirect error: $e');
      return AppRoutes.auth;  // 에러 시 로그인 페이지로
    }
  },
  routes: [
    // 인증 화면
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    
    // 팀 선택 화면
    GoRoute(
      path: AppRoutes.teamSelection,
      builder: (context, state) => TeamSelectionScreen(
        onTeamSelected: (team) {
          context.go(AppRoutes.calendar);
        },
      ),
    ),
    
    // 메인 앱 Shell Route (하단 네비게이션 바)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationScreen(child: child);
      },
      routes: [
        // 캘린더 화면
        GoRoute(
          path: AppRoutes.calendar,
          builder: (context, state) => const CalendarScreen(),
        ),
        
        // 다이어리 화면
        GoRoute(
          path: AppRoutes.diary,
          builder: (context, state) => const DiaryListScreen(),
        ),
        
        // 기록 화면
        GoRoute(
          path: AppRoutes.record,
          builder: (context, state) => const RecordScreen(),
        ),
        
        // 통계 화면
        GoRoute(
          path: AppRoutes.statistics,
          builder: (context, state) => const StatisticsScreen(),
        ),
        
        // 설정 화면
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);