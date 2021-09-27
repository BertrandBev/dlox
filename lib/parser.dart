import 'package:dlox/debug.dart';
import 'package:dlox/scanner.dart';

import 'error.dart';

class Parser {
  final List<Token> tokens;
  final List<CompilerError> errors = [];
  Token current;
  Token previous;
  Token secondPrevious;
  int currentIdx = 0;
  bool panicMode = false;
  Debug debug;

  Parser(this.tokens, {bool silent = false}) {
    debug = Debug(silent);
  }

  void errorAt(Token token, String message) {
    if (panicMode) return;
    panicMode = true;
    final error = CompilerError(token, message);
    errors.add(error);
    error.dump(debug);
  }

  void error(String message) {
    errorAt(previous, message);
  }

  void errorAtCurrent(String message) {
    errorAt(current, message);
  }

  void advance() {
    secondPrevious = previous; // TODO: is it needed?
    previous = current;
    while (currentIdx < tokens.length) {
      current = tokens[currentIdx++];
      // Skip invalid tokens
      if (current.type == TokenType.ERROR) {
        errorAtCurrent(current.str);
      } else if (current.type != TokenType.COMMENT) {
        break;
      }
    }
  }

  void consume(TokenType type, String message) {
    if (current.type == type) {
      advance();
      return;
    }
    errorAtCurrent(message);
  }

  bool check(TokenType type) {
    return current.type == type;
  }

  bool matchPair(TokenType first, TokenType second) {
    if (!check(first) ||
        currentIdx >= tokens.length ||
        tokens[currentIdx].type != second) return false;
    advance();
    advance();
    return true;
  }

  bool match(TokenType type) {
    if (!check(type)) return false;
    advance();
    return true;
  }
}
