;; z28r asm
jump main

fn main args
  vars adr
  store 0x40000004 absadr 0xbfffb800
  let adr = absadr stackptr
  inc adr += -4
  while gt adr > absadr eof
    if gt load 0x40000004 > adr
      if gt load 0x40000004 > 0x40004800
        store 0x40000004 sub load 0x40000004 - 0x4800
      else
        store 0x40000004 0x40000000
      end
    end
    store adr 0
    inc adr += -4
  end
  store 0x40000004 0x40000000
  let adr = 0x40000400
  inc adr += -4
  while gt adr 0x40000000
    store adr 0
    inc adr += -4
  end
  reset
end

skipby 4

data eof 0
end
