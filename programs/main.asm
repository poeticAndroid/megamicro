;; z28r asm
jump main
ext printChr 0x501c 1 0
ext printStr 0x5020 2
ext readLn 0x5024 2
ext openFile 0x503c 3
ext readFile 0x5040 2
ext intToStr 0x502c 3 0 ; intToStr int base dest
ext fill     0x5038 3 0 ; fill val dest len
ext memCopy  0x5034 3 0 ; memCopy src dest len

fn main args
  vars len, ls, err
  let len = true
  let ls = load buffer
  printStr cwd 64
  let len = sub absadr stackptr - buffer
  intToStr len 10 buffer
  printStr buffer 64
  printStr cmd 64
  
  while len
    store buffer ls
    let len = openFile 0x20206463 buffer 0
    readFile cwd len
    
    print_prompt
    store cmd 0
    readLn cmd 64
    let err = execute absadr cmd
    if err
      intToStr err 10 absadr buffer
      printChr 0x9a
      printStr buffer 8
    end
  end

  return 404
end

fn print_prompt
  printChr 0x0a
  printStr cwd -1
  printChr 0x3e
  printChr 0x20
end

fn execute cmd
  vars verblen args len
  let args = absadr cmd
  while gt load8u args > 0x20
    inc verblen += 1
    inc args += 1
  end
  while eq load8u args == 0x20
    inc args += 1
  end
  if eqz load8u cmd
    return 0
  end
  
  fill 0 absadr buffer 1024
  memCopy cmd absadr buffer verblen
  let len = openFile 0x20746567 buffer 0
  if len
    readFile buffer len
    return run args
  end
  
  store add verblen + absadr buffer 0x6772702e ; .prg
  let len = openFile 0x20746567 buffer 0
  if len
    readFile buffer len
    return run args
  end
  
  memCopy buffer add 1 + absadr buffer 256
  store8 buffer 0x2f ; /
  memCopy buffer add 4 + absadr buffer 256
  store buffer 0x646d632f ; /cmd
  let len = openFile 0x20746567 buffer 0
  if len
    readFile buffer len
    return run args
  end
  
  printStr 0x40004a00 256
  return 404
end

fn run args
  -1
  return exec buffer 1 args
end

data cwd "\n\nMegaDOS 1.\x9b\n\0"
end
skipby 64

data cmd " bytes free\n\n\0"
end
skipby 64

data buffer ".\0"
end
