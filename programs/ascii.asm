;; z28r asm
jump main
ext printChr    0x501c 1 0 ; printChr char
ext printStr    0x5020 2 0 ; printStr str max
ext intToStr    0x502c 3 0 ; intToStr int base dest

fn main args
  vars i
  let i = 32
  while lt i < 160
    intToStr i 16 int
    printStr int 4
    printChr i
    printChr 0x20
    inc i += 1
  end
  printChr 0x0a
  return 0
end

data int 0
end
