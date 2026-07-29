;; z28r asm
jump main
ext printChr 0x081c 1
ext printStr 0x0820 2
ext openFile 0x083c 3
ext readFile 0x0840 2

fn main args
  vars len
  
  if not args
    let args = buffer
  end
  if not load8u args
    let args = buffer
  end
  
  let len = openFile 0x206c6564 args 0 ; del
  if len
    readFile buffer len
    printStr buffer len
  else
    printStr 0x40000200 256
    printChr 0x0a
    return 1
  end

  return 0
end

data buffer ".\0"
end
