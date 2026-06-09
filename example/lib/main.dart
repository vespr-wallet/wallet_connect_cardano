import 'package:flutter/material.dart';

import 'config.dart';
import 'delegate/demo_wallet_delegate.dart';
import 'ui/home_screen.dart';
import 'wallet/demo_wallet.dart';
import 'wallet/wallet_connect_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleWalletApp());
}

class ExampleWalletApp extends StatelessWidget {
  const ExampleWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WC Cardano Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0033AD)),
        useMaterial3: true,
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  WalletConnectService? _service;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!AppConfig.hasReownProjectId) {
      setState(() {
        _error =
            'Set REOWN_PROJECT_ID via --dart-define when running the app.';
      });
      return;
    }

    try {
      final demoWallet = await DemoWallet.create();
      final delegate = DemoWalletDelegate(demoWallet: demoWallet);
      final service = WalletConnectService(
        projectId: AppConfig.reownProjectId,
        delegate: delegate,
      );
      await service.initialize();
      setState(() => _service = service);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_service == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return HomeScreen(service: _service!);
  }
}
