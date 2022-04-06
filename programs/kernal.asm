;; z28r asm
skipto 0x00
jump boot

skipto 0x10

fn playground
  vars i
  screenmode 1
  store8 0x40004bfe 1
  while lt i < 0xa0
    printchr i
    inc i 1
  end
  while true
    printchr load8u 0x40004b05
    store 0x40004b04 0
    vsync
  end
end

fn boot
  store8 0x40004800 add 1 + load8u 0x40004800
  sleep 0x100
  resethw

  ;call intro
  ;call launcher
  playground
end

fn resethw
  screenmode -1
  fill 0 0x40000000 0x4c00
  store8 0x40004bff -1
  vsync
end

fn screenmode mode
  store8 0x40004800 mode
  vsync
end

fn fill val dest len
  while gt len > 3
    store dest val
    inc dest 4
    inc len -4
  end
  if len
    store8 dest val
    inc dest 1
    inc len -1
  end
  return
end

fn pset x y c
  if lt x < 0
    endcall
  end
  if lt y < 0
    endcall
  end
  vars w
  let w = mult 8 * load8u 0x40004802
  if gt x > sub w - 1
    endcall
  end
  vars h
  let h = mult 8 * load8u 0x40004803
  if gt y > sub h - 1
    endcall
  end
  vars pal adr
  let pal = and load8u 0x40004801 & 3
  let adr = or 0x40000000 | rot load 0x40004808 << pal
  inc adr += add x + mult y * w
  adr c
  jump mult pal * 2
  endcall store8
  endcall store4bit
  endcall store2bit
  endcall storebit
end

fn pget x y
  if lt x < 0
    return 0
  end
  if lt y < 0
    return 0
  end
  vars w
  let w = mult 8 * load8u 0x40004802
  if gt x > sub w - 1
    return 0
  end
  vars h
  let h = mult 8 * load8u 0x40004803
  if gt y > sub h - 1
    return 0
  end
  vars pal adr
  let pal = and load8u 0x40004801 & 3
  let adr = or 0x40000000 | rot load 0x40004808 << pal
  inc adr += add x + mult y * w
  adr
  jump mult pal * 2
  return load8u
  return load4bit
  return load2bit
  return loadbit
end

fn scroll px
  if eqz px
    endcall
  end
  vars adr offset end h bg i
  let adr = or 0x40000000 | load 0x40004808
  let end = add adr + 0x4800
  let h = mult 8 * load8u 0x40004803
  let offset = mult px * div 0x4800 / h
  let bg = load8u 0x40004bfe
  let i = 32
  while i
    inc i -1
    pset i 0 bg
  end
  let bg = load adr

  inc end sub 0 - offset
  while lt adr end
    store adr load add adr + offset
    inc adr 4
  end

  inc end offset
  while lt adr end
    store adr bg
    inc adr 4
  end
end

fn printchr char
  vars col row
  let col = load8s 0x40004bfc
  let row = load8s 0x40004bfd

  if eq char == 0x08 ; backspace
    inc col -1
    if lt col < 0
      let col = add load8u 0x40004802 + col
      inc row -1
      if lt row < 0
        let col = 0
        let row = 0
      end
      store8 0x40004bfd row
    end
    store8 0x40004bfc col
    endcall
  end
  if eq char == 0x09 ; tab
    inc col 1
    while rem col % 8
      inc col 1
    end
    store8 0x40004bfc col
    endcall
  end
  if eq char == 0x0a ; newline
    let col = 0
    inc row 1
    store8 0x40004bfc col
    store8 0x40004bfd row
    endcall
  end
  if eq char == 0x0d ; carriage return
    let col = 0
    store8 0x40004bfc col
    endcall
  end
  if lt char < 0x20 ; other control code
    endcall
  end

  vars bg fg lastCol lastRow x y x1 y1 x2 y2 font bits
  let bg = load8u 0x40004bfe
  let fg = load8u 0x40004bff
  let lastCol = sub load8u 0x40004802 - 1
  let lastRow = sub load8u 0x40004803 - 1
  let font = add 0x40004c00 + mult 8 * and 127 & char

  while gt col > lastCol
    inc row 1
    inc col -1
    inc col sub 0 - lastCol
  end
  if gt row > lastRow
    scroll mult 8 * sub row - lastRow
    let row = lastRow
  end

  let x1 = mult 8 * col
  let y1 = mult 8 * row
  let x2 = add x1 + 8
  let y2 = add y1 + 8

  let y = y1
  while lt y < y2
    let bits = rot load8u font << -8
    let x = x1
    while lt x < x2
      let bits = rot bits << 1
      if and bits & 1
        pset x y fg
      else
        pset x y bg
      end
      inc x 1
    end
    inc font 1
    inc y 1
  end

  inc col 1
  store8 0x40004bfc col
  store8 0x40004bfd row
end

fn printstr str max
  vars char
  let char = load8u str
  while and eqz eqz char & eqz eqz max
    printchr char
    inc str 1
    let char = load8u str
    inc max -1
  end
end
