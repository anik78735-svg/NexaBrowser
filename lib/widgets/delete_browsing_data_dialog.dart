import 'package:flutter/material.dart';

enum DeleteTimeRange { last15Min, lastHour, last24Hours, last7Days, last4Weeks, allTime }

extension DeleteTimeRangeLabel on DeleteTimeRange {
  String get label {
    switch (this) {
      case DeleteTimeRange.last15Min:
        return "Last 15 minutes";
      case DeleteTimeRange.lastHour:
        return "Last hour";
      case DeleteTimeRange.last24Hours:
        return "Last 24 hours";
      case DeleteTimeRange.last7Days:
        return "Last 7 days";
      case DeleteTimeRange.last4Weeks:
        return "Last 4 weeks";
      case DeleteTimeRange.allTime:
        return "All time";
    }
  }

  Duration? get duration {
    switch (this) {
      case DeleteTimeRange.last15Min:
        return const Duration(minutes: 15);
      case DeleteTimeRange.lastHour:
        return const Duration(hours: 1);
      case DeleteTimeRange.last24Hours:
        return const Duration(hours: 24);
      case DeleteTimeRange.last7Days:
        return const Duration(days: 7);
      case DeleteTimeRange.last4Weeks:
        return const Duration(days: 28);
      case DeleteTimeRange.allTime:
        return null; // null => delete everything
    }
  }
}

class DeleteBrowsingDataResult {
  final DeleteTimeRange range;
  final bool clearHistory;
  final bool clearOpenTabs;
  final bool clearCookiesAndSiteData;

  DeleteBrowsingDataResult({
    required this.range,
    required this.clearHistory,
    required this.clearOpenTabs,
    required this.clearCookiesAndSiteData,
  });
}

Future<DeleteBrowsingDataResult?> showDeleteBrowsingDataDialog(
  BuildContext context, {
  required int openTabCount,
}) {
  return showModalBottomSheet<DeleteBrowsingDataResult>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _DeleteBrowsingDataSheet(),
  ).then((result) => result);
}

class _DeleteBrowsingDataSheet extends StatefulWidget {
  const _DeleteBrowsingDataSheet();

  @override
  State<_DeleteBrowsingDataSheet> createState() => _DeleteBrowsingDataSheetState();
}

class _DeleteBrowsingDataSheetState extends State<_DeleteBrowsingDataSheet> {
  DeleteTimeRange _range = DeleteTimeRange.last15Min;
  bool _showMoreOptions = false;

  bool _history = true;
  bool _openTabs = true;
  bool _cookiesSiteData = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Delete browsing data",
              style: TextStyle(color: colors.onSurface, fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 18),
            DropdownButtonHideUnderline(
              child: DropdownButton<DeleteTimeRange>(
                value: _range,
                dropdownColor: colors.surfaceContainerHighest,
                style: TextStyle(color: colors.primary, fontSize: 15),
                icon: Icon(Icons.arrow_drop_down, color: colors.primary),
                items: DeleteTimeRange.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _range = v ?? _range),
              ),
            ),
            const SizedBox(height: 8),
            _optionRow(
              icon: Icons.history,
              title: "Browsing history",
              subtitle: "History for this device",
              value: _history,
              onChanged: (v) => setState(() => _history = v),
            ),
            _optionRow(
              icon: Icons.tab_outlined,
              title: "Open tabs",
              subtitle: "Tabs on this device will be closed",
              value: _openTabs,
              onChanged: (v) => setState(() => _openTabs = v),
            ),
            _optionRow(
              icon: Icons.cookie_outlined,
              title: "Cookies, cache and other site data",
              subtitle: null,
              value: _cookiesSiteData,
              onChanged: (v) => setState(() => _cookiesSiteData = v),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("More options", style: TextStyle(color: colors.onSurface, fontSize: 15)),
                    ),
                    Icon(
                      _showMoreOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                      color: colors.onSurface,
                    ),
                  ],
                ),
              ),
            ),
            if (_showMoreOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Passwords, autofill data and site settings are not affected.",
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              "Search history and other forms of activity may be saved in your Google Account",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: colors.primary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DeleteBrowsingDataResult(
                        range: _range,
                        clearHistory: _history,
                        clearOpenTabs: _openTabs,
                        clearCookiesAndSiteData: _cookiesSiteData,
                      ),
                    );
                  },
                  child: Text("Delete data", style: TextStyle(color: colors.onPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Builder(builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.onSurface, fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? colors.primary
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}