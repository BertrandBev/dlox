import 'package:dlox/scanner.dart';

import 'debug.dart';

class LangError {
  final String type;
  final Token token;
  final String msg;

  LangError(this.type, this.token, this.msg);

  void dump(Debug debug) {
    debug.stdwriteln(toString());
  }

  @override
  String toString() {
    final buf = StringBuffer();
    if (token == null) {
      buf.write('$type error: $msg');
      return buf.toString();
    }
    buf.write('[${token.loc.i + 1}:${token.loc.j}] $type error');
    if (token.type == TokenType.EOF) {
      buf.write(' at end');
    } else if (token.type == TokenType.ERROR) {
      // Nothing.
    } else {
      buf.write(' at \'${token.str}\'');
    }
    buf.write(': $msg');
    return buf.toString();
  }
}

class CompilerError extends LangError {
  CompilerError(Token token, String msg) : super('Compile', token, msg);
}

class RuntimeError extends LangError {
  final RuntimeError link;

  RuntimeError(Token token, String msg, {this.link})
      : super('Runtime', token, msg);
}
