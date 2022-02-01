(() => {
  let cpu,
    ram = new WebAssembly.Memory({ initial: 4 }),
    mem = new Uint8Array(ram.buffer),
    speed = 1,
    vsyncfps = 9000,
    fps = 9000,
    fpssec = 0,
    running = false,
    waitingforuser = false,
    sleep = false,
    kbEnabled = true,
    kbBuffer = []

  let diskInitialized = false,
    diskInput = [],
    diskOutput = []

  let img,
    canvas = document.querySelector("canvas"),
    g = canvas.getContext("2d"),
    maxwidth = 1024,
    gmode = -1

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  async function init() {
    addEventListener("resize", resize); resize()
    addEventListener("keydown", onUser)
    addEventListener("keyup", onUser)
    canvas.addEventListener("mousedown", onUser)
    canvas.addEventListener("mouseup", onUser)
    canvas.addEventListener("mousemove", onUser)

    document.querySelector("#asmTxt").value = localStorage.getItem("program.asm") || `;;Peti asm
    ;; docs at https://github.com/poeticAndroid/peti

    (main: ;; must be the first function
      (@vars $argv
        )
      (sys (0x03) (@call memstart) (-1) (0x400) (3)) ;; printstr syscall
    
      (@return (0)) ;; return to dos with no error
    )
    
    (memstart: ;; must be the last function
      (@return (add (8) (here)))
    )

    (@string 0xe "Hello world!\\n")
    `.replaceAll("\n    ", "\n")
    document.querySelector("#adrTxt").value = localStorage.getItem("?adr") || "0x10000"
    document.querySelector("#speedTxt").value = localStorage.getItem("?speed") || "16"
    document.querySelector("#speedTxt").addEventListener("change", changeSpeed); changeSpeed()
    document.querySelector("#compileBtn").addEventListener("click", compileAsm)
    document.querySelector("#stopBtn").addEventListener("click", e => { running = false; clearTimeout(sleep) })
    document.querySelector("#stepBtn").addEventListener("click", e => cpu.run(1))
    document.querySelector("#runBtn").addEventListener("click", e => running = true)

    document.querySelector("#asmTxt").addEventListener("focus", e => kbEnabled = false)
    document.querySelector("#adrTxt").addEventListener("focus", e => kbEnabled = false)
    document.querySelector("#speedTxt").addEventListener("focus", e => kbEnabled = false)

    for (let i = 0; i < mem.length; i++) {
      mem[i] = 255 * Math.random()
      if (i > 8) {
        mem[i] = mem[i] & mem[1]
        mem[i] = mem[i] ^ mem[2]
      }
    }
    await loadCPU("cpu.wasm", { pcb: { ram: ram } })
    hwClock()
    render()
    window.mem = mem
    window.kbBuffer = kbBuffer
    console.log("cpu", cpu)
    console.log("mem", mem)
    console.log("img", img)
    setTimeout(loadROM, 256)
  } init()

  async function loadCPU(path, imports) {
    let bin = await (await fetch(path)).arrayBuffer()
    let wasm = await WebAssembly.instantiate(bin, imports)
    cpu = wasm.instance.exports
    window.cpu = cpu
  }

  function loadROM() {
    let bin
    bin = JSON.parse("[" +
      atob(kernal)
      + "]")
    mem.set(bin, 0x400)
    bin = JSON.parse("[" +
      atob(font)
      + "]")
    mem.set(bin, 0xb000)
    running = true
  }

  function render(t = 0) {
    let opcode
    if (running) {
      if (kbBuffer.length && mem[0xb4f4] === 0) {
        mem[0xb4f5] = kbBuffer.shift()
        mem[0xb4f4] = Math.min(255, 1 + kbBuffer.length)
      }
      try {
        opcode = cpu.run(speed)
      } catch (err) {
        console.error("CPU CRASH!! OH NOEZ!! O_O")
        running = false
        return setTimeout(() => {
          delete cpu
          loadCPU("cypu.wasm", { pcb: { ram: ram } }).then(
            render()
          )
        }, 16384)
      }
      // console.log(cpu.getReg(0), opcode)
      switch (opcode) {
        case 0x00: // halt
          running = false
          break
        case 0x01: // sleep
          running = false
          let adr = cpu.getVS()
          uint8.set(mem.slice(adr, adr + 4))
          sleep = setTimeout(() => {
            running = true
          }, int32[0])
          break
        case 0x02:
          vsyncfps++
          break
      }
    }

    // rendering
    let mode = mem[0xb4f8],
      bpp = Math.pow(2, mode & 0x3)
    if (gmode !== mode) {
      let pw = 1, ph = 1
      let w, h, px

      px = (18 * 1024 * 8) / bpp
      if (bpp & 0xa) {
        pw = 1 + (mode & 0x4) / 4
        ph = 3 - pw
      }
      w = ((mode & 0x3) > 1 ? 256 : 512) / pw
      h = px / w
      while (w * pw < maxwidth) {
        pw *= 2
        ph *= 2
      }

      canvas.width = w; canvas.height = h
      canvas.style.width = (w * pw) + "px"
      canvas.style.height = (h * ph) + "px"
      if (mode === 4) canvas.style.backgroundColor = "#241"
      else canvas.style.backgroundColor = "#000"
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
      gmode = mode
    }
    let start = 0xb800
    let end = 0x10000
    let i = 0
    for (let m = start; m < end; m++) {
      i += renderbyte(m, i, bpp, mode & 4)
    }

    g.putImageData(img, 0, 0)
    updateMonitor(cpu.getPC())
    updateStack()

    fps++
    if (fpssec !== Math.floor(t / 1000)) {
      document.querySelector("#fps").textContent = vsyncfps + "/" + fps + " fps"
      fps = 0
      vsyncfps = 0
      fpssec = Math.floor(t / 1000)
    }

    requestAnimationFrame(render)
    // setTimeout(render, 256)
  }

  function renderbyte(madr, iadr, bpp, alt) {
    let byte = mem[madr]
    let ppb = 8 / bpp
    let mask = Math.pow(2, bpp) - 1
    iadr += 4 * ppb
    let bm = 0xf
    let bs = 4
    let rm = 0xf
    let rs = 4
    let gm = 0xf
    let gs = 4
    while (bs + rs + gs > bpp) {
      if (bs + rs + gs > bpp) {
        bs--; bm = bm >> 1
      }
      if (bs + rs + gs > bpp) {
        rs--; rm = rm >> 1
      }
      if (bs + rs + gs > bpp) {
        gs--; gm = gm >> 1
      }
    }
    if (alt && bpp === 4) {
      bm = 15; rm = 15; gm = 15
      bs = 0; rs = 0; gs = 4
    }
    if (bpp === 2) {
      bm = 1; rm = 2; gm = 3
      gs = 2; rs = 0
    }
    if (bpp === 1) {
      bm = 1; rm = 1; gm = 1
    }
    if (alt && bpp === 1) {
      for (let i = 0; i < ppb; i++) {
        iadr -= 4
        img.data[iadr + 2] = (byte & bm) ? 3 : 15
        byte = byte >> bs
        img.data[iadr + 0] = (byte & rm) ? 7 : 31
        byte = byte >> rs
        img.data[iadr + 1] = (byte & gm) ? 15 : 63
        byte = byte >> gs
      }
    } else {
      for (let i = 0; i < ppb; i++) {
        iadr -= 4
        img.data[iadr + 2] = 255 * ((byte & bm) / bm)
        byte = byte >> bs
        img.data[iadr + 0] = 255 * ((byte & rm) / rm)
        byte = byte >> rs
        img.data[iadr + 1] = 255 * ((byte & gm) / gm)
        byte = byte >> gs
      }
    }
    return ppb * 4
  }

  function onUser(e) {
    if (e.type.slice(0, 5) === "mouse") {
      mem[0xb4f9] = Math.max(0, (e.offsetX / e.target.clientWidth) * 255)
      mem[0xb4fa] = Math.max(0, (e.offsetY / e.target.clientHeight) * 144)
      if (mem[0xb4fb] = e.buttons) kbEnabled = true
    }

    if (e.type === "keyup") {
      mem[0xb4f7] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
    }
    if (e.type === "keydown") {
      if (kbEnabled) {
        mem[0xb4f6] = e.keyCode
        mem[0xb4f7] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
        if (!e.ctrlKey && !e.metaKey) {
          if (e.key === "Backspace") {
            kbBuffer.push(0x08)
          }
          if (e.key === "Tab") {
            kbBuffer.push(0x09)
            e.preventDefault()
          }
          if (e.key === "Enter") {
            kbBuffer.push(0x0a)
          }
          if (e.key === "Escape") {
            kbBuffer.push(0x1b)
          }
          if (e.key.length === 1) {
            kbBuffer.push(e.key.charCodeAt(0))
          }
        }
      }
      if ((e.ctrlKey || e.metaKey) && e.key === "q") {
        compileAsm()
      }
    }
    if (!running) kbBuffer.length = 0

    if (waitingforuser) {
      waitingforuser = false
      running = true
    }
  }

  function handleDrive() {
    //todo
  }

  function hwClock() {
    let now = new Date()
    mem[0xb4e8] = now.getYear()
    mem[0xb4e9] = now.getMonth()
    mem[0xb4ea] = now.getDate()
    mem[0xb4eb] = now.getDay()
    mem[0xb4ec] = now.getHours()
    mem[0xb4ed] = now.getMinutes()
    mem[0xb4ee] = now.getSeconds()
    mem[0xb4ef] = 0
    setTimeout(hwClock, 1000 - now.getMilliseconds())
  }

  function changeSpeed(e) {
    let s = eval(document.querySelector("#speedTxt").value)
    speed = Math.pow(2, s)
    localStorage.setItem("?speed", document.querySelector("#speedTxt").value)
  }

  function compileAsm(e) {
    let asm = document.querySelector("#asmTxt").value
    let offset = eval(document.querySelector("#adrTxt").value)
    let bin = assemble(asm)
    mem.set(bin, offset)
    cpu.setPC(0x400)
    cpu.setCS(0)
    cpu.setVS(0)
    console.log(dumpMem(offset, bin.length))
    localStorage.setItem("program.asm", asm)
    localStorage.setItem("?adr", document.querySelector("#adrTxt").value)
  }

  function dumpMem(adr, len, pc) {
    adr = Math.max(0, adr)
    let txt = ""
    let end = adr + len
    while (adr < end) {
      txt += (adr == pc ? "> " : "  ")
      txt += ("000000" + adr.toString(16)).slice(-5) + " "
      txt += ("00" + mem[adr].toString(16)).slice(-2) + " "
      txt += (opcodes[mem[adr]] || "") + " "
      if (opcodes[mem[adr]] === "const") {
        uint8.set(mem.slice(adr + 1, adr + 5))
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += 4
      }
      txt += "\n"
      adr++
    }
    return txt
  }

  function dumpStack(len) {
    let adr = cpu.getVS()
    let cs = cpu.getCS()
    let txt = ""
    while (len > 0) {
      if (cs === adr) {
        txt += "--------\n"
        cs = -1
        len--
      }
      uint8.set(mem.slice(adr - 4, adr))
      if (adr > 0) {
        txt += "0x" + ("00000000" + int32[0].toString(16)).slice(-8) + " " + int32[0] + " "
        if (float32[0]) txt += float32[0]
      }
      if (cs < 0) cs = int32[0]
      len--
      adr -= 4
      if (adr <= 0) len = 0
      txt += "\n"
    }
    return txt
  }

  function updateMonitor(pc) {
    let txt = ""
    let i = 32
    while (!txt.includes(">"))
      txt = dumpMem(pc - i++, 64, pc)
    txt = txt.slice(0, txt.indexOf(">"))
    txt = txt.split("\n").slice(-6).join("\n")
    txt += dumpMem(pc, 64, pc)
    txt = txt.split("\n").slice(0, 17).join("\n")
    document.querySelector("#monitorPre").textContent = txt
  }

  function updateStack() {
    document.querySelector("#stackPre").textContent = "Stack size: 0x" + cpu.getVS().toString(16) + "\n" + dumpStack(10)
  }

  function resize(e) {
    if (window.innerWidth < 1070 || window.innerHeight < 700) {
      maxwidth = 512
    } else {
      maxwidth = 1024
    }
    gmode = -1
  }

  const font = 'MCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMTUsMTUsMTUsMTUsMCwwLDAsMCwyNDAsMjQwLDI0MCwyNDAsMCwwLDAsMCwyNTUsMjU1LDI1NSwyNTUsMTUsMTUsMTUsMTUsMCwwLDAsMCwxNSwxNSwxNSwxNSwxNSwxNSwxNSwxNSwxNSwxNSwxNSwxNSwyNDAsMjQwLDI0MCwyNDAsMTUsMTUsMTUsMTUsMjU1LDI1NSwyNTUsMjU1LDI0MCwyNDAsMjQwLDI0MCwwLDAsMCwwLDI0MCwyNDAsMjQwLDI0MCwxNSwxNSwxNSwxNSwyNDAsMjQwLDI0MCwyNDAsMjQwLDI0MCwyNDAsMjQwLDI0MCwyNDAsMjQwLDI0MCwyNTUsMjU1LDI1NSwyNTUsMjU1LDI1NSwyNTUsMjU1LDAsMCwwLDAsMjU1LDI1NSwyNTUsMjU1LDE1LDE1LDE1LDE1LDI1NSwyNTUsMjU1LDI1NSwyNDAsMjQwLDI0MCwyNDAsMjU1LDI1NSwyNTUsMjU1LDI1NSwyNTUsMjU1LDI1NSwwLDAsMCwwLDAsMCwwLDAsMjQsMjQsMjQsMjQsMCwwLDAsMCwwLDAsMCwxNSwxNSwwLDAsMCwyNCwyNCwyNCwzMSwxNSwwLDAsMCwwLDAsMCwwLDI0LDI0LDI0LDI0LDI0LDI0LDI0LDI0LDI0LDI0LDI0LDI0LDAsMCwwLDE1LDMxLDI0LDI0LDI0LDI0LDI0LDI0LDMxLDMxLDI0LDI0LDI0LDAsMCwwLDI0MCwyNDAsMCwwLDAsMjQsMjQsMjQsMjQ4LDI0MCwwLDAsMCwwLDAsMCwyNTUsMjU1LDAsMCwwLDI0LDI0LDI0LDI1NSwyNTUsMCwwLDAsMCwwLDAsMjQwLDI0OCwyNCwyNCwyNCwyNCwyNCwyNCwyNDgsMjQ4LDI0LDI0LDI0LDAsMCwwLDI1NSwyNTUsMjQsMjQsMjQsMjQsMjQsMjQsMjU1LDI1NSwyNCwyNCwyNCwwLDAsMCwwLDAsMCwwLDAsMTYsMTYsMTYsMTYsMTYsMCwxNiwwLDY4LDY4LDAsMCwwLDAsMCwwLDM2LDEyNiwzNiwzNiwzNiwxMjYsMzYsMCwxNiw2MCw2NCw1Niw0LDEyMCwxNiwwLDY2LDE2NCw3MiwxNiwzNiw3NCwxMzIsMCwyOCwzNCwzNiwyNCwzNyw2Niw2MSwwLDgsOCwwLDAsMCwwLDAsMCw4LDE2LDMyLDMyLDMyLDE2LDgsMCwxNiw4LDQsNCw0LDgsMTYsMCwxNiw4NCw1Niw4NCwxNiwwLDAsMCwwLDE2LDE2LDEyNCwxNiwxNiwwLDAsMCwwLDAsMCw4LDgsMTYsMCwwLDAsMCwxMjYsMCwwLDAsMCwwLDAsMCwwLDAsMCwxNiwwLDIsNCw4LDE2LDMyLDY0LDEyOCwwLDU2LDY4LDY4LDY4LDY4LDY4LDU2LDAsMTYsNDgsMTYsMTYsMTYsMTYsMTI0LDAsNTYsNjgsNCwyNCwzMiw2NCwxMjQsMCw1Niw2OCw0LDI0LDQsNjgsNTYsMCwyNCw0MCw3Miw3MiwxMjQsOCw4LDAsMTI0LDY0LDEyMCw0LDQsNjgsNTYsMCw1Niw2OCw2NCwxMjAsNjgsNjgsNTYsMCwxMjQsNCw4LDE2LDE2LDE2LDE2LDAsNTYsNjgsNjgsNTYsNjgsNjgsNTYsMCw1Niw2OCw2OCw2MCw0LDY4LDU2LDAsMCwxNiwwLDAsMTYsMCwwLDAsMCw4LDAsMCw4LDE2LDAsMCw0LDgsMTYsMzIsMTYsOCw0LDAsMCwwLDEyNiwwLDEyNiwwLDAsMCwxNiw4LDQsMiw0LDgsMTYsMCw1Niw2OCw0LDI0LDE2LDAsMTYsMCw2MCw2NiwxNTMsMTY1LDE2NSwxNTgsNjQsNjAsMTYsNDAsNDAsNjgsMTI0LDEzMCwxMzAsMCwyNTIsMTMwLDEzMCwyNTIsMTMwLDEzMCwyNTIsMCwxMjQsMTMwLDEyOCwxMjgsMTI4LDEzMCwxMjQsMCwyNTIsMTMwLDEzMCwxMzAsMTMwLDEzMCwyNTIsMCwyNTQsMTI4LDEyOCwyNDgsMTI4LDEyOCwyNTQsMCwyNTQsMTI4LDEyOCwyNDgsMTI4LDEyOCwxMjgsMCwxMjQsMTMwLDEyOCwxNDIsMTMwLDEzMCwxMjQsMCwxMzAsMTMwLDEzMCwyNTQsMTMwLDEzMCwxMzAsMCwxMjQsMTYsMTYsMTYsMTYsMTYsMTI0LDAsMiwyLDIsMiwyLDEzMCwxMjQsMCwxMzAsMTMyLDEzNiwyNDAsMTM2LDEzMiwxMzAsMCwxMjgsMTI4LDEyOCwxMjgsMTI4LDEyOCwyNTQsMCwxMzAsMTk4LDE3MCwxNDYsMTMwLDEzMCwxMzAsMCwxMzAsMTk0LDE2MiwxNDYsMTM4LDEzNCwxMzAsMCwxMjQsMTMwLDEzMCwxMzAsMTMwLDEzMCwxMjQsMCwyNTIsMTMwLDEzMCwxMzAsMjUyLDEyOCwxMjgsMCwxMjQsMTMwLDEzMCwxMzAsMTMwLDEzOCwxMjQsMiwyNTIsMTMwLDEzMCwyNTIsMTMyLDEzMCwxMzAsMCwxMjQsMTMwLDEyOCwxMjQsMiwxMzAsMTI0LDAsMjU0LDE2LDE2LDE2LDE2LDE2LDE2LDAsMTMwLDEzMCwxMzAsMTMwLDEzMCwxMzAsMTI0LDAsMTMwLDEzMCwxMzAsMTMwLDY4LDQwLDE2LDAsMTMwLDEzMCwxNDYsMTQ2LDE0NiwxMDgsNjgsMCwxMzAsNjgsNDAsMTYsNDAsNjgsMTMwLDAsMTMwLDEzMCw2OCw0MCwxNiwxNiwxNiwwLDI1NCw0LDgsMTYsMzIsNjQsMjU0LDAsNTYsMzIsMzIsMzIsMzIsMzIsNTYsMCwxMjgsNjQsMzIsMTYsOCw0LDIsMCwyOCw0LDQsNCw0LDQsMjgsMCwxNiw0MCw2OCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwyNTUsMTYsOCwwLDAsMCwwLDAsMCwwLDAsNjAsMiw2Miw2Niw2MiwwLDY0LDY0LDEyNCw2Niw2Niw2NiwxMjQsMCwwLDAsNjAsNjYsNjQsNjYsNjAsMCwyLDIsNjIsNjYsNjYsNjYsNjIsMCwwLDAsNjAsNjYsMTI0LDY0LDYyLDAsMTIsMTYsNTYsMTYsMTYsMTYsMTYsMCwwLDAsNjIsNjYsNjYsNjIsMiw2MCw2NCw2NCwxMjQsNjYsNjYsNjYsNjYsMCwxNiwwLDQ4LDE2LDE2LDE2LDU2LDAsNCwwLDEyLDQsNCw0LDY4LDU2LDY0LDY0LDY2LDY4LDEyMCw2OCw2NiwwLDQ4LDE2LDE2LDE2LDE2LDE2LDE2LDAsMCwwLDI1MiwxNDYsMTQ2LDE0NiwxNDYsMCwwLDAsMTI0LDY2LDY2LDY2LDY2LDAsMCwwLDYwLDY2LDY2LDY2LDYwLDAsMCwwLDEyNCw2Niw2Niw2NiwxMjQsNjQsMCwwLDYyLDY2LDY2LDY2LDYyLDIsMCwwLDk0LDk2LDY0LDY0LDY0LDAsMCwwLDYyLDY0LDYwLDIsMTI0LDAsMTYsMTYsNTYsMTYsMTYsMTYsMTIsMCwwLDAsNjYsNjYsNjYsNjYsNjIsMCwwLDAsNjYsNjYsNjYsMzYsMjQsMCwwLDAsNjUsNzMsNzMsNzMsNTQsMCwwLDAsNjgsNDAsMTYsNDAsNjgsMCwwLDAsNjYsNjYsNjYsNjIsMiw2MCwwLDAsMTI0LDgsMTYsMzIsMTI0LDAsOCwxNiwxNiwzMiwxNiwxNiw4LDAsMTYsMTYsMTYsMTYsMTYsMTYsMTYsMTYsMTYsOCw4LDQsOCw4LDE2LDAsMCwwLDk2LDE0NiwxMiwwLDAsMA=='
  const kernal = 'MTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwwLDAsMCwwLDQ4LDE2LDIzLDAsMCwwLDUsMTYsNjUsMiwwLDAsMTYsMCwwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMiwwLDAsMCw0OCwxNiwyOSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsOTIsNSwwLDAsMTYsMSwwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMywwLDAsMCw0OCwxNiwzNSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiwyMTIsOCwwLDAsMTYsMiwwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsNCwwLDAsMCw0OCwxNiw0MSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDE2LDMsOSwwLDAsMTYsMywwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsNSwwLDAsMCw0OCwxNiw0MSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDE2LDE3NywxMCwwLDAsMTYsMywwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsOCwwLDAsMCw0OCwxNiwzNSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiw1OSwxMSwwLDAsMTYsMiwwLDAsMCw4LDE2LDEsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsOSwwLDAsMCw0OCwxNiw0MSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDE2LDE3LDEzLDAsMCwxNiwzLDAsMCwwLDgsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCwxNywxNiwxNiwwLDAsMCw0OCwxNiw0MSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDE2LDE3OSwxNiwwLDAsMTYsMywwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMjUsMCwwLDAsNDgsMTYsMjMsMCwwLDAsNSwxNiwxNDcsMjQsMCwwLDE2LDAsMCwwLDAsOCwxNiwxLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDE3LDE2LDI2LDAsMCwwLDQ4LDE2LDIzLDAsMCwwLDUsMTYsMTY5LDI0LDAsMCwxNiwwLDAsMCwwLDgsMTYsMSwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCwxNywxNiwyNywwLDAsMCw0OCwxNiwyMywwLDAsMCw1LDE2LDIzNSwyNCwwLDAsMTYsMCwwLDAsMCw4LDE2LDEsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMzIsMCwwLDAsNDgsMTYsMzUsMCwwLDAsNSwxNiwxLDAsMCwwLDE3LDE2LDIsMCwwLDAsMTcsMTYsMTQwLDI1LDAsMCwxNiwyLDAsMCwwLDgsMTYsMSwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTIsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMSwwLDAsMSwxNiwwLDAsMCwwLDE2LDAsMTgwLDAsMCwyNSwxNiwxLDAsMCwwLDE2LDMsMiwxLDAsMjUsMTYsMCwwLDAsMCwxNywxNiwwLDAsMSwwLDQ5LDE2LDYxLDAsMCwwLDUsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDI3LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDQsNCw0LDMyLDI1LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDE4MywyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDE2LDAsMTgwLDAsMCwxNiwwLDc2LDAsMCwxNiwxODYsOCwwLDAsMTYsMywwLDAsMCw4LDE2LDU3LDAsMCwwLDE2LDAsMCwwLDAsOCwxNiwwLDAsMSwwLDIxLDE2LDE2LDAsMCwwLDQ4LDE2LDIyLDAsMCwwLDUsMTYsMCwwLDAsMCwxNiwwLDAsMSwwLDE2LDEsMCwwLDAsOSwxNiwwLDAsMCwwLDQsMTYsMTc1LDEsMCwwLDE2LDAsMCwwLDAsOCwxNiw0NCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwyNTIsMTc1LDAsMCwxNiwwLDAsMCwwLDI3LDE2LDI1NSwxNzUsMCwwLDE2LDI1NSwyNTUsMjU1LDI1NSwyOSwxNiwyNDgsMTgwLDAsMCwxNiwxLDAsMCwwLDI5LDE2LDIyMywyNCwwLDAsMTYsMCwwLDAsMCw4LDE2LDI1NSwyNTUsMjU1LDI1NSwxNiwyMjEsNSwwLDAsMTYsMiwwLDAsMCw4LDE2LDI0OCwxODAsMCwwLDE2LDAsMCwwLDAsMjksMTYsMCwwLDAsMCwxNiwyMzgsMTgwLDAsMCwyMSwyNSwxNiwwLDAsMCwwLDE3LDE2LDIzOCwxODAsMCwwLDIxLDQ4LDE2LDEzLDAsMCwwLDUsMTUsMTYsMjMwLDI1NSwyNTUsMjU1LDQsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTYsMjM4LDE4MCwwLDAsMjEsMjUsMTYsMCwwLDAsMCwxNywxNiwyMzgsMTgwLDAsMCwyMSw0OCwxNiwzMCwwLDAsMCw1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwxNSwwLDAsMCwzMiwyNSwxNiwyMTMsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMSwwLDAsMCwxNywxNiwxMCwwLDAsMCwxNiw2OSwyNCwwLDAsMTYsMCwwLDAsMCw4LDE2LDE0NCwwLDAsMCwzMiwxNiwxMDEsMTAsMCwwLDE2LDMsMCwwLDAsOCwxNiw0MSwyNCwwLDAsMTYsMCwwLDAsMCw4LDE2LDE0NCwwLDAsMCwzMiwxNiwyNTUsMjU1LDI1NSwyNTUsMTYsMzMsNSwwLDAsMTYsMiwwLDAsMCw4LDE2LDgsMjQsMCwwLDE2LDAsMCwwLDAsOCwxNiwxNDQsMSwwLDAsMzIsMTYsMjU1LDI1NSwyNTUsMjU1LDE2LDAsNSwwLDAsMTYsMiwwLDAsMCw4LDMxLDE2LDAsMCwxLDAsMzMsMTYsMTAsMCwwLDAsMTYsMjE5LDIzLDAsMCwxNiwwLDAsMCwwLDgsMTYsMTQ0LDAsMCwwLDMyLDE2LDI1MSw5LDAsMCwxNiwzLDAsMCwwLDgsMTYsMTkxLDIzLDAsMCwxNiwwLDAsMCwwLDgsMTYsMTQ0LDAsMCwwLDMyLDE2LDI1NSwyNTUsMjU1LDI1NSwxNiwxODMsNCwwLDAsMTYsMiwwLDAsMCw4LDE2LDE1OCwyMywwLDAsMTYsMCwwLDAsMCw4LDE2LDExMiwwLDAsMCwzMiwxNiwyNTUsMjU1LDI1NSwyNTUsMTYsMTUwLDQsMCwwLDE2LDIsMCwwLDAsOCwxNiwxMCwwLDAsMCwxNiwyMTcsMCwwLDAsMTYsMSwwLDAsMCw4LDE2LDAsMSwwLDAsMSwxNiwwLDAsMCwwLDExLDE2LDI0NCwxODAsMCwwLDE5LDE2LDI0LDAsMCwwLDUsMTYsMjQ0LDE4MCwwLDAsMTYsMCwwLDAsMCwyNywyLDE2LDIyNiwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiw2MSwyMywwLDAsMTYsMCwwLDAsMCw4LDE2LDY0LDAsMCwwLDMyLDE2LDI1NSwyNTUsMjU1LDI1NSwxNiw1Myw0LDAsMCwxNiwyLDAsMCwwLDgsMTYsMiwwLDAsMCwxNiwxMjksMCwwLDAsMTYsMCw0LDAsMCwxNiwyLDAsMCwwLDksMTYsMiwwLDAsMCwxNiw4LDAsMCwwLDE2LDAsNCwwLDAsMTYsMiwwLDAsMCw5LDE2LDEsMCwwLDAsMTYsNzcsMCwwLDAsNSwxNiw2MiwwLDAsMCwxNiw2NywwLDAsMCwxNiwxLDAsMCwwLDgsMTYsMzIsMCwwLDAsMTYsNTEsMCwwLDAsMTYsMSwwLDAsMCw4LDE2LDAsMSwwLDAsMTYsMTk0LDIyLDAsMCwxNiwwLDAsMCwwLDgsMTYsMTQ0LDAsMCwwLDMyLDE2LDE1NiwxMCwwLDAsMTYsMiwwLDAsMCw4LDE2LDE3NCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsOCwwLDAsMCw0OCwxNiwxMzAsMCwwLDAsNSwxNiwyNTIsMTc1LDAsMCwxNiwyNTIsMTc1LDAsMCwyMywxNiwxLDAsMCwwLDMzLDI5LDE2LDI1MiwxNzUsMCwwLDIzLDE2LDAsMCwwLDAsNDksMTYsODIsMCwwLDAsNSwxNiwyNTIsMTc1LDAsMCwxNiwxMzAsMjAsMCwwLDE2LDAsMCwwLDAsOCwxNiw4LDAsMCwwLDM1LDI5LDE2LDI1MywxNzUsMCwwLDE2LDI1MywxNzUsMCwwLDIzLDE2LDEsMCwwLDAsMzMsMjksMTYsMjUzLDE3NSwwLDAsMjMsMTYsMCwwLDAsMCw0OSwxNiwxNywwLDAsMCw1LDE2LDI1MiwxNzUsMCwwLDE2LDAsMCwwLDAsMjgsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDE3LDE2LDksMCwwLDAsNDgsMTYsNzgsMCwwLDAsNSwxNiwyNTIsMTc1LDAsMCwxNiwyNTIsMTc1LDAsMCwyMSwxNiwxLDAsMCwwLDMyLDI5LDE2LDI1MiwxNzUsMCwwLDIxLDE2LDgsMCwwLDAsMzYsMTYsMzAsMCwwLDAsNSwxNiwyNTIsMTc1LDAsMCwxNiwyNTIsMTc1LDAsMCwyMSwxNiwxLDAsMCwwLDMyLDI5LDE2LDIxNCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDE3LDE2LDEwLDAsMCwwLDQ4LDE2LDQxLDAsMCwwLDUsMTYsMjUyLDE3NSwwLDAsMTYsMCwwLDAsMCwyOSwxNiwyNTMsMTc1LDAsMCwxNiwyNTMsMTc1LDAsMCwyMSwxNiwxLDAsMCwwLDMyLDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMTMsMCwwLDAsNDgsMTYsMjMsMCwwLDAsNSwxNiwyNTIsMTc1LDAsMCwxNiwwLDAsMCwwLDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMTYsMzIsMCwwLDAsNDksMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE2LDI1MiwxNzUsMCwwLDIxLDE2LDgsMCwwLDAsMzQsMjUsMTYsMSwwLDAsMCwxNywxNiw0NywxOSwwLDAsMTYsMCwwLDAsMCw4LDUwLDE2LDQ2LDAsMCwwLDUsMTYsMjUyLDE3NSwwLDAsMTYsMCwwLDAsMCwyOSwxNiwyNTMsMTc1LDAsMCwxNiwyNTMsMTc1LDAsMCwyMSwxNiwxLDAsMCwwLDMyLDI5LDE2LDEsMCwwLDAsMTYsMCwwLDAsMCwyNSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwxLDAsMCwwLDE3LDE2LDgsMCwwLDAsMzIsMjUsMTYsMiwwLDAsMCwxNiwyNTMsMTc1LDAsMCwyMSwxNiw4LDAsMCwwLDM0LDI1LDE2LDIsMCwwLDAsMTcsMTYsNDgsMTksMCwwLDE2LDAsMCwwLDAsOCw1MCwxNiw2NiwwLDAsMCw1LDE2LDI1MywxNzUsMCwwLDE2LDI1MywxNzUsMCwwLDIxLDE2LDEsMCwwLDAsMzMsMjksMTYsMiwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDgsMCwwLDAsMzMsMjUsMTYsNywwLDAsMCwxNiw3LDAsMCwwLDE3LDE2LDgsMCwwLDAsMzIsMjUsMTYsMTcyLDI1NSwyNTUsMjU1LDQsMTYsMCwwLDAsMCw0LDE2LDcsMCwwLDAsMTcsMTYsMTg3LDE2LDAsMCwxNiwxLDAsMCwwLDgsMTYsNCwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDgsMCwwLDAsMzIsMjUsMTYsNywwLDAsMCwxNiwwLDE3NiwwLDAsMTYsMCwwLDAsMCwxNywxNiwxMjcsMCwwLDAsNTIsMTYsOCwwLDAsMCwzNCwzMiwyNSwxNiw2LDAsMCwwLDE2LDIsMCwwLDAsMTcsMjUsMTYsNiwwLDAsMCwxNywxNiw0LDAsMCwwLDE3LDQ5LDE2LDE4OCwwLDAsMCw1LDE2LDgsMCwwLDAsMTYsNywwLDAsMCwxNywyMSwxNiwyNDgsMjU1LDI1NSwyNTUsNTUsMjUsMTYsNSwwLDAsMCwxNiwxLDAsMCwwLDE3LDI1LDE2LDUsMCwwLDAsMTcsMTYsMywwLDAsMCwxNyw0OSwxNiw5MCwwLDAsMCw1LDE2LDgsMCwwLDAsMTYsOCwwLDAsMCwxNywxNiwxLDAsMCwwLDU1LDI1LDE2LDUsMCwwLDAsMTcsMTYsNiwwLDAsMCwxNywxNiwyNTQsMTc1LDAsMCwxNiw4LDAsMCwwLDE3LDE2LDEsMCwwLDAsNTIsMzIsMjEsMTYsMTAyLDksMCwwLDE2LDMsMCwwLDAsOCwxNiw1LDAsMCwwLDE2LDUsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMiwyNSwxNiwxNTMsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsNywwLDAsMCwxNiw3LDAsMCwwLDE3LDE2LDEsMCwwLDAsMzIsMjUsMTYsNiwwLDAsMCwxNiw2LDAsMCwwLDE3LDE2LDEsMCwwLDAsMzIsMjUsMTYsNTUsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMjUyLDE3NSwwLDAsMTYsMjUyLDE3NSwwLDAsMjEsMTYsMSwwLDAsMCwzMiwyOSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwxLDAsMCwwLDE3LDUxLDUxLDE2LDAsMCwwLDAsMTcsMjEsNTEsNTEsNTIsMTYsNjYsMCwwLDAsNSwxNiwwLDAsMCwwLDE3LDIxLDE2LDMxLDI1MiwyNTUsMjU1LDE2LDEsMCwwLDAsOCwxNiwxLDAsMCwwLDE2LDEsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMywyNSwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMiwyNSwxNiwxNzIsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDEsMCwwLDAsMTcsNTAsMTYsMTk2LDAsMCwwLDUsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDUwLDE2LDgwLDAsMCwwLDUsMTYsMSwwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDE5LDI3LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiw0LDAsMCwwLDMzLDI1LDE2LDE2NCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDgwLDAsMCwwLDUsMTYsMSwwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDE5LDI5LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDE3MCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDQ5LDE2LDIzNCwwLDAsMCw1LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwyLDAsMCwwLDE3LDMyLDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwyLDAsMCwwLDE3LDMyLDI1LDE2LDIsMCwwLDAsMTcsMTYsMywwLDAsMCw1MCwxNiw4MCwwLDAsMCw1LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiw0LDAsMCwwLDMzLDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDAsMCwwLDMzLDI1LDE2LDEsMCwwLDAsMTcsMTYsMCwwLDAsMCwxNywxOSwyNywxNiwyLDAsMCwwLDE2LDIsMCwwLDAsMTcsMTYsNCwwLDAsMCwzMywyNSwxNiwxNjQsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMiwwLDAsMCwxNywxNiw4MCwwLDAsMCw1LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDEsMCwwLDAsMTcsMTYsMCwwLDAsMCwxNywxOSwyOSwxNiwyLDAsMCwwLDE2LDIsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMywyNSwxNiwxNzAsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDUwLDE2LDYxLDAsMCwwLDUsMTYsMSwwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDI3LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiw0LDAsMCwwLDMzLDI1LDE2LDE4MywyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDc5LDAsMCwwLDUsMTYsMSwwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDI5LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiw4LDAsMCwwLDU1LDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDE3MSwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDUsMCwwLDAsMTYsMTc4LDE1LDAsMCwxNiwwLDAsMCwwLDgsMTYsODAsMCwwLDAsMzIsMjUsMTYsMywwLDAsMCwxNiwxLDAsMCwwLDI1LDE2LDAsMCwwLDAsMTcsMjEsMTYsNDUsMCwwLDAsNDgsMTYsMzUsMCwwLDAsNSwxNiwzLDAsMCwwLDE2LDI1NSwyNTUsMjU1LDI1NSwyNSwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMiwyNSwxNiwwLDAsMCwwLDQsMTYsMCwwLDAsMCwxNywyMSwxNiwxMjMsMSwwLDAsNSwxNiwxLDAsMCwwLDE3LDE2LDEwLDAsMCwwLDQ4LDE2LDExNCwwLDAsMCw1LDE2LDAsMCwwLDAsMTcsMjEsMTYsOTgsMCwwLDAsNDgsMTYsMTcsMCwwLDAsNSwxNiwxLDAsMCwwLDE2LDIsMCwwLDAsMjUsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTcsMjEsMTYsMTExLDAsMCwwLDQ4LDE2LDE3LDAsMCwwLDUsMTYsMSwwLDAsMCwxNiw4LDAsMCwwLDI1LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDE3LDIxLDE2LDEyMCwwLDAsMCw0OCwxNiwxNywwLDAsMCw1LDE2LDEsMCwwLDAsMTYsMTYsMCwwLDAsMjUsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsNCwxNiw0LDAsMCwwLDE2LDAsMCwwLDAsMjUsMTYsNCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDQ5LDE2LDE0MywwLDAsMCw1LDE2LDAsMCwwLDAsMTcsMjEsMTYsNSwwLDAsMCwxNywxNiw0LDAsMCwwLDE3LDMyLDIxLDQ4LDE2LDAsMCwwLDAsMTcsMjEsMTYsMzIsMCwwLDAsMzIsMTYsNSwwLDAsMCwxNywxNiw0LDAsMCwwLDE3LDMyLDIxLDQ4LDUzLDE2LDU2LDAsMCwwLDUsMTYsMiwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsMTcsMzQsMjUsMTYsMiwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDQsMCwwLDAsMTcsMzIsMjUsMTYsNCwwLDAsMCwxNiwxLDAsMCwwLDE3LDI1LDE2LDAsMCwwLDAsNCwxNiw0LDAsMCwwLDE2LDQsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMiwyNSwxNiwxMDAsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsNCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDQ4LDE2LDI1LDAsMCwwLDUsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDM0LDE2LDEsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDEyNiwyNTQsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMzQsMTYsMSwwLDAsMCwxMSwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiw1LDAsMCwwLDE2LDE2MSwxMywwLDAsMTYsMCwwLDAsMCw4LDE2LDgwLDAsMCwwLDMyLDI1LDE2LDAsMCwwLDAsMTcsMTYsMCwwLDAsMCw0OSwxNiw1NCwwLDAsMCw1LDE2LDIsMCwwLDAsMTcsMTYsNDUsMCwwLDAsMjksMTYsMiwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsMzIsMjUsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDI1NSwyNTUsMjU1LDI1NSwzNCwyNSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwyLDAsMCwwLDE3LDI1LDE2LDAsMCwwLDAsMTcsMTYsNzcsMCwwLDAsNSwxNiwyLDAsMCwwLDE3LDE2LDUsMCwwLDAsMTcsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDM2LDMyLDIxLDI5LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwxLDAsMCwwLDE3LDM1LDI1LDE2LDE3MywyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwzLDAsMCwwLDE3LDE2LDIsMCwwLDAsMTcsNDgsMTYsMzYsMCwwLDAsNSwxNiwyLDAsMCwwLDE3LDE2LDQ4LDAsMCwwLDI5LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDAsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDAsMCwwLDAsMjksMTYsNCwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMzMsMTYsMiwwLDAsMCwzNSwyNSwxNiw0LDAsMCwwLDE3LDE2LDEwNiwwLDAsMCw1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDAsMCwwLDAsMTYsMiwwLDAsMCwxNywyMSwyNSwxNiwyLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMjEsMjksMTYsMywwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDI5LDE2LDMsMCwwLDAsMTYsMywwLDAsMCwxNywxNiwxLDAsMCwwLDMyLDI1LDE2LDQsMCwwLDAsMTYsNCwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDE0NCwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDEsMCwwLDAsMTcsMTYsMCwwLDAsMCwyOSwxNiwyLDAsMCwwLDE3LDE2LDAsMCwwLDAsMTcsNDksMTYsMjIzLDEsMCwwLDUsMTYsMzIsMCwwLDAsMTYsNTYsMjQ1LDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDgsMCwwLDAsMTYsNDAsMjQ1LDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDI1NCwxNzUsMCwwLDE2LDI1NCwxNzUsMCwwLDIxLDE2LDI1NSwyNTUsMjU1LDI1NSw1NCwyOSwxNiwzMiwwLDAsMCwxNiw2LDI0NSwyNTUsMjU1LDE2LDEsMCwwLDAsOCwxNiwyNTQsMTc1LDAsMCwxNiwyNTQsMTc1LDAsMCwyMSwxNiwyNTUsMjU1LDI1NSwyNTUsNTQsMjksMTYsOCwwLDAsMCwxNiwyMjgsMjQ0LDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDI0NCwxODAsMCwwLDE5LDUxLDE2LDEzLDAsMCwwLDUsMiwxNiwyMzYsMjU1LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMjQ1LDE4MCwwLDAsMjEsMTYsMzIsMCwwLDAsNDksMTYsMTkxLDAsMCwwLDUsMTYsMzIsMCwwLDAsMTYsMTY4LDI0NCwyNTUsMjU1LDE2LDEsMCwwLDAsOCwxNiw4LDAsMCwwLDE2LDE1MiwyNDQsMjU1LDI1NSwxNiwxLDAsMCwwLDgsMTYsMjQ1LDE4MCwwLDAsMjEsMTYsOCwwLDAsMCw0OCwxNiw5OSwwLDAsMCw1LDE2LDIsMCwwLDAsMTcsMTYsMCwwLDAsMCw1MCwxNiw1OSwwLDAsMCw1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywzMiwxNiwwLDAsMCwwLDI5LDE2LDgsMCwwLDAsMTYsNjMsMjQ0LDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDE2LDAsMCwwLDQsMTYsNywwLDAsMCwxNiw0MSwyNDQsMjU1LDI1NSwxNiwxLDAsMCwwLDgsMTYsMCwwLDAsMCw0LDE2LDI0NSwxODAsMCwwLDIxLDE2LDEwLDAsMCwwLDQ4LDE2LDE4LDAsMCwwLDUsMTYsMiwwLDAsMCwxNiwwLDAsMCwwLDE3LDI1LDE2LDAsMCwwLDAsNCwxNiwxMjEsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDAsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMyw0OSwxNiw4MCwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMiwwLDAsMCwxNywzMiwxNiwyNDUsMTgwLDAsMCwyMSwyOSwxNiwyLDAsMCwwLDE2LDIsMCwwLDAsMTcsMTYsMSwwLDAsMCwzMiwyNSwxNiwxLDAsMCwwLDE3LDE2LDIsMCwwLDAsMTcsMzIsMTYsMCwwLDAsMCwyOSwxNiwyNDUsMTgwLDAsMCwyMSwxNiwxNTAsMjQzLDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDE2LDAsMCwwLDQsMTYsNywwLDAsMCwxNiwxMjgsMjQzLDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDI0NCwxODAsMCwwLDE2LDAsMCwwLDAsMjcsMTYsMjAsMjU0LDI1NSwyNTUsNCwxNiwwLDAsMCwwLDQsMTYsMTAsMCwwLDAsMTYsODksMjQzLDI1NSwyNTUsMTYsMSwwLDAsMCw4LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsMCwwLDAsMCw0OSwxNiwxMiwwLDAsMCw1LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDEsMCwwLDAsMTcsMTYsMCwwLDAsMCw0OSwxNiwxMiwwLDAsMCw1LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDcsMCwwLDAsMTYsMjQ4LDE4MCwwLDAsMjEsNTIsMTYsMTk4LDAsMCwwLDM0LDQsMTYsMCwwLDAsMCwxNywxNiwyNTUsMSwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDMxLDEsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDAsMiwwLDAsMTYsMSwwLDAsMCwxNywzNCwzMiwyNSwxNiw0LDAsMCwwLDE2LDEsMCwwLDAsMTYsMywwLDAsMCwxNywxNiw4LDAsMCwwLDM2LDM0LDI1LDE2LDMsMCwwLDAsMTYsMCwxODQsMCwwLDE2LDMsMCwwLDAsMTcsMTYsOCwwLDAsMCwzNSwzMiwyNSwxNiwzLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMjEsMTYsNCwwLDAsMCwxNywxNiw3LDAsMCwwLDMzLDU1LDE2LDI1NCwyNTUsMjU1LDI1NSw1MiwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsNTIsNTQsMTYsNywwLDAsMCwxNiw0LDAsMCwwLDE3LDMzLDU1LDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNywxNiwyNTUsMSwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDE0MywwLDAsMCw1MCwxNiwxMiwwLDAsMCw1LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDMsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwwLDIsMCwwLDE2LDEsMCwwLDAsMTcsMzQsMzIsMjUsMTYsNCwwLDAsMCwxNiwyLDAsMCwwLDE2LDMsMCwwLDAsMTcsMTYsNCwwLDAsMCwzNiwzNCwyNSwxNiwzLDAsMCwwLDE2LDAsMTg0LDAsMCwxNiwzLDAsMCwwLDE3LDE2LDQsMCwwLDAsMzUsMzIsMjUsMTYsMywwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDIxLDE2LDQsMCwwLDAsMTcsMTYsNiwwLDAsMCwzMyw1NSwxNiwyNTIsMjU1LDI1NSwyNTUsNTIsMTYsMiwwLDAsMCwxNywxNiwzLDAsMCwwLDUyLDU0LDE2LDYsMCwwLDAsMTYsNCwwLDAsMCwxNywzMyw1NSwyOSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsMTcsMTYsMjU1LDAsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMSwwLDAsMCwxNywxNiwxNDMsMCwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwzLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsMCwxLDAsMCwxNiwxLDAsMCwwLDE3LDM0LDMyLDI1LDE2LDQsMCwwLDAsMTYsNCwwLDAsMCwxNiwzLDAsMCwwLDE3LDE2LDIsMCwwLDAsMzYsMzQsMjUsMTYsMywwLDAsMCwxNiwwLDE4NCwwLDAsMTYsMywwLDAsMCwxNywxNiwyLDAsMCwwLDM1LDMyLDI1LDE2LDMsMCwwLDAsMTcsMTYsMywwLDAsMCwxNywyMSwxNiw0LDAsMCwwLDE3LDE2LDQsMCwwLDAsMzMsNTUsMTYsMjQwLDI1NSwyNTUsMjU1LDUyLDE2LDIsMCwwLDAsMTcsMTYsMTUsMCwwLDAsNTIsNTQsMTYsNCwwLDAsMCwxNiw0LDAsMCwwLDE3LDMzLDU1LDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNywxNiwyNTUsMCwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDcxLDAsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDAsMSwwLDAsMTYsMSwwLDAsMCwxNywzNCwzMiwyNSwxNiw0LDAsMCwwLDE2LDgsMCwwLDAsMTYsMywwLDAsMCwxNywxNiwxLDAsMCwwLDM2LDM0LDI1LDE2LDMsMCwwLDAsMTYsMCwxODQsMCwwLDE2LDMsMCwwLDAsMTcsMTYsMSwwLDAsMCwzNSwzMiwyNSwxNiwzLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMjEsMTYsNCwwLDAsMCwxNywxNiwwLDAsMCwwLDMzLDU1LDE2LDAsMjU1LDI1NSwyNTUsNTIsMTYsMiwwLDAsMCwxNywxNiwyNTUsMCwwLDAsNTIsNTQsMTYsMCwwLDAsMCwxNiw0LDAsMCwwLDE3LDMzLDU1LDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNywxNiwyNTUsMSwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDMxLDEsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDAsMiwwLDAsMTYsMSwwLDAsMCwxNywzNCwzMiwyNSwxNiw0LDAsMCwwLDE2LDEsMCwwLDAsMTYsMywwLDAsMCwxNywxNiw4LDAsMCwwLDM2LDM0LDI1LDE2LDMsMCwwLDAsMTYsMCwxODQsMCwwLDE2LDMsMCwwLDAsMTcsMTYsOCwwLDAsMCwzNSwzMiwyNSwxNiwzLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMjEsMTYsNCwwLDAsMCwxNywxNiw3LDAsMCwwLDMzLDU1LDE2LDI1NCwyNTUsMjU1LDI1NSw1MiwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsNTIsNTQsMTYsNywwLDAsMCwxNiw0LDAsMCwwLDE3LDMzLDU1LDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNywxNiwyNTUsMCwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDMxLDEsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDAsMSwwLDAsMTYsMSwwLDAsMCwxNywzNCwzMiwyNSwxNiw0LDAsMCwwLDE2LDIsMCwwLDAsMTYsMywwLDAsMCwxNywxNiw0LDAsMCwwLDM2LDM0LDI1LDE2LDMsMCwwLDAsMTYsMCwxODQsMCwwLDE2LDMsMCwwLDAsMTcsMTYsNCwwLDAsMCwzNSwzMiwyNSwxNiwzLDAsMCwwLDE3LDE2LDMsMCwwLDAsMTcsMjEsMTYsNCwwLDAsMCwxNywxNiw2LDAsMCwwLDMzLDU1LDE2LDI1MiwyNTUsMjU1LDI1NSw1MiwxNiwyLDAsMCwwLDE3LDE2LDMsMCwwLDAsNTIsNTQsMTYsNiwwLDAsMCwxNiw0LDAsMCwwLDE3LDMzLDU1LDI5LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNywxNiwyNTUsMCwwLDAsNTAsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE3LDE2LDE0MywwLDAsMCw1MCwxNiwxMiwwLDAsMCw1LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDMsMCwwLDAsMTYsMCwwLDAsMCwxNywxNiwwLDEsMCwwLDE2LDEsMCwwLDAsMTcsMzQsMzIsMjUsMTYsNCwwLDAsMCwxNiw0LDAsMCwwLDE2LDMsMCwwLDAsMTcsMTYsMiwwLDAsMCwzNiwzNCwyNSwxNiwzLDAsMCwwLDE2LDAsMTg0LDAsMCwxNiwzLDAsMCwwLDE3LDE2LDIsMCwwLDAsMzUsMzIsMjUsMTYsMywwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDIxLDE2LDQsMCwwLDAsMTcsMTYsNCwwLDAsMCwzMyw1NSwxNiwyNDAsMjU1LDI1NSwyNTUsNTIsMTYsMiwwLDAsMCwxNywxNiwxNSwwLDAsMCw1Miw1NCwxNiw0LDAsMCwwLDE2LDQsMCwwLDAsMTcsMzMsNTUsMjksMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDE3LDE2LDEyNywwLDAsMCw1MCwxNiwxMiwwLDAsMCw1LDE2LDAsMCwwLDAsMTEsMTYsMCwwLDAsMCw0LDE2LDEsMCwwLDAsMTcsMTYsMTQzLDAsMCwwLDUwLDE2LDEyLDAsMCwwLDUsMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDQsMTYsMywwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDEyOCwwLDAsMCwxNiwxLDAsMCwwLDE3LDM0LDMyLDI1LDE2LDQsMCwwLDAsMTYsOCwwLDAsMCwxNiwzLDAsMCwwLDE3LDE2LDEsMCwwLDAsMzYsMzQsMjUsMTYsMywwLDAsMCwxNiwwLDE4NCwwLDAsMTYsMywwLDAsMCwxNywxNiwxLDAsMCwwLDM1LDMyLDI1LDE2LDMsMCwwLDAsMTcsMTYsMywwLDAsMCwxNywyMSwxNiw0LDAsMCwwLDE3LDE2LDAsMCwwLDAsMzMsNTUsMTYsMCwyNTUsMjU1LDI1NSw1MiwxNiwyLDAsMCwwLDE3LDE2LDI1NSwwLDAsMCw1Miw1NCwxNiwwLDAsMCwwLDE2LDQsMCwwLDAsMTcsMzMsNTUsMjksMTYsMCwwLDAsMCwxMSwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTcsNTEsMTYsMTIsMCwwLDAsNSwxNiwwLDAsMCwwLDExLDE2LDAsMCwwLDAsNCwxNiwxLDAsMCwwLDE2LDAsMTg0LDAsMCwyNSwxNiwyLDAsMCwwLDE2LDAsMCwwLDAsMTcsMTYsNTYsMiwwLDAsMTYsMCwwLDAsMCw4LDM0LDI1LDE2LDMsMCwwLDAsMTYsMCwwLDEsMCwxNiwyLDAsMCwwLDE3LDMzLDI1LDE2LDEsMCwwLDAsMTcsMTYsMywwLDAsMCwxNyw0OSwxNiw1MSwwLDAsMCw1LDE2LDEsMCwwLDAsMTcsMTYsMSwwLDAsMCwxNywxNiwyLDAsMCwwLDE3LDMyLDE5LDI3LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDE5MiwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwzLDAsMCwwLDE2LDk5LDEsMCwwLDE2LDAsMCwwLDAsOCwyNSwxNiwwLDAsMCwwLDE2LDIzMSwwLDAsMCwxNiwwLDAsMCwwLDgsMjUsMTYsMiwwLDAsMCwxNiwzMiwwLDAsMCwyNSwxNiwyLDAsMCwwLDE3LDE2LDc3LDAsMCwwLDUsMTYsMCwwLDAsMCwxNywxNiwzLDAsMCwwLDE3LDE2LDI1NCwxNzUsMCwwLDIxLDE2LDEwNiwyNDgsMjU1LDI1NSwxNiwzLDAsMCwwLDgsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE3LDE2LDEsMCwwLDAsMzMsMjUsMTYsMiwwLDAsMCwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsMzMsMjUsMTYsMTczLDI1NSwyNTUsMjU1LDQsMTYsMCwwLDAsMCw0LDE2LDEsMCwwLDAsMTcsMTYsMjUyLDI1NSwwLDAsNDksMTYsNDMsMCwwLDAsNSwxNiwxLDAsMCwwLDE3LDE2LDI1MiwyNTUsMCwwLDE5LDI3LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiw0LDAsMCwwLDMyLDI1LDE2LDIwMSwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwwLDAsMCwwLDExLDE2LDMsMCwwLDAsMTYsMjQ4LDE4MCwwLDAsMjEsNTIsMTYsMTEsMCwwLDAsMzQsNCwxNiwxLDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDE1LDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMjU1LDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsNywwLDAsMCwxNiwyNDgsMTgwLDAsMCwyMSw1MiwxNiwxMSwwLDAsMCwzNCw0LDE2LDI1NSwxLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwxLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwxLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDI1NSwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDEyNywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDcsMCwwLDAsMTYsMjQ4LDE4MCwwLDAsMjEsNTIsMTYsMTEsMCwwLDAsMzQsNCwxNiwzMSwxLDAsMCwxNiwxLDAsMCwwLDExLDE2LDE0MywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDE0MywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDcxLDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMzEsMSwwLDAsMTYsMSwwLDAsMCwxMSwxNiwzMSwxLDAsMCwxNiwxLDAsMCwwLDExLDE2LDE0MywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDE0MywwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDcsMCwwLDAsMTYsMjQ4LDE4MCwwLDAsMjEsNTIsMTYsMTEsMCwwLDAsMzQsNCwxNiw2NCwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDEyOCwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDEyOCwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDAsMSwwLDAsMTYsMSwwLDAsMCwxMSwxNiw2NCwwLDAsMCwxNiwxLDAsMCwwLDExLDE2LDY0LDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMTI4LDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMTI4LDAsMCwwLDE2LDEsMCwwLDAsMTEsMTYsMCwwLDAsMCwxNiwwLDAsMCwwLDE2LDAsMCwwLDAsMTYsMiwwLDAsMCwxNiwxLDAsMCwwLDI1LDE2LDEsMCwwLDAsMTcsMTYsMCwwLDAsMCw1MCwxNiw0OSwwLDAsMCw1LDE2LDIsMCwwLDAsMTYsMiwwLDAsMCwxNywxNiwwLDAsMCwwLDE3LDM0LDI1LDE2LDEsMCwwLDAsMTYsMSwwLDAsMCwxNywxNiwxLDAsMCwwLDMzLDI1LDE2LDE5NSwyNTUsMjU1LDI1NSw0LDE2LDAsMCwwLDAsNCwxNiwyLDAsMCwwLDE3LDE2LDEsMCwwLDAsMTEsMTYsOCwwLDAsMCwxMywzMiwxNiwxLDAsMCwwLDExLDksMzIsNDcsNDcsNDcsMzIsODAsMTAxLDExNiwxMDUsNTYsMzIsMzIsNDcsNDcsNDcsOSw5LDksMzIsNDcsNDcsNDcsMzIsODAsMTAxLDExNiwxMDUsMzIsODIsMzIsNDcsNDcsNDcsMTAsMTAsMTAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMTAsODIsMTAxLDk3LDEwMCwxMjEsNDYsMTAsMTAsMCwwLDAsMCwwLDAsMCw0OCw0OSw1MCw1MSw1Miw1Myw1NCw1NSw1Niw1Nyw5Nyw5OCw5OSwxMDAsMTAxLDEwMiwxMDMsMTA0LDEwNSwxMDYsMTA3LDEwOCwxMDksMTEwLDExMSwxMTIsMTEzLDExNCwxMTUsMTE2LDExNywxMTgsMzIsOTgsMTIxLDExNiwxMDEsMTE1LDMyLDEwMiwxMTQsMTAxLDEwMSw0NiwxMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDEyMywxMTYsMTAxLDEwOSwxMTIsMTExLDExNCw5NywxMTQsMTIxLDMyLDExNSwxMTYsMTE0LDEwNSwxMTAsMTAzLDEyNSwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDMyLDEwNSwxMTIsMTE1LDQ2LDEwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMA=='
})()