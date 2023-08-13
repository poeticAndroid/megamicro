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
  
  let len = openFile 0x20726964 args 0 ; dir
  if len
    readFile buffer len
    printCrop absadr buffer
  else
    printStr 0x40004a00 256
    printChr 0x0a
    return 1
  end

  return 0
end

fn printCrop str
  vars p
  while load8u str
    if lt p < load8u 0x40004802
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
