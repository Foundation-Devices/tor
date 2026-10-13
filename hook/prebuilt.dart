import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

// Deployment floors used by the release workflow; zero means not applicable.
const releaseTargets = {
  'armv7-linux-androideabi': 24,
  'aarch64-linux-android': 24,
  'x86_64-linux-android': 24,
  'aarch64-apple-ios': 13,
  'aarch64-apple-ios-sim': 13,
  'x86_64-apple-ios': 13,
  'aarch64-apple-darwin': 11,
  'x86_64-apple-darwin': 11,
  'aarch64-unknown-linux-gnu': 0,
  'x86_64-unknown-linux-gnu': 0,
  'x86_64-pc-windows-msvc': 0,
};

String libraryName(String target) => target.contains('windows')
    ? 'tor_ffi_plugin.dll'
    : 'libtor_ffi_plugin.${target.contains('apple') ? 'dylib' : 'so'}';

String releaseFileName(String target) => '$target-${libraryName(target)}';

Future<String> fileHash(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

// Hash paths and contents so additions, deletions and ABI changes invalidate
// prebuilts. Track directories as well as files for Flutter's hook cache.
// Hidden entries are not native inputs and are skipped.
Future<({String hash, List<Uri> dependencies})> sourceFingerprint(
  Uri root,
) async {
  final dependencies = <Uri>[
    for (final path in [
      'rust/Cargo.toml',
      'rust/Cargo.lock',
      'rust/rust-toolchain.toml',
      'rust/build.rs',
      'hook/build.dart',
      'lib/tor_ffi_plugin_bindings_generated.dart',
      'rust/src/',
    ])
      root.resolve(path),
    ...await _sourceEntries(Directory.fromUri(root.resolve('rust/src/'))),
  ]..sort((a, b) => a.path.compareTo(b.path));
  final hashes = StringBuffer();
  for (final uri in dependencies) {
    final type = await FileSystemEntity.type(
      uri.toFilePath(),
      followLinks: false,
    );
    if (type == FileSystemEntityType.link) {
      throw StateError('Native source symlinks are unsupported: $uri');
    }
    if (type == FileSystemEntityType.directory) continue;
    // Git checkouts may use CRLF on Windows. Hash bytes rather than decoded
    // text so a file that is not UTF-8 cannot fail the build.
    final bytes = _lfLineEndings(await File.fromUri(uri).readAsBytes());
    hashes.writeln(
      '${uri.path.substring(root.path.length)}:${sha256.convert(bytes)}',
    );
  }
  return (
    hash: sha256.convert(utf8.encode(hashes.toString())).toString(),
    dependencies: dependencies,
  );
}

/// Entries under [directory], without descending into skipped directories.
Future<List<Uri>> _sourceEntries(Directory directory) async => [
  await for (final entry in directory.list(followLinks: false))
    if (!_isSkipped(entry)) ...[
      entry.uri,
      if (entry is Directory) ...await _sourceEntries(entry),
    ],
];

/// Whether [entry] is hidden, such as .DS_Store.
bool _isSkipped(FileSystemEntity entry) {
  final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
  return name.startsWith('.');
}

/// [bytes] with each CRLF replaced by LF.
List<int> _lfLineEndings(List<int> bytes) => [
  for (var i = 0; i < bytes.length; i++)
    if (bytes[i] != 0x0d || i + 1 == bytes.length || bytes[i + 1] != 0x0a)
      bytes[i],
];

String rustTarget(CodeConfig code) => switch ((
  code.targetOS,
  code.targetArchitecture,
)) {
  (OS.android, Architecture.arm) => 'armv7-linux-androideabi',
  (OS.android, Architecture.arm64) => 'aarch64-linux-android',
  (OS.android, Architecture.x64) => 'x86_64-linux-android',
  (OS.iOS, Architecture.arm64) =>
    code.iOS.targetSdk == IOSSdk.iPhoneSimulator
        ? 'aarch64-apple-ios-sim'
        : 'aarch64-apple-ios',
  (OS.iOS, Architecture.x64)
      when code.iOS.targetSdk == IOSSdk.iPhoneSimulator =>
    'x86_64-apple-ios',
  (OS.macOS, Architecture.arm64) => 'aarch64-apple-darwin',
  (OS.macOS, Architecture.x64) => 'x86_64-apple-darwin',
  (OS.linux, Architecture.arm64) => 'aarch64-unknown-linux-gnu',
  (OS.linux, Architecture.x64) => 'x86_64-unknown-linux-gnu',
  (OS.windows, Architecture.x64) => 'x86_64-pc-windows-msvc',
  _ => throw UnsupportedError(
    'No prebuilt for ${code.targetOS}/${code.targetArchitecture}. Use native_build: source.',
  ),
};

String _digest(Object? value) {
  if (value is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value)) {
    throw FormatException('Expected a SHA-256 digest (64 hex characters).');
  }
  return value.toLowerCase();
}

Future<void> _download(
  HttpClient client,
  Uri url,
  File file,
  String hash,
  int limit,
) async {
  for (var redirects = 0; redirects <= 5; redirects++) {
    if (url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasFragment) {
      throw FormatException(
        'Prebuilt URLs require HTTPS without credentials or fragments.',
      );
    }
    final request = await client
        .getUrl(url)
        .timeout(const Duration(seconds: 30));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 30));
    if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.listen(null).cancel();
      if (location == null) {
        throw HttpException('Missing redirect location', uri: url);
      }
      url = url.resolve(location);
      continue;
    }
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > limit) {
      await response.listen(null).cancel();
      throw HttpException(
        'Invalid prebuilt response: HTTP ${response.statusCode}',
        uri: url,
      );
    }
    final sink = file.openWrite();
    var received = 0;
    try {
      await sink.addStream(
        response.timeout(const Duration(seconds: 30)).map((bytes) {
          received += bytes.length;
          if (received > limit) {
            throw StateError('Prebuilt exceeds expected size.');
          }
          return bytes;
        }),
      );
    } finally {
      await sink.close();
    }
    if (await fileHash(file) != hash) {
      throw StateError('Checksum mismatch: $url');
    }
    return;
  }
  throw HttpException('Too many prebuilt redirects', uri: url);
}

Future<bool> usePrebuilt(BuildInput input, BuildOutputBuilder output) async {
  final mode = input.userDefines['native_build'] ?? 'source';
  if (mode == 'source') return false;
  if (mode != 'prebuilt') {
    throw FormatException('native_build must be source or prebuilt.');
  }
  final url = input.userDefines['prebuilt_manifest_url'];
  if (url is! String) throw FormatException('Missing prebuilt_manifest_url.');
  final pin = _digest(input.userDefines['prebuilt_manifest_sha256']);
  final manifestUrl = Uri.parse(url);
  final code = input.config.code;
  if (code.linkModePreference == LinkModePreference.static ||
      code.sanitizer != null) {
    throw UnsupportedError(
      'Prebuilts require dynamic linking without sanitizers.',
    );
  }
  final target = rustTarget(code);
  final minimum = switch (code.targetOS) {
    OS.android => code.android.targetNdkApi,
    OS.iOS => code.iOS.targetVersion,
    OS.macOS => code.macOS.targetVersion,
    _ => 0,
  };
  if (minimum < releaseTargets[target]!) {
    throw UnsupportedError(
      '$target prebuilts require OS/API ${releaseTargets[target]}.',
    );
  }
  final source = await sourceFingerprint(input.packageRoot);
  output.dependencies.addAll(source.dependencies);
  final directory = await Directory.fromUri(input.outputDirectory)
      .create(recursive: true);
  final temporary = await directory.createTemp('prebuilt-');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final manifestFile = File.fromUri(temporary.uri.resolve('manifest.json'));
    await _download(client, manifestUrl, manifestFile, pin, 1024 * 1024);
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    if (manifest['schema_version'] != 1 ||
        manifest['package'] != 'tor_ffi_plugin') {
      throw FormatException('Unsupported tor_ffi_plugin manifest.');
    }
    if (manifest['source_sha256'] != source.hash) {
      throw StateError(
        'Prebuilt source mismatch. Use the matching package revision or native_build: source.',
      );
    }
    final artifact = (manifest['artifacts'] as Map<String, dynamic>)[target];
    if (artifact is! Map<String, dynamic>) {
      throw StateError('Missing prebuilt for $target.');
    }
    final hash = _digest(artifact['sha256']);
    final size = artifact['size'];
    if (size is! int || size <= 0 || size > 1024 * 1024 * 1024) {
      throw FormatException('Invalid prebuilt size for $target.');
    }
    final library = File.fromUri(temporary.uri.resolve(libraryName(target)));
    await _download(
      client,
      manifestUrl.resolve(releaseFileName(target)),
      library,
      hash,
      size,
    );
    if (await library.length() != size) {
      throw StateError('Prebuilt size mismatch.');
    }
    final bundled = await library.copy(
      directory.uri.resolve(libraryName(target)).toFilePath(),
    );
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'tor_ffi_plugin_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: bundled.uri,
      ),
    );
    return true;
  } finally {
    client.close(force: true);
    await temporary.delete(recursive: true);
  }
}
