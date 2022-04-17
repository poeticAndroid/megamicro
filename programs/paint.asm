;; z28r asm
jump main
ext cls         0x5008 0 0 ; cls
ext pset        0x500c 3 0 ; pset x y c
ext pget        0x5010 2 1 ; pget:c x y
ext rect        0x5014 5 0 ; rect x y w h c
ext pxCopy      0x5018 5 0 ; *pxCopy x y w h src

globals mouseX mouseY

fn main args
  cls
  let mouseX = -8
  let mouseY = -8
  while true
    readMouse xhair
    if load8u 0x40004b04
      store8 0x40004800 and 7 load8u 0x40004b05
      store 0x40004b04 0
      vsync
    end
    if load8u 0x40004b0b ; mouse btn pressed
      if eq load8u 0x40004b0b == 2
        subColor mouseX mouseY 4
      else
        addColor mouseX mouseY 4
      end
    end
    vsync xhair
  end
  return 0
end

fn addColor x y s
  vars x1 y1 x2 y2
  let x1 = sub x - s
  let y1 = sub y - s
  let x2 = add 1 + add x + s
  let y2 = add 1 + add y + s
  let y = y1
  while lt y < y2
    let x = x1
    while lt x < x2
      pset x y add 1 + pget x y
      inc x += 1
    end
    inc y += 1
  end
end

fn subColor x y s
  vars x1 y1 x2 y2
  let x1 = sub x - s
  let y1 = sub y - s
  let x2 = add 1 + add x + s
  let y2 = add 1 + add y + s
  let y = y1
  while lt y < y2
    let x = x1
    while lt x < x2
      if pget x y
        pset x y sub (pget x y) - 1
      end
      inc x += 1
    end
    inc y += 1
  end
end

fn readMouse
  if eq load8u 0x40004800 == 0
    let mouseX = mult load8u 0x40004b09 * 2
    let mouseY = mult load8u 0x40004b0a * 2
    endcall
  end
  if eq load8u 0x40004800 == 1
    let mouseX = mult load8u 0x40004b09 * 2
    let mouseY =      load8u 0x40004b0a
    endcall
  end
  if eq load8u 0x40004800 == 2
    let mouseX =      load8u 0x40004b09
    let mouseY =      load8u 0x40004b0a
    endcall
  end
  if eq load8u 0x40004800 == 3
    let mouseX =      load8u 0x40004b09
    let mouseY = div  load8u 0x40004b0a / 2
    endcall
  end
  if eq load8u 0x40004800 == 4
    let mouseX = mult load8u 0x40004b09 * 2
    let mouseY = mult load8u 0x40004b0a * 2
    endcall
  end
  if eq load8u 0x40004800 == 5
    let mouseX =      load8u 0x40004b09
    let mouseY = mult load8u 0x40004b0a * 2
    endcall
  end
  if eq load8u 0x40004800 == 6
    let mouseX =      load8u 0x40004b09
    let mouseY =      load8u 0x40004b0a
    endcall
  end
  if eq load8u 0x40004800 == 7
    let mouseX = div  load8u 0x40004b09 / 2
    let mouseY =      load8u 0x40004b0a
    endcall
  end
end

fn xhair
  vars i j
  let i = sub mouseX - 4
  let j = add mouseX + 5
  while lt i < j
    pset i mouseY xor -1 pget i mouseY
    inc i += 1
  end
  let i = sub mouseY - 4
  let j = add mouseY + 5
  while lt i < j
    pset mouseX i xor -1 pget mouseX i
    inc i += 1
  end
end
