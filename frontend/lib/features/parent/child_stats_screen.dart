import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

/// Bola statistikasi grafiklar bilan.
class ChildStatsScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  const ChildStatsScreen({super.key, required this.child});

  @override
  State<ChildStatsScreen> createState() => _ChildStatsScreenState();
}

class _ChildStatsScreenState extends State<ChildStatsScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _api.getChildStats(widget.child['id']);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(widget.child['full_name'] ?? 'Bola')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Ma\'lumotlarni yuklab bo\'lmadi'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildCategoryChart(),
                        const SizedBox(height: 24),
                        _buildWeeklyChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final stars = widget.child['total_stars'] ?? 0;
    final completed = _stats!['total_lessons_completed'] ?? 0;
    final timeMin = _stats!['total_time_minutes'] ?? 0;
    final avgScore = _stats!['average_score'] ?? 0;
    final streak = _stats!['streak_days'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          icon: Icons.star,
          color: Colors.amber,
          label: 'Yulduzlar',
          value: '$stars',
        ),
        _StatCard(
          icon: Icons.check_circle,
          color: AppTheme.successColor,
          label: 'Tugatilgan',
          value: '$completed',
        ),
        _StatCard(
          icon: Icons.access_time,
          color: AppTheme.primaryColor,
          label: 'Vaqt (min)',
          value: '$timeMin',
        ),
        _StatCard(
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
          label: 'Ketma-ket kun',
          value: '$streak',
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    final byCategory = (_stats!['by_category'] as Map?) ?? {};
    if (byCategory.isEmpty) {
      return _buildEmptyChart('Kategoriya bo\'yicha', 'Hali natijalar yo\'q');
    }

    final categoryNames = {
      'letters': 'Harflar',
      'numbers': 'Sonlar',
      'colors': 'Ranglar',
      'shapes': 'Shakllar',
      'memory': 'Xotira',
      'puzzle': 'Jumboq',
    };

    final entries = byCategory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kategoriya bo'yicha o'rtacha ball",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox();
                        final name = categoryNames[entries[i].key] ?? entries[i].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final data = e.value.value as Map;
                  final avg = (data['avg_score'] as num).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: avg,
                        color: AppTheme.primaryColor,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final weekly = (_stats!['weekly_activity'] as List?) ?? [];
    if (weekly.isEmpty) {
      return _buildEmptyChart('Haftalik faollik', 'Hali faollik qayd etilmagan');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Oxirgi 7 kun faolligi (darslar soni)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= weekly.length) return const SizedBox();
                        final date = weekly[i]['date'] as String?;
                        if (date == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            date.substring(5),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppTheme.successColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.successColor.withOpacity(0.2),
                    ),
                    spots: weekly.asMap().entries.map((e) {
                      final lessons = (e.value['lessons'] as num).toDouble();
                      return FlSpot(e.key.toDouble(), lessons);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Icon(Icons.bar_chart,
                    size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 8),
                Text(message,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
