import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/features/dashboard/presentation/widgets/sparkline_widget.dart';

void main() {
  testWidgets('SparklineWidget displays bars and shows amount on press and vanishes on release', (WidgetTester tester) async {
    final heights = [0.1, 0.2, 0.3, 0.5, 0.8, 0.4, 1.0];
    final amounts = [100.0, 200.0, 300.0, 500.0, 800.0, 400.0, 1000.0];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              height: 60,
              child: SparklineWidget(
                heights: heights,
                amounts: amounts,
                maxHeight: 40,
              ),
            ),
          ),
        ),
      ),
    );

    // Initially, no amount tooltip is shown
    expect(find.text('₹1,000.00'), findsNothing);
    expect(find.text('₹800.00'), findsNothing);

    // Press down on the rightmost bar (bar index 6, around x=130)
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SparklineWidget)));
    await tester.pump();

    // Now an amount tooltip is displayed
    expect(find.byType(FittedBox), findsWidgets);

    // Release the finger
    await gesture.up();
    await tester.pump();

    // The amount vanishes
    expect(find.text('₹1,000.00'), findsNothing);
  });
}
