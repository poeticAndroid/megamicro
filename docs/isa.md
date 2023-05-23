CPU instruction set
===================
`cpuver = 6`

\      | 0x Flow                                              | 1x Memory                                   | 2x Math                             | 3x Logic
-------|------------------------------------------------------|---------------------------------------------|-------------------------------------|-----------------------------
**x0** | [halt](#halt)                                        | [lit](#literals):val                        | [add](#addn-a-b):n a b              | [eq](#eqbool-a-b):bool a b
**x1** | [sleep](#sleep-ms) ms                                | [get](#getval-index):val index              | [sub](#subn-a-b):n a b              | [lt](#ltbool-a-b):bool a b
**x2** | [vsync](#vsync)                                      | [stackptr](#stackptrnegadr):negadr          | [mult](#multn-a-b):n a b            | [gt](#gtbool-a-b):bool a b
**x3** |                                                      | [load](#loadval-adr):val adr                | [div](#divn-a-b):n a b              | [eqz](#eqzbool-a):bool a
**x4** | [jump](#jump-adr) adr                                | [load8u](#load8uval-adr):val adr            | [rem](#remn-a-b):n a b              | [and](#andn-a-b):n a b
**x5** | [jumpifz](#jumpifz-adr-val) adr val                  | [setread](#setread-adr-chsize) adr chsize   | [load8s](#load8sval-adr):val adr    | [or](#orn-a-b):n a b
**x6** |                                                      | [skipread](#skipread-chunks) chunks         | [load16s](#load16sval-adr):val adr  | [xor](#xorn-a-b):n a b
**x7** | [endcall](#endcall)                                  | [read](#readval):val                        | [itof](#itoffloat-int):float int    | [rot](#rotn-a-b):n a b
**x8** | [call](#callresult-adr-paramcount):result adr params | [drop](#drop-val) val                       | [fadd](#faddn-a-b):n a b            | [feq](#feqbool-a-b):bool a b
**x9** | [return](#return-result) result                      | [set](#set-index-val) index val             | [fsub](#fsubn-a-b):n a b            | [flt](#fltbool-a-b):bool a b
**xA** | [exec](#execerr-adr-paramcount):err adr params       | [inc](#inc-index-delta) index delta         | [fmult](#fmultn-a-b):n a b          | [fgt](#fgtbool-a-b):bool a b
**xB** | [break](#break)                                      | [store](#store-adr-val) adr val             | [fdiv](#fdivn-a-b):n a b            |
**xC** | [reset](#reset)                                      | [store8](#store8-adr-val) adr val           | [ffloor](#ffloorn-a):n a            |
**xD** | [absadr](#absadrabsadr-adr):absadr adr               | [setwrite](#setwrite-adr-chsize) adr chsize |                                     |
**xE** | [cpuver](#cpuverversion):ver                         | [skipwrite](#skipwrite-chunks) chunks       | [store16](#store16-adr-val) adr val |
**xF** | [noop](#noop)                                        | [write](#write-val) val                     | [ftoi](#ftoiint-float):int float    |

 - All instructions are 1 byte, except for literals (read [below](#literals))
 - Instruction parameters are popped in specified order and thus must be pushed in reverse order
 - All values are stored as little endian


Literals
--------
Specific values are pushed onto the stack using literals.
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
Some will push a result (prefixed in the documentation with a `:`) back onto the stack.
`adr` parameters can be given as either a relative or absolute address as described [above](#literals).
Relative addresses are relative to the end of the instruction byte that operates on that address.

### `halt`
Pause the cpu indefinitely (and open a debugger?).

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

### `call:result?` `adr` `paramcount`
Start a new stack, move `paramcount` values over to the new stack in reverse order and jump to `adr`.
(Note that a `result` might not be returned.)

### `return` `result`
Like [`endcall`](#endcall), but push `result` onto the previous stack.

### `exec:err?` `adr` `paramcount`
Like [`call`](#callresult-adr-paramcount), but store the current stack and program counter as a safe state to return to, if a [`break`](#break) is invoked by a program or user interrupt.
Useful for running untrusted programs.
If there was already a safe state stored, this will just behave like a [`call`](#callresult-adr-paramcount).

### `break`
If a safe state is stored, this will [`return`](#return-result) `-1` to the safe state and clear it.
If no safe state is stored, this will act as a [`reset`](#reset).

### `reset`
Clear all stacks and safe state and set the program counter to the 32bit address
stored at 8 bytes before end of memory.

### `absadr:absadr` `adr`
Return `adr` as a positive absolute address.

### `cpuver:version`
Return the version number of the current cpu isa.

### `noop`
Waste one cpu cycle doing nothing.

### `lit:val`
Return and jump the next 4 bytes.

### `get:val` `index`
Return the value at the given `index` of the current stack.
Positive `index` counts from the top of the stack.
Negative `index` counts from the bottom of the stack, useful for accessing function parameters and local variables.

### `stackptr:negadr`
Return the negative absolute address of the stack pointer.

### `load:val` `adr`
Load a 32bit value from `adr` and return it.

### `load8u:val` `adr`
Load a 8bit value from `adr` and return it as an unsigned integer.

### `setread` `adr` `chsize`
Prepare reading chunks of `chsize` bits, starting from `adr`.

### `skipread` `chunks`
Skip reading the next `chunk` number of chunks.

### `read:val`
Read the next chunk of bits and return it as a unsigned integer.

### `drop` `val`
Do nothing with `val`.

### `set` `index` `val`
Like [`get`](#getval-index), but overwrites the value in the stack with `val` without returning it.

### `inc` `index` `delta`
Like [`set`](#set-index-val), but increments the integer in stack by `delta`.

### `store` `adr` `val`
Store a 32bit `val` at `adr`.

### `store8` `adr` `val`
Store a 8bit `val` at `adr`.

### `setwrite` `adr` `chsize`
Prepare writing chunks of `chsize` bits, starting from `adr`.

### `skipwrite` `chunks`
Skip writing the next `chunk` number of chunks.

### `write` `val`
Write `val` as the next chunk of bits.

### `add:n` `a` `b`
Return the result of adding `a` and `b`.

### `sub:n` `a` `b`
Return the result of subtracting `b` from `a`.

### `mult:n` `a` `b`
Return the result of multiplying `a` and `b`.

### `div:n` `a` `b`
Return the result of integer dividing `a` by `b`.

### `rem:n` `a` `b`
Return the remainder of integer dividing `a` by `b`.

### `itof:float` `int`
Return `int` as a floating point number.

### `fadd:n` `a` `b`
Like [`add`](#addn-a-b), but for floating point numbers.

### `fsub:n` `a` `b`
Like [`sub`](#subn-a-b), but for floating point numbers.

### `fmult:n` `a` `b`
Like [`mult`](#multn-a-b), but for floating point numbers.

### `fdiv:n` `a` `b`
Like [`div`](#divn-a-b), but for floating point numbers. (and doing actual division, not integer division.)

### `ffloor:n` `a`
Return the largest integer (as a float) that is not larger than `a`.

### `ftoi:int` `float`
Return `float` as an integer.

### `eq:bool` `a` `b`
Return 1 if `a` is equal to `b`, else return 0.

### `lt:bool` `a` `b`
Return 1 if `a` is less than `b`, else return 0.

### `gt:bool` `a` `b`
Return 1 if `a` is greater than `b`, else return 0.

### `eqz:bool` `a`
Return 1 if `a` is zero, else return 0.

### `and:n` `a` `b`
Return the result of bitwise `and`ing `a` and `b`.

### `or:n` `a` `b`
Return the result of bitwise `or`ing `a` and `b`.

### `xor:n` `a` `b`
Return the result of bitwise `xor`ing `a` and `b`.

### `rot:n` `a` `b`
Return the result of rotating `a` `b` bits to the left.

### `feq:bool` `a` `b`
Like [`eq`](#eqbool-a-b), but for floating point numbers.

### `flt:bool` `a` `b`
Like [`lt`](#ltbool-a-b), but for floating point numbers.

### `fgt:bool` `a` `b`
Like [`gt`](#gtbool-a-b), but for floating point numbers.
