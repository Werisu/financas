import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/debtors_screen.dart';
import 'package:financas/utils/app_info.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/category_totals_chart.dart';
import 'package:financas/widgets/debtor_ranking_panel.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openDebtors(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Devedores')),
          body: const DebtorsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final invoiceView = ref.watch(invoiceViewProvider);
    final total = ref.watch(monthlyTotalAmountProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final cards = ref.watch(cardsProvider);
    final cardFilter = ref.watch(expenseFilterCardProvider);
    final newTotal = ref.watch(statementNewPurchasesTotalProvider);
    final carryTotal = ref.watch(statementCarryoversTotalProvider);
    final incomeTotal = ref.watch(monthlyIncomeTotalProvider);
    final debtors = ref.watch(debtorRankingProvider);
    final debtorTotal = ref.watch(debtorTotalOwedProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Por fatura'),
              icon: Icon(Icons.credit_card, size: 18),
            ),
            ButtonSegment(
              value: false,
              label: Text('Por compra'),
              icon: Icon(Icons.shopping_bag_outlined, size: 18),
            ),
          ],
          selected: {invoiceView},
          onSelectionChanged: (value) {
            ref.read(invoiceViewProvider.notifier).state = value.first;
          },
        ),
        const SizedBox(height: 12),
        const MonthSelector(),
        if (invoiceView) ...[
          const SizedBox(height: 8),
          Text(
            'Mês = vencimento da fatura (ex.: vence 05/08 → agosto)',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: cardFilter,
            decoration: const InputDecoration(
              labelText: 'Cartão da fatura',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...cards.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(expenseFilterCardProvider.notifier).state = value;
            },
          ),
        ],
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
                invoiceView
                    ? 'Total da fatura · ${capitalize(monthYearFormat.format(month))}'
                    : 'Total em ${capitalize(monthYearFormat.format(month))}',
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
                    ? (invoiceView
                        ? 'Nenhum lançamento nesta fatura'
                        : 'Nenhum gasto neste mês ainda')
                    : '${totals.length} categorias com movimentação',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (invoiceView && total > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BreakdownCard(
                  title: 'Compras novas',
                  subtitle: 'À vista ou 1ª parcela',
                  value: newTotal,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BreakdownCard(
                  title: 'Parcelas antigas',
                  subtitle: '2/5, 3/5, 5/5…',
                  value: carryTotal,
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.secondary.withValues(alpha: 0.15),
              foregroundColor: scheme.secondary,
              child: const Icon(Icons.trending_up),
            ),
            title: Text(
              'Receitas do mês',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Entradas em ${capitalize(monthYearFormat.format(month))}',
            ),
            trailing: Text(
              formatCurrency(incomeTotal),
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        DebtorRankingPanel(
          debtors: debtors,
          totalOwed: debtorTotal,
          onSeeAll: () => _openDebtors(context),
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
                  Text(
                    invoiceView
                        ? 'Importe a fatura CSV escolhendo o cartão e o mês de vencimento para ver o total real.'
                        : 'Adicione gastos manualmente ou importe a fatura CSV.',
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

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  final String title;
  final String subtitle;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Text(
              formatCurrency(value),
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
