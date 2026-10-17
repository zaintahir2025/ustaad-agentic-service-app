import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations_en.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations_ur.dart';
import 'package:ustaad_flutter/src/models.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('supportedLocales contains en, ur, and en_PK', () {
      final supported = AppLocalizations.supportedLocales;
      expect(supported, contains(const Locale('en')));
      expect(supported, contains(const Locale('ur')));
      expect(supported, contains(const Locale('en', 'PK')));
    });

    test('English localization strings load accurately', () {
      final en = AppLocalizationsEn();
      expect(en.appTitle, 'Ustaad');
      expect(en.signIn, 'Sign in');
      expect(en.createAccount, 'Create account');
      expect(en.findProviders, 'Find providers');
      expect(en.quickBook, 'Quick book');
    });

    test('Urdu localization strings load with authentic Nastaliq text', () {
      final ur = AppLocalizationsUr();
      expect(ur.appTitle, 'استاد');
      expect(ur.signIn, 'سائن ان کریں');
      expect(ur.createAccount, 'نیا اکاؤنٹ بنائیں');
      expect(ur.findProviders, 'ماہرین تلاش کریں');
      expect(ur.price, 'قیمت');
      expect(ur.rating, 'درجہ بندی');
    });

    test('Roman Urdu localization strings load Pakistani localized text', () {
      final roman = AppLocalizationsEnPk();
      expect(roman.appTitle, 'Ustaad');
      expect(roman.signIn, 'Sign In Karein');
      expect(roman.createAccount, 'Naya Account Banayein');
      expect(roman.findProviders, 'Expert Talash Karein');
      expect(roman.quickBook, 'Jaldi Book Karein');
    });
  });

  group('UstaadState Localization & RTL Tests', () {
    test('currentLocale and isRtl respond dynamically to selectedLanguage', () {
      final state = UstaadState(UstaadRepository());

      state.selectedLanguage = 'English';
      expect(state.currentLocale, const Locale('en'));
      expect(state.isRtl, isFalse);

      state.selectedLanguage = 'Urdu';
      expect(state.currentLocale, const Locale('ur'));
      expect(state.isRtl, isTrue);

      state.selectedLanguage = 'Roman Urdu';
      expect(state.currentLocale, const Locale('en', 'PK'));
      expect(state.isRtl, isFalse);
    });

    test('User preferredLanguage takes precedence over default selectedLanguage', () {
      final state = UstaadState(UstaadRepository());
      state.selectedLanguage = 'English';

      state.user = const UstaadUser(
        id: 'u-1',
        name: 'Ahmed',
        email: 'ahmed@example.com',
        city: 'Islamabad',
        address: 'F-7',
        preferredLanguage: 'Urdu',
        bio: '',
        avatarUrl: '',
      );

      expect(state.currentLocale, const Locale('ur'));
      expect(state.isRtl, isTrue);
    });
  });
}
