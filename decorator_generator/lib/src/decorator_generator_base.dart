/// Part description
part of decorator_generator;

// ignore_for_file: prefer_interpolation_to_compose_strings
/// Sample docs
class DecoratorGenerator extends GeneratorForAnnotation<Decorator> {
  final DecoratorGeneratorOptions options;
  final TypeChecker hostWrapperType = TypeChecker.fromRuntime(Wrapper);
  final TypeChecker functionDecoratorType =
      TypeChecker.fromRuntime(FunctionDecorator);

  ///
  DecoratorGenerator(this.options);

  ///
  Spec dartObject2Literal(DartObject arg, String decorator,
      FunctionElement element, DartEmitter dartEmitter) {
    final constant = ConstantReader(arg);
    if (constant.isNull) {
      return literalNull;
    }

    if (constant.isBool) {
      return literal(arg.toBoolValue());
    }

    if (constant.isDouble) {
      return literal(constant.doubleValue);
    }

    if (constant.isInt) {
      return literal(constant.intValue);
    }

    if (constant.isString) {
      return literal(arg.toStringValue());
    }

    if (constant.isList) {
      return literal(arg.toListValue());
    }

    if (constant.isMap) {
      return literal(arg.toMapValue());
    }

    /// Perhaps an object instantiation?
    final revived = constant.revive();
    return Code('${revivedLiteral(revived, element, dartEmitter)}');

    // throw InvalidGenerationSourceError(
    //   '$decorator was constructed with an unsupported literal type:'
    //       '${constant.literalValue}',
    //   element: element,
    // );
  }

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is FunctionElement) {
      final dartEmitter = DartEmitter();

      final revivedDecorator =
          revivedLiteral(annotation.revive(), element, dartEmitter);

      if (!element.isPrivate) {
        throw InvalidGenerationSourceError(
            'Only private elements can be decorated',
            element: element,
            todo: 'Change ${element.name} to _${element.name}');
      }

      final argLiteral = StringBuffer('{');
      final kwargLiteral = StringBuffer('{');

      final argMapping = StringBuffer();
      final kwargMapping = StringBuffer();

      for (var parameter in element.parameters) {
        if (parameter.isPositional) {
          argLiteral.write("'${parameter.name}':${parameter.name}");
          if (parameter.defaultValueCode != null) {
            argLiteral.write(' ?? ${parameter.defaultValueCode}');
          }

          /// Add trailing comma
          argLiteral.write(',');

          argMapping.write(
              "args['${parameter.name}'] as ${parameter.type.displayName},");
        } else {
          kwargLiteral.write("'${parameter.name}':${parameter.name}");

          if (parameter.defaultValueCode != null) {
            kwargLiteral.write(' ?? ${parameter.defaultValueCode}');
          }

          /// Add trailing comma
          kwargLiteral.write(',');

          kwargMapping.write("${parameter.name}:kwargs['${parameter.name}']"
              ' as ${parameter.type.displayName},');
        }
      }

      argLiteral.write('}');
      kwargLiteral.write('}');

      final body = <String>[
        'HostElement(',

        /// Escape displayName
        "r'''${element.toString().replaceAll("'''", r"\'\'\'")}''', ",
        '$argLiteral, $kwargLiteral, ',
        '([args, kwargs]) => ${element.name}(',
        '$argMapping $kwargMapping',
        '),',
        ')',
        '.wrapWith($revivedDecorator)',
        '.value;',
      ];

      final proxy = Method((b) {
        b
          ..name = element.name.substring(1)
          ..docs = ListBuilder(<String>[element.documentationComment])
          ..requiredParameters = ListBuilder(element.parameters
              .where((p) => !p.isOptional && p.isPositional)
              .map<Parameter>((p) => Parameter((b) => b
                ..name = p.name
                ..type = refer(p.type.displayName))))
          ..optionalParameters = ListBuilder(element.parameters
              .where((p) => p.isOptional)
              .map<Parameter>((p) => Parameter((b) => b
                ..name = p.name
                ..type = refer(p.type.displayName)
                ..named = p.isNamed)))
          ..returns = refer(element.returnType.displayName)
          ..lambda = true
          ..body = Code(body.join('\n'));

        if (element.isAsynchronous && element.isGenerator) {
          // TODO(devkabiir): async generators, https://github.com/devkabiir/decorator/issues/
          b.modifier = MethodModifier.asyncStar;
        }
        if (element.isSynchronous && element.isGenerator) {
          // TODO(devkabiir): sync generators, https://github.com/devkabiir/decorator/issues/
          b.modifier = MethodModifier.syncStar;
        }
        if (element.isAsynchronous && !element.isGenerator) {
          b.modifier = MethodModifier.async;
        }
      });

      return '${proxy.accept(dartEmitter)}';
    } else {
      throw InvalidGenerationSourceError(
          'FunctionDecorators can only be applied to functions');
    }
  }

  /// Returns `const $revived($args $kwargs)`
  String revivedLiteral(
      Revivable revived, FunctionElement element, DartEmitter dartEmitter) {
    String instantiation = '';
    final location = revived.source.toString().split('#');

    /// If this is a class instantiation then `location[1]` will be populated
    /// with the class name
    if (location.length > 1) {
      instantiation = location[1] +
          (revived.accessor.isNotEmpty ? '.${revived.accessor}' : '');
    } else {
      /// Getters, Setters, Methods can't be declared as constants so this
      /// literal must either be a top-level constant or a static constant and
      /// can be directly accessed by `revived.accessor`
      return revived.accessor;
    }

    final args = StringBuffer();
    final kwargs = StringBuffer();

    for (var arg in revived.positionalArguments) {
      final literalValue =
          dartObject2Literal(arg, instantiation, element, dartEmitter);

      args.write('${literalValue.accept(dartEmitter)},');
    }

    for (var arg in revived.namedArguments.keys) {
      final literalValue = dartObject2Literal(
          revived.namedArguments[arg], instantiation, element, dartEmitter);

      kwargs.write('$arg:${literalValue.accept(dartEmitter)},');
    }

    return 'const $instantiation($args $kwargs)';
  }
}

class DecoratorGeneratorOptions {
  /// Helper to construct from [options]
  DecoratorGeneratorOptions.fromOptions(BuilderOptions options) {}
}
