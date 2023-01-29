CPU instruction set
===================
Just an idea I had.. not implemented..

`cpuver = 4`

\      | 0x Flow                                              | 1x Vars+Logic                             | 2x Math                          | 3x (Mode 0) Memory                                      | 3x (Mode 1) Gfx
-------|------------------------------------------------------|-------------------------------------------|----------------------------------|---------------------------------------------------------|----------------------------------------------------------------------------------------------
**x0** | [halt](#halt)                                        | [load](#loadval-adr):val adr              | [add](#addn-a-b):n a b           | [load8u](#load8uval-adr):val adr                        | [fgcolor](#fgcolorpcol-col):pcol col
**x1** | [sleep](#sleep-ms) ms                                | [store](#store-adr-val) adr val           | [sub](#subn-a-b):n a b           | [load8s](#load8sval-adr):val adr                        | [pget](#pgetcol-img-x-y):col img x y
**x2** | [vsync](#vsync)                                      | [incadr](#incadr-adr) adr                 | [mult](#multn-a-b):n a b         | [load16u](#load16uval-adr):val adr                      | [pset](#pset-img-x-y) img x y
**x3** | [mode](#modepmode-mode):pmode mode                   | [incadrby](#incadrby-adr-delta) adr delta | [div](#divn-a-b):n a b           | [load16s](#load16sval-adr):val adr                      | [rect](#rect-img-x-y-w-h) img x y w h
**x4** | [jump](#jump-adr) adr                                | [get](#getval-index):val index            | [rem](#remn-a-b):n a b           | [loadbit](#loadbitval-adr-bit):val adr bit              |
**x5** | [jumpifz](#jumpifz-adr-val) adr val                  | [set](#set-index-val) index val           | [lt](#ltbool-a-b):bool a b       | [loadbits](#loadbitval-adr-bit-len):val adr bit len     |
**x6** | [stackptr](#stackptrnegadr):negadr                   | [inc](#inc-index) index                   | [gt](#gtbool-a-b):bool a b       |                                                         |
**x7** | [endcall](#endcall)                                  | [incby](#incby-index-delta) index delta   | [itof](#itoffloat-int):float int |                                                         |
**x8** | [call](#callresult-adr-paramcount):result adr params | [eqz](#eqzbool-a):bool a                  | [fadd](#faddn-a-b):n a b         | [store8](#store8-adr-val) adr val                       | [bgcolor](#bgcolorpcol-col):pcol col
**x9** | [return](#return-result) result                      | [eq](#eqbool-a-b):bool a b                | [fsub](#fsubn-a-b):n a b         |                                                         | [pxdepth](#pxdepthpdepth-depth):pdepth depth
**xA** | [exec](#execerr-adr-paramcount):err adr params       | [feq](#feqbool-a-b):bool a b              | [fmult](#fmultn-a-b):n a b       | [store16](#store16-adr-val) adr val                     | [copyimg](#copyimg-simg-dimg-dx-dy) simg dimg dx dy
**xB** | [break](#break)                                      | [and](#andn-a-b):n a b                    | [fdiv](#fdivn-a-b):n a b         |                                                         | [copyrect](#copyrect-simg-dimg-sx-sy-dx-dy-w-h) simg dimg sx sy dx dy w h
**xC** | [reset](#reset)                                      | [or](#orn-a-b):n a b                      | [ffloor](#ffloorn-a):n a         | [storebit](#storebit-adr-bit-val) adr bit val           | [copyscaled](#copyscaled-simg-dimg-sx-sy-dx-dy-sw-sh-dw-dh) simg dimg sx sy dx dy sw sh dw dh
**xD** | [absadr](#absadrabsadr-adr):absadr adr               | [xor](#xorn-a-b):n a b                    | [flt](#fltbool-a-b):bool a b     | [storebits](#storebits-adr-bit-len-val) adr bit len val |
**xE** | [cpuver](#cpuverversion):ver                         | [rot](#rotn-a-b):n a b                    | [fgt](#fgtbool-a-b):bool a b     | [memcopy](#memcopy-src-dest-len) src dest len           |
**xF** | [lit](#literals):val                                 | [drop](#drop-val) val                     | [ftoi](#ftoiint-float):int float |                                                         |

 - All instructions are 1 byte, except for literals (read [below](#literals))
 - Instruction parameters are popped in specified order and thus must be pushed in reverse order
 - All values are stored as little endian


Literals
--------
Specific values are pushed onto the stack using literals.
Smaller numbers can be compressed into fewer bytes as described in the following table.

Type                    | Byte 0    | Byte 1    | Byte 2    | Byte 3    | Byte 4
------------------------|-----------|-----------|-----------|-----------|----------
32bit `lit`eral         | 0000 1111 | bbbb aaaa | dddd cccc | ffff eeee | hhhh gggg
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

### `mode:pmode` `mode`
Set the current memory mode and return the previous mode.

### `jump` `adr`
Jump to `adr`.

### `jumpifz` `adr` `val`
Jump to `adr` if `val` is zero.

### `stackptr:negadr`
Return the negative absolute address of the stack pointer.

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

### `lit:val`
Return and jump the next 4 bytes.


### `load:val` `adr`
Load a 32bit value from `adr` and return it.

### `store` `adr` `val`
Store a 32bit `val` at `adr`.

### `incadr` `adr`
Increment the integer at `adr` by 1.

### `incadrby` `adr` `delta`
Increment the integer at `adr` by `delta`.

### `get:val` `index`
Return the value at the given `index` of the current stack.
Positive `index` counts from the top of the stack.
Negative `index` counts from the bottom of the stack, useful for accessing function parameters and local variables.

### `set` `index` `val`
Like [`get`](#getval-index), but overwrites the value in the stack with `val` without returning it.

### `inc` `index`
Increment the integer in stack by 1.

### `incby` `index` `delta`
Increment the integer in stack by `delta`.

### `eqz:bool` `a`
Return 1 if `a` is zero, else return 0.

### `eq:bool` `a` `b`
Return 1 if `a` is equal to `b`, else return 0.

### `feq:bool` `a` `b`
Like [`eq`](#eqbool-a-b), but for floating point numbers.

### `and:n` `a` `b`
Return the result of bitwise `and`ing `a` and `b`.

### `or:n` `a` `b`
Return the result of bitwise `or`ing `a` and `b`.

### `xor:n` `a` `b`
Return the result of bitwise `xor`ing `a` and `b`.

### `rot:n` `a` `b`
Return the result of rotating `a` `b` bits to the left.

### `drop` `val`
Take a value from the stack and do nothing with it.


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

### `lt:bool` `a` `b`
Return 1 if `a` is less than `b`, else return 0.

### `gt:bool` `a` `b`
Return 1 if `a` is greater than `b`, else return 0.

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

### `flt:bool` `a` `b`
Like [`lt`](#ltbool-a-b), but for floating point numbers.

### `fgt:bool` `a` `b`
Like [`gt`](#gtbool-a-b), but for floating point numbers.

### `ftoi:int` `float`
Return `float` as an integer.


### `load8u:val` `adr`
Load a 8-bit value from `adr` and return it as an unsigned integer.

### `load8s:val` `adr`
Load a 8-bit value from `adr` and return it as a signed integer.

### `load16u:val` `adr`
Load a 16-bit value from `adr` and return it as an unsigned integer.

### `load16s:val` `adr`
Load a 16-bit value from `adr` and return it as a signed integer.

### `loadbit:val` `adr` `bit`
Load the `bit`th bit from `adr` and return it.

### `loadbits:val` `adr` `bit` `len`
Load `len` bits starting from the `bit`th bit of `adr` and return them as an unsigned integer.

### `store8` `adr` `val`
Store a 8-bit `val` at `adr`.

### `store16` `adr` `val`
Store a 16-bit `val` at `adr`.

### `storebit` `adr` `bit` `val`
Store the least significant bit of `val` at the `bit`th bit of `adr`.

### `storebits` `adr` `bit` `len` `val`
Store the `len` least significant bits of `val` at the `bit`th bit of `adr`.

### `memcopy` `src` `dest` `len`
Copy `len` bytes of data from `src` to `dest` in memory. `dest` _should_ be an absolute address.


### `fgcolor:pcol` `col`
Set the current foreground color and return the prevous foreground color.

### `pget:col` `img` `x` `y`
Get the pixel color from a image resource `img` at coordinates `x`,`y`.

### `pset` `img` `x` `y`
Set the pixel color of a image resource `img` at coordinates `x`,`y` to the current foreground color.

### `rect` `img` `x` `y` `w` `h`
Draw a filled rectangle in the current foreground color to `img`.

### `bgcolor:pcol` `col`
Set the current background color and return the prevous background color.

### `pxdepth:pdepth` `depth`
Set the current pixel color depth and return the prevous pixel color depth.

### `copyimg` `simg` `dimg` `dx` `dy`
Copy all of `simg` onto `dimg` starting at coordinates `dx`,`dy`, skipping all pixels in `simg` that match the current background color.

### `copyrect` `simg` `dimg` `sx` `sy` `dx` `dy` `w` `h`
Copy some of `simg`, specified by coordinates `sx`,`sy` and size `w`,`h`, onto `dimg` at starting at coordinates `dx`,`dy`, skipping all pixels in `simg` that match the current background color.

### `copyscaled` `simg` `dimg` `sx` `sy` `dx` `dy` `sw` `sh` `dw` `dh`
Copy some of `simg`, specified by coordinates `sx`,`sy` and size `sw`,`sh`, onto `dimg` at starting at coordinates `dx`,`dy` and scaling it to fit size `dw`,`dh`, skipping all pixels in `simg` that match the current background color.


