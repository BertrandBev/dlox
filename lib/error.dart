import 'package:dlox/scanner.dart';

import 'debug.dart';

class LangError {
  final String type;
  final Token token;
  int line;
  final String msg;

  LangError(this.type, this.msg, {this.line, this.token});

  void dump(Debug debug) {
    debug.stdwriteln(toString());
  }

  @override
  String toString() {
    final buf = StringBuffer();
    if (token != null) {
      buf.write('[${token.loc.i + 1}:${token.loc.j}] $type error');
      if (token.type == TokenType.EOF) {
        buf.write(' at end');
      } else if (token.type == TokenType.ERROR) {
        // Nothing.
      } else {
        buf.write(' at \'${token.str}\'');
      }
    } else if (line != null) {
      buf.write('[$line] $type error');
    } else {
      buf.write('$type error');
    }
    buf.write(': $msg');
    return buf.toString();
  }
}

class CompilerError extends LangError {
  CompilerError(Token token, String msg)
      : super('Compile', msg, token: token, line: token.loc.i);
}

class RuntimeError extends LangError {
  final RuntimeError link;

  RuntimeError(int line, String msg, {this.link})
      : super('Runtime', msg, line: line);
}
