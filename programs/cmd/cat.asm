;; z28r asm
jump main
ext printChr 0x501c 1
ext printStr 0x5020 2
ext openFile 0x503c 3
ext readFile 0x5040 2

fn main args
  vars len
  
  if eqz args
    let args = buffer
  end
  if eqz load8u args
    let args = buffer
  end
  
  let len = openFile 0x20746567 args 0 ; get
  if len
    readFile buffer len
    printStr buffer len
  else
    printStr 0x40004a00 256
    printChr 0x0a
    return 1
  end

  return 0
end

data buffer ".\0"
end
