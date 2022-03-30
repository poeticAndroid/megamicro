;; z28r asm
skipto 0x00
jump boot

skipto 0x10

fn fun
  vars ptr
  printchr 0x0a ;\n
  printchr 0x48 ; H
  printchr 0x65 ; e
  printchr 0x6c ; l
  printchr 0x6c ; l
  printchr 0x6f ; o
  printchr 0x0a ;\n
  printchr 0x57 ; W
  printchr 0x6f ; o
  printchr 0x72 ; r
  printchr 0x6c ; l
  printchr 0x64 ; d
  printchr 0x21 ; !
  printchr 0x0a ;\n
  while lt ptr < 0xa0
    printchr ptr
    inc ptr
  end
  let ptr = 0
  sleep 4096
  while true
    store 0x40004800 4 ptr
    inc ptr
    if eqz rem ptr % 1024
      store 0x40004804 1 add loadu 0x40004804 1 + 1
    end
    vsync
  end
end

fn boot
  store 0x40004804 4 add 1 + loadu 0x40004804 1
  sleep 0x100
  resethw

  ;call intro
  ;call launcher
  fun
end

fn resethw
  store 0x40004804 4 -1
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
  let w = mult 8 * loadu 0x40004806 1
  if gt x > sub w - 1
    endcall
  end
  vars h
  let h = mult 8 * loadu 0x40004807 1
  if gt y > sub h - 1
    endcall
  end
  vars bpp
  let bpp = loadu 0x40004805 1

  storebit (or 0x40000000 | loadu 0x40004800 4) (mult bpp * add x + mult y * w) bpp c
end

fn printchr char
  vars col row
  let col = load 0x40004bfc 1
  let row = load 0x40004bfd 1

  if eq char == 0x08 ; backspace
    dec col
    if lt col < 0
      let col = add loadu 0x40004806 1 + col
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
  let lastCol = sub loadu 0x40004806 1 - 1
  let lastRow = sub loadu 0x40004807 1 - 1
  let font = add 0x40004c00 + mult 8 * and 127 & char

  while gt col > lastCol
    inc row
    dec col
    let col = sub col - lastCol
  end
  if gt row > lastRow
    ; todo: scroll
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

