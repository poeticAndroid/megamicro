;; z28r asm
jump main
ext printStr    0x5020 2 0 ; printStr str max
ext strToInt    0x5028 3 1 ; strToInt:int str base max


fn main args
  if eqz args
    printStr help_str -1
    return 1
  end
  
  while eq load8u args == 0x20
    inc args +=1
  end
  if load8u args
    store8 0x40004800 strToInt args 10 4
  else
    printStr help_str -1
  end
  while gt load8u args > 0x20
    inc args +=1
  end
  
  while eq load8u args == 0x20
    inc args +=1
  end
  if load8u args
    store8 0x40004bfe strToInt args 10 4
  end
  while gt load8u args > 0x20
    inc args +=1
  end
  
  while eq load8u args == 0x20
    inc args +=1
  end
  if load8u args
    store8 0x40004bff strToInt args 10 4
  end
  while gt load8u args > 0x20
    inc args +=1
  end
  
  vsync
  return 0
end

data help_str
  "Usage: mode [screen mode] [bg color] [fg color]\n\0"
end
