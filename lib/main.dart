import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app_theme.dart';
import 'src/ustaad_state.dart';
import 'src/ustaad_repository.dart';
import 'src/ustaad_ui.dart';

const String supabaseUrl = 'https://dcsioxiiyazchampqulz.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_d4p1s2x8fkzBdkYi9a6dsA_vYdWF30G';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => UstaadState(
        UstaadRepository(Supabase.instance.client),
      )..bootstrap(),
      child: const UstaadApp(),
    ),
  );
}

class UstaadApp extends StatelessWidget {
  const UstaadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UstaadState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Ustaad Orchestrator',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: UstaadTheme.light,
          darkTheme: UstaadTheme.dark,
          home: const UstaadRouter(),
        );
      },
    );
  }
}
