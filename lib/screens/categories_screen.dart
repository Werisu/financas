import 'package:financas/models/category.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static const _colorOptions = [
    Color(0xFF2A9D8F),
    Color(0xFFE76F51),
    Color(0xFF457B9D),
    Color(0xFF6D597A),
    Color(0xFFF4A261),
    Color(0xFF264653),
    Color(0xFFE9C46A),
    Color(0xFF1D3557),
    Color(0xFF8D99AE),
    Color(0xFFBC6C25),
  ];

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    var iconKey = category?.iconKey ?? 'shopping_cart';
    var colorValue = category?.colorValue ?? _colorOptions.first.toARGB32();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                category == null ? 'Nova categoria' : 'Editar categoria',
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ícone',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoryIcons.byName.entries.map((entry) {
                        final selected = entry.key == iconKey;
                        return ChoiceChip(
                          selected: selected,
                          label: Icon(entry.value, size: 18),
                          onSelected: (_) =>
                              setLocal(() => iconKey = entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cor',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        final selected = color.toARGB32() == colorValue;
                        return GestureDetector(
                          onTap: () =>
                              setLocal(() => colorValue = color.toARGB32()),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await ref.read(categoriesProvider.notifier).save(
            Category(
              id: category?.id ?? const Uuid().v4(),
              name: nameController.text.trim(),
              iconKey: iconKey,
              colorValue: colorValue,
            ),
          );
    }
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Categoria'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.15),
                foregroundColor: category.color,
                child: Icon(category.icon),
              ),
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        _openEditor(context, ref, category: category),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  if (!category.id.startsWith('cat_'))
                    IconButton(
                      onPressed: () async {
                        await ref
                            .read(categoriesProvider.notifier)
                            .delete(category.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
