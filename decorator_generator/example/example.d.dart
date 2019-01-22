// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: ,avoid_as,lines_longer_than_80_chars,prefer_equal_for_default_values,unnecessary_const

part of decorator_generator.example;

// **************************************************************************
// DecoratorGenerator
// **************************************************************************

/// This function joins its args
String joinArgs(List<String> arg1,
        {List<String> arg2: const [r'''$Default''', 'Args']}) =>
    HostElement(
      r'''_joinArgs(List<String> arg1, {List<String> arg2: const [r\'\'\'$Default\'\'\', 'Args']}) → String''',
      {
        'arg1': arg1,
      },
      {
        'arg2': arg2,
      },
      ([args, kwargs]) => _joinArgs(
            args['arg1'] as List<String>,
            arg2: kwargs['arg2'] as List<String>,
          ),
    )
        .wrapWith(const MyLogger(
          '_joinArgs',
          const Level(
            'mylevel',
            555,
          ),
        ))
        .value;

/// This function also joins its args but doesnt check them against being null
String joinArgs2(List<String> arg1, [List<String> arg2]) => HostElement(
      r'''_joinArgs2(List<String> arg1, [List<String> arg2]) → String''',
      {
        'arg1': arg1,
        'arg2': arg2,
      },
      {},
      ([args, kwargs]) => _joinArgs2(
            args['arg1'] as List<String>,
            args['arg2'] as List<String>,
          ),
    ).wrapWith(const ArgumentsNotNull()).value;

/// This one also joins its args but it is decorated with a [HostWrapper], this
/// is useful when the decorater doesn't require any additional args.
String joinArgs3(List<String> arg1, {List<String> arg2}) => HostElement(
      r'''_joinArgs3(List<String> arg1, {List<String> arg2}) → String''',
      {
        'arg1': arg1,
      },
      {
        'arg2': arg2,
      },
      ([args, kwargs]) => _joinArgs3(
            args['arg1'] as List<String>,
            arg2: kwargs['arg2'] as List<String>,
          ),
    )
        .wrapWith(const DecorateWith(
          greet,
        ))
        .value;

/// Another one just for fun
Future<String> joinArgs4(List<String> arg1, {List<String> arg2}) async =>
    HostElement(
      r'''_joinArgs4(List<String> arg1, {List<String> arg2}) → Future<String>''',
      {
        'arg1': arg1,
      },
      {
        'arg2': arg2,
      },
      ([args, kwargs]) => _joinArgs4(
            args['arg1'] as List<String>,
            arg2: kwargs['arg2'] as List<String>,
          ),
    )
        .wrapWith(const MyLogger.detached(
          'loggerName',
        ))
        .value;
