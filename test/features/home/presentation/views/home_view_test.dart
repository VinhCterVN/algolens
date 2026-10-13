import 'package:algolens/features/home/presentation/views/home_view.dart';
import 'package:algolens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App opens the home view with branding', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('AlgoLens'), findsOneWidget);
    expect(find.text('See the Logic Behind Every Algorithm'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home supports a small viewport and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const HomeView(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text('See the Logic Behind Every Algorithm'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
