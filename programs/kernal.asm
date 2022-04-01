;; z28r asm
skipto 0x00
jump boot

skipto 0x10

data hello_str
  "Hello World!\x9b\n\n|\n\n\0"
end
fn fun
  vars ptr
  store 0x40004800 1 1
  vsync
  printstr hello_str -1
  store 0x40004bfe 1 1
  store 0x40004bff 1 2
  let ptr = 1023
  while ptr
    printchr ptr
    dec ptr
  end
  sleep 4096
  while true
    store 0x40004804 4 ptr
    dec ptr
    if eqz rem ptr % 1024
      store 0x40004800 1 add loadu 0x40004800 1 + 1
    end
    vsync
  end
end

fn boot
  store 0x40004800 1 add 1 + loadu 0x40004800 1
  sleep 0x100
  resethw

  ;call intro
  ;call launcher
  fun
end

fn resethw
  store 0x40004800 1 -1
  vsync
  fill 0 0x40000000 0x4c00
  store 0x40004bff 1 -1
  vsync
end

fn fill val dest len
  while gt len > 3
    store dest 4 val
    let dest = add dest + 4
    let len = sub len - 4
  end
  if len
    store dest len val
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
  let w = mult 8 * loadu 0x40004802 1
  if gt x > sub w - 1
    endcall
  end
  vars h
  let h = mult 8 * loadu 0x40004803 1
  if gt y > sub h - 1
    endcall
  end
  vars bpp
  let bpp = loadu 0x40004801 1

  storebit (or 0x40000000 | loadu 0x40004808 4) (mult bpp * add x + mult y * w) bpp c
end

fn pget x y
  if lt x < 0
    return 0
  end
  if lt y < 0
    return 0
  end
  vars w
  let w = mult 8 * loadu 0x40004802 1
  if gt x > sub w - 1
    return 0
  end
  vars h
  let h = mult 8 * loadu 0x40004803 1
  if gt y > sub h - 1
    return 0
  end
  vars bpp
  let bpp = loadu 0x40004801 1

  loadbit (or 0x40000000 | loadu 0x40004808 4) (mult bpp * add x + mult y * w) bpp
end

fn scroll px
  if eqz px
    endcall
  end
  vars adr offset end w bpp bg
  let adr = or 0x40000000 | loadu 0x40004808 4
  let end = add adr + 0x4800
  let w = mult 8 * loadu 0x40004802 1
  let bpp = loadu 0x40004801 1
  let offset = div (mult px * mult bpp * w) / 8
  let bg = loadu 0x40004bfe 1
  storebit adr 0 bpp bg
  let bg = loadbit adr 0 bpp
  while lt bpp < 32
    let bg = or bg | rot bg bpp
    let bpp = mult bpp * 2
  end

  let end = sub end - offset
  while lt adr end
    store adr 4 loadu add adr + offset 4
    let adr = add adr + 4
  end

  let end = add end + offset
  while lt adr end
    store adr 4 bg
    let adr = add adr + 4
  end
end

fn printchr char
  vars col row
  let col = load 0x40004bfc 1
  let row = load 0x40004bfd 1

  if eq char == 0x08 ; backspace
    dec col
    if lt col < 0
      let col = add loadu 0x40004802 1 + col
      dec row
      if lt row < 0
        let col = 0
        let row = 0
      end
      store 0x40004bfd 1 row
    end
    store 0x40004bfc 1 col
    endcall
  end
  if eq char == 0x09 ; tab
    inc col
    while rem col % 8
      inc col
    end
    store 0x40004bfc 1 col
    endcall
  end
  if eq char == 0x0a ; newline
    let col = 0
    inc row
    store 0x40004bfc 1 col
    store 0x40004bfd 1 row
    endcall
  end
  if eq char == 0x0d ; carriage return
    let col = 0
    store 0x40004bfc 1 col
    endcall
  end
  if lt char < 0x20 ; other control code
    endcall
  end

  vars bg fg lastCol lastRow x y x1 y1 x2 y2 font bits
  let bg = loadu 0x40004bfe 1
  let fg = loadu 0x40004bff 1
  let lastCol = sub loadu 0x40004802 1 - 1
  let lastRow = sub loadu 0x40004803 1 - 1
  let font = add 0x40004c00 + mult 8 * and 127 & char

  while gt col > lastCol
    inc row
    dec col
    let col = sub col - lastCol
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
    let bits = rot loadu font 1 << -8
    let x = x1
    while lt x < x2
      let bits = rot bits << 1
      if and bits & 1
        pset x y fg
      else
        pset x y bg
      end
      inc x
    end
    inc font
    inc y
  end

  inc col
  store 0x40004bfc 1 col
  store 0x40004bfd 1 row
end

fn printstr str max
  vars char
  let char = loadu str 1
  while and eqz eqz char & eqz eqz max
    printchr char
    inc str
    let char = loadu str 1
    dec max
  end
end
