;; z28r asm
jump main
ext cls         0x5008 0 0 ; cls
ext pset        0x500c 3 0 ; pset x y c
ext pget        0x5010 2 1 ; pget:c x y
ext rect        0x5014 5 0 ; rect x y w h c
ext pxCopy      0x5018 5 0 ; *pxCopy x y w h src

globals mouseX mouseY color

fn main args
  let color = 0x40000100
  while gt color > 0x40000000
    inc color += -1
    store8 color color
  end
  let mouseX = -8
  let mouseY = -8
  let color = -1
  while true
    xhair
    if load8u 0x40004b04
      store8 0x40004800 and 7 load8u 0x40004b05
      store 0x40004b04 0
      vsync
    end
    readMouse
    if load8u 0x40004b0b ; mouse btn pressed
      if eq load8u 0x40004b0b == 2
        let color = pget mouseX mouseY
        store8 0x40000100 color
      else
        rect (sub mouseX - 4) (sub mouseY - 4) 8 8 color
      end
    end
    xhair
    vsync
  end
  return 0
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
