/// MaintenanceGate — wraps the app and blocks it if backend is in maintenance.
///
/// Architecture:
///   ProviderScope
///     └─ MaintenanceGate(child: MindoraApp())
///           ├─ loading  → splash dark
///           ├─ enabled  → MaintenanceScreen
///           └─ disabled → child (MindoraApp, router intact)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'maintenance_screen.dart';
import 'maintenance_service.dart';

class MaintenanceGate extends ConsumerWidget {
  const MaintenanceGate({super.key, required this.child});

  /// The wrapped app widget (usually `MindoraApp`).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenance = ref.watch(maintenanceCheckProvider);

    return maintenance.when(
      loading: () => _buildSplash(),
      // Fail-open : si le check échoue, on laisse passer
      error: (_, __) => child,
      data: (status) {
        if (!status.enabled) return child;
        return MaterialApp(
          title: 'MINDORA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          home: MaintenanceScreen(
            message: status.message,
            eta: status.eta,
          ),
        );
      },
    );
  }

  Widget _buildSplash() {
    return MaterialApp(
      title: 'MINDORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6E8DFF)),
              SizedBox(height: 20),
              Text(
                'MINDORA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
