import 'package:financas/providers/finance_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryTotalsChart extends StatelessWidget {
  const CategoryTotalsChart({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final totalAmount = totals.fold<double>(0, (sum, item) => sum + item.total);
    if (totalAmount <= 0) {
      return const SizedBox(height: 180, child: Center(child: Text('Sem dados')));
    }

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: totals.map((item) {
                  final percent = item.total / totalAmount;
                  return PieChartSectionData(
                    color: item.category.color,
                    value: item.total,
                    title: percent >= 0.08
                        ? '${(percent * 100).round()}%'
                        : '',
                    radius: 52,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView(
              children: totals.take(6).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
