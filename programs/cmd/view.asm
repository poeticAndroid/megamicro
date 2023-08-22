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
    readFile 0x40004800 1
    readFile 0x40000000 3
    while load 0x40004b00
      readFile 0x40000000 0x4800
      vsync
    end
    while load 0x40004b04
      store 0x40004b04 0
      vsync
    end
    while eqz load 0x40004b04
      vsync
    end
  else
    printStr 0x40004a00 256
    printChr 0x0a
    return 1
  end

  return 0
end

data buffer ".\0"
end
