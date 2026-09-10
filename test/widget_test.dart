// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeevandhara/main.dart';
import 'package:jeevandhara/localization/app_localizations.dart';
import 'package:jeevandhara/screens/auth_screen.dart';
import 'package:jeevandhara/widgets/main_navigation.dart';

void main() {
  testWidgets('app renders a startup state', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(firebaseError: StateError('test')));
    await tester.pumpAndSettle();

    expect(find.text('Jeevandhara could not start'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('authenticated shell exposes one five-tab navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const MainNavigation(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('main-navigation')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Advice'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-market-section')), findsOneWidget);
  });

  testWidgets('password visibility control exposes its current action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('login loading state exits when authentication throws', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'farmer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('navigation shell remains usable at narrow large text size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: MaterialApp(
          home: const MainNavigation(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('main-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
