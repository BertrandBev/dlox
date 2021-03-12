import 'package:dlox/chunk.dart';
import 'package:dlox/debug.dart';
import 'package:dlox/error.dart';
import 'package:dlox/object.dart';
import 'package:dlox/parser.dart';
import 'package:dlox/scanner.dart';
import 'package:dlox/value.dart';

// TODO: Optimisation - bump
const UINT8_COUNT = 256;
const UINT8_MAX = UINT8_COUNT - 1;
const UINT16_MAX = 65535;

enum Precedence {
  NONE,
  ASSIGNMENT, // =
  OR, // or
  AND, // and
  EQUALITY, // == !=
  COMPARISON, // < > <= >=
  TERM, // + -
  FACTOR, // * / %
  POWER, // ^
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
  final Token name;
  int depth;
  bool isCaptured = false;

  Local(this.name, {this.depth = -1, this.isCaptured = false});

  bool get initialized {
    return depth >= 0;
  }
}

class Upvalue {
  Token name;
  int index;
  bool isLocal;

  Upvalue(this.name, this.index, this.isLocal);
}

enum FunctionType { FUNCTION, INITIALIZER, METHOD, SCRIPT }

class ClassCompiler {
  ClassCompiler enclosing;
  Token name;
  bool hasSuperclass;

  ClassCompiler(this.enclosing, this.name, this.hasSuperclass);
}

class CompilerResult {
  final ObjFunction function;
  final List<CompilerError> errors;
  final Debug debug;

  CompilerResult(this.function, this.errors, this.debug);
}

class Compiler {
  final Compiler enclosing;
  Parser parser;
  ClassCompiler currentClass;
  ObjFunction function;
  FunctionType type;
  final List<Local> locals = [];
  final List<Upvalue> upvalues = [];
  int scopeDepth = 0;
  // Degug tracer
  bool traceBytecode;

  Compiler._(
    this.type, {
    this.parser,
    this.enclosing,
    this.traceBytecode = false,
  }) {
    function = ObjFunction();
    if (enclosing != null) {
      assert(parser == null);
      parser = enclosing.parser;
      currentClass = enclosing.currentClass;
      scopeDepth = enclosing.scopeDepth + 1;
      traceBytecode = enclosing.traceBytecode;
    } else {
      assert(parser != null);
    }

    if (type != FunctionType.SCRIPT) {
      function.name = parser.previous.str;
    }

    final str = type != FunctionType.FUNCTION ? 'this' : '';
    final name = Token(TokenType.FUN, str: str);
    locals.add(Local(name, depth: 0));
  }

  static CompilerResult compile(List<Token> tokens,
      {bool silent = false, bool traceBytecode = false}) {
    // Compile script
    final parser = Parser(tokens, silent: silent);
    final compiler = Compiler._(
      FunctionType.SCRIPT,
      parser: parser,
      traceBytecode: traceBytecode,
    );
    parser.advance();
    while (!compiler.match(TokenType.EOF)) {
      compiler.declaration();
    }
    final function = compiler.endCompiler();
    return CompilerResult(
      function,
      parser.errors,
      parser.debug,
    );
  }

  ObjFunction endCompiler() {
    emitReturn();
    if (parser.errors.isEmpty && traceBytecode) {
      parser.debug.disassembleChunk(currentChunk, function.name ?? '<script>');
    }
    return function;
  }

  Chunk get currentChunk {
    return function.chunk;
  }

  void consume(TokenType type, String message) {
    parser.consume(type, message);
  }

  bool match(TokenType type) {
    final res = parser.match(type);
    return res;
  }

  bool matchPair(TokenType first, TokenType second) {
    final res = parser.matchPair(first, second);
    return res;
  }

  void emitOp(OpCode op) {
    emitByte(op.index);
  }

  void emitByte(int byte) {
    currentChunk.write(byte, parser.previous);
  }

  void emitBytes(int byte1, int byte2) {
    emitByte(byte1);
    emitByte(byte2);
  }

  void emitLoop(int loopStart) {
    emitOp(OpCode.LOOP);
    var offset = currentChunk.count - loopStart + 2;
    if (offset > UINT16_MAX) parser.error('Loop body too large');
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
      parser.error('Too many constants in one chunk');
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
      parser.error('Too much code to jump over');
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
        if (!local.initialized) {
          parser.error('Can\'t read local variable in its own initializer');
        }
        return i;
      }
    }
    return -1;
  }

  int addUpvalue(Token name, int index, bool isLocal) {
    assert(upvalues.length == function.upvalueCount);
    for (var i = 0; i < upvalues.length; i++) {
      var upvalue = upvalues[i];
      if (upvalue.index == index && upvalue.isLocal == isLocal) {
        return i;
      }
    }
    if (upvalues.length == UINT8_COUNT) {
      parser.error('Too many closure variables in function');
      return 0;
    }
    upvalues.add(Upvalue(name, index, isLocal));
    return function.upvalueCount++;
  }

  int resolveUpvalue(Token name) {
    if (enclosing == null) return -1;
    final localIdx = enclosing.resolveLocal(name);
    if (localIdx != -1) {
      final local = enclosing.locals[localIdx];
      local.isCaptured = true;
      return addUpvalue(local.name, localIdx, true);
    }
    final upvalueIdx = enclosing.resolveUpvalue(name);
    if (upvalueIdx != -1) {
      final upvalue = enclosing.upvalues[upvalueIdx];
      return addUpvalue(upvalue.name, upvalueIdx, false);
    }
    return -1;
  }

  void addLocal(Token name) {
    if (locals.length >= UINT8_COUNT) {
      parser.error('Too many local variables in function');
      return;
    }
    locals.add(Local(name));
  }

  void delareLocalVariable() {
    // Global variables are implicitly declared.
    if (scopeDepth == 0) return;
    var name = parser.previous;
    for (var i = locals.length - 1; i >= 0; i--) {
      var local = locals[i];
      if (local.depth != -1 && local.depth < scopeDepth) {
        break; // [negative]
      }
      if (identifiersEqual(name, local.name)) {
        parser.error('Already variable with this name in this scope');
      }
    }
    addLocal(name);
  }

  int parseVariable(String errorMessage) {
    consume(TokenType.IDENTIFIER, errorMessage);
    if (scopeDepth > 0) {
      delareLocalVariable();
      return 0;
    } else {
      return identifierConstant(parser.previous);
    }
  }

  void markLocalVariableInitialized() {
    if (scopeDepth == 0) return;
    locals.last.depth = scopeDepth;
  }

  void defineVariable(int global, {Token token, int peekDist = 0}) {
    final isLocal = scopeDepth > 0;
    if (isLocal) {
      markLocalVariableInitialized();
    } else {
      emitBytes(OpCode.DEFINE_GLOBAL.index, global);
    }
  }

  int argumentList() {
    var argCount = 0;
    if (!parser.check(TokenType.RIGHT_PAREN)) {
      do {
        expression();
        if (argCount == 255) {
          parser.error("Can't have more than 255 arguments");
        }
        argCount++;
      } while (match(TokenType.COMMA));
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after arguments");
    return argCount;
  }

  void _and(bool canAssign) {
    var endJump = emitJump(OpCode.JUMP_IF_FALSE);
    emitOp(OpCode.POP);
    parsePrecedence(Precedence.AND);
    patchJump(endJump);
  }

  void binary(bool canAssign) {
    var operatorType = parser.previous.type;
    final rule = getRule(operatorType);
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
      case TokenType.CARET:
        emitOp(OpCode.POW);
        break;
      case TokenType.PERCENT:
        emitOp(OpCode.MOD);
        break;
      default:
        return; // Unreachable.
    }
  }

  void call(bool canAssign) {
    var argCount = argumentList();
    emitBytes(OpCode.CALL.index, argCount);
  }

  void listIndex(bool canAssign) {
    var getRange = match(TokenType.COLUMN);
    // Left hand side operand
    if (getRange) {
      emitConstant(Nil);
    } else {
      expression();
      getRange = match(TokenType.COLUMN);
    }
    // Right hand side operand
    if (match(TokenType.RIGHT_BRACK)) {
      if (getRange) emitConstant(Nil);
    } else {
      if (getRange) expression();
      consume(TokenType.RIGHT_BRACK, "Expect ']' after list indexing");
    }
    // Emit operation
    if (getRange) {
      emitOp(OpCode.CONTAINER_GET_RANGE);
    } else if (canAssign && match(TokenType.EQUAL)) {
      expression();
      emitOp(OpCode.CONTAINER_SET);
    } else {
      emitOp(OpCode.CONTAINER_GET);
    }
  }

  void dot(bool canAssign) {
    consume(TokenType.IDENTIFIER, "Expect property name after '.'");
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
      case TokenType.NIL:
        emitOp(OpCode.NIL);
        break;
      case TokenType.FALSE:
        emitOp(OpCode.FALSE);
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
    consume(TokenType.RIGHT_PAREN, "Expect ')' after expression");
  }

  void listInit(bool canAssign) {
    var valCount = 0;
    if (!parser.check(TokenType.RIGHT_BRACK)) {
      expression();
      valCount += 1;
      if (parser.match(TokenType.COLUMN)) {
        expression();
        valCount = -1;
      } else {
        while (match(TokenType.COMMA)) {
          expression();
          valCount++;
        }
      }
    }
    consume(TokenType.RIGHT_BRACK, "Expect ']' after list initializer");
    if (valCount >= 0) {
      emitBytes(OpCode.LIST_INIT.index, valCount);
    } else {
      emitByte(OpCode.LIST_INIT_RANGE.index);
    }
  }

  void mapInit(bool canAssign) {
    var valCount = 0;
    if (!parser.check(TokenType.RIGHT_BRACE)) {
      do {
        expression();
        consume(TokenType.COLUMN, "Expect ':' between map key-value pairs");
        expression();
        valCount++;
      } while (match(TokenType.COMMA));
    }
    consume(TokenType.RIGHT_BRACE, "Expect '}' after map initializer");
    emitBytes(OpCode.MAP_INIT.index, valCount);
  }

  void number(bool canAssign) {
    final value = double.tryParse(parser.previous.str);
    if (value == null) {
      parser.error('Invalid number');
    } else {
      emitConstant(value);
    }
  }

  void object(bool canAssign) {
    final value = parser.previous.val;
    emitConstant(value);
  }

  void _or(bool canAssign) {
    var elseJump = emitJump(OpCode.JUMP_IF_FALSE);
    var endJump = emitJump(OpCode.JUMP);
    patchJump(elseJump);
    emitOp(OpCode.POP);
    parsePrecedence(Precedence.OR);
    patchJump(endJump);
  }

  void string(bool canAssign) {
    final str = parser.previous.str;
    emitConstant(str);
  }

  void getOrSetVariable(Token name, bool canAssign) {
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

    // Special mathematical assignment
    OpCode assignOp;
    if (canAssign) {
      if (matchPair(TokenType.PLUS, TokenType.EQUAL)) {
        assignOp = OpCode.ADD;
      } else if (matchPair(TokenType.MINUS, TokenType.EQUAL)) {
        assignOp = OpCode.SUBTRACT;
      } else if (matchPair(TokenType.STAR, TokenType.EQUAL)) {
        assignOp = OpCode.MULTIPLY;
      } else if (matchPair(TokenType.SLASH, TokenType.EQUAL)) {
        assignOp = OpCode.DIVIDE;
      } else if (matchPair(TokenType.PERCENT, TokenType.EQUAL)) {
        assignOp = OpCode.MOD;
      } else if (matchPair(TokenType.CARET, TokenType.EQUAL)) {
        assignOp = OpCode.POW;
      }
    }

    if (canAssign && (assignOp != null || match(TokenType.EQUAL))) {
      if (assignOp != null) emitBytes(getOp.index, arg);
      expression();
      if (assignOp != null) emitOp(assignOp);
      emitBytes(setOp.index, arg);
    } else {
      emitBytes(getOp.index, arg);
    }
  }

  void variable(bool canAssign) {
    getOrSetVariable(parser.previous, canAssign);
  }

  Token syntheticToken(String str) {
    return Token(TokenType.IDENTIFIER, str: str);
  }

  void _super(bool canAssign) {
    if (currentClass == null) {
      parser.error("Can't use 'super' outside of a class");
    } else if (!currentClass.hasSuperclass) {
      parser.error("Can't use 'super' in a class with no superclass");
    }

    consume(TokenType.DOT, "Expect '.' after 'super'");
    consume(TokenType.IDENTIFIER, 'Expect superclass method name');
    var name = identifierConstant(parser.previous);

    getOrSetVariable(syntheticToken('this'), false);
    if (match(TokenType.LEFT_PAREN)) {
      var argCount = argumentList();
      getOrSetVariable(syntheticToken('super'), false);
      emitBytes(OpCode.SUPER_INVOKE.index, name);
      emitByte(argCount);
    } else {
      getOrSetVariable(syntheticToken('super'), false);
      emitBytes(OpCode.GET_SUPER.index, name);
    }
  }

  void _this(bool canAssign) {
    if (currentClass == null) {
      parser.error("Can't use 'this' outside of a class");
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
        TokenType.LEFT_BRACE: ParseRule(mapInit, null, Precedence.NONE),
        TokenType.RIGHT_BRACE: ParseRule(null, null, Precedence.NONE),
        TokenType.LEFT_BRACK: ParseRule(listInit, listIndex, Precedence.CALL),
        TokenType.RIGHT_BRACK: ParseRule(null, null, Precedence.NONE),
        TokenType.COMMA: ParseRule(null, null, Precedence.NONE),
        TokenType.DOT: ParseRule(null, dot, Precedence.CALL),
        TokenType.MINUS: ParseRule(unary, binary, Precedence.TERM),
        TokenType.PLUS: ParseRule(null, binary, Precedence.TERM),
        TokenType.SEMICOLON: ParseRule(null, null, Precedence.NONE),
        TokenType.SLASH: ParseRule(null, binary, Precedence.FACTOR),
        TokenType.STAR: ParseRule(null, binary, Precedence.FACTOR),
        TokenType.CARET: ParseRule(null, binary, Precedence.POWER),
        TokenType.PERCENT: ParseRule(null, binary, Precedence.FACTOR),
        TokenType.COLUMN: ParseRule(null, null, Precedence.NONE),
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
        TokenType.OBJECT: ParseRule(object, null, Precedence.NONE),
        TokenType.AND: ParseRule(null, _and, Precedence.AND),
        TokenType.CLASS: ParseRule(null, null, Precedence.NONE),
        TokenType.ELSE: ParseRule(null, null, Precedence.NONE),
        TokenType.FALSE: ParseRule(literal, null, Precedence.NONE),
        TokenType.FOR: ParseRule(null, null, Precedence.NONE),
        TokenType.FUN: ParseRule(null, null, Precedence.NONE),
        TokenType.IF: ParseRule(null, null, Precedence.NONE),
        TokenType.NIL: ParseRule(literal, null, Precedence.NONE),
        TokenType.OR: ParseRule(null, _or, Precedence.OR),
        TokenType.PRINT: ParseRule(null, null, Precedence.NONE),
        TokenType.RETURN: ParseRule(null, null, Precedence.NONE),
        TokenType.SUPER: ParseRule(_super, null, Precedence.NONE),
        TokenType.THIS: ParseRule(_this, null, Precedence.NONE),
        TokenType.TRUE: ParseRule(literal, null, Precedence.NONE),
        TokenType.VAR: ParseRule(null, null, Precedence.NONE),
        TokenType.WHILE: ParseRule(null, null, Precedence.NONE),
        TokenType.BREAK: ParseRule(null, null, Precedence.NONE),
        TokenType.CONTINUE: ParseRule(null, null, Precedence.NONE),
        TokenType.ERROR: ParseRule(null, null, Precedence.NONE),
        TokenType.EOF: ParseRule(null, null, Precedence.NONE),
      };

  void parsePrecedence(Precedence precedence) {
    parser.advance();
    final prefixRule = getRule(parser.previous.type).prefix;
    if (prefixRule == null) {
      parser.error('Expect expression');
      return;
    }
    final canAssign = precedence.index <= Precedence.ASSIGNMENT.index;
    prefixRule(canAssign);

    while (precedence.index <= getRule(parser.current.type).precedence.index) {
      parser.advance();
      final infixRule = getRule(parser.previous.type).infix;
      infixRule(canAssign);
    }

    if (canAssign && match(TokenType.EQUAL)) {
      parser.error('Invalid assignment target');
    }
  }

  ParseRule getRule(TokenType type) {
    return rules[type];
  }

  void expression() {
    parsePrecedence(Precedence.ASSIGNMENT);
  }

  void block() {
    while (
        !parser.check(TokenType.RIGHT_BRACE) && !parser.check(TokenType.EOF)) {
      declaration();
    }
    consume(TokenType.RIGHT_BRACE, 'Unterminated block');
  }

  ObjFunction functionInner() {
    // beginScope(); // [no-end-scope]
    // not needeed because of wrapped compiler scope propagation

    // Compile the parameter list.
    // final functionToken = parser.previous;
    consume(TokenType.LEFT_PAREN, "Expect '(' after function name");
    var args = <Token>[];
    if (!parser.check(TokenType.RIGHT_PAREN)) {
      do {
        function.arity++;
        if (function.arity > 255) {
          parser.errorAtCurrent("Can't have more than 255 parameters");
        }
        parseVariable('Expect parameter name');
        markLocalVariableInitialized();
        args.add(parser.previous);
      } while (match(TokenType.COMMA));
    }
    for (var k = 0; k < args.length; k++) {
      defineVariable(0, token: args[k], peekDist: args.length - 1 - k);
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters");

    // The body.
    consume(TokenType.LEFT_BRACE, 'Expect function body');
    block();

    // Create the function object.
    return endCompiler();
  }

  ObjFunction functionBlock(FunctionType type) {
    final compiler = Compiler._(type, enclosing: this);
    final function = compiler.functionInner();
    emitBytes(OpCode.CLOSURE.index, makeConstant(function));
    for (var i = 0; i < compiler.upvalues.length; i++) {
      emitByte(compiler.upvalues[i].isLocal ? 1 : 0);
      emitByte(compiler.upvalues[i].index);
    }
    return function;
  }

  void method() {
    // Methods don't require
    // consume(TokenType.FUN, 'Expect function identifier');
    consume(TokenType.IDENTIFIER, 'Expect method name');
    final identifier = parser.previous;
    var constant = identifierConstant(identifier);
    var type = FunctionType.METHOD;
    if (identifier.str == 'init') {
      type = FunctionType.INITIALIZER;
    }
    functionBlock(type);
    emitBytes(OpCode.METHOD.index, constant);
  }

  void classDeclaration() {
    consume(TokenType.IDENTIFIER, 'Expect class name');
    final className = parser.previous;
    final nameConstant = identifierConstant(parser.previous);
    delareLocalVariable();

    emitBytes(OpCode.CLASS.index, nameConstant);
    defineVariable(nameConstant);

    final classCompiler = ClassCompiler(currentClass, parser.previous, false);
    currentClass = classCompiler;

    if (match(TokenType.LESS)) {
      consume(TokenType.IDENTIFIER, 'Expect superclass name');
      variable(false);

      if (identifiersEqual(className, parser.previous)) {
        parser.error("A class can't inherit from itself");
      }

      beginScope();
      addLocal(syntheticToken('super'));
      defineVariable(0);

      getOrSetVariable(className, false);
      emitOp(OpCode.INHERIT);
      classCompiler.hasSuperclass = true;
    }

    getOrSetVariable(className, false);
    consume(TokenType.LEFT_BRACE, 'Expect class body');
    while (
        !parser.check(TokenType.RIGHT_BRACE) && !parser.check(TokenType.EOF)) {
      method();
    }
    consume(TokenType.RIGHT_BRACE, 'Unterminated class body');
    emitOp(OpCode.POP);

    if (classCompiler.hasSuperclass) {
      endScope();
    }

    currentClass = currentClass.enclosing;
  }

  void funDeclaration() {
    var global = parseVariable('Expect function name');
    final token = parser.previous;
    markLocalVariableInitialized();
    functionBlock(FunctionType.FUNCTION);

    defineVariable(global, token: token);
  }

  void varDeclaration() {
    do {
      final global = parseVariable('Expect variable name');
      final token = parser.previous;
      if (match(TokenType.EQUAL)) {
        expression();
      } else {
        emitOp(OpCode.NIL);
      }
      defineVariable(global, token: token);
    } while (match(TokenType.COMMA));
    consume(TokenType.SEMICOLON, 'Expect a newline after variable declaration');
  }

  void expressionStatement() {
    expression();
    consume(TokenType.SEMICOLON, 'Expect a newline after expression');
    emitOp(OpCode.POP);
  }

  void forStatementCheck() {
    if (match(TokenType.LEFT_PAREN)) {
      legacyForStatement();
    } else {
      forStatement();
    }
  }

  void legacyForStatement() {
    // Deprecated
    beginScope();
    // consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'");
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
      consume(TokenType.SEMICOLON, "Expect ';' after loop condition");
      exitJump = emitJump(OpCode.JUMP_IF_FALSE);
      emitOp(OpCode.POP); // Condition.
    }

    if (!match(TokenType.RIGHT_PAREN)) {
      final bodyJump = emitJump(OpCode.JUMP);
      final incrementStart = currentChunk.count;
      expression();
      emitOp(OpCode.POP);
      consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses");
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

  void forStatement() {
    beginScope();
    // Key variable
    parseVariable('Expect variable name'); // Streamline those operations
    emitOp(OpCode.NIL);
    defineVariable(0, token: parser.previous); // Remove 0
    var stackIdx = locals.length - 1;
    if (match(TokenType.COMMA)) {
      // Value variable
      parseVariable('Expect variable name');
      emitOp(OpCode.NIL);
      defineVariable(0, token: parser.previous);
    } else {
      // Create dummy value slot
      addLocal(syntheticToken('_for_val_'));
      emitConstant(0); // Emit a zero to permute val & key
      markLocalVariableInitialized();
    }
    // Now add two dummy local variables. Idx & entries
    addLocal(syntheticToken('_for_idx_'));
    emitOp(OpCode.NIL);
    markLocalVariableInitialized();
    addLocal(syntheticToken('_for_iterable_'));
    emitOp(OpCode.NIL);
    markLocalVariableInitialized();
    // Rest of the loop
    consume(TokenType.IN, "Expect 'in' after loop variables");
    expression(); // Iterable
    // Iterator
    final loopStart = currentChunk.count;
    emitBytes(OpCode.CONTAINER_ITERATE.index, stackIdx);
    final exitJump = emitJump(OpCode.JUMP_IF_FALSE);
    emitOp(OpCode.POP); // Condition
    // Body
    statement();
    emitLoop(loopStart);
    // Exit
    patchJump(exitJump);
    emitOp(OpCode.POP); // Condition
    endScope();
  }

  void ifStatement() {
    // consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'");
    expression();
    // consume(TokenType.RIGHT_PAREN, "Expect ')' after condition"); // [paren]
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
    consume(TokenType.SEMICOLON, 'Expect a newline after value');
    emitOp(OpCode.PRINT);
  }

  void returnStatement() {
    // if (type == FunctionType.SCRIPT) {
    //   parser.error("Can't return from top-level code");
    // }
    if (match(TokenType.SEMICOLON)) {
      emitReturn();
    } else {
      if (type == FunctionType.INITIALIZER) {
        parser.error("Can't return a value from an initializer");
      }
      expression();
      consume(TokenType.SEMICOLON, 'Expect a newline after return value');
      emitOp(OpCode.RETURN);
    }
  }

  void whileStatement() {
    final loopStart = currentChunk.count;

    // consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'");
    expression();
    // consume(TokenType.RIGHT_PAREN, "Expect ')' after condition");

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
      }

      parser.advance();
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
      forStatementCheck();
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
}
