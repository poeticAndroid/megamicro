;; z28r asm
jump main
ext resethw     0x5004 0 0 ; resethw
ext cls         0x5008 0 0 ; cls
ext pset        0x500c 3 0 ; pset x y c
ext pget        0x5010 2 1 ; pget:c x y
ext rect        0x5014 5 0 ; rect x y w h c
ext pxCopy      0x5018 5 0 ; *pxCopy x y w h src
ext printChr    0x501c 1 0 ; printChr char
ext printStr    0x5020 2 0 ; printStr str max
ext readLn      0x5024 2 0 ; readLn dest max
ext strToInt    0x5028 3 1 ; strToInt:int str base max
ext intToStr    0x502c 3 0 ; intToStr int base dest
ext strLen      0x5030 2 1 ; strLen:len str max
ext memCopy     0x5034 3 0 ; memCopy src dest len
ext fill        0x5038 3 0 ; fill val dest len
ext open        0x503c 3 1 ; open:bytes cmd path bytes
ext read        0x5040 2 1 ; read:bytes dest max
ext write       0x5044 2 1 ; write:bytes src len

data greeting_str
  "Hello World!\x9b\n\0"
end
fn main args
  printStr greeting_str -1
  return 0
end
