import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/sticker_data.dart';

class StickerSelectionModal extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<StickerType>) onStickersSelected;

  const StickerSelectionModal({
    super.key,
    required this.selectedDate,
    required this.onStickersSelected,
  });

  @override
  State<StickerSelectionModal> createState() => _StickerSelectionModalState();
}

class _StickerSelectionModalState extends State<StickerSelectionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<StickerType> _selectedStickers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStickerIcon(StickerType stickerType, {required double size}) {
    if (stickerType.icon == FontAwesomeIcons.baseballBatBall) {
      return FaIcon(
        stickerType.icon,
        size: size * 0.85,
        color: stickerType.color,
      );
    }
    
    return Icon(
      stickerType.icon,
      size: size,
      color: stickerType.color,
    );
  }

  Widget _buildStickerGrid(List<StickerType> stickers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return _buildStickerCard(sticker);
      },
    );
  }

  Widget _buildStickerCard(StickerType stickerType) {
    final theme = Theme.of(context);
    final isSelected = _selectedStickers.contains(stickerType);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedStickers.remove(stickerType);
          } else {
            _selectedStickers.add(stickerType);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? stickerType.color.withValues(alpha: 0.2) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? stickerType.color : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: stickerType.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _buildStickerIcon(
                stickerType,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stickerType.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '스티커 선택',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedStickers.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          widget.onStickersSelected(_selectedStickers.toList());
                          Navigator.of(context).pop();
                        },
                        child: Text('완료 (${_selectedStickers.length})'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 선택된 날짜 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget.selectedDate.day}일',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // 탭바
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '경기'),
              Tab(text: '활동'),
              Tab(text: '기타'),
            ],
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            indicatorSize: TabBarIndicatorSize.label,
          ),
          
          // 스티커 그리드
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStickerGrid(StickerType.getGameRelatedTypes()),
                _buildStickerGrid(StickerType.getActivityTypes()),
                _buildStickerGrid([
                  StickerType.rain,
                  StickerType.postponed,
                  StickerType.special,
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}