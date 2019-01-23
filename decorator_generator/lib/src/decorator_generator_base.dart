/// Part description
part of decorator_generator;

/// Sample docs
class DecoratorGenerator extends Generator {
  final DecoratorGeneratorOptions options;
  final TypeChecker hostWrapperType = TypeChecker.fromRuntime(Wrapper);
  final TypeChecker decoratorTypeChecker = TypeChecker.fromRuntime(Decorator);
  final TypeChecker functionDecoratorType =
      TypeChecker.fromRuntime(FunctionDecorator);

  ///
  DecoratorGenerator(this.options);

  ///
  Spec dartObject2Literal(DartObject arg, String decorator,
      ExecutableElement element, DartEmitter dartEmitter) {
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
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = StringBuffer();

    for (var element in library.allElements) {
      final annotations =
          decoratorTypeChecker.annotationsOf(element, throwOnUnresolved: false);
      if (annotations.isNotEmpty) {
        final generatedValue = await generateForAnnotatedElement(
          element,
          annotations
              .toList()

              /// Apply decorators in reverse order
              .reversed
              .map<ConstantReader>((a) => ConstantReader(a)),
          buildStep,
        );

        values.writeln(generatedValue);
      }
    }

    return values.toString();
  }

  @override
  Future<String> generateForAnnotatedElement(Element element,
      Iterable<ConstantReader> annotations, BuildStep buildStep) async {
    if (element is ExecutableElement) {
      final dartEmitter = DartEmitter();

      final revivedDecorators = annotations.map(
        (a) => '.wrapWith('
            '${revivedLiteral(a.revive(), element, dartEmitter)}'
            ')',
      );

      if (!element.isPrivate) {
        throw InvalidGenerationSourceError(
            'Only private elements can be decorated',
            element: element,
            todo: 'Change ${element.name} to _${element.name} or '
                '__${element.name} (for private proxy metthod)');
      }

      final argLiteral = StringBuffer('{');
      final kwargLiteral = StringBuffer('{');

      final argMapping = StringBuffer();
      final kwargMapping = StringBuffer();

      final requiredProxyParams = ListBuilder<Parameter>();
      final optionalProxyParams = ListBuilder<Parameter>();

      for (var parameter in element.parameters) {
        if (parameter.isPositional) {
          argLiteral
            ..write("'${parameter.name}':${parameter.name}")

            /// Add trailing comma
            ..write(',');

          argMapping.write(
              "args['${parameter.name}'] as ${parameter.type.displayName},");

          /// [requiredProxyParams] only accepts positional and required
          (parameter.isOptional ? optionalProxyParams : requiredProxyParams)
              .add(Parameter((b) {
            b
              ..name = parameter.name
              ..type = refer(parameter.type.displayName);

            if (parameter.defaultValueCode != null) {
              b.defaultTo = Code(parameter.defaultValueCode);
            }
          }));
        } else {
          kwargLiteral
            ..write("'${parameter.name}':${parameter.name}")

            /// Add trailing comma
            ..write(',');

          kwargMapping.write("${parameter.name}: kwargs['${parameter.name}']"
              ' as ${parameter.type.displayName},');

          optionalProxyParams.add(Parameter((b) {
            b
              ..name = parameter.name
              ..type = refer(parameter.type.displayName)
              ..named = parameter.isNamed;

            if (parameter.defaultValueCode != null) {
              b.defaultTo = Code(parameter.defaultValueCode);
            }
          }));
        }
      }

      argLiteral.write('}');
      kwargLiteral.write('}');

      final elementAsAccessor =
          element is PropertyAccessorElement && !element.isSynthetic
              ? element
              : null;

      final evalBody = (element.name) +
          (elementAsAccessor?.isGetter ?? false

              /// Getters don't have any args, just needs a trailing comma
              ? ','
              : elementAsAccessor?.isSetter ?? false

                  /// Setters only have 1 required arg
                  ? '$argMapping'
                  : '($argMapping $kwargMapping),');

      final body = <String>[
        'HostElement(',

        /// Escape displayName
        "r'''${element.toString().replaceAll("'''", r"\'\'\'")}''', ",
        '$argLiteral, $kwargLiteral, ',
        '([args, kwargs]) => $evalBody',
        ')',
        '${revivedDecorators.join('\n')}',
        '.value;',
      ];

      final proxy = Method((b) {
        b
          ..name = element.name.substring(1).replaceFirst('=', '')
          ..docs = ListBuilder(<String>[element.documentationComment ?? ''])
          ..requiredParameters = requiredProxyParams
          ..optionalParameters = optionalProxyParams
          ..lambda = true
          ..body = Code(body.join('\n'));

        /// if it's a setter then it doesn't need a return type
        if (!(elementAsAccessor?.isSetter ?? false)) {
          b.returns = refer(element.returnType.displayName);
        }

        if (element is PropertyAccessorElement && !element.isSynthetic) {
          b.type = element.isGetter ? MethodType.getter : MethodType.setter;
        }

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
          'Decorators can only be applied to Executable elements');
    }
  }

  /// Returns `const $revived($args $kwargs)`
  String revivedLiteral(
      Revivable revived, ExecutableElement element, DartEmitter dartEmitter) {
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
