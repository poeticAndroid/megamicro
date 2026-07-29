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
jump openFile
skipto 0x40
jump readFile
skipto 0x44
jump writeFile

skipto 0x50



fn boot
  store 0x40000000 add 1 + load 0x40000000
  sleep 0x100
  resethw

  intro
  bootDisk
end

data loading_str "Loading \0"
end
data dots_str " ... \0"
end
data mainFile_str "main.prg\0"
end
data root_str "/\0"
end
data reboot_str
  "\n\n"
  "\t\t\x88\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x89\n"
  "\t\t\x90 Insert bootable media into any \x90\n"
  "\t\t\x90 drive and press Alt+Q to reboot\x90\n"
  "\t\t\x8a\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x8b\n"
  0
end
fn bootDisk
  vars len drive
  let drive = 4
  while drive
    inc drive += -1
    store 0x400003f8 drive
    drop openFile 0x20206463 root_str 0 ; cd
  end
  while lt drive < 4
    store 0x400003f8 drive
    if load8u 0x400003fc
      printChr 0x0a
    end
    printStr loading_str -1
    printChr 0x44
    intToStr drive 10 main_prg
    printStr main_prg 4
    printChr 0x3a
    printStr root_str -1
    printStr mainFile_str -1
    printStr dots_str -1
    let len = openFile 0x20746567 mainFile_str 0 ; get
    if len
      intToStr len 10 main_prg
      printStr main_prg 16
      printStr bytes_str -1
      printChr 0x0a
      drop readFile main_prg len
      runUser
    else
      printStr 0x40000200 255
    end
    inc drive += 1
  end
  printStr reboot_str -1
  halt
  reset
end

data return_str "\nReturn code: \0"
end
fn runUser
  store main_prg call main_prg 1 0 0
  resethw
  screenmode 0
  colors -1 0
  intToStr load main_prg 10 main_prg
  printStr return_str -1
  printStr main_prg 16
  printChr 0x0a
  printChr 0x0a
end

data intro_str "\t    Mega      ///\t\t/// MegaMicro ///\n\n\n\0"
end
data cpu_str "CPU:    z28r \0"
end
data speed_str "Speed:  \0"
end
data ips_str " ips\n\0"
end
data memory_str "Memory: \0"
end
data bytes_str " bytes\n\0"
end
fn intro
  vars kb ins sec
  colors -1 0
  screenmode 1
  cls
  printStr intro_str -1
  screenmode 0

  printStr cpu_str -1
  intToStr cpuver 10 main_prg
  printStr main_prg -1
  printChr 0x0a

  printStr speed_str -1
  let sec = load8u 0x40000311
  let ins = 8
  while eq sec == load8u 0x40000311
  end
  let sec = load8u 0x40000311
  while eq sec == load8u 0x40000311
    inc ins += 12
  end
  intToStr ins 10 main_prg
  printStr main_prg -1
  printStr ips_str -1

  printStr memory_str -1
  sleep 0x200
  let kb = 0x40000000
  while lt kb < absadr stackptr
    inc kb += 0x10000
  end
  let kb = xor kb ^ 0x40000000
  intToStr kb 10 main_prg
  printStr main_prg -1
  printStr bytes_str -1

  printChr 0x0a
end

fn resethw
  fill 0 0x40000004 780
  store 0x40000004 absadr 0xbfffb666
  store 0x40000008 absadr 0xbfffb666
end


;;; graphics ;;;

fn cls
  vars adr end bg i
  let adr = or 0x40000000 | load 0x40000008
  store 0x40000008 adr
  let end = add adr + 0x4800
  let bg = load8u 0x400003fe
  let i = 32
  while i
    inc i -1
    pset i 0 bg
  end
  let bg = load adr

  while lt adr < end
    store adr bg
    inc adr 4
  end

  store8 0x400003fc 0
  store8 0x400003fd 0
end

fn screenmode mode
  if eq load8u 0x40000000 == mode
    endcall
  end
  store8 0x40000000 mode
  vsync
end

fn colors fg bg
  store8 0x400003ff fg
  store8 0x400003fe bg
end

fn pset x y c
  if lt x < 0
    endcall
  end
  if lt y < 0
    endcall
  end
  vars w
  let w = mult 8 * load8u 0x40000002
  if gt x > sub w - 1
    endcall
  end
  vars h
  let h = mult 8 * load8u 0x40000003
  if gt y > sub h - 1
    endcall
  end

  setwrite load 0x40000008 load8u 0x40000001
  skipwrite add x + mult y * w
  write c
end

fn pget x y
  if lt x < 0
    return 0
  end
  if lt y < 0
    return 0
  end
  vars w
  let w = mult 8 * load8u 0x40000002
  if gt x > sub w - 1
    return 0
  end
  vars h
  let h = mult 8 * load8u 0x40000003
  if gt y > sub h - 1
    return 0
  end

  setread load 0x40000004 load8u 0x40000001
  skipread add x + mult y * w
  return read
end

fn rect x1 y1 w h c
  vars x y x2 y2
  let x2 = add x1 + w
  let y2 = add y1 + h
  let y = y1
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
  let y = y1
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
  if not px
    endcall
  end
  vars start edge end clear keep h bg i
  let start = or 0x40000000 | load 0x40000008
  let end = add start + 0x4800
  let h = mult 8 * load8u 0x40000003
  let clear = mult px * div 0x4800 / h
  let keep = sub 0x4800 - clear
  let bg = load8u 0x400003fe
  if gt clear > 0
    if gt clear > 0x4800
      let bg = load 0x400003fc
      cls
      store 0x400003fc bg
      endcall
    end
    let i = 32
    while i
      inc i -1
      pset i 0 bg
    end
    let bg = load start

    let edge = add start + clear
    memCopy edge start keep
    let edge = add start + keep
    fill bg edge clear
  else
    let clear = mult clear * -1
    if gt clear > 0x4800
      let bg = load 0x400003fc
      cls
      store 0x400003fc bg
      endcall
    end
    let keep = sub 0x4800 - clear
    let edge = add start + clear
    memCopy start edge keep

    let i = 32
    while i
      inc i -1
      pset i 0 bg
    end
    let bg = load start

    fill bg start clear
  end
end

fn printChr char
  vars col row
  let col = load8s 0x400003fc
  let row = load8s 0x400003fd

  if eq char == 0x08 ; backspace
    inc col -1
    while lt col < 0
      inc col load8u 0x40000002
      inc row -1
      store8 0x400003fd row
    end
    store8 0x400003fc col
    endcall
  end
  if eq char == 0x09 ; tab
    inc col 1
    while rem col % 8
      inc col 1
    end
    store8 0x400003fc col
    endcall
  end
  if eq char == 0x0a ; newline
    let col = 0
    inc row 1
    store8 0x400003fc col
    store8 0x400003fd row
    endcall
  end
  if eq char == 0x0d ; carriage return
    let col = 0
    store8 0x400003fc col
    endcall
  end
  if lt char < 0x20 ; other control code
    endcall
  end

  vars lastCol lastRow x y font w linerest
  let w = mult 8 * load8u 0x40000002
  let linerest = sub w - 8
  let lastCol = sub load8u 0x40000002 - 1
  let lastRow = sub load8u 0x40000003 - 1
  let font = add 0x40000400 + mult 8 * and 127 & char

  while gt col > lastCol
    inc row 1
    inc col -1
    inc col sub 0 - lastCol
  end
  if lt row < 0
    scroll mult 8 * row
    let row = 0
  end
  if gt row > lastRow
    scroll mult 8 * sub row - lastRow
    let row = lastRow
  end

  let x = mult 8 * col
  let y = mult 8 * row
  setwrite load 0x40000008 load8u 0x40000001
  skipwrite add x + mult y * w

  setread font 1
  let y = 8
  while y
    let x = 8
    while x
      write load8u add 0x400003fe + read
      inc x -1
    end
    skipwrite linerest
    inc y -1
  end

  inc col 1
  store8 0x400003fc col
  store8 0x400003fd row
end

fn printStr str max
  vars char
  let char = load8u str
  while and not not char & not not max
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
    inc dest += 1
  end
  while lt dest < end
    store8 dest 0
    inc dest += 1
  end
  store8 dest 0
  let dest = start
  while load8u dest
    printChr load8u dest
    inc dest += 1
  end
  while not done
    printChr 0x20
    printChr 0x08
    store8 0x400003ff xor -1 load8u 0x400003ff
    store8 0x400003fe xor -1 load8u 0x400003fe
    if load8u dest
      printChr load8u dest
    else
      printChr 0x20
    end
    store8 0x400003ff xor -1 load8u 0x400003ff
    store8 0x400003fe xor -1 load8u 0x400003fe
    printChr 0x08
    while not load 0x40000304
      vsync
    end
    if eq load8u 0x40000306 == 0x23 ; End
      while load8u dest
        printChr load8u dest
        inc dest += 1
      end
    end
    if eq load8u 0x40000306 == 0x24 ; Home
      if load8u dest
        printChr load8u dest
      else
        printChr 0x20
      end
      printChr 0x08
      while gt dest > start
        printChr 0x08
        inc dest += -1
      end
    end
    if eq load8u 0x40000306 == 0x25 ; Left
      if gt dest > start
        if load8u dest
          printChr load8u dest
        else
          printChr 0x20
        end
        printChr 0x08
        printChr 0x08
        inc dest += -1
      end
    end
    if eq load8u 0x40000306 == 0x26 ; Up
      let done = load8u 0x40000002
      if load8u dest
        printChr load8u dest
      else
        printChr 0x20
      end
      printChr 0x08
      while done
        if gt dest > start
          printChr 0x08
          inc dest += -1
        end
        inc done += -1
      end
    end
    if eq load8u 0x40000306 == 0x27 ; Right
      if load8u dest
        printChr load8u dest
        inc dest += 1
      end
    end
    if eq load8u 0x40000306 == 0x28 ; Down
      let done = load8u 0x40000002
      while done
        if load8u dest
          printChr load8u dest
          inc dest += 1
        end
        inc done += -1
      end
    end
    if eq load8u 0x40000305 == 0x08 ; Backspace
      if gt dest > start
        printChr 0x08
        printChr 0x20
        if load8u dest
          printChr load8u dest
        else
          printChr 0x20
        end
        printChr 0x08
        printChr 0x08
        if load8u dest
          inc dest += -1
          store8 dest 0x20
        else
          inc dest += -1
          store8 dest 0
        end
      end
    end
    if eq load8u 0x40000305 == 0x0a ; Enter
      if load8u dest
        printChr load8u dest
      else
        printChr 0x20
      end
      printChr 0x08
      let done = true
    end
    if gt load8u 0x40000305 > 0x1f ; any printable
      if lt dest < end
        store8 dest load8u 0x40000305
        printChr load8u dest
        inc dest += 1
      end
    end
    store 0x40000304 0
  end
  while gt load8u dest > 0x1f
    printChr load8u dest
    inc dest += 1
  end
  store8 dest 0
  printChr 0x0a
end

;;; strings ;;;

data digits "0123456789abcdef\0"
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
    if not load8u str
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
  while len
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

fn openFile cmd path bytes
  vars bytes
  fill 0 0x40000100 516
  vsync
  store 0x40000100 cmd
  memCopy path 0x40000104 strLen path 250
  store add 0x40000100 + strLen 0x40000100 250 0x20
  intToStr bytes 10 add 0x40000100 + strLen 0x40000100 250
  store8 0x40000301 strLen 0x40000100 255
  store8 0x40000300 add 1 + load8u 0x400003f8
  while load 0x40000300
    if not load8u 0x40000300
      store8 0x40000301 0
    end
    if load8u 0x40000302
      if eq load 0x40000200 == 0x20206b6f ; ok
        let bytes = strToInt 0x40000204 10 250
        store8 0x40000302 0
        if bytes
          return bytes
        else
          return true
        end
      else
        store 0x40000300 0
      end
    end
  end
  return null
end

globals readPos
fn readFile dest max
  vars bytes
  if lt readPos < 0x40000200
    let readPos = 0x40000200
  end
  while load 0x40000300
    if not load8u 0x40000300
      store8 0x40000301 0
    end
    if max
      if load8u 0x40000302
        store8 dest load8u readPos
        inc dest += 1
        inc readPos += 1
        inc bytes += 1
        inc max += -1
        if eq load8u 0x40000302 == 1
          let readPos = 0x40000200
        end
        store8 0x40000302 sub load8u 0x40000302 - 1
      else
        let readPos = 0x40000200
      end
    else
      return bytes
    end
  end
  return bytes
end

fn writeFile src len
  vars bytes
  while load8u 0x40000300
    if len
      if not load8u 0x40000301
        if lt len < 255
          memCopy src 0x40000100 len
          store8 0x40000301 len
          inc bytes += len
          inc src += len
          inc len += sub 0 - len
        else
          memCopy src 0x40000100 255
          store8 0x40000301 255
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

data main_prg ; this is where programs are loaded to.
end
