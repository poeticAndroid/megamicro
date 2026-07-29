;; z28r asm
jump main
ext cls         0x0808 0 0 ; cls
ext pset        0x080c 3 0 ; pset x y c
ext pget        0x0810 2 1 ; pget:c x y

globals mouseX mouseY penX penY

fn main args
  cls
  let mouseX = -8
  let mouseY = -8
  while true
    readMouse xhair
    if load8u 0x40000304 ; key pressed
      store8 0x40000000 and 7 load8u 0x40000305
      store 0x40000304 0
      vsync
    end
    if load8u 0x4000030b ; mouse btn pressed
      while or (not eq penX != mouseX) | (not eq penY != mouseY)
        if lt penX < mouseX
          inc penX += 1
        end
        if gt penX > mouseX
          inc penX += -1
        end
        if lt penY < mouseY
          inc penY += 1
        end
        if gt penY > mouseY
          inc penY += -1
        end
        if eq load8u 0x4000030b == 2
          subColor penX penY 4
        else
          addColor penX penY 4
        end
      end
    else
      let penX = mouseX
      let penY = mouseY
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
  if eq load8u 0x40000000 == 0
    let mouseX = mult load8u 0x40000309 * 2
    let mouseY = mult load8u 0x4000030a * 2
    endcall
  end
  if eq load8u 0x40000000 == 1
    let mouseX = mult load8u 0x40000309 * 2
    let mouseY =      load8u 0x4000030a
    endcall
  end
  if eq load8u 0x40000000 == 2
    let mouseX =      load8u 0x40000309
    let mouseY =      load8u 0x4000030a
    endcall
  end
  if eq load8u 0x40000000 == 3
    let mouseX =      load8u 0x40000309
    let mouseY = div  load8u 0x4000030a / 2
    endcall
  end
  if eq load8u 0x40000000 == 4
    let mouseX = mult load8u 0x40000309 * 2
    let mouseY = mult load8u 0x4000030a * 2
    endcall
  end
  if eq load8u 0x40000000 == 5
    let mouseX =      load8u 0x40000309
    let mouseY = mult load8u 0x4000030a * 2
    endcall
  end
  if eq load8u 0x40000000 == 6
    let mouseX =      load8u 0x40000309
    let mouseY =      load8u 0x4000030a
    endcall
  end
  if eq load8u 0x40000000 == 7
    let mouseX = div  load8u 0x40000309 / 2
    let mouseY =      load8u 0x4000030a
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
