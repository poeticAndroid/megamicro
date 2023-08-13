;; z28r asm
jump main
ext cls         0x5008 0 0 ; cls
ext printChr    0x501c 1 0 ; printChr char
ext readLn      0x5024 2 0 ; readLn dest max
ext strToInt    0x5028 3 1 ; strToInt:int str base max

fn main args
  vars i_str
  let i_str = add absadr input_str + 2
  printChr 0x0a
  while true
    store input_str 0
    readLn input_str 1024
    if eq 0x3d62 == load16s input_str ; b=
      store8 0x40004bfe strToInt i_str 10 4
    end
    if eq 0x00736c63 == load input_str ; cls
      cls
    end
    if eq 0x3d66 == load16s input_str ; f=
      store8 0x40004bff strToInt i_str 10 4
    end
    if eq 0x3d6d == load16s input_str ; m=
      store8 0x40004800 strToInt i_str 10 4
      vsync
    end
  end
end

data input_str
  0
end
