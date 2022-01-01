(() => {
  let cpu,
    ram = new WebAssembly.Memory({ initial: 1 }),
    mem = new Uint8Array(ram.buffer),
    speed = 1,
    running = true,
    waitingforuser = false

  let img,
    canvas = document.querySelector("canvas"),
    g = canvas.getContext("2d"),
    gmode = -1

  async function init() {
    addEventListener("keydown", onUser)
    addEventListener("keyup", onUser)
    addEventListener("mousedown", onUser)
    addEventListener("mouseup", onUser)
    addEventListener("mousemove", onUser)

    document.querySelector("#asmTxt").value = localStorage.getItem("rom.asm") || ";;asm\n"
    document.querySelector("#compileBtn").addEventListener("click", compileAsm)

    for (let i = 0x0; i < mem.length; i++) {
      mem[i] = 255 * Math.random()
    }
    mem[0] = 0
    mem[0x6fff] = 0
    await loadCPU("cypu.wasm", { pcb: { ram: ram } })
    render()
    window.cpu = cpu
    window.mem = mem
    console.log("cpu", cpu)
    console.log("mem", mem)
    console.log("img", img)
  } init()

  async function loadCPU(path, imports) {
    let bin = await (await fetch(path)).arrayBuffer()
    await WebAssembly.instantiate(bin, imports).then(wasm => {
      cpu = wasm.instance.exports
    })
  }

  function render(t) {
    if (running) {
      let opcode = cpu.run(speed)
      // console.log(cpu.getReg(0), opcode)
      switch (opcode) {
        case 0x00: // halt
          running = false
          break
        case 0x01: // sleep
          running = false
          setTimeout(() => {
            running = true
          }, mem[cpu.getReg(0) - 2] * 256 + mem[cpu.getReg(0) - 1])
          break

        default:
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
    updateMonitor()

    // requestAnimationFrame(render)  
    setTimeout(render, 256)
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

  function compileAsm(e) {
    let asm = document.querySelector("#asmTxt").value
    let offset = eval(document.querySelector("#adrTxt").value)
    let bin = assemble(asm)
    mem.set(bin, offset)
    cpu.setReg(0, offset)
    running = true
    localStorage.setItem("rom.asm", asm)
  }

  function updateMonitor() {
    let pc = cpu.getReg(0)
    let adr = Math.max(0, pc - 16)
    let len = 14
    let txt = ""
    while (len--) {
      txt += (adr == pc ? "> " : "  ")
      txt += ("000000" + adr.toString(16)).slice(-5) + " "
      txt += ("0000" + mem[adr + 0].toString(16)).slice(-2) + " "
      txt += ("0000" + mem[adr + 1].toString(16)).slice(-2) + " "
      txt += ("0000" + mem[adr + 2].toString(16)).slice(-2) + " "
      txt += ("0000" + mem[adr + 3].toString(16)).slice(-2) + " "
      txt += opcodes[mem[adr]] || ""
      txt += "\n"
      adr += 4
    }
    document.querySelector("#monitorPre").textContent = txt
  }
})()