;; z28r asm
jump boot

skipto 0x04
jump resethw
skipto 0x08
jump cls
skipto 0x0c
jump pset
skipto 0x10
jump pget
skipto 0x14
jump rect
skipto 0x18
jump pxCopy
skipto 0x1c
jump printChr
skipto 0x20
jump printStr
skipto 0x24
jump readLn
skipto 0x28
jump strToInt
skipto 0x2c
jump intToStr
skipto 0x30
jump strLen
skipto 0x34
jump memCopy
skipto 0x38
jump fill
skipto 0x3c
jump open
skipto 0x40
jump read
skipto 0x44
jump write

skipto 0x50



fn boot
  store 0x40004800 add 1 + load 0x40004800
  sleep 0x100
  resethw

  intro
  bootDisk
end

data loading_str
  "Loading \0"
end
data dots_str
  " ... \0"
end
data mainFile_str
  "main.prg\0"
end
data root_str
  "/\0"
end
data reboot_str
  "\n\nInsert bootable media into any\ndrive and press Ctrl+Q to reboot\n\0"
end
fn bootDisk
  vars len drive
  let drive = 4
  while drive
    inc drive += -1
    store 0x40004bf8 drive
    drop open 0x20206463 root_str 0 ; cd
  end
  while lt drive < 4
    store 0x40004bf8 drive
    if load8u 0x40004bfc
      printChr 0x0a
    end
    printStr loading_str -1
    printChr 0x44
    intToStr drive 10 user_prg
    printStr user_prg 4
    printChr 0x3a
    printStr root_str -1
    printStr mainFile_str -1
    printStr dots_str -1
    let len = open 0x20746567 mainFile_str 0 ; get
    if len
      intToStr len 10 user_prg
      printStr user_prg 16
      printStr bytes_str -1
      printChr 0x0a
      drop read user_prg len
      runUser
    else
      printStr 0x40004a00 255
    end
    inc drive += 1
  end
  printStr reboot_str -1
  halt
  reset
end

data return_str
  "\nReturn code: \0"
end
fn runUser
  store user_prg call user_prg 1 0 0
  resethw
  screenmode 0
  colors -1 0
  intToStr load user_prg 10 user_prg
  printStr return_str -1
  printStr user_prg 16
  printChr 0x0a
  printChr 0x0a
end

data intro_str
  "\t    Mega      ///\t\t/// MegaMicro ///\n\n\n\0"
end
data memory_str
  "Memory: \0"
end
data bytes_str
  " bytes\n\0"
end
data speed_str
  "Speed: \0"
end
data ips_str
  " ips\n\0"
end
fn intro
  vars kb ins sec
  colors -1 0
  screenmode 1
  cls
  printStr intro_str -1
  screenmode 0

  printStr memory_str -1
  let sec = load8u 0x40004b11
  while eq sec == load8u 0x40004b11
    vsync
  end
  sleep 0x200
  let kb = 0x40000000
  while lt kb < absadr stackptr
    inc kb += 0x10000
  end
  let kb = xor kb ^ 0x40000000
  intToStr kb 10 user_prg
  printStr user_prg -1
  printStr bytes_str -1

  printStr speed_str -1
  let sec = load8u 0x40004b11
  let ins = 8
  while eq sec == load8u 0x40004b11
  end
  let sec = load8u 0x40004b11
  while eq sec == load8u 0x40004b11
    inc ins += 12
  end
  intToStr ins 10 user_prg
  printStr user_prg -1
  printStr ips_str -1

  printChr 0x0a
end

fn resethw
  fill 0 0x40004804 780
end


;;; graphics ;;;

fn cls
  vars adr end bg i
  let adr = or 0x40000000 | load 0x40004808
  let end = add adr + 0x4800
  let bg = load8u 0x40004bfe
  let i = 32
  while i
    inc i -1
    pset i 0 bg
  end
  let bg = load adr

  while lt adr end
    store adr bg
    inc adr 4
  end

  store8 0x40004bfc 0
  store8 0x40004bfd 0
end

fn screenmode mode
  if eq load8u 0x40004800 == mode
    endcall
  end
  store8 0x40004800 mode
  vsync
end

fn colors fg bg
  store8 0x40004bff fg
  store8 0x40004bfe bg
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

fn rect x1 y1 w h c
  vars x y x2 y2
  let x2 = add x1 + w
  let y2 = add y1 + h
  let y = x1
  while lt y < y2
    let x = x1
    while lt x < x2
      pset x y c
      inc x += 1
    end
    inc y += 1
  end
end

fn pxCopy x1 y1 w h src
  vars x y x2 y2
  let x2 = add x1 + w
  let y2 = add y1 + h
  let y = x1
  while lt y < y2
    let x = x1
    while lt x < x2
      ; TODO!
      inc x += 1
    end
    inc y += 1
  end
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

fn printChr char
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

fn printStr str max
  vars char
  let char = load8u str
  while and eqz eqz char & eqz eqz max
    printChr char
    inc str 1
    let char = load8u str
    inc max -1
  end
end

fn readLn dest max
  vars start end done
  let start = dest
  let end = sub add dest + max - 1
  while gt load8u dest > 0x1f
    printChr load8u dest
    inc dest += 1
  end
  while eqz done
    printChr 0x9e
    printChr 0x08
    while eqz load8u 0x40004b04
      vsync
    end
    if eq load8u 0x40004b05 == 0x08
      if gt dest > start
        printChr 0x08
        printChr 0x20
        printChr 0x20
        printChr 0x08
        printChr 0x08
        inc dest += -1
      end
    end
    if eq load8u 0x40004b05 == 0x0a
      printChr 0x0a
      let done = true
    end
    if gt load8u 0x40004b05 > 0x1f
      if lt dest < end
        store8 dest load8u 0x40004b05
        printChr load8u dest
        inc dest += 1
      end
    end
    store 0x40004b04 0
  end
  store8 dest 0
end

;;; strings ;;;

data digits
  "0123456789abcdef\0"
end

fn strToInt str base max
  vars int fact i digs
  let digs = digits
  let fact = 1
  if eq load8u str == 0x2d ;minus
    let fact = -1
    inc str 1
    if max
      inc max -1
    end
  end
  while and (gt max 0) & (gt load8u str 0)
    if eq base == 10
      if eq load8u str == 0x62 ; b
        let base = 2
        inc str 1
        if max
          inc max -1
        end
      end
      if eq load8u str == 0x6f ; o
        let base = 8
        inc str 1
        if max
          inc max -1
        end
      end
      if eq load8u str == 0x78 ; x
        let base = 16
        inc str 1
        if max
          inc max -1
        end
      end
    end
    let i = 0
    while lt i < base
      if or (eq load8u str load8u add digs + i) | (eq add load8u str + 0x20 load8u add digs + i)
        let int = mult int * base
        let int = add int + i
        let i = base
      end
      inc i 1
    end
    if eq i == base
      return mult int * fact
    end
    inc str 1
    if max
      inc max -1
    end
  end
  return mult int * fact
end

fn intToStr int base dest
  vars start len digs
  let digs = digits
  if lt int < 0   ;; minus
    store8 dest 0x2d
    inc dest += 1
    let int = mult int * -1
  end
  let start = dest
  while int
    store8 dest load8u add digs + rem int % base
    inc dest += 1
    let int = div int / base
  end
  if eq start == dest
    store8 dest 0x30
    inc dest += 1
  end
  store8 dest 0
  let len = div (sub dest - start) / 2
  while len
    let dest = sub dest - 1
    let int = load8u dest
    store8 dest load8u start
    store8 start int
    inc start += 1
    inc len += -1
  end
end

fn strLen str max
  vars len
  inc str -1
  inc len -1
  while max
    inc str 1
    inc len 1
    inc max -1
    if eqz load8u str
      let max = 0
    end
  end
  return len
end


;;; memory ;;;

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
end

fn memCopy src dest len
  if gt src > dest
    while gt len > 3
      store dest load src
      inc src 4
      inc dest 4
      inc len -4
    end
    while len
      store8 dest load8u src
      inc src 1
      inc dest 1
      inc len -1
    end
  end
  if lt src < dest
    inc src len
    inc dest len
    while gt len > 3
      inc src -4
      inc dest -4
      store dest load src
      inc len -4
    end
    while len
      inc src -1
      inc dest -1
      store8 dest load8u src
      inc len -1
    end
  end
end


;;; filesystem ;;;

fn open cmd path bytes
  vars bytes
  fill 0 0x40004900 516
  vsync
  store 0x40004900 cmd
  memCopy path 0x40004904 strLen path 250
  store add 0x40004900 + strLen 0x40004900 250 0x20
  intToStr bytes 10 add 0x40004900 + strLen 0x40004900 250
  store8 0x40004b01 strLen 0x40004900 255
  store8 0x40004b00 add 1 + load8u 0x40004bf8
  while load 0x40004b00
    if eqz load8u 0x40004b00
      store8 0x40004b01 0
    end
    if load8u 0x40004b02
      if eq load 0x40004a00 == 0x20206b6f ; ok
        let bytes = strToInt 0x40004a04 10 250
        store8 0x40004b02 0
        if bytes
          return bytes
        else
          return true
        end
      else
        store 0x40004b00 0
      end
    end
  end
  return null
end

globals readPos
fn read dest max
  vars bytes
  if lt readPos < 0x40004a00
    let readPos = 0x40004a00
  end
  while load 0x40004b00
    if eqz load8u 0x40004b00
      store8 0x40004b01 0
    end
    if max
      if load8u 0x40004b02
        store8 dest load8u readPos
        inc dest += 1
        inc readPos += 1
        inc bytes += 1
        inc max += -1
        if eq load8u 0x40004b02 == 1
          let readPos = 0x40004a00
        end
        store8 0x40004b02 sub load8u 0x40004b02 - 1
      else
        let readPos = 0x40004a00
      end
    else
      return bytes
    end
  end
  return bytes
end

fn write src len
  vars bytes
  while load8u 0x40004b00
    if len
      if eqz load8u 0x40004b01
        if lt len < 255
          memCopy src 0x40004900 len
          store8 0x40004b01 len
          inc bytes += len
          inc src += len
          inc len += sub 0 - len
        else
          memCopy src 0x40004900 255
          store8 0x40004b01 255
          inc bytes += 255
          inc src += 255
          inc len += -255
        end
      end
    else
      return bytes
    end
  end
  return bytes
end

data user_prg
  ; this is where programs are loaded to.
end
