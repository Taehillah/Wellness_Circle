import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellcheck/src/app.dart';
import 'package:wellcheck/src/shared/providers/shared_providers.dart';
import 'package:wellcheck/src/shared/services/preferences_service.dart';

void main() {
  testWidgets('renders login view when no session is persisted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          preferencesServiceProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const App(),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
  });
}
