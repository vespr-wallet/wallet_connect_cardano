import 'dart:io';

/// Locates `wallet_connect_cardano/` by walking up from [Directory.current].
///
/// [Platform.script] is unreliable when tool scripts run inside a sandboxed
/// Flutter macOS app (it points into the app container), so we use cwd instead.
String repoRootPath() {
  const overrideRoot = String.fromEnvironment('REPO_ROOT');
  if (overrideRoot.isNotEmpty) {
    return overrideRoot;
  }

  var dir = Directory.current;
  while (true) {
    final rootPubspec = File('${dir.path}/pubspec.yaml');
    final examplePubspec = File('${dir.path}/example/pubspec.yaml');
    if (rootPubspec.existsSync() &&
        examplePubspec.existsSync() &&
        rootPubspec.readAsStringSync().contains('name: wallet_connect_cardano')) {
      return dir.path;
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  throw StateError(
    'Could not find wallet_connect_cardano repo root from '
    '${Directory.current.path}. Run from example/ or pass '
    '--dart-define=REPO_ROOT=/path/to/wallet_connect_cardano',
  );
}

File repoFile(String relativePath) => File('${repoRootPath()}/$relativePath');
