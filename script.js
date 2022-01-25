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
    kbBuffer = []

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

    document.querySelector("#asmTxt").value = localStorage.getItem("rom.asm") || ";;Peti asm\n\n(main:\n  (@vars $a)\n  \n  (@return (0))\n)\n"
    document.querySelector("#adrTxt").value = localStorage.getItem("?adr") || "0x0400"
    document.querySelector("#speedTxt").value = localStorage.getItem("?speed") || "0"
    document.querySelector("#speedTxt").addEventListener("change", changeSpeed); changeSpeed()
    document.querySelector("#compileBtn").addEventListener("click", compileAsm)
    document.querySelector("#stopBtn").addEventListener("click", e => { running = false; clearTimeout(sleep) })
    document.querySelector("#stepBtn").addEventListener("click", e => cpu.run(1))
    document.querySelector("#runBtn").addEventListener("click", e => running = true)

    for (let i = 0; i < mem.length; i++) {
      mem[i] = 255 * Math.random()
      if (i > 8) {
        mem[i] = mem[i] & mem[1]
        mem[i] = mem[i] ^ mem[2]
      }
    }
    await loadCPU("cypu.wasm", { pcb: { ram: ram } })
    render()
    window.mem = mem
    window.kbBuffer = kbBuffer
    console.log("cpu", cpu)
    console.log("mem", mem)
    console.log("img", img)
  } init()

  async function loadCPU(path, imports) {
    let bin = await (await fetch(path)).arrayBuffer()
    let wasm = await WebAssembly.instantiate(bin, imports)
    cpu = wasm.instance.exports
    window.cpu = cpu
  }

  function render(t = 0) {
    let opcode
    if (running) {
      if (kbBuffer.length && mem[0xb210] === 0) {
        mem[0xb211] = kbBuffer.shift()
        mem[0xb210] = 1
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
    let mode = mem[0xb240],
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
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
      gmode = mode
    }
    let start = 0xb800
    let end = 0x10000
    let i = 0
    for (let m = start; m < end; m++) {
      i += renderbyte(m, i, bpp)
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

  function renderbyte(madr, iadr, bpp) {
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
    if (bpp === 2) {
      bm = 1; rm = 2; gm = 3
      gs = 2; rs = 0
    }
    if (bpp === 1) {
      bm = 1; rm = 1; gm = 1
    }
    for (let i = 0; i < ppb; i++) {
      iadr -= 4
      // let c = byte & mask
      img.data[iadr + 2] = 255 * ((byte & bm) / bm)
      byte = byte >> bs
      img.data[iadr + 0] = 255 * ((byte & rm) / rm)
      byte = byte >> rs
      img.data[iadr + 1] = 255 * ((byte & gm) / gm)
      byte = byte >> gs
    }
    return ppb * 4
  }

  function onUser(e) {
    if (e.type.slice(0, 5) === "mouse") {
      mem[0xb220] = Math.max(0, (e.offsetX / e.target.clientWidth) * 255)
      mem[0xb221] = Math.max(0, (e.offsetY / e.target.clientHeight) * 144)
      mem[0xb222] = e.buttons
    }

    if (e.type === "keydown") {
      mem[0xb212] = e.keyCode
      if (!e.ctrlKey && !e.metaKey) {
        if (e.key === "Backspace") {
          kbBuffer.push(0x08)
        }
        if (e.key === "Tab") {
          kbBuffer.push(0x09)
        }
        if (e.key === "Enter") {
          kbBuffer.push(0x0a)
        }
        if (e.key.length === 1) {
          kbBuffer.push(e.key.charCodeAt(0))
        }
        // mem[0xb210] = 1
      }
    }
    if (!running) kbBuffer.length = 0

    if (waitingforuser) {
      waitingforuser = false
      running = true
    }
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
    cpu.setPC(offset)
    cpu.setCS(0)
    cpu.setVS(0)
    console.log(dumpMem(offset, bin.length))
    localStorage.setItem("rom.asm", asm)
    localStorage.setItem("?adr", document.querySelector("#adrTxt").value)
  }

  function dumpMem(adr, len, pc) {
    adr = Math.max(0, adr)
    // for (let i = 1; i <= 4; i++) {
    //   if (opcodes[mem[adr - i]] === "const") {
    //     adr = adr - i
    //     i = 5
    //   }
    // }
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
})()