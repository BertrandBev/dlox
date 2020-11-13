enum TokenType {
  // Single-Stringacter tokens.
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

  // One or two Stringacter tokens.
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

  ERROR,
  EOF
}

class Token {
  TokenType type;
  String str;
  int start;
  int line;

  Token(this.type, this.str, this.start, this.line);

  bool strEqual(Token other) {
    return other.str == str;
  }
}

class Scanner {
  String source;
  int start = 0;
  int current = 0;
  int line = 1;

  Scanner(this.source);

  static bool isDigit(String c) {
    return '0'.compareTo(c) <= 0 && '9'.compareTo(c) >= 0;
  }

  static bool isAlpha(String c) {
    return ('a'.compareTo(c) <= 0 && 'z'.compareTo(c) >= 0) ||
        ('A'.compareTo(c) <= 0 && 'Z'.compareTo(c) >= 0) ||
        (c == '_');
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
    final str = source.substring(start, current);
    return Token(type, str, start, line);
  }

  Token errorToken(String message) {
    return Token(TokenType.ERROR, message, -1, line);
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
          line++;
          advance();
          break;

        case '/':
          if (peekNext == '/') {
            // A comment goes until the end of the line.
            while (peek != '\n' && !isAtEnd) {
              advance();
            }
          } else {
            return;
          }
          break;

        default:
          return;
      }
    }
  }

  TokenType checkKeyword(int start, int length, String rest, TokenType type) {
    if (current - this.start == start + length &&
        source.substring(this.start + start, this.start + start + length) ==
            rest) {
      return type;
    }
    return TokenType.IDENTIFIER;
  }

  TokenType identifierType() {
    switch (charAt(start)) {
      case 'a':
        return checkKeyword(1, 2, 'nd', TokenType.AND);
      case 'c':
        return checkKeyword(1, 4, 'lass', TokenType.CLASS);
      case 'e':
        return checkKeyword(1, 3, 'lse', TokenType.ELSE);
      case 'f':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'a':
              return checkKeyword(2, 3, 'lse', TokenType.FALSE);
            case 'o':
              return checkKeyword(2, 1, 'r', TokenType.FOR);
            case 'u':
              return checkKeyword(2, 1, 'n', TokenType.FUN);
          }
        }
        break;
      case 'i':
        return checkKeyword(1, 1, 'f', TokenType.IF);
      case 'n':
        return checkKeyword(1, 2, 'il', TokenType.NIL);
      case 'o':
        return checkKeyword(1, 1, 'r', TokenType.OR);
      case 'p':
        return checkKeyword(1, 4, 'rint', TokenType.PRINT);
      case 'r':
        return checkKeyword(1, 5, 'eturn', TokenType.RETURN);
      case 's':
        return checkKeyword(1, 4, 'uper', TokenType.SUPER);
      case 't':
        if (current - start > 1) {
          switch (charAt(start + 1)) {
            case 'h':
              return checkKeyword(2, 2, 'is', TokenType.THIS);
            case 'r':
              return checkKeyword(2, 2, 'ue', TokenType.TRUE);
          }
        }
        break;
      case 'v':
        return checkKeyword(1, 2, 'ar', TokenType.VAR);
      case 'w':
        return checkKeyword(1, 4, 'hile', TokenType.WHILE);
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
      if (peek == '\n') line++;
      advance();
    }

    if (isAtEnd) return errorToken('Unterminated string.');

    // The closing quote.
    advance();
    return makeToken(TokenType.STRING);
  }

  Token scanToken() {
    skipWhitespace();

    start = current;

    if (isAtEnd) return makeToken(TokenType.EOF);

    final c = advance();

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
    }

    return errorToken('Unexpected character: $c.');
  }
}

Scanner scanner;
