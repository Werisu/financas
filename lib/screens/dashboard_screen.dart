import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/app_info.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/category_totals_chart.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final total = ref.watch(monthlyTotalAmountProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const MonthSelector(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.secondary,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total em ${capitalize(monthYearFormat.format(month))}',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(total),
                style: GoogleFonts.fraunces(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totals.isEmpty
                    ? 'Nenhum gasto neste mês ainda'
                    : '${totals.length} categorias com movimentação',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Onde estou gastando',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (totals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.insights_outlined,
                      size: 40, color: scheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'Adicione gastos manualmente ou importe a fatura CSV para ver a distribuição por categoria.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryTotalsChart(totals: totals),
            ),
          ),
          const SizedBox(height: 16),
          ...totals.map((item) {
            final percent = total == 0 ? 0.0 : item.total / total;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.category.color.withValues(alpha: 0.15),
                  foregroundColor: item.category.color,
                  child: Icon(item.category.icon, size: 20),
                ),
                title: Text(item.category.name),
                subtitle: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: item.category.color,
                  backgroundColor: item.category.color.withValues(alpha: 0.12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('${(percent * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 28),
        Text(
          AppInfo.creditLine,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
