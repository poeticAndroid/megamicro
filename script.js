(() => {
  let cpu,
    ram = new WebAssembly.Memory({ initial: 1 }),
    mem = new Uint8Array(ram.buffer),
    speed = 1,
    fps = 9000,
    fpssec = 0,
    running = false,
    waitingforuser = false

  let img,
    canvas = document.querySelector("canvas"),
    g = canvas.getContext("2d"),
    gmode = -1

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  async function init() {
    addEventListener("keydown", onUser)
    addEventListener("keyup", onUser)
    addEventListener("mousedown", onUser)
    addEventListener("mouseup", onUser)
    addEventListener("mousemove", onUser)

    document.querySelector("#asmTxt").value = localStorage.getItem("rom.asm") || ";;cyber asm\n\n(return (0) (1))\n"
    document.querySelector("#adrTxt").value = localStorage.getItem("?adr") || "0x0400"
    document.querySelector("#speedTxt").value = localStorage.getItem("?speed") || "0"
    document.querySelector("#speedTxt").addEventListener("change", changeSpeed); changeSpeed()
    document.querySelector("#compileBtn").addEventListener("click", compileAsm)
    document.querySelector("#stopBtn").addEventListener("click", e => running = false)
    document.querySelector("#stepBtn").addEventListener("click", e => cpu.run(1))
    document.querySelector("#runBtn").addEventListener("click", e => running = true)

    for (let i = 0; i < mem.length; i++) {
      mem[i] = 255 * Math.random()
      if (i > 8) {
        mem[i] = mem[i] & mem[1]
        mem[i] = mem[i] | mem[2]
      }
    }
    await loadCPU("cypu.wasm", { pcb: { ram: ram } })
    render()
    window.mem = mem
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

  function render(t) {
    let opcode
    if (running) {
      try {
        opcode = cpu.run(speed)
      } catch (err) {
        console.error("CPU CRASH!! OH NOEZ!! O_O")
        delete cpu
        loadCPU("cypu.wasm", { pcb: { ram: ram } })
        opcode = 0
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
          setTimeout(() => {
            running = true
          }, int32[0])
          break
      }
    }
    let mode = mem[0x6fff] % 0x8
    let bpp = 8, pw = 1, ph = 1
    let w = canvas.width, h = canvas.height
    switch (mode) {
      case 0x0:
      case 0x1:
        bpp = 8; pw = 4; ph = 4
        w = 256; h = 144
        break

      case 0x2:
        bpp = 4; pw = 4; ph = 2
        w = 256; h = 144 * 2
        break
      case 0x3:
        bpp = 4; pw = 2; ph = 4
        w = 256 * 2; h = 144
        break

      case 0x4:
      case 0x5:
        bpp = 2; pw = 2; ph = 2
        w = 512; h = 288
        break

      case 0x6:
        bpp = 1; pw = 2; ph = 1
        w = 512; h = 288 * 2
        break
      case 0x7:
        bpp = 1; pw = 1; ph = 2
        w = 512 * 2; h = 288
        break
    }
    if (gmode !== mode) {
      gmode = mode
      canvas.width = w; canvas.height = h
      canvas.style.width = (w * pw) + "px"
      canvas.style.height = (h * ph) + "px"
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
    }
    let start = 0x7000
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
      document.querySelector("#fps").textContent = fps + " fps"
      fps = 0
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
      }
      uint8.set(mem.slice(adr - 4, adr))
      if (adr > 0) txt += "0x" + ("00000000" + int32[0].toString(16)).slice(-8) + " " + int32[0] + " "
      adr -= 4
      if (float32[0]) txt += float32[0]
      if (cs < 0) cs = int32[0]
      len--
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
    document.querySelector("#stackPre").textContent = "Stack size: 0x" + cpu.getVS().toString(16) + "\n" + dumpStack(16)
  }
})()