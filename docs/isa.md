CPU instruction set
===================

\      | 0x Flow                | 1x Memory                   | 2x Math         | 3x Logic
-------|------------------------|-----------------------------|-----------------|-------------
**x0** | halt                   | lit:val                     | add:n a b       | eq:bool a b
**x1** | sleep ms               | get:val index               | sub:n a b       | lt:bool a b
**x2** | vsync                  | stackptr:negadr             | mult:n a b      | gt:bool a b
**x3** |                        | memsize:bytes               | div:n a b       | eqz:bool a
**x4** | jump adr               |                             | rem:n a b       | and:n a b
**x5** | jumpifz adr val        | loadbit:val adr bit bitlen  |                 | or:n a b
**x6** |                        | load:val adr len            | itof:float int  | xor:n a b
**x7** | endcall                | loadu:val adr len           | uitof:float int | rot:n a b
**x8** | call:result adr params | drop val                    | fadd:n a b      | feq:bool a b
**x9** | return result          | set index val               | fsub:n a b      | flt:bool a b
**xA** | exec:err adr params    | inc index                   | fmult:n a b     | fgt:bool a b
**xB** | break                  | dec index                   | fdiv:n a b      |
**xC** | reset                  |                             | ffloor:n a      |
**xD** | absadr:absadr adr      | storebit adr bit bitlen val |                 |
**xE** | cpuver:ver             | store adr len val           |                 |
**xF** | noop                   |                             | ftoi:int float  |

 - All instructions are 1 byte, except for literals (read below)
 - Instruction parameters are popped in specified order and thus must be pushed in reverse order
 - All values are stored as little endian


Literals
--------
Specific values can be pushed onto the stack using literals.
Smaller numbers can be compressed into fewer bytes as described in the following table.

Type                    | Byte 0    | Byte 1    | Byte 2    | Byte 3    | Byte 4
------------------------|-----------|-----------|-----------|-----------|----------
32bit `lit`eral         | 0001 0000 | bbbb aaaa | dddd cccc | ffff eeee | hhhh gggg
4bit  positive relative | 0100 aaaa |           |           |           |
4bit  positive absolute | 0101 aaaa |           |           |           |
4bit  negative relative | 0110 aaaa |           |           |           |
4bit  negative absolute | 0111 aaaa |           |           |           |
12bit positive relative | 1000 aaaa | cccc bbbb |           |           |
12bit positive absolute | 1001 aaaa | cccc bbbb |           |           |
12bit negative relative | 1010 aaaa | cccc bbbb |           |           |
12bit negative absolute | 1011 aaaa | cccc bbbb |           |           |
20bit positive relative | 1100 aaaa | cccc bbbb | eeee dddd |           |
20bit positive absolute | 1101 aaaa | cccc bbbb | eeee dddd |           |
20bit negative relative | 1110 aaaa | cccc bbbb | eeee dddd |           |
20bit negative absolute | 1111 aaaa | cccc bbbb | eeee dddd |           |

 - `aaaa` = least significant nibble
 - `hhhh` = most significant nibble
 - `positive` = rest of nibbles are `0000`
 - `negative` = rest of nibbles are `1111`
 - `absolute` = second most significant bit (2^30) is flipped (for absolute addresses from either beginning(+) or end(-) of memory)

Instructions
------------
Each instruction will pop the required number of parameters off of the stack.
Some will push a result (prefixed in the documentation with a `:`.) back onto the stack.
`adr` parameters can be given as either a relative or absolute address.
Relative addresses are relative to the end of the instrction byte that operates on that address.

### `halt`
Pause the cpu indefinately (and open a debugger?).

### `sleep` `ms`
Pause the cpu for `ms` milliseconds.

### `vsync`
Pause the cpu until next screen refresh.

### `jump` `adr`
Jump to `adr`.

### `jumpifz` `adr` `val`
Jump to `adr` if `val` is zero.

### `endcall`
Clear the current stack and jump back to where the current function was called from.
If this brings us back to the safe state (if one is stored), the safe state will be cleared.

### `call` `:result?` `adr` `paramcount`
Start a new stack, move `paramcount` values over to the new stack in reverse order and jump to `adr`.
(Note that a `result` might not be returned.)

### `return` `result`
Like `endcall`, but push `result` onto the previous stack.

### `exec` `:err` `adr` `paramcount`
Like `call`, but store the current stack and program counter as a safe state to return to, if a `break` is invoked by a program or user interupt.
If there was already a safe state saved, this will just behave like a `call`.

### `break`
If a safe state is stored, this will `return` `-1` to the safe state and clear it.
If no safe state is stored, this will act as a `reset`.

### `reset`
Clear all stacks and safe state and set the program counter to the 32bit address
stored at 8 bytes before end of memory.

### `absadr` `:absadr` `adr`
Return `adr` as a positive absolute address.

### `cpuver` `:version`
Return the version number of the current cpu isa.

### `noop`
Waste one cpu cycle doing nothing.

### `lit` `:val`
Return and jump the next 4 bytes.

### `get` `:val` `index`
Return the value at the given `index` of the current stack.
Positive `index` counts from the top of the stack.
Negative `index` counts from the bottom of the stack, useful for local variables.

### `stackptr` `:negadr`
Return the negative absolute address of the stack pointer.

### `memsize` `:bytes`
Return the total amount of memory in bytes.

### `loadbit` `:val` `adr` `bit` `bitlen`
Read `bitlen` number of bits at `adr`, skipping `bit` bits, and return it as an unsigned integer.
`bitlen` cannot go beyond the end of the byte.

### `load` `:val` `adr` `len`
Read `len` number of bytes at `adr` and return it as a signed integer.

### `loadu` `:val` `adr` `len`
Read `len` number of bytes at `adr` and return it as an unsigned integer.

### `drop` `val`
Take a value from the stack and do nothing with it.

### `set` `index` `val`
Like `get`, but overwrites the value in the stack with `val` without returning it.

### `inc` `index`
Like `set`, but increments the integer in stack by 1.

### `dec` `index`
Like `set`, but decrements the integer in stack by 1.

### `storebit` `adr` `bit` `bitlen` `val`
Like `loadbit`, but stores `val` instead of reading and returning it.

### `store` `adr` `len` `val`
Like `load`, but stores `val` instead of reading and returning it.

### `add` `:n` `a` `b`
Return the result of adding `a` and `b`.

### `sub` `:n` `a` `b`
Return the result of subtracting `b` from `a`.

### `mult` `:n` `a` `b`
Return the result of multiplying `a` and `b`.

### `div` `:n` `a` `b`
Return the result of integer dividing `a` by `b`.

### `rem` `:n` `a` `b`
Return the remainder of integer dividing `a` by `b`.

### `itof` `:float` `int`
Return `int` as a floating point number.

### `uitof` `:float` `int`
Return `int` as a positive floating point number.

### `fadd` `:n` `a` `b`
Like `add`, but for floating point numbers.

### `fsub` `:n` `a` `b`
Like `sub`, but for floating point numbers.

### `fmult` `:n` `a` `b`
Like `mult`, but for floating point numbers.

### `fdiv` `:n` `a` `b`
Like `div`, but for floating point numbers. (and doing actual division, not integer division.)

### `ffloor` `:n` `a`
Return the largest integer that is not larger than `a`.

### `ftoi` `:int` `float`
Return `float` as an integer.

### `eq` `:bool` `a` `b`
Return 1 if `a` is equal to `b`, else return 0.

### `lt` `:bool` `a` `b`
Return 1 if `a` is less than `b`, else return 0.

### `gt` `:bool` `a` `b`
Return 1 if `a` is greater than `b`, else return 0.

### `eqz` `:bool` `a`
Return 1 if `a` is zero, else return 0.

### `and` `:n` `a` `b`
Return the result of bitwise `and`ing `a` and `b`.

### `or` `:n` `a` `b`
Return the result of bitwise `or`ing `a` and `b`.

### `xor` `:n` `a` `b`
Return the result of bitwise `xor`ing `a` and `b`.

### `rot` `:n` `a` `b`
Return the result of rotating `a` `b` bits to the left.

### `feq` `:bool` `a` `b`
Like `eq`, but for floating point numbers.

### `flt` `:bool` `a` `b`
Like `lt`, but for floating point numbers.

### `fgt` `:bool` `a` `b`
Like `gt`, but for floating point numbers.
