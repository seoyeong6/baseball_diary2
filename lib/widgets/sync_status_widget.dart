import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/sticker_data.dart';

/// 동기화 상태를 표시하고 충돌을 해결하는 위젯
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final DiaryService _diaryService = DiaryService();
  late SyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = _diaryService.syncService;
    _syncService.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusHeader(),
            if (_syncService.hasConflicts) ...[
              const SizedBox(height: 16),
              _buildConflictsList(),
            ],
            if (_syncService.lastError != null) ...[
              const SizedBox(height: 8),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    IconData icon;
    Color color;
    String statusText;

    switch (_syncService.syncStatus) {
      case SyncStatus.idle:
        icon = Icons.cloud_outlined;
        color = Colors.grey;
        statusText = '동기화 대기 중';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        statusText = '동기화 중...';
        break;
      case SyncStatus.completed:
        icon = Icons.cloud_done;
        color = Colors.green;
        statusText = '동기화 완료';
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off;
        color = Colors.red;
        statusText = '동기화 실패';
        break;
      case SyncStatus.conflict:
        icon = Icons.warning;
        color = Colors.orange;
        statusText = '충돌 발견 (${_syncService.conflicts.length}개)';
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (_syncService.lastSyncTime != null)
                Text(
                  '마지막 동기화: ${_formatDateTime(_syncService.lastSyncTime!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        if (_syncService.syncStatus == SyncStatus.syncing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (!_syncService.isSyncing)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performSync,
            tooltip: '수동 동기화',
          ),
      ],
    );
  }

  Widget _buildConflictsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '충돌 해결 필요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _keepAllLocal,
                  child: const Text('모두 로컬 유지'),
                ),
                TextButton(
                  onPressed: _keepAllRemote,
                  child: const Text('모두 클라우드 유지'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._syncService.conflicts.map(_buildConflictItem),
      ],
    );
  }

  Widget _buildConflictItem(ConflictInfo conflict) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(conflict.description),
        subtitle: Text(
          '로컬: ${_formatDateTime(conflict.localUpdateTime)} | '
          '클라우드: ${_formatDateTime(conflict.remoteUpdateTime)}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildConflictComparison(conflict),
                const SizedBox(height: 16),
                _buildConflictActions(conflict),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictComparison(ConflictInfo conflict) {
    if (conflict.type == 'diary') {
      final localEntry = DiaryEntry.fromJson(conflict.localData);
      final remoteEntry = DiaryEntry.fromJson(conflict.remoteData);

      return Row(
        children: [
          Expanded(
            child: _buildDataCard('로컬 데이터', localEntry.title, localEntry.content),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDataCard('클라우드 데이터', remoteEntry.title, remoteEntry.content),
          ),
        ],
      );
    } else {
      final localSticker = StickerData.fromJson(conflict.localData);
      final remoteSticker = StickerData.fromJson(conflict.remoteData);

      return Row(
        children: [
          Expanded(
            child: _buildDataCard(
              '로컬 데이터',
              '스티커: ${localSticker.type.displayName}',
              '날짜: ${_formatDateTime(localSticker.date)}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDataCard(
              '클라우드 데이터',
              '스티커: ${remoteSticker.type.displayName}',
              '날짜: ${_formatDateTime(remoteSticker.date)}',
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDataCard(String title, String subtitle, String content) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConflictActions(ConflictInfo conflict) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: () => _resolveConflict(conflict.id, ConflictResolutionStrategy.keepLocal),
          child: const Text('로컬 유지'),
        ),
        OutlinedButton(
          onPressed: () => _resolveConflict(conflict.id, ConflictResolutionStrategy.keepRemote),
          child: const Text('클라우드 유지'),
        ),
        if (conflict.type == 'diary')
          OutlinedButton(
            onPressed: () => _resolveConflict(conflict.id, ConflictResolutionStrategy.merge),
            child: const Text('병합'),
          ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _syncService.lastError ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _performSync() async {
    try {
      await _diaryService.syncWithCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('동기화를 시작했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resolveConflict(String conflictId, ConflictResolutionStrategy strategy) async {
    try {
      await _syncService.resolveConflictWithUserChoice(conflictId, strategy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('충돌이 해결되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('충돌 해결 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _keepAllLocal() async {
    try {
      await _syncService.keepAllLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 충돌을 로컬 데이터로 해결했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('충돌 해결 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _keepAllRemote() async {
    try {
      await _syncService.keepAllRemote();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 충돌을 클라우드 데이터로 해결했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('충돌 해결 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}