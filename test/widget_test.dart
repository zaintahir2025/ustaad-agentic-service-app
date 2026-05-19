import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ustaad_flutter/main.dart';
import 'package:ustaad_flutter/src/models.dart';
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
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Enter Email Address'), findsOneWidget);
    expect(find.text('Keep me logged in'), findsOneWidget);
    expect(find.byTooltip('Switch theme'), findsOneWidget);
    expect(state.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pumpAndSettle();

    expect(state.themeMode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Full Name'), findsOneWidget);
    expect(find.text('Enter Phone Number'), findsOneWidget);
  });

  testWidgets('gateway fits a phone viewport without clipping', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = UstaadState(UstaadRepository(Supabase.instance.client))
      ..bootstrapped = true;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const UstaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    final loginButtonRect =
        tester.getRect(find.widgetWithText(FilledButton, 'Sign in'));
    final resetLinkRect = tester.getRect(find.text('Forgot Password?'));

    expect(loginButtonRect.left, greaterThanOrEqualTo(0));
    expect(loginButtonRect.right, lessThanOrEqualTo(390));
    expect(resetLinkRect.right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in home scales across app surfaces', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = UstaadState(UstaadRepository(Supabase.instance.client))
      ..bootstrapped = true
      ..backendOnline = true
      ..screen = UstaadScreen.commandCenter
      ..user = const UstaadUser(
        id: 'test-user',
        name: 'Test Customer',
        email: 'customer@example.com',
      );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const UstaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi Test'), findsOneWidget);
    expect(find.text('Quick book'), findsOneWidget);
    expect(find.text('Provider directory'), findsOneWidget);
    expect(find.text('Find providers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider matching and booking filters render cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = UstaadState(UstaadRepository(Supabase.instance.client))
      ..bootstrapped = true
      ..screen = UstaadScreen.commandCenter
      ..user = const UstaadUser(
        id: 'test-user',
        name: 'Test Customer',
        email: 'customer@example.com',
      );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const UstaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Request'),
      'Urgent pani leak in kitchen',
    );
    await tester.tap(find.text('Find providers'));
    await tester.pumpAndSettle();

    expect(find.text('Matches'), findsOneWidget);
    expect(find.textContaining('Plumber'), findsWidgets);

    state.openBookings();
    await tester.pumpAndSettle();

    expect(find.text('Bookings'), findsWidgets);
    expect(find.text('No bookings yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Urdu requests infer the correct service intent', () {
    final state = UstaadState(UstaadRepository(Supabase.instance.client));

    state.startAnalysis('بجلی کا مسئلہ ہے', 'G-13, Islamabad');
    expect(state.intent?.role, 'Electrician');
    expect(state.intent?.language, 'Urdu');

    state.startAnalysis('کچن میں پانی لیک ہو رہا ہے', 'G-13, Islamabad');
    expect(state.intent?.role, 'Plumber');
    expect(state.intent?.language, 'Urdu');

    state.startAnalysis('کل صبح اے سی ٹھنڈا نہیں ہو رہا', 'G-13, Islamabad');
    expect(state.intent?.role, 'AC Repair');
    expect(state.intent?.timeLabel, 'Tomorrow morning');
    expect(state.intent?.language, 'Urdu');
  });
}
