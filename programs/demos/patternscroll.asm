;; z28r asm
jump main

fn main args
  vars adr, last
  let adr = load 0x40000008
  let last = add adr + 0x4800

  while lt adr < last
    store8 adr adr
    inc adr += 1
  end

  let adr = load 0x40000008
  let last = add adr + 0x4800

  while true
    if load8u 0x40000304
      store8 0x40000000 load8u 0x40000305
      store 0x40000304 0
    end

    while lt adr < last
      store8 adr add 1 + load8u adr
      inc adr += 1
    end

    let adr = load 0x40000008
    let last = add adr + 0x4800
    ;vsync
  end

  return 0
end
