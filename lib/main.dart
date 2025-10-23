import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'features/negocios/pages/map_negocios_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Censo de Negocios',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MapNegociosPage(),
    );
  }
}
