import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations.dart';
import 'package:ustaad_flutter/src/screens/gateway_screen.dart';
import 'package:ustaad_flutter/src/theme/ustaad_theme.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture Login and OTP Screens Goldens', (tester) async {
    final state = UstaadState(UstaadRepository());

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<UstaadState>.value(
        value: state,
        child: MaterialApp(
          theme: UstaadThemeData.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GatewayScreen(),
        ),
      ),
    );

    await tester.pump();

    // 1. Capture Login Screen Golden
    await expectLater(
      find.byType(GatewayScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );

    // 2. Switch to Phone OTP mode
    final phoneAuthBtn = find.text('Sign in with Phone (OTP)');
    expect(phoneAuthBtn, findsOneWidget);
    await tester.tap(phoneAuthBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Send verification code
    final sendOtpBtn = find.text('Send Verification Code (OTP)');
    expect(sendOtpBtn, findsOneWidget);
    await tester.tap(sendOtpBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Capture OTP Verification Screen Golden
    await expectLater(
      find.byType(GatewayScreen),
      matchesGoldenFile('goldens/otp_screen.png'),
    );
  });
}
