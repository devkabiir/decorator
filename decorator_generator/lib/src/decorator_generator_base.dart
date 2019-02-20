/// Part description
part of decorator_generator;

/// Sample docs
class DecoratorGenerator extends Generator {
  static const _classMethodDecorator =
      TypeChecker.fromRuntime(ClassMethodDecorator);
  static const _classMemberDecorator =
      TypeChecker.fromRuntime(ClassMemberDecorator);
  static const _classPropertyDecorator =
      TypeChecker.fromRuntime(ClassPropertyDecorator);
  static const _propertyDecorator = TypeChecker.fromRuntime(PropertyDecorator);

  static const _wrapper = TypeChecker.fromRuntime(Wrapper);
  static const _functionDecorator = TypeChecker.fromRuntime(FunctionDecorator);
  static const _classDecorator = TypeChecker.fromRuntime(ClassDecorator);

  static const _decorator = TypeChecker.fromRuntime(Decorator);

  /// Options this generator accepts
  final DecoratorGeneratorOptions options;

  ///
  DecoratorGenerator(this.options);

  /// Returns `const $revived($args $kwargs)`
  String constantLiteral(Object object, DartEmitter dartEmitter) {
    Revivable revived;
    if (object is Revivable) {
      revived = object;
    }
    if (object is DartObject) {
      revived = ConstantReader(object).revive();
    }
    if (revived == null) {
      throw ArgumentError.value(object, 'object',
          'Only `Revivable` and `DartObject` are supported values');
    }
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
    Spec objectToSpec(DartObject object) {
      final constant = ConstantReader(object);
      if (constant.isNull) {
        return literalNull;
      }

      if (constant.isBool) {
        return literal(constant.boolValue);
      }

      if (constant.isDouble) {
        return literal(constant.doubleValue);
      }

      if (constant.isInt) {
        return literal(constant.intValue);
      }

      if (constant.isString) {
        return literal(constant.stringValue);
      }

      if (constant.isList) {
        return literal(constant.listValue);
      }

      if (constant.isMap) {
        return literal(constant.mapValue);
      }

      /// Perhaps an object instantiation?
      /// In that case, try initializing it and remove `const` to reduce noise
      final revived = constantLiteral(constant.revive(), dartEmitter)
          .replaceFirst('const ', '');
      return Code(revived);
    }

    for (var arg in revived.positionalArguments) {
      final literalValue = objectToSpec(arg);

      args.write('${literalValue.accept(dartEmitter)},');
    }

    for (var arg in revived.namedArguments.keys) {
      final literalValue = objectToSpec(revived.namedArguments[arg]);

      kwargs.write('$arg:${literalValue.accept(dartEmitter)},');
    }

    return 'const $instantiation($args $kwargs)';
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final generators = <Future<String>>[];

    /// Queue [element] for generation if it's been decorated
    void _generate(Element element) {
      final annotations =
          _decorator.annotationsOf(element, throwOnUnresolved: false);

      if (annotations.isEmpty) {
        return;
      }

      generators
          .add(generateForAnnotatedElement(element, annotations, buildStep));
    }

    for (var topLevelElement in library.element.topLevelElements) {
      if (topLevelElement is ClassElement) {
        /// Getters and Setters
        topLevelElement.accessors.forEach(_generate);

        /// Methods
        topLevelElement.methods.forEach(_generate);
      }

      _generate(topLevelElement);
    }

    final generated = await Future.wait(generators, eagerError: true);

    return generated.where((gen) => gen.isNotEmpty).join('\n');
  }

  /// Generates proxy method for decorated elements
  Future<String> generateForAnnotatedElement(Element element,
      Iterable<DartObject> annotations, BuildStep buildStep) async {
    if (element.library.displayName?.isEmpty ?? true) {
      throw InvalidGenerationSourceError(
        'Library name not defined',
        element: element,
      );
    }

    /// Check for unacceptable decorators in [annotations] using [expectedType]
    void checkInvalidDecorators(
        Iterable<DartObject> annotations, TypeChecker expectedType) {
      final invalidAnnotation = annotations.firstWhere(
          (a) => !expectedType.isAssignableFromType(a.type),
          orElse: () => null);

      if (invalidAnnotation != null) {
        throw InvalidGenerationSourceError(
            'Decorator ${invalidAnnotation.type.displayName} cannot be '
            'applied to element ${element.displayName}',
            element: element,
            todo:
                'Remove @${invalidAnnotation.type.displayName} decorator from '
                '${element.displayName}');
      }
    }

    final dartEmitter = DartEmitter();

    if (element is PropertyAccessorElement &&
        element.library.topLevelElements.contains(element)) {
      checkInvalidDecorators(annotations, _propertyDecorator);

      return _decoratePropertyElement(element, annotations, dartEmitter);
    }

    if (element is FunctionElement) {
      checkInvalidDecorators(annotations, _functionDecorator);

      return _decorateFunctionElement(element, annotations, dartEmitter);
    }

    if (element is ClassElement) {
      checkInvalidDecorators(annotations, _classDecorator);
      throw InvalidGenerationSourceError('Classes not supported (yet)',
          element: element);
    }

    if (element is ClassMemberElement) {
      checkInvalidDecorators(annotations, _classMemberDecorator);
      throw InvalidGenerationSourceError('Classe members not supported (yet)',
          element: element);
    }

    if (element is MethodElement) {
      checkInvalidDecorators(annotations, _classMethodDecorator);
      throw InvalidGenerationSourceError('Class methods not supported (yet)',
          element: element);
    }

    if (element is PropertyAccessorElement &&
        !element.library.topLevelElements.contains(element)) {
      checkInvalidDecorators(annotations, _classPropertyDecorator);
      throw InvalidGenerationSourceError(
          'Class Getters/Setters not supported (yet)',
          element: element);
    }

    throw InvalidGenerationSourceError('Unsupported element type',
        element: element);
  }

  Future<String> _decorateFunctionElement(FunctionElement element,
      Iterable<DartObject> annotations, DartEmitter dartEmitter) {
    if (annotations.every((a) => _wrapper.isAssignableFromType(a.type))) {
      return _generateWrapperForFunction(element, annotations, dartEmitter);
    }
    throw InvalidGenerationSourceError('Other uses cases TBD',
        element: element);
  }

  Future<String> _decoratePropertyElement(PropertyAccessorElement element,
      Iterable<DartObject> annotations, DartEmitter dartEmitter) {
    if (annotations.every((a) => _wrapper.isAssignableFromType(a.type))) {
      return _generateWrapperForProperty(element, annotations, dartEmitter);
    }
    throw InvalidGenerationSourceError('Other uses cases TBD',
        element: element);
  }

  Future<String> _generateWrapperForFunction(ExecutableElement element,
      Iterable<DartObject> annotations, DartEmitter dartEmitter) async {
    if (!element.isPrivate) {
      throw InvalidGenerationSourceError(
          'Only private elements can be decorated',
          element: element,
          todo: 'Change ${element.name} to _${element.name} or '
              '__${element.name} (for private proxy method)');
    }
    final revivedDecorators = annotations
        .toList()
        .reversed // Apply decorators in reverse order
        .map(
          (a) => '.wrapWith('
              '${constantLiteral(a, dartEmitter)}'
              ')',
        );

    final argLiteral = StringBuffer();
    final kwargLiteral = StringBuffer();

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

    final elementAsAccessor =
        element is PropertyAccessorElement && !element.isSynthetic
            ? element
            : null;

    final evalBody = (element.name) +
        (elementAsAccessor?.isGetter ?? false

            /// Getters don't have any args, just needs a trailing comma
            ? ','
            : elementAsAccessor?.isSetter ?? false

                /// Setters only have 1 required arg,
                /// already has trailing comma
                ? '$argMapping'
                : '($argMapping $kwargMapping),');

    final body = <String>[
      'HostElement(',

      /// Escape displayName
      "r'''${element.toString().replaceAll("'''", r"\'\'\'")}''', ",
      '([args, kwargs]) => $evalBody',
      '${argLiteral.isNotEmpty ? 'args:{$argLiteral},' : ''}',
      '${kwargLiteral.isNotEmpty ? 'kwargs:{$kwargLiteral},' : ''}',
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
  }

  Future<String> _generateWrapperForProperty(ExecutableElement element,
          Iterable<DartObject> annotations, DartEmitter dartEmitter) =>
      // TODO(devkabiir): split generator for functions and properties, https://github.com/devkabiir/decorator/issues/

      _generateWrapperForFunction(element, annotations, dartEmitter);
}

class DecoratorGeneratorOptions {
  /// Helper to construct from [options]
  DecoratorGeneratorOptions.fromOptions(BuilderOptions options) {}
}
