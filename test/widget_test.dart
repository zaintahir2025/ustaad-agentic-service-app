import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations.dart';
import 'package:ustaad_flutter/src/screens/command_center_screen.dart';
import 'package:ustaad_flutter/src/screens/gateway_screen.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'GatewayScreen renders localized text and responds to language changes',
      (tester) async {
    final state = UstaadState(UstaadRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<UstaadState>.value(
        value: state,
        child: Consumer<UstaadState>(
          builder: (context, state, _) {
            return MaterialApp(
              locale: state.currentLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const GatewayScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial English localization
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Enter Email Address'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);

    // Switch to Urdu
    await state.setLanguage('Urdu');
    await tester.pumpAndSettle();

    // Verify Urdu Nastaliq text
    expect(find.text('سائن ان کریں'), findsWidgets);
    expect(find.text('پاس ورڈ بھول گئے؟'), findsOneWidget);
    expect(find.text('ای میل ایڈریس درج کریں'), findsOneWidget);
    expect(find.text('پاس ورڈ درج کریں'), findsOneWidget);

    // Verify Directionality is RTL when Urdu is selected
    final directionality = tester.widget<Directionality>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);

    // Switch to Roman Urdu
    await state.setLanguage('Roman Urdu');
    await tester.pumpAndSettle();

    expect(find.text('Sign In Karein'), findsWidgets);
    expect(find.text('Password Bhool Gaye?'), findsOneWidget);
  });

  testWidgets(
      'CommandCenterScreen renders adaptively across mobile and desktop viewport sizes',
      (tester) async {
    final state = UstaadState(UstaadRepository());

    // Mobile Viewport (iPhone / Pixel form factor)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<UstaadState>.value(
        value: state,
        child: MaterialApp(
          locale: state.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CommandCenterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find providers'), findsOneWidget);
    expect(find.text('Quick book'), findsOneWidget);

    // Desktop Viewport (Web Browser / Large display)
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();

    expect(find.text('Provider directory'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
  });

  testWidgets('Accessibility: interactive elements have valid tooltips and semantic labels',
      (tester) async {
    final state = UstaadState(UstaadRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<UstaadState>.value(
        value: state,
        child: MaterialApp(
          locale: state.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GatewayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify tooltip on Theme and Language buttons
    expect(find.byTooltip('Switch theme'), findsOneWidget);
    expect(find.byTooltip('Change language'), findsOneWidget);
  });
}
