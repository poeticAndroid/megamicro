```wat
(sys ({call code}) ({arg 1}) ({arg 2})...({arg n}) (0x400) ({number of args + 1}))
```

Call codes
----------

\      | 0x sys | 1x gfx
-------|--------|---------------
**x0** | reboot | pset x y c
**x1** |        | rect x y w h c
**x2** |        |
**x3** |        |
**x4** |        |
**x5** |        |
**x6** |        |
**x7** |        |
**x8** |        | pget:c x y
**x9** |        | scrndepth:c
**xA** |        | scrnwidth:w
**xB** |        | scrnheight:h
**xC** |        |
**xD** |        |
**xE** |        |
**xF** |        |
