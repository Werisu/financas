import 'package:financas/app.dart';
import 'package:financas/data/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await AppDatabase.init();
  runApp(const FinancasApp());
}
