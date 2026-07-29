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
  
  let len = openFile 0x20726964 args 0 ; dir
  if len
    readFile buffer len
    printCrop absadr buffer
  else
    printStr 0x40000200 256
    printChr 0x0a
    return 1
  end

  return 0
end

fn printCrop str
  vars p
  while load8u str
    if lt p < load8u 0x40000002
      printChr load8u str
      inc p += 1
    end
    if eq load8u str == 0x0a
      let p = 0
    end
    
    inc str += 1
  end
end

data buffer ".\0"
end
