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
      debugPrint('Error loading settings: $e');
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
      debugPrint('Export error: $e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 테마 설정
          _buildSettingCard(
            context,
            title: '테마 설정',
            children: [
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 팀 설정
          _buildSettingCard(
            context,
            title: '응원팀',
            children: [
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 데이터 관리
          _buildSettingCard(
            context,
            title: '데이터 관리',
            children: [
              ListTile(
                title: const Text('데이터 내보내기'),
                subtitle: const Text('기록을 JSON 파일로 백업'),
                trailing: const Icon(Icons.download),
                onTap: _exportData,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 앱 정보
          _buildSettingCard(
            context,
            title: '앱 정보',
            children: [
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
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}