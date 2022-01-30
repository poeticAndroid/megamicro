CPU instructions
----------------

\      | 0x Flow                       | 1x Memory       | 2x Math         | 3x Logic
-------|-------------------------------|-----------------|-----------------|-------------
**x0** | halt                          | const:val       | add:n a b       | eq:bool a b
**x1** | sleep ms                      | get:val index   | sub:n a b       | lt:bool a b
**x2** | vsync                         |                 | mult:n a b      | gt:bool a b
**x3** |                               | load:val adr    | div:n a b       | eqz:bool a
**x4** | jump offset                   | load16u:val adr | rem:n a b       | and:bool a b
**x5** | jumpifz val offset            | load8u:val adr  |                 | or:bool a b
**x6** |                               | load16s:val adr |                 | xor:bool a b
**x7** | cpuver:ver                    | load8s:val adr  | ftoi:int float  | rot:bool a b
**x8** | call:results... offset params | drop val        | fadd:n a b      | feq:bool a b
**x9** | sys:results... adr params     | set index val   | fsub:n a b      | flt:bool a b
**xA** |                               |                 | fmult:n a b     | fgt:bool a b
**xB** | return results                | store adr val   | fdiv:n a b      |
**xC** | reset                         | store16 adr val |                 |
**xD** | here:adr                      | store8 adr val  |                 |
**xE** | goto adr                      | stacksize:bytes | uitof:float int |
**xF** | noop                          | memsize:bytes   | sitof:float int |

 - All instructions are 1 byte, except for `const` which is 5 bytes (opcode + 32bit value)..
 - All values are little endian..
