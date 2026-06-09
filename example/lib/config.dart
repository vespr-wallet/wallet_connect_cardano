/// Build-time configuration via `--dart-define`.
class AppConfig {
  AppConfig._();

  static const String reownProjectId = String.fromEnvironment(
    'REOWN_PROJECT_ID',
    defaultValue: '',
  );

  /// Demo wallet mnemonic — override for local testing only.
  ///
  /// Default uses the chief-fiber test vector from cardano_flutter_sdk tests.
  /// Fund the derived preprod address via the faucet before signTx demos.
  static const String demoMnemonic = String.fromEnvironment(
    'DEMO_MNEMONIC',
    defaultValue:
        'chief fiber betray curve tissue output feature jungle adapt smile brown '
        'crane accuse gospel plate unlock pull arrow hard february tape soccer '
        'patrol fetch',
  );

  static bool get hasReownProjectId =>
      reownProjectId.isNotEmpty && reownProjectId != 'your_project_id_here';
}
