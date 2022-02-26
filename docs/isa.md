CPU instructions
================

\      | 0x Flow                | 1x Memory                   | 2x Math         | 3x Logic
-------|------------------------|-----------------------------|-----------------|-------------
**x0** | halt                   | const:val                   | add:n a b       | eq:bool a b
**x1** | sleep ms               | get:val index               | sub:n a b       | lt:bool a b
**x2** | vsync                  |                             | mult:n a b      | gt:bool a b
**x3** |                        | load:val adr len            | div:n a b       | eqz:bool a
**x4** | jump adr               | loadbit:val adr bit bitlen  | rem:n a b       | and:bool a b
**x5** | jumpifz val adr        | loadu:val adr len           |                 | or:bool a b
**x6** |                        |                             |                 | xor:bool a b
**x7** |                        | stackptr:adr                | ftoi:int float  | rot:bool a b
**x8** | call:result adr params | drop val                    | fadd:n a b      | feq:bool a b
**x9** | return result          | set index val               | fsub:n a b      | flt:bool a b
**xA** |                        |                             | fmult:n a b     | fgt:bool a b
**xB** |                        | store adr len val           | fdiv:n a b      |
**xC** | reset                  | storebit adr bit bitlen val |                 |
**xD** | here:adr               |                             |                 |
**xE** | cpuver:ver             |                             | uitof:float int |
**xF** | noop                   | memsize:bytes               | sitof:float int |

 - All instructions are 1 byte, except for constants (read below)
 - Instruction parameters are popped in specified order and thus must be pushed in reverse order
 - All values are stored as little endian


Constants
---------

Type                 | Byte 0    | Byte 1    | Byte 2    | Byte 3    | Byte 4
---------------------|-----------|-----------|-----------|-----------|----------
32bit literal        | 0001 0000 | bbbb aaaa | dddd cccc | ffff eeee | hhhh gggg
4bit positive        | 0100 aaaa |           |           |           |
4bit absolute first  | 0101 aaaa |           |           |           |
4bit negative        | 0110 aaaa |           |           |           |
4bit absolute last   | 0111 aaaa |           |           |           |
12bit positive       | 1000 aaaa | cccc bbbb |           |           |
12bit absolute first | 1001 aaaa | cccc bbbb |           |           |
12bit negative       | 1010 aaaa | cccc bbbb |           |           |
12bit absolute last  | 1011 aaaa | cccc bbbb |           |           |
20bit positive       | 1100 aaaa | cccc bbbb | eeee dddd |           |
20bit absolute first | 1101 aaaa | cccc bbbb | eeee dddd |           |
20bit negative       | 1110 aaaa | cccc bbbb | eeee dddd |           |
20bit absolute last  | 1111 aaaa | cccc bbbb | eeee dddd |           |

 - `aaaa` = least significant nibble
 - `hhhh` = most significant nibble
 - `positive` = rest of nibbles are `0000`
 - `negative` = rest of nibbles are `1111`
 - `absolute` = second most significant bit (2^30) is flipped (for absolute addresses from either beginning or end of memory)
