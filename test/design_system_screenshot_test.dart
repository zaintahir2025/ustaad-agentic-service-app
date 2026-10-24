import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ustaad_flutter/src/screens/design_system_gallery_screen.dart';
import 'package:ustaad_flutter/src/theme/ustaad_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Capture Design System Gallery Screen Golden', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: UstaadThemeData.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const DesignSystemGalleryScreen(),
      ),
    );

    // Pump once to lay out and render initial frame
    await tester.pump();

    // Golden test automatically renders and writes the PNG to disk
    await expectLater(
      find.byType(DesignSystemGalleryScreen),
      matchesGoldenFile('goldens/phase1_design_system.png'),
    );
  });
}
