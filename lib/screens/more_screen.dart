import 'package:financas/screens/card_payments_screen.dart';
import 'package:financas/screens/cards_screen.dart';
import 'package:financas/screens/categories_screen.dart';
import 'package:financas/screens/debtors_screen.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _open(BuildContext context, {required String title, required Widget page}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _MoreTile(
          icon: Icons.category_outlined,
          color: scheme.primary,
          title: 'Categorias',
          subtitle: 'Organize os tipos de gasto',
          onTap: () => _open(
            context,
            title: 'Categorias',
            page: const CategoriesScreen(),
          ),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.credit_card_outlined,
          color: scheme.secondary,
          title: 'Cartões',
          subtitle: 'Bandeiras, fechamento e vencimento',
          onTap: () => _open(
            context,
            title: 'Cartões',
            page: const CardsScreen(),
          ),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.payments_outlined,
          color: scheme.primary,
          title: 'Pagamentos de fatura',
          subtitle: 'Total ou parcial dos cartões',
          onTap: () => _open(
            context,
            title: 'Pagamentos de fatura',
            page: const CardPaymentsScreen(),
          ),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.people_outline,
          color: scheme.tertiary,
          title: 'Devedores',
          subtitle: 'Quem te deve e quanto',
          onTap: () => _open(
            context,
            title: 'Devedores',
            page: const DebtorsScreen(),
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
