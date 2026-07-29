;; z28r asm
jump main
ext printChr    0x081c 1 0 ; printChr char
ext printStr    0x0820 2 0 ; printStr str max

fn main args
  printStr args -1
  printChr 0x0a
  return 0
end
