import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:erten/app_state.dart';
import 'package:erten/main.dart';

void main() {
  testWidgets('renders splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ErtenApp(),
      ),
    );

    expect(find.text('erten'), findsOneWidget);
    expect(find.textContaining('Personal time design'), findsOneWidget);
  });
}
