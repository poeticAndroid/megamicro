;; z28r asm
jump main
ext printStr 0x5020 2

data greeting_str "Hello World!\x9b\n\0"
end
fn main args
  printStr greeting_str -1
  return 0
end
