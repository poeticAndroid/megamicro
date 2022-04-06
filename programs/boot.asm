;; z28r asm

fn main
  store 0x40004900 0x64616f6c ; load
  store 0x40004904 0x20202020 ; spaces
  access filename 0x40005000
  reset
end

fn access file dest
  vars drive len
  store 0x40004b00 0
  while and (eqz eq load8u file == 0x0) & (eqz eq load8u file == 0x3a)
    inc file 1
  end
  inc file -1
  let drive = sub load8u file - 0x2f
  inc file 1
  inc file 1
  vsync
  memCopy file 0x40004908 247
  store8 0x400049ff 0
  store8 0x40004b01 strLen 0x40004900 255
  store8 0x40004b00 drive
  while eqz load8u 0x40004b02
    if eqz load8u 0x40004b00
      store 0x40004b00 0
      return 0
    end
  end
  if eqz eq load 0x40004a00 == 0x20206b6f  ;; not ok
    store 0x40004b00 0
    return 0
  end
  let len = strToInt 0x40004a04 10 255
  store8 0x40004b02 0
  while gt len > 0 
    while eqz load8u 0x40004b02
      if eqz load8u 0x40004b00
        store 0x40004b00 0
        return 0
      end
    end
    memCopy 0x40004a00 dest load8u 0x40004b02
    let dest = add dest + load8u 0x40004b02
    let len = sub len - load8u 0x40004b02
    store8 0x40004b02 0
  end
  store 0x40004b00 0
  return 1
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

data filename
  "disk0:/kernal.prg\0"
end
data digits
  "0123456789abcdef\0"
end