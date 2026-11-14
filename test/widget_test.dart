import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:securiot_mobile/core/i18n/app_localizations.dart';
import 'package:securiot_mobile/providers/auth_provider.dart';
import 'package:securiot_mobile/providers/locale_provider.dart';
import 'package:securiot_mobile/screens/auth/login_screen.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en', 'US')}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  testWidgets('LoginScreen shows validation errors on empty submit', (tester) async {
    // Tall surface so the Sign in button is on screen regardless of the host's font metrics.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    // The form now sits in a card, so the button can start below the fold.
    await tester.ensureVisible(find.text('Sign in').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in').last);
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('LoginScreen renders every visible string in es_419', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen(), locale: const Locale('es', 'PE')));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  testWidgets('LoginScreen shows a visible email label, never placeholder-only', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
