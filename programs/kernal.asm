;; z28r asm
skipto 0x00
jump boot

skipto 0x10

fn fun
  vars ptr
  while true
    store 0x40004800 4 ptr
    inc ptr
    if eqz rem ptr % 1024
      store 0x40004804 1 add load 0x40004804 1 + 1
    end
    vsync
  end
end

fn boot
  store 0x40004804 1 add load 0x40004804 1 + 1
  sleep 0x100
  fill 0 0x40000000 0x4c00

  ;call intro
  ;call launcher
  fun
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

