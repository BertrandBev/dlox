import 'package:dlox/scanner.dart';

import 'debug.dart';

class LangError {
  final String type;
  final Token token;
  final String msg;

  LangError(this.type, this.token, this.msg);

  void dump() {
    if (token == null) {
      stdwriteln('$type error: $msg');
      return;
    }
    stdwrite('[${token.loc}] $type error');
    if (token.type == TokenType.EOF) {
      stdwrite(' at end');
    } else if (token.type == TokenType.ERROR) {
      // Nothing.
    } else {
      stdwrite(' at \'${token.str}\'');
    }
    stdwrite(': $msg\n');
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
