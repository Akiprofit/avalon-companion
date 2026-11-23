import 'package:avalon_companion/core/theme/app_theme.dart';
import 'package:avalon_companion/core/widgets/danger_button.dart';
import 'package:avalon_companion/core/widgets/primary_button.dart';
import 'package:avalon_companion/core/widgets/secondary_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The buttons are drawn by one shared `ButtonFrame`. These tests pin the
/// geometry and the behaviour the rest of the app relies on, so a change to the
/// face cannot quietly move the target or swallow a tap.

Future<void> pumpInColumn(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// A row offers its children unbounded width — the case where a button that
/// asks for `double.infinity`, or a face that sizes itself from its bounds,
/// blows up or swallows the line.
Future<void> pumpInRow(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: Row(children: [child])),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the gold action fills the row at the shared height', (
    tester,
  ) async {
    await pumpInColumn(
      tester,
      PrimaryButton(label: 'Confirm the team', onPressed: () {}),
    );

    expect(tester.getSize(find.byType(PrimaryButton)), const Size(320, 56));
    expect(
      tester.getSize(find.byKey(const Key('primary_button_ink'))),
      const Size(320, 56),
      reason: 'the tap target is the whole face, not just the label',
    );
    expect(find.text('Confirm the team'), findsOneWidget);
  });

  testWidgets('a compact action sizes itself when width is unbounded', (
    tester,
  ) async {
    await pumpInRow(
      tester,
      PrimaryButton(label: 'Continue', expand: false, onPressed: () {}),
    );

    final size = tester.getSize(find.byType(PrimaryButton));
    expect(size.height, 56);
    expect(size.width, greaterThan(0));
    expect(
      size.width,
      lessThan(320),
      reason: 'a compact action must not claim the whole line',
    );
  });

  testWidgets('a tap on the face fires, and a disabled face refuses it', (
    tester,
  ) async {
    var taps = 0;
    await pumpInColumn(
      tester,
      PrimaryButton(label: 'Begin the night', onPressed: () => taps++),
    );
    await tester.tap(find.byKey(const Key('primary_button_ink')));
    await tester.pump();
    expect(taps, 1);

    await pumpInColumn(
      tester,
      const PrimaryButton(label: 'Begin', onPressed: null),
    );
    await tester.tap(find.byKey(const Key('primary_button_ink')));
    await tester.pump();
    expect(taps, 1, reason: 'a disabled action must not fire');
    expect(find.text('Begin'), findsOneWidget);
    expect(
      tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const Key('primary_button_ink')),
              matching: find.byType(Opacity),
            ),
          )
          .map((widget) => widget.opacity),
      contains(0.45),
      reason: 'a disabled face is dimmed, not hidden',
    );
  });

  testWidgets('a loading action shows a spinner and refuses the tap', (
    tester,
  ) async {
    var taps = 0;
    await pumpInColumn(
      tester,
      PrimaryButton(
        label: 'Saving',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('primary_button_ink')));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('the face sits in the artwork instead of floating over it', (
    tester,
  ) async {
    await pumpInColumn(
      tester,
      PrimaryButton(label: 'Confirm the team', onPressed: () {}),
    );

    final face = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(PrimaryButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = face.decoration as BoxDecoration;
    expect(
      decoration.boxShadow ?? const <BoxShadow>[],
      isEmpty,
      reason: 'no halo: against the plates it cannot be seen and does no work',
    );
    expect(
      decoration.gradient,
      isNotNull,
      reason: 'the face is still lit rather than a flat block',
    );
  });

  testWidgets('the outline and destructive actions share the same face', (
    tester,
  ) async {
    var taps = 0;
    await pumpInColumn(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(label: 'Back', onPressed: () => taps++),
          const SizedBox(height: 8),
          DangerButton(label: 'Abort', onPressed: () => taps++),
        ],
      ),
    );

    expect(tester.getSize(find.byType(SecondaryButton)).height, 56);
    expect(tester.getSize(find.byType(DangerButton)).height, 56);
    expect(
      tester.getSize(find.byKey(const Key('secondary_button_ink'))).height,
      56,
    );
    await tester.tap(find.byKey(const Key('secondary_button_ink')));
    await tester.pump();
    await tester.tap(find.byType(DangerButton));
    await tester.pump();
    expect(taps, 2);
  });
}
