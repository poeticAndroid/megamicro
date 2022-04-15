;; z28r asm
jump main
ext printChr    0x501c 1 0 ; printChr char
ext printStr    0x5020 2 0 ; printStr str max
ext readLn      0x5024 2 0 ; readLn dest max
ext strToInt    0x5028 3 1 ; strToInt:int str base max
ext intToStr    0x502c 3 0 ; intToStr int base dest

fn main args
  vars mode cols i
  
  while true
    store input 0
    printStr mode_str -1
    readLn input 2
    let mode = strToInt input 10 16
    store8 0x40004800 mode
    vsync
    let mode = and mode 3
    if eq mode == 0
      let cols = 2
    end
    if eq mode == 1
      let cols = 4
    end
    if eq mode == 2
      let cols = 16
    end
    if eq mode == 3
      let cols = 256
    end
    let i = 0
    while lt i < cols
      store8 0x40004bfe i
      printChr 0x20
      inc i += 1
    end
    store8 0x40004bfe 0
    printChr 0x0a
  end

  return 0
end

data mode_str
  "Display mode: \0"
end
data input
  "\0\0\0\0"
end
