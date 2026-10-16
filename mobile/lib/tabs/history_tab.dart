import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/history_entry.dart';
import '../providers/history_provider.dart';

class HistoryTab extends StatefulWidget {
  final bool onlyFavorites;
  const HistoryTab({super.key, this.onlyFavorites = false});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(HistoryEntry item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete translation?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will permanently remove this entry from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final history = Provider.of<HistoryProvider>(context, listen: false);
    final index = history.entries.indexWhere((e) => e.id == item.id);
    final success = await history.deleteEntry(item.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Translation deleted'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => history.restoreEntry(item, index),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final historyProvider = Provider.of<HistoryProvider>(context);
    final allList = widget.onlyFavorites
        ? historyProvider.favorites
        : historyProvider.entries;

    final filteredList = allList.where((e) {
      final q = _query.toLowerCase();
      return e.sourceText.toLowerCase().contains(q) ||
          e.translatedText.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.onlyFavorites
                      ? 'Search favorites...'
                      : 'Search translations...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: primary, size: 22),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: historyProvider.isLoading
                ? _buildSkeleton()
                : filteredList.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => historyProvider.fetchHistory(),
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Center(
                                child: _buildEmpty(theme, primary),
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => historyProvider.fetchHistory(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF131C2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              primary.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              AppConstants.getLanguageName(
                                                  item.sourceLang),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 12, color: primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppConstants.getLanguageName(
                                                  item.targetLang),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => historyProvider
                                                .toggleFavorite(item.id),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: Icon(
                                                item.isFavorite
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                        .favorite_border_rounded,
                                                color: item.isFavorite
                                                    ? const Color(0xFFEF4444)
                                                    : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => _confirmDelete(item),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.sourceText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.translatedText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.onlyFavorites
                ? Icons.favorite_border_rounded
                : Icons.history_rounded,
            size: 52,
            color: primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.onlyFavorites
              ? 'No favorite translations yet'
              : 'No translation history yet',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          widget.onlyFavorites
              ? 'Tap the heart icon on any translation to save it here'
              : 'Translate some text, speech, or photos to see them here',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const AlwaysScrollableScrollPhysics(),
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C2E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: base),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _skeletonBox(base, 90, 20, BorderRadius.circular(8)),
                  const Spacer(),
                  _skeletonBox(base, 40, 28, BorderRadius.circular(14)),
                ],
              ),
              const SizedBox(height: 14),
              _skeletonBox(base, double.infinity, 16, BorderRadius.circular(6)),
              const SizedBox(height: 8),
              _skeletonBox(base, double.infinity, 14, BorderRadius.circular(6)),
            ],
          ),
        );
      }),
    );
  }

  Widget _skeletonBox(Color base, double w, double h, BorderRadius radius) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.7),
        borderRadius: radius,
      ),
    );
  }
}
