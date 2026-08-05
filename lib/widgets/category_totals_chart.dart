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

    final sections = totals.map((item) {
      final percent = item.total / totalAmount;
      return PieChartSectionData(
        color: item.category.color,
        value: item.total,
        title: percent >= 0.08 ? '${(percent * 100).round()}%' : '',
        radius: 52,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }).toList();

    final legend = _Legend(
      totals: totals.take(6).toList(),
      totalAmount: totalAmount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;

        if (stacked) {
          return Column(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              legend,
            ],
          );
        }

        return SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: legend),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.totals, required this.totalAmount});

  final List<CategoryTotal> totals;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in totals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
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
                    style: textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${((item.total / totalAmount) * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
