/// Defines types of supported decorators
library decorator.types;

import 'package:logging/logging.dart';

import 'decorator.impl.dart';

/// Logger for `decorator.types`
final Logger logger = Logger('decorator.types');

/// Base interface for a decorator that decorates a class
mixin ClassDecorator on Decorator {}

/// Base interface for a decorator that decorates a class method
mixin ClassMethodDecorator on Decorator implements ClassMemberDecorator {}

/// Base interface for a decorator that decorates a class member
/// equivalent to mixins [ClassMethodDecorator] and [ClassPropertyDecorator]
mixin ClassMemberDecorator on Decorator {}

/// Base interface for a decorator that decorates a class property
/// (fields, getters, setters)
mixin ClassPropertyDecorator on Decorator implements ClassMemberDecorator {}

/// Base interface for a decorator that decorates a top-level property
/// (fields, getters, setters)
mixin PropertyDecorator on Decorator {}

/// Interface for a decorator that wraps a [host] element
mixin Wrapper on Decorator {
  /// This is the actual wrapper function
  ///
  /// Remember to return the [host] for other decorators to consume, it
  /// can be the same instance or a different one
  HostElement<R> wraps<R>(HostElement<R> host);
}

/// Base interface for a decorator that decorates a top-level function
mixin FunctionDecorator on Decorator {}

/// A Decorator that generates code based on it's [host]
// class GeneratorDecorator implements Decorator {
//   final String varname;

//   ///
//   const GeneratorDecorator(this.varname);

//   @override
//   // TODO: implement runInRelease
//   bool get runInRelease => null;

//   /// The code block this decorator generates
//   cb.Spec get template {
//     /// This builder needs to run before all others so that constants
//     ///  can be passed to other builders
//     final value = Platform.environment[varname];
//     return cb.Code('const String $varname = ${cb.literalString(value)}');
//   }
// }
