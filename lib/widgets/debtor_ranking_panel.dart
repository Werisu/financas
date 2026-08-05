import 'package:financas/models/debtor.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DebtorRankingPanel extends StatelessWidget {
  const DebtorRankingPanel({
    super.key,
    required this.debtors,
    required this.totalOwed,
    required this.onSeeAll,
  });

  final List<Debtor> debtors;
  final double totalOwed;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = debtors.take(5).toList();
    final maxAmount = top.isEmpty
        ? 0.0
        : top.map((d) => d.amountOwed).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Maiores devedores',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum valor a receber. Cadastre em Mais → Devedores.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          )
        else ...[
          Text(
            'Total a receber',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatCurrency(totalOwed),
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _DebtorRankRow(
              rank: i + 1,
              debtor: top[i],
              share: maxAmount <= 0 ? 0 : top[i].amountOwed / maxAmount,
              onTap: onSeeAll,
            ),
          ],
        ],
      ],
    );
  }
}

class _DebtorRankRow extends StatelessWidget {
  const _DebtorRankRow({
    required this.rank,
    required this.debtor,
    required this.share,
    required this.onTap,
  });

  final int rank;
  final Debtor debtor;
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    debtor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatCurrency(debtor.amountOwed),
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
                color: scheme.primary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
