import 'package:financas/models/category.dart';

class CategorySuggestionService {
  static const Map<String, List<String>> _keywords = {
    'cat_supermercado': [
      'supermercado',
      'mercado',
      'atacadao',
      'atacadão',
      'carrefour',
      'extra',
      'pao de acucar',
      'pão de açúcar',
      'assai',
      'assaí',
      'bodega',
      'hortifruti',
      'ifood mercado',
    ],
    'cat_saude': [
      'drogasil',
      'droga raia',
      'drogaria',
      'farmacia',
      'farmácia',
      'hospital',
      'clinica',
      'clínica',
      'laboratorio',
      'laboratório',
      'unimed',
      'amil',
      'sulamerica',
      'odont',
    ],
    'cat_transportes': [
      'uber',
      '99app',
      '99 pop',
      'cabify',
      'posto',
      'shell',
      'ipiranga',
      'petrobras',
      'combustivel',
      'combustível',
      'estacionamento',
      'sem parar',
      'conectcar',
      'metro',
      'metrô',
      'onibus',
      'ônibus',
      'passagem',
      'gol linhas',
      'latam',
      'azul linhas',
    ],
    'cat_moradia': [
      'aluguel',
      'condominio',
      'condomínio',
      'enel',
      'light',
      'cemig',
      'copel',
      'sabesp',
      'sanepar',
      'vivo fixo',
      'claro residencial',
      'net ',
      'internet',
      'seguro residencial',
    ],
    'cat_lazer': [
      'cinema',
      'ingresso',
      'steam',
      'playstation',
      'xbox',
      'nintendo',
      'spotify',
      'show',
      'parque',
      'viagem',
      'booking',
      'airbnb',
      'hotel',
    ],
    'cat_educacao': [
      'escola',
      'faculdade',
      'universidade',
      'curso',
      'udemy',
      'alura',
      'coursera',
      'livro',
      'livraria',
      'mensalidade',
    ],
    'cat_restaurantes': [
      'restaurante',
      'ifood',
      'rappi',
      'uber eats',
      'mcdonald',
      'burger',
      'starbucks',
      'padaria',
      'lanchonete',
      'pizza',
      'bar ',
      'cafe ',
      'café',
    ],
    'cat_assinaturas': [
      'netflix',
      'spotify',
      'disney',
      'prime video',
      'amazon prime',
      'youtube premium',
      'apple.com/bill',
      'google one',
      'icloud',
      'adobe',
      'microsoft',
      'openai',
      'chatgpt',
      'cursor',
    ],
  };

  String suggestCategoryId(String description, List<Category> categories) {
    final normalized = _normalize(description);
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(_normalize(keyword))) {
          final exists = categories.any((c) => c.id == entry.key);
          if (exists) return entry.key;
        }
      }
    }
    final outros = categories.where((c) => c.id == 'cat_outros');
    if (outros.isNotEmpty) return outros.first.id;
    return categories.isNotEmpty ? categories.first.id : 'cat_outros';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll('ç', 'c');
  }
}
