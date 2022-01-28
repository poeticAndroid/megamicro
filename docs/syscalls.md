```wat
(sys ({call code}) ({arg 1}) ({arg 2})...({arg n}) (0x400) ({number of args + 1}))
```

Call codes
----------

\      | 0x System              | 1x Graphics     | 2x Math   | 3x Files
-------|------------------------|-----------------|-----------|------------------------
**x0** | reboot                 | pset x y c      | pow:n a b | *load:done file dest
**x1** |                        | *rect x y w h c |           | *save:done file src len
**x2** | printchar c            |                 |           | *delete:done file
**x3** | printstr s             |                 |           |
**x4** | memcopy src dest len   |                 |           | *info:done file dest
**x5** | fill val dest len      |                 |           |
**x6** |                        |                 |           |
**x7** |                        |                 |           |
**x8** | strtoint:int str base  | *pget:c x y     |           | *list:done path dest
**x9** | inttostr int base dest | scrndepth:c     |           | *cd:done path
**xA** | *readln dest           | scrnwidth:w     |           | *mkdir:done path
**xB** |                        | scrnheight:h    |           |
**xC** |                        |                 |           |
**xD** |                        |                 |           |
**xE** |                        |                 |           |
**xF** |                        |                 |           |
