# dlox

A full-featured VM written in dart

[![Website shields.io](https://img.shields.io/website-up-down-green-red/http/shields.io.svg)](https://bertrandbev.github.io/dlox/)
[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://raw.githubusercontent.com/BertrandBev/dlox/master/LICENSE)

<img src="https://raw.githubusercontent.com/BertrandBev/dlox/master/doc/images/intro.gif" width="100%">

## Live editor

Head over to the [live editor](https://bertrandbev.github.io/dlox/) to play with dlox online!
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

## VM primer

The VM utilizes a stack to maintain all its local variables, function arguments, temporary operation results and return values. As its name suggets, a stack is a simple data structure supporting two main operations

- Pushing and element on top of it
- Popping its topmost element

Let's see how that works
Head over to the [editor](https://bertrandbev.github.io/dlox/) and enter the simple program

```javascript
var a = (1 + 2) * 3;
print a;
```

The top right panel shows the compiled bytecode
> On small screens, the compiler panel is hidden by default. Press the rightmost button on the top toolbar to show it

<img src="https://raw.githubusercontent.com/BertrandBev/dlox/master/doc/images/bytecode.png" width="60%">

Here's a breakdown of the compile program

```javascript
OP_CONSTANT '1'      // Push 1 on top of the stack
OP_CONSTANT '2'      // Push 2 on top of the stack
OP_ADD               // Pop the two last elements off the stack
                     // Add them and push the result on the stack
OP_CONSTANT '3'      // Push 3 on top of the stack
OP_MULTIPLY          // Pop the two last elements off the stack
                     // Multiply them and push the result on the stack
OP_DEFINE_GLOBAL 'a' // Pop the last stack entry
                     // Assign it to the global variable 'a'
OP_GET_GLOBAL 'a'    // Push the global variable 'a' on the stack
OP_PRINT             // Pop the last stack entry
                     // Print it
OP_NIL               // Push NIL on the stack
OP_RETURN            // Pop and return the last stack value
```

Wow, that seems a lot for such a simple program! Well, breaking it down in simple instructions allows the Virtual machine to execute it in a really streamlined fashion. All it needs to do is rip through the instructions one by one while carefully bookkeeping the global variables and managing the stack

Now run that nifty piece of code. The terminal output should print `9`. The bottom right panel shows the VM trace
> On small screens, the VM panel is hidden by default. Press the rightmost button on the bottom toolbar to show it

Here's the first few lines

<img src="https://raw.githubusercontent.com/BertrandBev/dlox/master/doc/images/vm_output.png" width="60%">

The VM trace shows instruction per instruction what the state of the stack is. We can see that is starts with the `<script>` object, and then proceeds to add `1 + 2`, and to mutiply the result by `3`, before popping it and assigning it to the global variable `'a'`.

For further in-depth exploration, make sure to play with the [examples](https://bertrandbev.github.io/dlox/) in the top left drawer and make your own!
Of course, Bob's [book](https://github.com/munificent/craftinginterpreters) explains everything in incredible details.

## Benchmark

To really unleash the VM thirst for code, disable the trace by swiching the performance button on the bottom toolbar.

<img src="https://raw.githubusercontent.com/BertrandBev/dlox/master/doc/images/benchmark.png">

That should make the execution significantly faster. The indicator on the left shows the average number of instructions per second

## Running the test suite

Should you feel like tweaking things to you liking, a little regression testing here and there never hurts

```bash
# in dlox
dart lib/test.dart
```