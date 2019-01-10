import 'package:decorator/decorator.dart';

/// There are 2 ways for creating custom decorators

/// 1. Either use the provided [DecorateWith] decorator to create wrapper
/// functions and use [DecorateWith] as a proxy decorator

/// Greets the host
HostElement<R> greet<R>(HostElement<R> host) {
  print('Hello $host');

  return host;
}

/// 2. Or implement the [Wrapper] and [FunctionDecorator] interfaces, and create
/// the decorator yourself

/// Decorater that null checks all args
class ArgumentsNotNull implements Wrapper, FunctionDecorator {
  const ArgumentsNotNull();
  @override
  bool get runInRelease => true;

  @override
  HostElement<R> wraps<R>(HostElement<R> host) {
    if (host.args?.isNotEmpty ?? false) {
      for (var arg in host.args.keys) {
        if (host.args[arg] == null) {
          throw ArgumentError.notNull(arg);
        }
      }
    }

    if (host.kwargs?.keys?.isNotEmpty ?? false) {
      for (var kwarg in host.kwargs.keys) {
        if (host.kwargs[kwarg] == null) {
          throw ArgumentError.notNull(kwarg);
        }
      }
    }

    return host;
  }
}
