import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final _api = ApiClient();
  List<dynamic> _children = [];
  bool _isLoading = true;

  // childId -> limit (daqiqa, 0 = cheksiz)
  Map<String, int> _limits = {};
  // childId -> yoqilgan/o'chirilgan
  Map<String, bool> _enabled = {};

  static const _limitOptions = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final children = await _api.getMyChildren();
      final prefs = await SharedPreferences.getInstance();

      final limits = <String, int>{};
      final enabled = <String, bool>{};

      for (final child in children) {
        final id = child['id'] as String;
        limits[id] = prefs.getInt('st_limit_$id') ?? 60;
        enabled[id] = prefs.getBool('st_enabled_$id') ?? false;
      }

      if (!mounted) return;
      setState(() {
        _children = children;
        _limits = limits;
        _enabled = enabled;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setEnabled(String childId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('st_enabled_$childId', value);
    setState(() => _enabled[childId] = value);
  }

  Future<void> _setLimit(String childId, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('st_limit_$childId', minutes);
    setState(() => _limits[childId] = minutes);
  }

  String _formatLimit(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h soat' : '$h soat $m daq';
    }
    return '$minutes daqiqa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ekran vaqti nazorati'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    ..._children.map((child) => _buildChildCard(child)),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.child_care, size: 80, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Hali bola qo\'shilmagan',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kunlik vaqt limitini qo\'ying. Bola limitga yetganda '
              'eslatma ko\'rsatiladi.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    final id = child['id'] as String;
    final isOn = _enabled[id] ?? false;
    final limit = _limits[id] ?? 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sarlavha va toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    (child['full_name'] as String).isNotEmpty
                        ? (child['full_name'] as String)[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['full_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${child['age_group']} yosh',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isOn,
                  onChanged: (v) => _setEnabled(id, v),
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          // Limit sozlamalari
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                isOn ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Kunlik limit:',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatLimit(limit),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _limitOptions.map((mins) {
                          final selected = limit == mins;
                          return GestureDetector(
                            onTap: () => _setLimit(id, mins),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatLimit(mins),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      _UsageBar(
                        childId: id,
                        limitMinutes: limit,
                        api: _api,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatefulWidget {
  final String childId;
  final int limitMinutes;
  final ApiClient api;

  const _UsageBar({
    required this.childId,
    required this.limitMinutes,
    required this.api,
  });

  @override
  State<_UsageBar> createState() => _UsageBarState();
}

class _UsageBarState extends State<_UsageBar> {
  int _usedMinutes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  @override
  void didUpdateWidget(_UsageBar old) {
    super.didUpdateWidget(old);
    if (old.childId != widget.childId) _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      final stats = await widget.api.getChildStats(widget.childId);
      if (!mounted) return;
      setState(() {
        _usedMinutes = (stats['total_time_minutes'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final ratio = (_usedMinutes / widget.limitMinutes).clamp(0.0, 1.0);
    final overLimit = _usedMinutes >= widget.limitMinutes;
    final barColor = overLimit ? AppTheme.secondaryColor : AppTheme.successColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Bugungi foydalanish:",
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
            Text(
              '$_usedMinutes / ${widget.limitMinutes} daq',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: overLimit
                    ? AppTheme.secondaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        if (overLimit) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppTheme.secondaryColor),
              const SizedBox(width: 4),
              Text(
                'Kunlik limit tugadi!',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
