import 'dart:io';

import 'package:dlox/chunk.dart';
import 'package:dlox/common.dart';
import 'package:dlox/debug.dart';
import 'package:dlox/object.dart';
import 'package:dlox/scanner.dart';
import 'package:sprintf/sprintf.dart';

const UINT8_COUNT = 256;
const UINT8_MAX = UINT8_COUNT - 1;
const UINT16_MAX = 65535;

class Parser {
  Token current;
  Token previous;
  bool hadError;
  bool panicMode;
}

enum Precedence {
  NONE,
  ASSIGNMENT, // =
  OR, // or
  AND, // and
  EQUALITY, // == !=
  COMPARISON, // < > <= >=
  TERM, // + -
  FACTOR, // * /
  UNARY, // ! -
  CALL, // . ()
  PRIMARY
}

typedef ParseFn = void Function(bool canAssign);

class ParseRule {
  ParseFn prefix;
  ParseFn infix;
  Precedence precedence;

  ParseRule(this.prefix, this.infix, this.precedence);
}

class Local {
  Token name;
  int depth = 0;
  bool isCaptured = false;

  Local(this.name, {this.depth = 0, this.isCaptured = false});
}

class Upvalue {
  int index;
  bool isLocal;

  Upvalue(this.index, this.isLocal);
}

enum FunctionType { FUNCTION, INITIALIZER, METHOD, SCRIPT }

class ClassCompiler {
  ClassCompiler enclosing;
  Token name;
  bool hasSuperclass;

  ClassCompiler(this.enclosing, this.name, this.hasSuperclass);
}

class Compiler {
  // TODO: create wrapper (TODO: abstract those fields out)
  static Parser parser;
  static ClassCompiler currentClass;

  //
  Compiler enclosing;
  ObjFunction function = ObjFunction();
  FunctionType type;

  List<Local> locals = <Local>[];
  List<Upvalue> upvalues = <Upvalue>[];
  // int localCount = 0;
  int scopeDepth = 0;

  Compiler(this.type, [Compiler parent]) {
    enclosing = parent;

    if (type != FunctionType.SCRIPT) {
      function.name = parser.previous.str;
    }

    final str = type != FunctionType.FUNCTION ? 'this' : '';
    final name = Token(TokenType.FUN, str, 0, 0);
    locals.add(Local(name));
  }

  ObjFunction endCompiler() {
    emitReturn();
    if (DEBUG_PRINT_CODE) {
      if (!parser.hadError) {
        disassembleChunk(currentChunk, function.name ?? '<script>');
      }
    }
    return function;
  }

  Chunk get currentChunk {
    return function.chunk;
  }

  void emitOp(OpCode op) {
    emitByte(op.index);
  }

  void emitByte(int byte) {
    currentChunk.write(byte, parser.previous.line);
  }

  void emitBytes(int byte1, int byte2) {
    emitByte(byte1);
    emitByte(byte2);
  }

  void emitLoop(int loopStart) {
    emitOp(OpCode.LOOP);
    var offset = currentChunk.count - loopStart + 2;
    if (offset > UINT16_MAX) error('Loop body too large.');
    emitByte((offset >> 8) & 0xff);
    emitByte(offset & 0xff);
  }

  int emitJump(OpCode instruction) {
    emitOp(instruction);
    emitByte(0xff);
    emitByte(0xff);
    return currentChunk.count - 2;
  }

  void emitReturn() {
    if (type == FunctionType.INITIALIZER) {
      emitBytes(OpCode.GET_LOCAL.index, 0);
    } else {
      emitOp(OpCode.NIL);
    }

    emitOp(OpCode.RETURN);
  }

  int makeConstant(Object value) {
    var constant = currentChunk.addConstant(value);
    if (constant > UINT8_MAX) {
      error('Too many constants in one chunk.');
      return 0;
    }
    return constant;
  }

  void emitConstant(Object value) {
    emitBytes(OpCode.CONSTANT.index, makeConstant(value));
  }

  void patchJump(int offset) {
    // -2 to adjust for the bytecode for the jump offset itself.
    var jump = currentChunk.count - offset - 2;
    if (jump > UINT16_MAX) {
      error('Too much code to jump over.');
    }
    currentChunk.code[offset] = (jump >> 8) & 0xff;
    currentChunk.code[offset + 1] = jump & 0xff;
  }

  void beginScope() {
    scopeDepth++;
  }

  void endScope() {
    scopeDepth--;
    while (locals.isNotEmpty && locals.last.depth > scopeDepth) {
      if (locals.last.isCaptured) {
        emitOp(OpCode.CLOSE_UPVALUE);
      } else {
        emitOp(OpCode.POP);
      }
      locals.removeLast();
    }
  }

  int identifierConstant(Token name) {
    return makeConstant(name.str);
  }

  bool identifiersEqual(Token a, Token b) {
    return a.strEqual(b);
  }

  int resolveLocal(Token name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      var local = locals[i];
      if (identifiersEqual(name, local.name)) {
        if (local.depth == -1) {
          error('Can\'t read local variable in its own initializer.');
        }
        return i;
      }
    }
    return -1;
  }

  int addUpvalue(int index, bool isLocal) {
    assert(upvalues.length == function.upvalueCount);
    for (var i = 0; i < upvalues.length; i++) {
      var upvalue = upvalues[i];
      if (upvalue.index == index && upvalue.isLocal == isLocal) {
        return i;
      }
    }
    if (upvalues.length == UINT8_COUNT) {
      error('Too many closure variables in function.');
      return 0;
    }
    upvalues.add(Upvalue(index, isLocal));
    return function.upvalueCount++;
  }

  int resolveUpvalue(Token name) {
    if (enclosing == null) return -1;
    var local = enclosing.resolveLocal(name);
    if (local != -1) {
      enclosing.locals[local].isCaptured = true;
      return addUpvalue(local, true);
    }
    var upvalue = enclosing.resolveUpvalue(name);
    if (upvalue != -1) {
      return addUpvalue(upvalue, false);
    }
    return -1;
  }

  void addLocal(Token name) {
    if (locals.length >= UINT8_COUNT) {
      error('Too many local variables in function.');
      return;
    }
    locals.add(Local(name, depth: -1, isCaptured: false));
  }

  void declareVariable() {
    // Global variables are implicitly declared.
    if (scopeDepth == 0) return;
    var name = parser.previous;
    for (var i = locals.length - 1; i >= 0; i--) {
      var local = locals[i];
      if (local.depth != -1 && local.depth < scopeDepth) {
        break; // [negative]
      }
      if (identifiersEqual(name, local.name)) {
        error('Already variable with this name in this scope.');
      }
    }
    addLocal(name);
  }

  int parseVariable(String errorMessage) {
    consume(TokenType.IDENTIFIER, errorMessage);
    declareVariable();
    if (scopeDepth > 0) return 0;

    return identifierConstant(parser.previous);
  }

  void markInitialized() {
    if (scopeDepth == 0) return;
    locals.last.depth = scopeDepth;
  }

  void defineVariable(int global) {
    if (scopeDepth > 0) {
      markInitialized();
      return;
    }
    emitBytes(OpCode.DEFINE_GLOBAL.index, global);
  }

  int argumentList() {
    var argCount = 0;
    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        expression();
        if (argCount == 255) {
          error("Can't have more than 255 arguments.");
        }
        argCount++;
      } while (match(TokenType.COMMA));
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after arguments.");
    return argCount;
  }

  void and_(bool canAssign) {
    var endJump = emitJump(OpCode.JUMP_IF_FALSE);
    emitOp(OpCode.POP);
    parsePrecedence(Precedence.AND);
    patchJump(endJump);
  }

  void binary(bool canAssign) {
    var operatorType = parser.previous.type;
    ParseRule rule = getRule(operatorType);
    parsePrecedence(Precedence.values[rule.precedence.index + 1]);

    // Emit the operator instruction.
    switch (operatorType) {
      case TokenType.BANG_EQUAL:
        emitBytes(OpCode.EQUAL.index, OpCode.NOT.index);
        break;
      case TokenType.EQUAL_EQUAL:
        emitOp(OpCode.EQUAL);
        break;
      case TokenType.GREATER:
        emitOp(OpCode.GREATER);
        break;
      case TokenType.GREATER_EQUAL:
        emitBytes(OpCode.LESS.index, OpCode.NOT.index);
        break;
      case TokenType.LESS:
        emitOp(OpCode.LESS);
        break;
      case TokenType.LESS_EQUAL:
        emitBytes(OpCode.GREATER.index, OpCode.NOT.index);
        break;
      case TokenType.PLUS:
        emitOp(OpCode.ADD);
        break;
      case TokenType.MINUS:
        emitOp(OpCode.SUBTRACT);
        break;
      case TokenType.STAR:
        emitOp(OpCode.MULTIPLY);
        break;
      case TokenType.SLASH:
        emitOp(OpCode.DIVIDE);
        break;
      default:
        return; // Unreachable.
    }
  }

  void call(bool canAssign) {
    var argCount = argumentList();
    emitBytes(OpCode.CALL.index, argCount);
  }

  void dot(bool canAssign) {
    consume(TokenType.IDENTIFIER, "Expect property name after '.'.");
    var name = identifierConstant(parser.previous);
    if (canAssign && match(TokenType.EQUAL)) {
      expression();
      emitBytes(OpCode.SET_PROPERTY.index, name);
    } else if (match(TokenType.LEFT_PAREN)) {
      var argCount = argumentList();
      emitBytes(OpCode.INVOKE.index, name);
      emitByte(argCount);
    } else {
      emitBytes(OpCode.GET_PROPERTY.index, name);
    }
  }

  void literal(bool canAssign) {
    switch (parser.previous.type) {
      case TokenType.FALSE:
        emitOp(OpCode.FALSE);
        break;
      case TokenType.NIL:
        emitOp(OpCode.NIL);
        break;
      case TokenType.TRUE:
        emitOp(OpCode.TRUE);
        break;
      default:
        return; // Unreachable.
    }
  }

  void grouping(bool canAssign) {
    expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
  }

  void number(bool canAssign) {
    var value = double.parse(parser.previous.str);
    emitConstant(value);
  }

  void or_(bool canAssign) {
    var elseJump = emitJump(OpCode.JUMP_IF_FALSE);
    var endJump = emitJump(OpCode.JUMP);
    patchJump(elseJump);
    emitOp(OpCode.POP);
    parsePrecedence(Precedence.OR);
    patchJump(endJump);
  }

  void string(bool canAssign) {
    final str = parser.previous.str;
    emitConstant(str.substring(1, str.length - 1));
  }

  void namedVariable(Token name, bool canAssign) {
    OpCode getOp, setOp;
    var arg = resolveLocal(name);
    if (arg != -1) {
      getOp = OpCode.GET_LOCAL;
      setOp = OpCode.SET_LOCAL;
    } else if ((arg = resolveUpvalue(name)) != -1) {
      getOp = OpCode.GET_UPVALUE;
      setOp = OpCode.SET_UPVALUE;
    } else {
      arg = identifierConstant(name);
      getOp = OpCode.GET_GLOBAL;
      setOp = OpCode.SET_GLOBAL;
    }

    if (canAssign && match(TokenType.EQUAL)) {
      expression();
      emitBytes(setOp.index, arg);
    } else {
      emitBytes(getOp.index, arg);
    }
  }

  void variable(bool canAssign) {
    namedVariable(parser.previous, canAssign);
  }

  Token syntheticToken(String text) {
    return Token(TokenType.IDENTIFIER, text, 0, 0);
  }

  void super_(bool canAssign) {
    if (currentClass == null) {
      error("Can't use 'super' outside of a class.");
    } else if (!currentClass.hasSuperclass) {
      error("Can't use 'super' in a class with no superclass.");
    }

    consume(TokenType.DOT, "Expect '.' after 'super'.");
    consume(TokenType.IDENTIFIER, 'Expect superclass method name.');
    var name = identifierConstant(parser.previous);

    namedVariable(syntheticToken('this'), false);
    if (match(TokenType.LEFT_PAREN)) {
      var argCount = argumentList();
      namedVariable(syntheticToken('super'), false);
      emitBytes(OpCode.SUPER_INVOKE.index, name);
      emitByte(argCount);
    } else {
      namedVariable(syntheticToken('super'), false);
      emitBytes(OpCode.GET_SUPER.index, name);
    }
  }

  void this_(bool canAssign) {
    if (currentClass == null) {
      error("Can't use 'this' outside of a class.");
      return;
    }
    variable(false);
  }

  void unary(bool canAssign) {
    var operatorType = parser.previous.type;
    parsePrecedence(Precedence.UNARY);
    switch (operatorType) {
      case TokenType.BANG:
        emitOp(OpCode.NOT);
        break;
      case TokenType.MINUS:
        emitOp(OpCode.NEGATE);
        break;
      default:
        return; // Unreachable.
    }
  }

  Map<TokenType, ParseRule> get rules => {
        TokenType.LEFT_PAREN: ParseRule(grouping, call, Precedence.CALL),
        TokenType.RIGHT_PAREN: ParseRule(null, null, Precedence.NONE),
        TokenType.LEFT_BRACE: ParseRule(null, null, Precedence.NONE),
        TokenType.RIGHT_BRACE: ParseRule(null, null, Precedence.NONE),
        TokenType.COMMA: ParseRule(null, null, Precedence.NONE),
        TokenType.DOT: ParseRule(null, dot, Precedence.CALL),
        TokenType.MINUS: ParseRule(unary, binary, Precedence.TERM),
        TokenType.PLUS: ParseRule(null, binary, Precedence.TERM),
        TokenType.SEMICOLON: ParseRule(null, null, Precedence.NONE),
        TokenType.SLASH: ParseRule(null, binary, Precedence.FACTOR),
        TokenType.STAR: ParseRule(null, binary, Precedence.FACTOR),
        TokenType.BANG: ParseRule(unary, null, Precedence.NONE),
        TokenType.BANG_EQUAL: ParseRule(null, binary, Precedence.EQUALITY),
        TokenType.EQUAL: ParseRule(null, null, Precedence.NONE),
        TokenType.EQUAL_EQUAL: ParseRule(null, binary, Precedence.EQUALITY),
        TokenType.GREATER: ParseRule(null, binary, Precedence.COMPARISON),
        TokenType.GREATER_EQUAL: ParseRule(null, binary, Precedence.COMPARISON),
        TokenType.LESS: ParseRule(null, binary, Precedence.COMPARISON),
        TokenType.LESS_EQUAL: ParseRule(null, binary, Precedence.COMPARISON),
        TokenType.IDENTIFIER: ParseRule(variable, null, Precedence.NONE),
        TokenType.STRING: ParseRule(string, null, Precedence.NONE),
        TokenType.NUMBER: ParseRule(number, null, Precedence.NONE),
        TokenType.AND: ParseRule(null, and_, Precedence.AND),
        TokenType.CLASS: ParseRule(null, null, Precedence.NONE),
        TokenType.ELSE: ParseRule(null, null, Precedence.NONE),
        TokenType.FALSE: ParseRule(literal, null, Precedence.NONE),
        TokenType.FOR: ParseRule(null, null, Precedence.NONE),
        TokenType.FUN: ParseRule(null, null, Precedence.NONE),
        TokenType.IF: ParseRule(null, null, Precedence.NONE),
        TokenType.NIL: ParseRule(literal, null, Precedence.NONE),
        TokenType.OR: ParseRule(null, or_, Precedence.OR),
        TokenType.PRINT: ParseRule(null, null, Precedence.NONE),
        TokenType.RETURN: ParseRule(null, null, Precedence.NONE),
        TokenType.SUPER: ParseRule(super_, null, Precedence.NONE),
        TokenType.THIS: ParseRule(this_, null, Precedence.NONE),
        TokenType.TRUE: ParseRule(literal, null, Precedence.NONE),
        TokenType.VAR: ParseRule(null, null, Precedence.NONE),
        TokenType.WHILE: ParseRule(null, null, Precedence.NONE),
        TokenType.ERROR: ParseRule(null, null, Precedence.NONE),
        TokenType.EOF: ParseRule(null, null, Precedence.NONE),
      };

  void parsePrecedence(Precedence precedence) {
    advance();
    final prefixRule = getRule(parser.previous.type).prefix;
    if (prefixRule == null) {
      error('Expect expression.');
      return;
    }
    final canAssign = precedence.index <= Precedence.ASSIGNMENT.index;
    prefixRule(canAssign);

    while (precedence.index <= getRule(parser.current.type).precedence.index) {
      advance();
      final infixRule = getRule(parser.previous.type).infix;
      infixRule(canAssign);
    }

    if (canAssign && match(TokenType.EQUAL)) {
      error('Invalid assignment target.');
    }
  }

  ParseRule getRule(TokenType type) {
    return rules[type];
  }

  void expression() {
    parsePrecedence(Precedence.ASSIGNMENT);
  }

  void block() {
    while (!check(TokenType.RIGHT_BRACE) && !check(TokenType.EOF)) {
      declaration();
    }
    consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");
  }

  // TODO: handle more gracefully (upon creation)
  ObjFunction functionInner() {
    beginScope(); // [no-end-scope]

    // Compile the parameter list.
    consume(TokenType.LEFT_PAREN, "Expect '(' after function name.");
    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        function.arity++;
        if (function.arity > 255) {
          errorAtCurrent("Can't have more than 255 parameters.");
        }

        var paramConstant = parseVariable('Expect parameter name.');
        defineVariable(paramConstant);
      } while (match(TokenType.COMMA));
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");

    // The body.
    consume(TokenType.LEFT_BRACE, "Expect '{' before function body.");
    block();

    // Create the function object.
    return endCompiler();
  }

  void functionBlock(FunctionType type) {
    final compiler = Compiler(type, this);
    final function = compiler.functionInner();
    emitBytes(OpCode.CLOSURE.index, makeConstant(function));
    for (var i = 0; i < compiler.upvalues.length; i++) {
      emitByte(compiler.upvalues[i].isLocal ? 1 : 0);
      emitByte(compiler.upvalues[i].index);
    }
  }

  void method() {
    consume(TokenType.IDENTIFIER, 'Expect method name.');
    var constant = identifierConstant(parser.previous);
    var type = FunctionType.METHOD;
    if (parser.previous.str == 'init') {
      type = FunctionType.INITIALIZER;
    }
    functionBlock(type);
    emitBytes(OpCode.METHOD.index, constant);
  }

  void classDeclaration() {
    consume(TokenType.IDENTIFIER, 'Expect class name.');
    final className = parser.previous;
    final nameConstant = identifierConstant(parser.previous);
    declareVariable();

    emitBytes(OpCode.CLASS.index, nameConstant);
    defineVariable(nameConstant);

    final classCompiler = ClassCompiler(currentClass, parser.previous, false);
    currentClass = classCompiler;

    if (match(TokenType.LESS)) {
      consume(TokenType.IDENTIFIER, 'Expect superclass name.');
      variable(false);

      if (identifiersEqual(className, parser.previous)) {
        error("A class can't inherit from itself.");
      }

      beginScope();
      addLocal(syntheticToken('super'));
      defineVariable(0);

      namedVariable(className, false);
      emitOp(OpCode.INHERIT);
      classCompiler.hasSuperclass = true;
    }

    namedVariable(className, false);
    consume(TokenType.LEFT_BRACE, "Expect '{' before class body.");
    while (!check(TokenType.RIGHT_BRACE) && !check(TokenType.EOF)) {
      method();
    }
    consume(TokenType.RIGHT_BRACE, "Expect '}' after class body.");
    emitOp(OpCode.POP);

    if (classCompiler.hasSuperclass) {
      endScope();
    }

    currentClass = currentClass.enclosing;
  }

  void funDeclaration() {
    var global = parseVariable('Expect function name.');
    markInitialized();
    functionBlock(FunctionType.FUNCTION);
    defineVariable(global);
  }

  void varDeclaration() {
    var global = parseVariable('Expect variable name.');

    if (match(TokenType.EQUAL)) {
      expression();
    } else {
      emitOp(OpCode.NIL);
    }
    consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");

    defineVariable(global);
  }

  void expressionStatement() {
    expression();
    consume(TokenType.SEMICOLON, "Expect ';' after expression.");
    emitOp(OpCode.POP);
  }

  void forStatement() {
    beginScope();
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");
    if (match(TokenType.SEMICOLON)) {
      // No initializer.
    } else if (match(TokenType.VAR)) {
      varDeclaration();
    } else {
      expressionStatement();
    }

    var loopStart = currentChunk.count;
    var exitJump = -1;
    if (!match(TokenType.SEMICOLON)) {
      expression();
      consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");
      exitJump = emitJump(OpCode.JUMP_IF_FALSE);
      emitOp(OpCode.POP); // Condition.
    }

    if (!match(TokenType.RIGHT_PAREN)) {
      final bodyJump = emitJump(OpCode.JUMP);
      final incrementStart = currentChunk.count;
      expression();
      emitOp(OpCode.POP);
      consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");
      emitLoop(loopStart);
      loopStart = incrementStart;
      patchJump(bodyJump);
    }

    statement();
    emitLoop(loopStart);
    if (exitJump != -1) {
      patchJump(exitJump);
      emitOp(OpCode.POP); // Condition.
    }
    endScope();
  }

  void ifStatement() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.");
    expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after condition."); // [paren]
    final thenJump = emitJump(OpCode.JUMP_IF_FALSE);
    emitOp(OpCode.POP);
    statement();
    final elseJump = emitJump(OpCode.JUMP);
    patchJump(thenJump);
    emitOp(OpCode.POP);
    if (match(TokenType.ELSE)) statement();
    patchJump(elseJump);
  }

  void printStatement() {
    expression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    emitOp(OpCode.PRINT);
  }

  void returnStatement() {
    if (type == FunctionType.SCRIPT) {
      error("Can't return from top-level code.");
    }
    if (match(TokenType.SEMICOLON)) {
      emitReturn();
    } else {
      if (type == FunctionType.INITIALIZER) {
        error("Can't return a value from an initializer.");
      }
      expression();
      consume(TokenType.SEMICOLON, "Expect ';' after return value.");
      emitOp(OpCode.RETURN);
    }
  }

  void whileStatement() {
    final loopStart = currentChunk.count;

    consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");
    expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.");

    final exitJump = emitJump(OpCode.JUMP_IF_FALSE);

    emitOp(OpCode.POP);
    statement();

    emitLoop(loopStart);

    patchJump(exitJump);
    emitOp(OpCode.POP);
  }

  void synchronize() {
    parser.panicMode = false;

    while (parser.current.type != TokenType.EOF) {
      if (parser.previous.type == TokenType.SEMICOLON) return;

      switch (parser.current.type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;

        default:
          // Do nothing.
          ;
      }

      advance();
    }
  }

  void declaration() {
    if (match(TokenType.CLASS)) {
      classDeclaration();
    } else if (match(TokenType.FUN)) {
      funDeclaration();
    } else if (match(TokenType.VAR)) {
      varDeclaration();
    } else {
      statement();
    }
    if (parser.panicMode) synchronize();
  }

  void statement() {
    if (match(TokenType.PRINT)) {
      printStatement();
    } else if (match(TokenType.FOR)) {
      forStatement();
    } else if (match(TokenType.IF)) {
      ifStatement();
    } else if (match(TokenType.RETURN)) {
      returnStatement();
    } else if (match(TokenType.WHILE)) {
      whileStatement();
    } else if (match(TokenType.LEFT_BRACE)) {
      beginScope();
      block();
      endScope();
    } else {
      expressionStatement();
    }
  }

  // STATIC FIELD METHODS
  static ObjFunction compile(String source) {
    scanner = Scanner(source);
    // Print scanner result

    if (DEBUG_TRACE_SCANNER) {
      var line = -1;
      for (;;) {
        final token = scanner.scanToken();
        if (token.line != line) {
          stdout.write(sprintf('%4d ', [token.line]));
          line = token.line;
        } else {
          stdout.write('   | ');
        }
        stdout.write(sprintf("%2d '%s'\n", [token.type.index, token.str]));
        if (token.type == TokenType.EOF) break;
      }
      return null;
    }

    parser = Parser();
    final compiler = Compiler(FunctionType.SCRIPT);
    parser.hadError = false;
    parser.panicMode = false;
    // TODO: extract in compiler
    advance();
    while (!match(TokenType.EOF)) {
      compiler.declaration();
    }
    final function = compiler.endCompiler();
    return parser.hadError ? null : function;
  }

  static void errorAt(Token token, String message) {
    if (parser.panicMode) return;
    parser.panicMode = true;

    stderr.write('[line ${token.line}] Error');

    if (token.type == TokenType.EOF) {
      stderr.write(' at end');
    } else if (token.type == TokenType.ERROR) {
      // Nothing.
    } else {
      stderr.write(' at \'${token.str}\'');
    }

    stderr.write(': $message\n');
    parser.hadError = true;
  }

  static void error(String message) {
    errorAt(parser.previous, message);
  }

  static void errorAtCurrent(String message) {
    errorAt(parser.current, message);
  }

  static void advance() {
    parser.previous = parser.current;
    for (;;) {
      parser.current = scanner.scanToken();
      if (parser.current.type != TokenType.ERROR) break;
      errorAtCurrent(parser.current.str);
    }
  }

  static void consume(TokenType type, String message) {
    if (parser.current.type == type) {
      advance();
      return;
    }
    errorAtCurrent(message);
  }

  static bool check(TokenType type) {
    return parser.current.type == type;
  }

  static bool match(TokenType type) {
    if (!check(type)) return false;
    advance();
    return true;
  }
}
