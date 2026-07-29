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
  
  let len = openFile 0x20746567 args 0 ; get
  if len
    store 0x400003fc 0
    readFile 0x40000000 1
    readFile 0x400003fe 1
    store8 0x400003ff xor -1 load8u 0x400003fe
    readFile load 0x40000008 2
    
    while load 0x40000300
      readFile load 0x40000008 0x4800
      vsync
    end
    while load 0x40000304
      store 0x40000304 0
      vsync
    end
    while not load 0x40000304
      vsync
    end
  else
    printStr 0x40000200 256
    printChr 0x0a
    return 1
  end

  return 0
end

data buffer ".\0"
end
