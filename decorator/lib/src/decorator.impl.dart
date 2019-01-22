/// Decorator annotation implementation and helpers
library decorator.impl;

/// The element being decorated, To evaluate the host call
/// the passed in [HostElement] object e.g. `host(args, kwargs)`
///
/// In case the passed in [HostElement] object represents a field/getter `host.value`
/// can be use to access it's value
///
/// In case the passed in [HostElement] object represents a setter
/// `host.value = newValue` can be used
///
/// This is just a placeholder, used as a reference throughout the docs
/// it's value is always `null`.
const Object host = null;

/// A closure that evaluates the value of [host]
/// - [args] are positional arguments, if any, of host
/// - [kwargs] are named arguments, if any, of host
///
/// This is provided automatically after running `build_runner` but can also be
/// set manually for overriding the [host] element
typedef HostEvaluator<R> = R Function(
    [Map<String, Object> args, Map<String, Object> kwargs]);

/// Signature of function that wraps a [host]
typedef HostWrapper = HostElement<R> Function<R>(HostElement<R> host);

/// This is a proxy [Decorator] that takes in a [HostWrapper] and proxies it's
/// call to [wraps] to the given [decorator]
class DecorateWith implements Wrapper, FunctionDecorator {
  /// The actual decorator function
  final HostWrapper decorator;

  @override
  final bool runInRelease;

  /// Create a proxy decorator that proxies its call to [wraps] to the given
  /// [decorator]
  const DecorateWith(this.decorator, {this.runInRelease = false});

  @override
  HostElement<R> wraps<R>(HostElement<R> host) => decorator?.call(host);
}

/// Base decorator interface, used for filtering decorated elements, a
/// decorator is a proxy to the host element, anything can be decorated
/// including class, class method, class field, top-level method,
/// top-level field. The only requirement for an element to be decorated is
/// it being *private* e.g. to decorate a function `void myFunc()` first make it
/// private, annotate it with the required decorator(s) and then execute command
/// `pub run build_runner build`
///
///     @myDecorator
///     void _myFunc(){}
/// A proxy function `void myFunc()` is generated that applies the
/// `myDecorator` to the original function. If the generated proxy function
/// is required to be private simply prefix the host with 2 underscores
/// e.g.
///
///     @myDecorator
///     void __myFunc(){}
/// will generate `void _myFunc()`.
///
/// Actual implementation of the proxy function may change but it's signature
/// will be equal to the [host]
abstract class Decorator {
  ///
  const Decorator();

  /// if this decorator should be in effect in release mode
  ///
  /// when `false` the host element behaves as if it wasn't decorated by this
  /// particular decorator
  bool get runInRelease;
}

/// Base interface for a decorator that decorates a top-level function
abstract class FunctionDecorator extends Decorator {
  ///
  const FunctionDecorator();
}

/// Helper to pass the host between decorators. A [host] can be anything
/// including
/// class, class method, class field, top-level method, top-level field
///
/// Here [R] is the type of the host or return type in case of a method.
///
/// This has the advantage of being able to evaluate the [host] by calling
/// `host(args, kwargs)` inside the decorator's `wraps`
/// method. In case of a field `host.value` can also be used
class HostElement<R> {
  _Object<R> _evaluatedObject;

  /// Positional arguments, if any, of the [host] and their corresponding values
  /// If there are no positional arguments this will be an empty map
  final Map<String, Object> args;

  /// Named arguments, if any, of the [host] and their corresponding values
  /// If there are no Named arguments this will be an empty map
  final Map<String, Object> kwargs;

  /// Representation of [host] as it appears in code
  final String displayName;

  bool _isModified;

  HostEvaluator<R> _eval;

  bool _isEvaluated = false;

  /// Construct a [host] to be passed around in decorators
  HostElement(this.displayName, this.args, this.kwargs, [this._eval])
      : _isModified = false;

  /// Whether [value] is already evaluated or not. This does not check if the
  /// [value] is `null` rather this flag gets set whenever [value] is set, i.e.
  ///  - when [value] getter is invoked
  ///  - when [value] setter is used to explicitly set it
  ///  - when [call] is invoked (i.e. `host(args, kwargs)`)
  bool get isEvaluated => _isEvaluated;

  /// Whether [displayName], [args], [kwargs], [value] or [call] was modified
  /// from the original [host]
  bool get isModified => _isModified;

  /// Evaluated value from the [host], this value comes either from evaluating
  /// the [host] with [args] and [kwargs] or explicitly set by
  /// preceding decorators
  ///
  /// This getter evaluates the [host] *once* when the value is
  /// not known and subsequent calls get memoized values, which is ideal
  /// for most decorators.
  /// If multiple evaluations is a requirement then call the
  /// [HostElement] object as a function instead. i.e. `host(args, kwargs)`
  ///
  /// This can return `null`
  /// - when the value returned from host is indeed `null`
  /// - when the host did not return anything i.e. it's return type is `void`
  R get value {
    if (isEvaluated) {
      /// Here value can be `null`, but this simply means the [host] evaluated
      /// with a `null` value.
      return _evaluatedObject.value;
    }

    return call();
  }

  /// Explicitly set the Evaluated value of the [host], this can also be `null`
  set value(R newValue) {
    _isEvaluated = true;
    _evaluatedObject = _Object(newValue);
  }

  /// Evaluate this [host] with original [this.args] and [this.kwargs],
  /// optionally specify [args] and [kwargs] to use those instead
  ///
  /// This is equivalent to calling the [host] if it's a function
  /// There is no guarantee if this is the first time [host] is being evaluated
  R call([Map<String, Object> args, Map<String, Object> kwargs]) =>
      value = _eval(args ?? this.args, kwargs ?? this.kwargs);

  /// Copy this instance with changes, if no changes are specifed, returns a
  /// copy of this instance
  ///
  /// When specifying [value], set [nullValue] to `true` when it's indeed `null`
  /// to help distinguish it from being initialized to `null` vs not being
  /// initialized
  HostElement<R> copyWith({
    String displayName,
    Map<String, Object> args,
    Map<String, Object> kwargs,
    R value,
    HostEvaluator<R> eval,
    bool nullValue = false,
  }) {
    if (displayName == null &&
        args == null &&
        kwargs == null &&
        value == null &&
        eval == null) {
      return HostElement(
        this.displayName,
        this.args,
        this.kwargs,
        _eval,
      )
        .._isEvaluated = _isEvaluated
        .._evaluatedObject = _evaluatedObject
        .._isModified = _isModified;
    }

    return HostElement(
      displayName ?? this.displayName,
      args ?? this.args,
      kwargs ?? this.kwargs,
      eval ?? _eval,
    )
      .._isEvaluated = nullValue || value != null || _isEvaluated
      .._evaluatedObject =
          nullValue ? _Object(null) : _Object(value ?? _evaluatedObject?.value)
      .._isModified = true;
  }

  /// Representation of [host] as it appears in code
  @override
  String toString() => displayName;

  /// Wrap this [host] with [decorator], this will throw an [Exception] when
  /// the [decorator] does not return an object of type [HostElement<R>]
  HostElement<R> wrapWith<D extends Decorator>(D decorator) {
    var host = this;

    if (decorator is Wrapper) {
      host = decorator.wraps(host);
    }

    if (host is! HostElement<R>) {
      throw Exception(
          'Expected returned host from decorator `${decorator.runtimeType}` to '
          'be of type `HostElement<$R>` but got '
          '`${host.runtimeType}` instead');
    }

    return host;
  }
}

/// Base interface for a decorator that decorates a class method
abstract class MethodDecorator extends Decorator {
  ///
  const MethodDecorator();
}

/// Interface for a decorator that wraps a [host] element
abstract class Wrapper extends Decorator {
  ///
  const Wrapper();

  /// This is the actual wrapper function
  ///
  /// Remember to return the [host] for other decorators to consume, it
  /// can be the same instance or a different one
  HostElement<R> wraps<R>(HostElement<R> host);
}

/// Helper to check if an object is initialized with `null` value
/// or uninitialized
class _Object<T> {
  final T value;

  /// Helper to check if an object is initialized with `null` value
  /// or uninitialized
  _Object(this.value);
}
