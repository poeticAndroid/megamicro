;; z28r asm

fn main
  store 0x40004900 4 0x64616f6c ; load
  store 0x40004904 4 0x20202020 ; spaces
  access filename 0x40005000
  reset
end

fn access file dest
  vars drive len
  store 0x40004b00 4 0
  while and (eqz eq loadu file 1 0x0) (eqz eq loadu file 1 0x3a)
    inc file
  end
  dec file
  let drive = sub loadu file 1 0x2f
  inc file
  inc file
  vsync
  memCopy file 0x40004908 247
  store 0x400049ff 1 0
  store 0x40004b01 1 strLen 0x40004900 255
  store 0x40004b00 1 drive
  while eqz loadu 0x40004b02 1
    if eqz loadu 0x40004b00 1
      store 0x40004b00 4 0
      return 0
    end
  end
  if eqz eq load 0x40004a00 4 0x20206b6f  ;; not ok
    store 0x40004b00 4 0
    return 0
  end
  let len = strToInt 0x40004a04 10 255
  store 0x40004b02 1 0
  while gt len 0 
    while eqz loadu 0x40004b02 1
      if eqz loadu 0x40004b00 1
        store 0x40004b00 4 0
        return 0
      end
    end
    memCopy 0x40004a00 dest loadu 0x40004b02 1
    let dest = add dest loadu 0x40004b02 1
    let len = sub len loadu 0x40004b02 1
    store 0x40004b02 1 0
  end
  store 0x40004b00 4 0
  return 1
end


fn memCopy src dest len
  if gt src dest
    while gt len 3
      store dest 4 loadu src 4
      let src = add src 4
      let dest = add dest 4
      let len = sub len 4
    end
    if len
      store dest len loadu src len
    end
  end
  if lt src dest
    let src = add src len
    let dest = add dest len
    while gt len 3
      let src = sub src 4
      let dest = sub dest 4
      store dest 4 loadu src 4
      let len = sub len 4
    end
    if len
      let src = sub src len
      let dest = sub dest len
      store dest len loadu src 4
    end
  end
end

fn strLen str max
  vars len
  dec str
  dec len
  while max
    inc str
    inc len
    dec max
    if eqz loadu str 1
      let max = 0
    end
  end
  return len
end

fn strToInt str base max
  vars int fact i digs
  let digs = digits
  let fact = 1
  if eq loadu str 1 0x2d ;minus
    let fact = -1
    inc str
    if max
      dec max
    end
  end
  while and (gt max 0) (gt loadu str 1 0)
    if eq base 10
      if eq loadu str 1 0x62 ; b
        let base = 2
        inc str
        if max
          dec max
        end
      end
      if eq loadu str 1 0x6f ; o
        let base = 8
        inc str
        if max
          dec max
        end
      end
      if eq loadu str 1 0x78 ; x
        let base = 16
        inc str
        if max
          dec max
        end
      end
    end
    let i = 0
    while lt i base
      if or (eq loadu str 1 loadu add digs i 1) (eq add loadu str 1 0x20 loadu add digs i 1)
        let int = mult int base
        let int = add int i
        let i = base
      end
      inc i
    end
    if eq i base
      return mult int fact
    end
    inc str
    if max
      dec max
    end
  end
  return mult int fact
end

data filename
  "disk0:/kernal.prg\0"
end

data digits
  "0123456789abcdef\0"
end