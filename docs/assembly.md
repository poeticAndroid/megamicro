Z28R assembly language
======================

Syntax
------
The source code is essentially parsed as a sequence of lines of words and numbers. All words are case-insensitive. All comments(starting with `;`) and non-alphanumeric characters(outside of strings) are ignored and used purely to make the code more readable.

Keywords
--------
All keywords must be the first word of a line.

### `ext` `name` `adr` `paramCount`
Register an external function located in memory `adr` as `name`.
```
ext printStr 0x5020 2
```

### `fn` `name` `params...`
Define a function called `name`. Ends with `end`.
```
fn pow a b
  vars z
  let z = 1
  while gt b > 0
    let z = mult z * a
    inc b += -1
  end
  return z
end
```

### `vars` `varnames...`
Declare some local variables and initialize them to zero.
```
  vars foo bar fizz buzz
```

### `data` `name`
Insert arbitrary data which can be referenced by `name`. Ends with `end`.
```
data greeting_str
  "Hello World!\x9b\n" 0
end
```

### `globals` `varnames...`
Declare some global variables and initialize them to zero.
```
globals foo bar fizz buzz
```

### `const` `name` `value`
Define a constant value.
```
const MEANING = 42
```

### `skipby` `bytes`
Insert a number of null bytes.
```
data greeting_str
  "Hello World!\x9b\n"
end
skipby 1
```

### `skipto` `pos`
Insert null bytes until `pos` is reached.
```
skipto 0x04
jump resethw
skipto 0x08
jump cls
skipto 0x0c
jump pset
```

### `while` `cond`
Repeat enclosed block of code as long as `cond` is nonzero. Ends with `end`.
```
  let i = 3
  while i
    printChr add 0x30 + i
    inc i += -1
  end
```

### `if` `cond`
Only execute block of code if `cond` is nonzero, otherwise jump to the matching `else`. Ends with `end`.
```
  if gt age > 18
    printStr oldEnough_str -1
  else
    printStr tooYoung_str -1
  end
```

### `let` `varname` `value`
Assign `value` to local or global `varname`.
```
  let four = add 2 + 2
```

### `inc` `varname` `delta`
Increment local or global `varname` by `delta`.
```
  inc fourMore += add 2 + 2
```

### `jump` `fnname`
Jump to function or address without starting a new stack.
```
jump main
```
