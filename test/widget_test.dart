import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/data/db/app_database.dart';
import 'package:oil_checker/main.dart';
import 'package:oil_checker/presentation/providers.dart';

void main() {
  testWidgets('Oil Checker 앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const OilCheckerApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(OilCheckerApp), findsOneWidget);

    await db.close();
  });
}
