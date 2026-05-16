import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ustaad_flutter/main.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'sb_publishable_test_key',
    );
  });

  testWidgets('gateway shows auth actions and theme control', (tester) async {
    final state = UstaadState(UstaadRepository(Supabase.instance.client))
      ..bootstrapped = true;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const UstaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('USTAAD'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);
    expect(find.text('Remember email'), findsOneWidget);
  });
}
