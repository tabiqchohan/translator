import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onChanged;
  final bool allowAuto;

  const LanguageSelector({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.allowAuto = false,
  });

  List<String> _recentLangs(BuildContext context) {
    try {
      return Provider.of<SettingsProvider>(context, listen: false).recentLangs;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    SettingsProvider? settings;
    try {
      settings = Provider.of<SettingsProvider>(context, listen: false);
    } catch (_) {}

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagePickerSheet(
        selectedCode: selectedCode,
        allowAuto: allowAuto,
        recentLangs: _recentLangs(context),
      ),
    );

    if (selected != null) {
      settings?.addRecentLang(selected);
      if (selected != selectedCode) onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppConstants.getLanguageName(selectedCode),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final String selectedCode;
  final bool allowAuto;
  final List<String> recentLangs;

  const _LanguagePickerSheet({
    required this.selectedCode,
    required this.allowAuto,
    required this.recentLangs,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _allLangs() {
    return widget.allowAuto
        ? AppConstants.languages
        : AppConstants.languages.where((l) => l['code'] != 'auto').toList();
  }

  List<Map<String, String>> _filter(List<Map<String, String>> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((l) =>
            (l['name'] ?? '').toLowerCase().contains(q) ||
            (l['code'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = isDark ? const Color(0xFF131C2E) : Colors.white;

    final allLangs = _filter(_allLangs());
    final querying = _query.trim().isNotEmpty;
    final recentCodes = widget.recentLangs
        .where((c) => widget.allowAuto || c != 'auto')
        .toList();
    final recentList = _filter(
      recentCodes
          .map((c) => {'code': c, 'name': AppConstants.getLanguageName(c)})
          .toList(),
    );
    final recentSet = recentList.map((l) => l['code']).toSet();
    final remaining =
        allLangs.where((l) => !recentSet.contains(l['code'])).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Material(
          color: surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search languages...',
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
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: (allLangs.isEmpty && recentList.isEmpty)
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No languages found'),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          if (!querying && recentList.isNotEmpty) ...[
                            _sectionHeader(context, 'Recent'),
                            ...recentList
                                .map((l) => _tile(context, l, primary)),
                            _sectionHeader(context, 'All Languages'),
                          ],
                          ...remaining.map((l) => _tile(context, l, primary)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Map<String, String> lang, Color primary) {
    final code = lang['code'] ?? '';
    final isSelected = code == widget.selectedCode;
    final isRecent = widget.recentLangs.contains(code);

    return ListTile(
      dense: true,
      onTap: () => Navigator.pop(context, code),
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? primary : Colors.grey.shade400,
        size: 20,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              lang['name'] ?? '',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primary : null,
              ),
            ),
          ),
          if (isRecent && !isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.history_rounded,
                  size: 14, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}
