import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import '../services/team_selection_helper.dart';
import '../services/diary_service.dart';
import '../models/team.dart';
import '../controllers/theme_controller.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/team_info_widget.dart';
import '../services/auth_service.dart';
import '../widgets/sync_status_widget.dart';
import 'team_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Team? _selectedTeam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final team = await TeamSelectionHelper.getSelectedTeam();
      setState(() {
        _selectedTeam = team;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeTeam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamSelectionScreen(
          onTeamSelected: (team) async {
            await TeamSelectionHelper.saveSelectedTeam(team);
            setState(() {
              _selectedTeam = team;
            });
            
            // 캘린더 컨트롤러에 팀 변경 알림
            if (context.mounted) {
              final calendarController = context.read<CalendarController>();
              await calendarController.onTeamChanged();
            }
          },
        ),
      ),
    );

    if (result != null) {
      _loadSettings();
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final diaryService = DiaryService();
      await diaryService.initialize();

      final backupData = await diaryService.createDataBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'baseball_diary_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: '야구 다이어리 백업 데이터',
        subject: '야구 다이어리 데이터 백업',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터가 성공적으로 내보내졌습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 내보내기에 실패했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAllData() async {
    // 확인 대화상자 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '모든 야구 일기와 스티커 기록이 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.\n\n'
          '정말로 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final diaryService = DiaryService();
      await diaryService.initialize();
      await diaryService.clearAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 데이터 삭제 플래그를 잠시 후 리셋 (리스너들이 처리할 시간을 줌)
        Future.delayed(const Duration(milliseconds: 100), () {
          diaryService.resetDataClearedFlag();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 삭제에 실패했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0, right: 8.0),
          child: TeamInfoWidget(),
        ),
      ),
      body: ListView(
        children: [
          // 테마 설정 섹션
          _buildSectionHeader(context, '테마 설정'),
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('시스템 설정 따라가기'),
                    subtitle: const Text('기기의 다크모드 설정을 따름'),
                    value: ThemeMode.system,
                    groupValue: themeController.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeController.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('라이트 모드'),
                    subtitle: const Text('밝은 테마 사용'),
                    value: ThemeMode.light,
                    groupValue: themeController.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeController.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('다크 모드'),
                    subtitle: const Text('어두운 테마 사용'),
                    value: ThemeMode.dark,
                    groupValue: themeController.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeController.setThemeMode(value);
                      }
                    },
                  ),
                ],
              );
            },
          ),

          _buildDivider(context),

          // 응원팀 섹션
          _buildSectionHeader(context, '응원팀'),
          ListTile(
            title: const Text('선택된 팀'),
            subtitle: Text(_selectedTeam?.name ?? '팀을 선택해주세요'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedTeam != null)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedTeam!.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _changeTeam,
          ),

          _buildDivider(context),

          // 동기화 상태 섹션
          _buildSectionHeader(context, '데이터 동기화'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SyncStatusWidget(),
          ),

          _buildDivider(context),

          // 데이터 관리 섹션
          _buildSectionHeader(context, '데이터 관리'),
          ListTile(
            title: const Text('데이터 내보내기'),
            subtitle: const Text('기록을 JSON 파일로 백업'),
            trailing: const Icon(Icons.download),
            onTap: _exportData,
          ),
          ListTile(
            title: Text(
              '데이터 삭제하기',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: const Text('모든 기록을 삭제 (복구 불가)'),
            trailing: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: _deleteAllData,
          ),

          _buildDivider(context),

          // 계정 설정 섹션
          _buildSectionHeader(context, '계정 설정'),
          ListTile(
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('현재 계정에서 로그아웃'),
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.red,
            ),
            onTap: _logout,
          ),

          _buildDivider(context),

          // 앱 정보 섹션
          _buildSectionHeader(context, '앱 정보'),
          const ListTile(
            title: Text('버전'),
            subtitle: Text('1.0.0'),
            trailing: Icon(Icons.info_outline),
          ),
          const ListTile(
            title: Text('개발자'),
            subtitle: Text('Baseball Diary Team'),
            trailing: Icon(Icons.person_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // 확인 대화상자 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말로 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // AuthService를 통해 로그아웃
      final authService = AuthService();
      await authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}
