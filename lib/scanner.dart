import 'package:sprintf/sprintf.dart';
import 'debug.dart';

enum TokenType {
  // Single-char tokens.
  LEFT_PAREN,
  RIGHT_PAREN,
  LEFT_BRACE,
  RIGHT_BRACE,
  LEFT_BRACK,
  RIGHT_BRACK,
  COMMA,
  DOT,
  MINUS,
  PLUS,
  SEMICOLON,
  SLASH,
  STAR,
  COLUMN,
  PERCENT,
  CARET,

  // One or two char tokens.
  BANG,
  BANG_EQUAL,
  EQUAL,
  EQUAL_EQUAL,
  GREATER,
  GREATER_EQUAL,
  LESS,
  LESS_EQUAL,

  // Literals.
  IDENTIFIER,
  STRING,
  NUMBER,
  OBJECT,

  // Keywords.
  AND,
  CLASS,
  ELSE,
  FALSE,
  FOR,
  FUN,
  IF,
  NIL,
  OR,
  PRINT,
  RETURN,
  SUPER,
  THIS,
  TRUE,
  VAR,
  WHILE,
  IN,
  BREAK, // TODO: add in dlox?
  CONTINUE, // TODO: add in dlox?

  // Editor syntactic sugar & helpers (dummy tokens)
  ERROR,
  COMMENT,
  EOF,
  ELIF,
  NLINE,
}

const TOKEN_REPR = {
  // Symbols
  TokenType.LEFT_PAREN: '(',
  TokenType.RIGHT_PAREN: ')',
  TokenType.LEFT_BRACE: '{',
  TokenType.RIGHT_BRACE: '}',
  TokenType.LEFT_BRACK: '[',
  TokenType.RIGHT_BRACK: ']',
  TokenType.COMMA: ',',
  TokenType.DOT: '.',
  TokenType.SEMICOLON: ';',
  TokenType.COLUMN: ':',
  TokenType.BANG: '!',

  // Operators
  TokenType.MINUS: '-',
  TokenType.PLUS: '+',
  TokenType.SLASH: '/',
  TokenType.STAR: '*',
  TokenType.PERCENT: '%',
  TokenType.CARET: '^',
  TokenType.EQUAL: '=',
  TokenType.AND: 'and',
  TokenType.OR: 'or',

  // Comparators
  TokenType.BANG_EQUAL: '!=',
  TokenType.EQUAL_EQUAL: '==',
  TokenType.GREATER: '>',
  TokenType.GREATER_EQUAL: '>=',
  TokenType.LESS: '<',
  TokenType.LESS_EQUAL: '<=',

  // Literals
  TokenType.IDENTIFIER: '<identifier>',
  TokenType.STRING: '<str>',
  TokenType.NUMBER: '<num>',
  TokenType.OBJECT: '<obj>',

  // Keywords
  TokenType.CLASS: 'class',
  TokenType.ELSE: 'else',
  TokenType.FALSE: 'false',
  TokenType.FOR: 'for',
  TokenType.FUN: 'fun',
  TokenType.IF: 'if',
  TokenType.NIL: 'nil',
  TokenType.PRINT: 'print',
  TokenType.RETURN: 'rtn',
  TokenType.SUPER: 'super',
  TokenType.THIS: 'this',
  TokenType.TRUE: 'true',
  TokenType.VAR: 'var',
  TokenType.WHILE: 'while',
  TokenType.IN: 'in',
  TokenType.BREAK: 'break',
  TokenType.CONTINUE: 'continue',

  // Editor syntactic sugar (dummy tokens)
  TokenType.COMMENT: '<//>',
  TokenType.ELIF: 'elif',
  TokenType.EOF: 'eof',
  TokenType.NLINE: 'nline',
  TokenType.ERROR: '<error>',
};

class Loc {
  final int i, j;

  const Loc(this.i, this.j);

  Loc get right => Loc(i, j + 1);

  Loc get left => Loc(i, j - 1);

  Loc get top => Loc(i - 1, 0);

  Loc get bottom => Loc(i + 1, 0);

  bool after(Loc other) {
    return other != null && (i > other.i || (i == other.i && j > other.j));
  }

  @override
  String toString() {
    return '$i:$j';
  }

  @override
  bool operator ==(other) {
    return (other is Loc) && other.i == i && other.j == j;
  }

  @override
  int get hashCode => i.hashCode ^ j.hashCode;
}

class Token {
  final TokenType type;
  final String str;
  final Loc loc;
  final Object val;

  const Token(this.type, {this.str, this.val, this.loc = const Loc(-1, -1)});

  Token copyWidth({TokenType type, String str, Loc loc, Object val}) {
    return Token(
      type ?? this.type,
      loc: loc ?? this.loc,
      str: str ?? this.str,
      val: val ?? this.val,
    );
  }

  bool strEqual(Token other) {
    return other.str == str;
  }

  String get info {
    return '<${toString()} at $loc>';
  }

  @override
  String toString() {
    if (!TOKEN_REPR.containsKey(type)) {
      throw Exception('Representation not found: $type');
    }
    if (type == TokenType.EOF) return '';
    if (type == TokenType.NUMBER ||
        type == TokenType.STRING ||
        type == TokenType.IDENTIFIER) return str;
    return TOKEN_REPR[type];
  }

  @override
  bool operator ==(o) =>
      o is Token && o.type == type && o.loc == loc && o.str == str;

  @override
  int get hashCode => type.hashCode ^ loc.hashCode ^ str.hashCode;
}

class Scanner {
  final debug = Debug(false);
  String source;
  int start = 0;
  int current = 0;
  Loc loc = Loc(0, 0);
  // Mark line as comment
  bool commentLine = false;
  bool traceScanner = false;

  Scanner._(this.source);

  static List<Token> scan(String source, {bool eof = true}) {
    final scanner = Scanner._(source);
    var tokens = <Token>[];
    do {
      tokens.add(scanner.scanToken());
    } while (tokens.last.type != TokenType.EOF);
    if (!eof) tokens.removeLast();
    if (scanner.traceScanner) {
      var line = -1;
      for (var token in tokens) {
        if (token.loc.i != line) {
          scanner.debug.stdwrite(sprintf('%4d ', [token.loc.i]));
          line = token.loc.i;
        } else {
          scanner.debug.stdwrite('   | ');
        }
        scanner.debug
            .stdwrite(sprintf("%2d '%s'\n", [token.type.index, token.str]));
      }
    }
    return tokens;
  }

  static bool isDigit(String c) {
    if (c == null) return false;
    return '0'.compareTo(c) <= 0 && '9'.compareTo(c) >= 0;
  }

  static bool isAlpha(String c) {
    if (c == null) return false;
    return ('a'.compareTo(c) <= 0 && 'z'.compareTo(c) >= 0) ||
        ('A'.compareTo(c) <= 0 && 'Z'.compareTo(c) >= 0) ||
        (c == '_');
  }

  void newLine() {
    loc = Loc(loc.i + 1, 0);
    commentLine = false;
  }

  bool get isAtEnd {
    return current >= source.length;
  }

  String get peek {
    if (isAtEnd) return null;
    return charAt(current);
  }

  String get peekNext {
    if (current >= source.length - 1) return null;
    return charAt(current + 1);
  }

  String charAt(int index) {
    return source.substring(index, index + 1);
  }

  String advance() {
    current++;
    return charAt(current - 1);
  }

  bool match(String expected) {
    if (isAtEnd) return false;
    if (peek != expected) return false;
    current++;
    return true;
  }

  Token makeToken(TokenType type) {
    var str = source.substring(start, current);
    if (type == TokenType.STRING) str = str.substring(1, str.length - 1);
    final token = Token(type, loc: loc, str: str);
    loc = Loc(loc.i, loc.j + 1);
    return token;
  }

  Token errorToken(String message) {
    return Token(TokenType.ERROR, loc: loc, str: message);
  }

  void skipWhitespace() {
    while (true) {
      final c = peek;
      switch (c) {
        case ' ':
        case '\r':
        case '\t':
          advance();
          break;

        case '\n':
          newLine();
          advance();
          break;

        default:
          return;
      }
    }
  }

  TokenType checkKeyword(int start, String rest, TokenType type) {
    if (current - this.start == start + rest.length &&
        source.substring(
                this.start + start, this.start + start + rest.length) ==
            rest) {
      return type;
    }
    return TokenType.IDENTIFIER;
  }

  TokenType identifierType() {
    switch (charAt(start)) {
      case 'a':
        return checkKeyword(1, 'nd', TokenType.AND);
      case 'b':
        return checkKeyword(1, 'reak', TokenType.BREAK);
      case 'c':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'l':
              return checkKeyword(2, 'ass', TokenType.CLASS);
            case 'o':
              return checkKeyword(2, 'ntinue', TokenType.CONTINUE);
          }
        }
        break;
      case 'e':
        return checkKeyword(1, 'lse', TokenType.ELSE);
      case 'f':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'a':
              return checkKeyword(2, 'lse', TokenType.FALSE);
            case 'o':
              return checkKeyword(2, 'r', TokenType.FOR);
            case 'u':
              return checkKeyword(2, 'n', TokenType.FUN);
          }
        }
        break;
      case 'i':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'f':
              return checkKeyword(2, '', TokenType.IF);
            case 'n':
              return checkKeyword(2, '', TokenType.IN);
          }
        }
        break;
      case 'n':
        return checkKeyword(1, 'il', TokenType.NIL);
      case 'o':
        return checkKeyword(1, 'r', TokenType.OR);
      case 'p':
        return checkKeyword(1, 'rint', TokenType.PRINT);
      case 'r':
        return checkKeyword(1, 'eturn', TokenType.RETURN);
      case 's':
        return checkKeyword(1, 'uper', TokenType.SUPER);
      case 't':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'h':
              return checkKeyword(2, 'is', TokenType.THIS);
            case 'r':
              return checkKeyword(2, 'ue', TokenType.TRUE);
          }
        }
        break;
      case 'v':
        return checkKeyword(1, 'ar', TokenType.VAR);
      case 'w':
        return checkKeyword(1, 'hile', TokenType.WHILE);
    }
    return TokenType.IDENTIFIER;
  }

  Token identifier() {
    while (isAlpha(peek) || isDigit(peek)) {
      advance();
    }

    return makeToken(identifierType());
  }

  Token number() {
    while (isDigit(peek)) {
      advance();
    }

    // Look for a fractional part.
    if (peek == '.' && isDigit(peekNext)) {
      // Consume the '.'.
      advance();

      while (isDigit(peek)) {
        advance();
      }
    }

    return makeToken(TokenType.NUMBER);
  }

  Token string() {
    while (peek != '"' && !isAtEnd) {
      if (peek == '\n') newLine();
      advance();
    }

    if (isAtEnd) return errorToken('Unterminated string.');

    // The closing quote.
    advance();
    return makeToken(TokenType.STRING);
  }

  Token comment() {
    while (peek != ' ' && peek != '\n' && !isAtEnd) {
      advance();
    }
    return makeToken(TokenType.COMMENT);
  }

  Token scanToken() {
    skipWhitespace();

    start = current;

    if (isAtEnd) return makeToken(TokenType.EOF);

    final c = advance();

    if (c == '/' && match('/')) {
      // Consume comment
      commentLine = true;
      return scanToken();
    }
    if (commentLine) return comment();
    if (isAlpha(c)) return identifier();
    if (isDigit(c)) return number();

    switch (c) {
      case '(':
        return makeToken(TokenType.LEFT_PAREN);
      case ')':
        return makeToken(TokenType.RIGHT_PAREN);
      case '[':
        return makeToken(TokenType.LEFT_BRACK);
      case ']':
        return makeToken(TokenType.RIGHT_BRACK);
      case '{':
        return makeToken(TokenType.LEFT_BRACE);
      case '}':
        return makeToken(TokenType.RIGHT_BRACE);
      case ';':
        return makeToken(TokenType.SEMICOLON);
      case ',':
        return makeToken(TokenType.COMMA);
      case '.':
        return makeToken(TokenType.DOT);
      case '-':
        return makeToken(TokenType.MINUS);
      case '+':
        return makeToken(TokenType.PLUS);
      case '/':
        return makeToken(TokenType.SLASH);
      case '*':
        return makeToken(TokenType.STAR);
      case '!':
        return makeToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
      case '=':
        return makeToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
      case '<':
        return makeToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
      case '>':
        return makeToken(
            match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
      case '"':
        return string();
      case ':':
        return makeToken(TokenType.COLUMN);
      case '%':
        return makeToken(TokenType.PERCENT);
      case '^':
        return makeToken(TokenType.CARET);
    }

    return errorToken('Unexpected character: $c.');
  }
}
