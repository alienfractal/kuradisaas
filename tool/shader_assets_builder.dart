import 'dart:convert';
import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

/// FlutterGen handles assets/fonts; this covers Flutter's separate shader list.
Builder shaderAssetsBuilder(BuilderOptions options) => _ShaderAssetsBuilder();

class _ShaderAssetsBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        'pubspec.yaml': ['lib/gen/shaders.gen.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final manifest = loadYaml(await buildStep.readAsString(buildStep.inputId));
    final paths =
        (manifest['flutter']['shaders'] as List?)?.cast<String>() ?? [];
    final names = <String>{};
    final fields = <String>[];
    for (final path in paths) {
      final basename = path.split('/').last.split('.').first;
      final words = basename.split(RegExp(r'[^a-zA-Z0-9]+'));
      var name = words.first.toLowerCase() +
          words
              .skip(1)
              .where((word) => word.isNotEmpty)
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join();
      if (RegExp(r'^\d').hasMatch(name)) name = 'shader$name';
      if (name.isEmpty || !names.add(name)) {
        throw StateError('Shader names must be unique Dart identifiers: $path');
      }
      fields.add('  static const String $name = '
          '${jsonEncode(path).replaceAll(r'$', r'\$')};');
    }
    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/gen/shaders.gen.dart'),
        '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
        '// Generated from flutter.shaders in pubspec.yaml.\n\n'
        '// ignore_for_file: type=lint\n\n'
        'abstract final class ShaderAssets {\n${fields.join('\n')}\n}\n');
  }
}
