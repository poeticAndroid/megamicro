;; z28r asm
jump main

fn main args
  vars adr
  let adr = 0x40000000

  while lt adr < 0x40004800
    store8 adr adr
    inc adr += 1
  end

  let adr = 0x40000000

  while true
    if load8u 0x40004b04
      store8 0x40004800 load8u 0x40004b05
      store 0x40004b04 0
    end

    while lt adr < 0x40004800
      store8 adr add 1 + load8u adr
      inc adr += 1
    end

    let adr = 0x40000000
    ;vsync
  end

  return 0
end
