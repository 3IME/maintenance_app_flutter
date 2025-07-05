// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/main.dart'; // Assurez-vous que l'import est correct

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // --- CORRECTION ICI ---
    await tester.pumpWidget(const MaintenanceApp());
    // --- FIN DE LA CORRECTION ---

    // Le reste du test va échouer car il cherche un '0' et un '1' qui n'existent plus
    // sur l'écran du dashboard. Vous pouvez le modifier ou le commenter.
    // Pour l'instant, nous allons le commenter pour que le test passe sans erreur.

    // Verify that our counter starts at 0.
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);

    // Un test plus pertinent pour notre application serait de vérifier la présence du titre du dashboard.
    expect(find.text('Dashboard de Maintenance'), findsOneWidget);
  });
}
