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

  runApp(const UstaadBootstrapApp());
}

class UstaadBootstrapApp extends StatefulWidget {
  const UstaadBootstrapApp({super.key});

  @override
  State<UstaadBootstrapApp> createState() => _UstaadBootstrapAppState();
}

class _UstaadBootstrapAppState extends State<UstaadBootstrapApp> {
  late Future<void> _startup = _initialize();

  Future<void> _initialize() {
    return Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    ).timeout(const Duration(seconds: 12));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupShell(
            title: 'Ustaad',
            message: 'Preparing your service desk...',
            busy: true,
          );
        }

        if (snapshot.hasError) {
          return _StartupShell(
            title: 'Connection needed',
            message: 'Check your internet connection and try again.',
            onRetry: () => setState(() => _startup = _initialize()),
          );
        }

        return ChangeNotifierProvider(
          create: (_) => UstaadState(
            UstaadRepository(Supabase.instance.client),
          )..bootstrap(),
          child: const UstaadApp(),
        );
      },
    );
  }
}

class _StartupShell extends StatelessWidget {
  const _StartupShell({
    required this.title,
    required this.message,
    this.busy = false,
    this.onRetry,
  });

  final String title;
  final String message;
  final bool busy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ustaad',
      debugShowCheckedModeBanner: false,
      theme: UstaadTheme.light,
      darkTheme: UstaadTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/branding/ustaad_logo.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UstaadApp extends StatelessWidget {
  const UstaadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UstaadState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Ustaad',
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
