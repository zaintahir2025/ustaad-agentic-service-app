import 'package:flutter/material.dart';
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

    expect(find.bySemanticsLabel('USTAAD logo'), findsOneWidget);
    expect(find.text('LOGIN'), findsWidgets);
    expect(find.text('JOIN US'), findsOneWidget);
    expect(find.text('Enter Email Address'), findsOneWidget);
    expect(find.text('Keep me logged in'), findsOneWidget);
    expect(find.byTooltip('Switch theme'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);

    await tester.tap(find.text('JOIN US'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Full Name'), findsOneWidget);
    expect(find.text('Enter Phone Number'), findsOneWidget);
  });
}
