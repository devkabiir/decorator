library decorator_generator;

import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:decorator/decorator.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

/// Include the part
part 'src/decorator_generator_base.dart';

const String _addExtension = '.d';

/// Header of generated library
final String decoratorHeader = [
  '// GENERATED CODE - DO NOT MODIFY BY HAND',
  '// ignore_for_file: ${ignoreLints.join(', ')}'
].join('\n');

/// lints to ignore using `ignore_for_file` comment
final List<String> ignoreLints = [
  'avoid_as',
  'lines_longer_than_80_chars',
  'prefer_equal_for_default_values',
  'unnecessary_const',
];

/// Logger for `decorator_generator`
final Logger logger = Logger('decorator_generator');

///
Builder decoratorBuilder(BuilderOptions options) => PartBuilder([
      DecoratorGenerator(DecoratorGeneratorOptions.fromOptions(options))
    ], '$_addExtension.dart', header: decoratorHeader);
