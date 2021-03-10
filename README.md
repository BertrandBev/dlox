# dlox

A fully featured VM written in dart

[![Website shields.io](https://img.shields.io/website-up-down-green-red/http/shields.io.svg)](https://bertrandbev.github.io/dlox/)
[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://raw.githubusercontent.com/BertrandBev/dlox/master/LICENSE)

<img src="https://raw.githubusercontent.com/BertrandBev/dlox/master/doc/images/fib.png" width="100%">

## Live editor

Head over to the [live editor](https://bertrandbev.github.io/dlox/#/) to play with dlox online!
The editor is based on the [code_text_field](https://pub.dev/packages/code_text_field) flutter widget, and has been compiled in javascript to run entirely in the browser. Indeed, both **dlox** and the **editor** 
 
## Implementation

dlox is a strict superset of the fantastic [lox](https://github.com/munificent/craftinginterpreters) language designed by Bob Nystrom.

## Features

### Common with lox VM
- Arithmetic operations
- Control flow
- Loops (for & while)
- Stack based local variables manipulation
- Scoping & closures
- Classes & inheritance

## Extensions
- Suport for list and maps
- Container traversal
- Usual mathematical functions
- Controlled execution

## Using the CLI

A repl can be spun up this way

```bash
# in dlox
dart lib/main.dart
> fun sum(a, b) { return a + b; }
> print sum(2, 3) # 5
```

Or a file can be executed

```bash
# in dlox
dart lib/main.dart editor/assets/snippets/fibonacci.lox
```

## Running the test suite

```bash
# in dlox
dart lib/test.dart
```