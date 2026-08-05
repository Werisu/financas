import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/dashboard_screen.dart';
import 'package:financas/screens/expense_form_screen.dart';
import 'package:financas/screens/expenses_screen.dart';
import 'package:financas/screens/import_csv_screen.dart';
import 'package:financas/screens/income_form_screen.dart';
import 'package:financas/screens/incomes_screen.dart';
import 'package:financas/screens/more_screen.dart';
import 'package:financas/screens/profile_screen.dart';
import 'package:financas/utils/app_info.dart';
import 'package:financas/utils/profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titles = ['Visão geral', 'Gastos', 'Entradas', 'Mais'];

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Seus dados continuam salvos na nuvem. Você poderá entrar novamente depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _resetAccounts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar lançamentos?'),
        content: const Text(
          'Isso apaga permanentemente todos os gastos e pagamentos de fatura '
          '(no aparelho e na nuvem).\n\n'
          'Categorias, cartões, entradas, devedores e perfil serão mantidos.\n\n'
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar lançamentos'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Apagando lançamentos...')),
            ],
          ),
        ),
      ),
    );

    try {
      await ref.read(expensesProvider.notifier).resetAll();
      ref.read(cardPaymentsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamentos apagados.')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao resetar: $e')),
      );
    }
  }

  Widget? _buildFab() {
    if (_index == 0 || _index == 1) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo gasto'),
      );
    }
    if (_index == 2) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IncomeFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova entrada'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final pages = [
      const DashboardScreen(),
      const ExpensesScreen(),
      const IncomesScreen(),
      const MoreScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final label =
        (profile?.displayName ?? user?.displayName)?.trim().isNotEmpty == true
            ? (profile?.displayName ?? user!.displayName!)
            : (user?.email ?? 'Conta');
    final avatarImage = profileImageProvider(
      photoBase64: profile?.photoBase64,
      photoUrl: profile?.photoUrl ?? user?.photoURL,
    );

    final content = Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Importar CSV',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportCsvScreen()),
              );
            },
            icon: const Icon(Icons.upload_file_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Conta',
            onSelected: (value) {
              if (value == 'profile') _openProfile();
              if (value == 'reset') _resetAccounts();
              if (value == 'about') _showAbout(context);
              if (value == 'logout') _signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              label.isNotEmpty ? label[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline),
                  title: Text('Meu perfil'),
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined),
                  title: Text('Resetar lançamentos'),
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text('Sobre'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: pages[_index],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Visão',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Gastos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.trending_up_outlined),
                  selectedIcon: Icon(Icons.trending_up),
                  label: 'Entradas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'Mais',
                ),
              ],
            ),
    );

    if (!wide) return content;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text('Visão'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Gastos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: Text('Entradas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz),
                label: Text('Mais'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.account_balance_wallet_outlined,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const SizedBox(height: 8),
        Text(
          AppInfo.creditLine,
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'Organize os gastos do cartão por categoria e acompanhe para onde o dinheiro está indo.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
