import 'package:able/able.dart';
import 'package:country_listing/app.dart';
import 'package:country_listing/data/repository/in_memory_country_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Able.initialize);

  Future<void> pumpApp(WidgetTester tester, {int failuresBeforeSuccess = 0}) async {
    await tester.pumpWidget(
      CountryListingApp(
        countryRepository: InMemoryCountryRepository(
          latency: const Duration(milliseconds: 100),
          failuresBeforeSuccess: failuresBeforeSuccess,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists countries and filters them by search', (tester) async {
    await pumpApp(tester);

    expect(find.text('Argentina'), findsOneWidget);
    expect(find.textContaining('Showing 33 of 33'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'accra');
    await tester.pumpAndSettle();

    expect(find.text('Ghana'), findsOneWidget);
    expect(find.text('Argentina'), findsNothing);
  });

  testWidgets('shows the error with a Retry that recovers', (tester) async {
    await pumpApp(tester, failuresBeforeSuccess: 1);

    expect(find.textContaining('Could not reach'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Argentina'), findsOneWidget);
    expect(find.text('Countries refreshed'), findsOneWidget);
  });

  testWidgets('reloading keeps the list on screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Reload'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Argentina'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Countries refreshed'), findsOneWidget);
  });

  testWidgets('the detail favorite button toggles', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Argentina'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from favorites'), findsOneWidget);
  });

  testWidgets('favoriting a country updates the summary', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add Argentina to favorites'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove Argentina from favorites'), findsOneWidget);
    expect(find.textContaining('1/5 favorites'), findsOneWidget);
  });

  testWidgets('opens the detail screen with neighbours', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Argentina'));
    await tester.pumpAndSettle();

    expect(find.text('Buenos Aires'), findsOneWidget);
    expect(find.text('More in Americas'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Brazil'), findsOneWidget);
  });
}
