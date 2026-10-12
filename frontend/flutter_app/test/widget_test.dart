import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/app.dart';

void main() {
  testWidgets('App boots and renders splash brand name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MindoraApp()));
    await tester.pump(); // first frame
    expect(find.text('MINDORA'), findsWidgets);
  });
}
