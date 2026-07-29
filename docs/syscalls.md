System calls
============

```
;; z28r asm
ext resethw     0x0804 0 0 ; resethw
ext cls         0x0808 0 0 ; cls
ext pset        0x080c 3 0 ; pset x y c
ext pget        0x0810 2 1 ; pget:c x y
ext rect        0x0814 5 0 ; rect x y w h c
ext pxCopy      0x0818 5 0 ; *pxCopy x y w h src
ext printChr    0x081c 1 0 ; printChr char
ext printStr    0x0820 2 0 ; printStr str max
ext readLn      0x0824 2 0 ; readLn dest max
ext strToInt    0x0828 3 1 ; strToInt:int str base max
ext intToStr    0x082c 3 0 ; intToStr int base dest
ext strLen      0x0830 2 1 ; strLen:len str max
ext memCopy     0x0834 3 0 ; memCopy src dest len
ext fill        0x0838 3 0 ; fill val dest len
ext openFile        0x083c 3 1 ; open:bytes cmd path bytes
ext readFile        0x0840 2 1 ; read:bytes dest max
ext writeFile       0x0844 2 1 ; write:bytes src len
```

*not yet implemented
