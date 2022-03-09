(() => {
  let cpu,
    ram = new WebAssembly.Memory({ initial: 2 }),
    mem = new Uint8Array(ram.buffer),
    speed = 1,
    vsyncfps = 9000,
    fps = 9000,
    fpssec = 0,
    running = false,
    waitingforuser = false,
    sleep = false,
    kbEnabled = true,
    kbBuffer = [],
    debugMode

  let diskInitialized = false,
    diskReq = [],
    diskResp = [],
    diskCwd = ["/", "/", "/", "/"],
    diskBusy, diskWrite

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
    canvas.addEventListener("mouseout", e => canvas.style.cursor = "crosshair")

    document.querySelector("#speedTxt").value = localStorage.getItem("?speed") || "16"
    document.querySelector("#speedTxt").addEventListener("change", changeSpeed); changeSpeed()
    document.querySelector("#stopBtn").addEventListener("click", e => { running = false; clearTimeout(sleep) })
    document.querySelector("#stepBtn").addEventListener("click", e => cpu.run(1))
    document.querySelector("#runBtn").addEventListener("click", e => running = true)
    document.querySelector("#speedTxt").addEventListener("focus", e => kbEnabled = false)
    document.querySelector("#debugChk").addEventListener("change", toggleDebug); toggleDebug()

    for (let i = 0; i < mem.length; i++) {
      mem[i] = 255 * Math.random()
      if (i > 8) {
        mem[i] = mem[i] & mem[1]
        mem[i] = mem[i] ^ mem[2]
      }
    }
    await loadCPU("z28r_cpu.wasm", { env: { ram: ram } })
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
    mem.set([0, 0x50, 0x04], 0x0)
    mem.set([0x50, 0x04], 0x5000)
    bin = JSON.parse("[" +
      atob(font)
      + "]")
    mem.set(bin, 0x4c00)
    mem.set([0x00, 0x50, 0, 0], mem.length - 8)
    cpu.reset()
    running = true
  }

  function render(t = 0) {
    let opcode
    if (running) {
      if (kbBuffer.length && mem[0x4b04] === 0) {
        mem[0x4b05] = kbBuffer.shift()
        mem[0x4b04] = Math.min(255, 1 + kbBuffer.length)
      }
      if (mem[0x4b00]) {
        if (mem[0x4b01]) {
          diskReq.push(mem.slice(0x4900, 0x4900 + mem[0x4b01]))
          mem[0x4b01] = 0
        }
        handleDrive(mem[0x4b00] - 1)
        if (!mem[0x4b02]) {
          if (diskResp.length) {
            mem[0x4b02] = diskResp[0].length
            mem.set(diskResp.shift(), 0x4a00)
          } else if (!diskBusy && !diskWrite) {
            mem[0x4b00] = 0
          }
        }
      } else {
        diskReq.length = 0
        diskResp.length = 0
        diskBusy = false
        diskWrite = null
      }
      try {
        opcode = cpu.run(speed)
      } catch (err) {
        console.error("CPU CRASH!! OH NOEZ!! O_O")
        running = false
        return setTimeout(() => {
          delete cpu
          loadCPU("z28r_cpu.wasm", { env: { ram: ram } }).then(
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
          sleep = setTimeout(() => {
            running = true
          }, cpu.getSleep())
          break
        case 0x02:
          vsyncfps++
          break
      }
    }

    // rendering
    let mode = mem[0x4b08],
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
      if ((mode & 7) === 4) canvas.style.backgroundColor = "#241"
      else canvas.style.backgroundColor = "#000"
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
      gmode = mode
    }
    let start = 0x0000
    let end = 0x4800
    let i = 0
    for (let m = start; m < end; m++) {
      i += renderbyte(m, i, bpp, mode & 4)
    }

    g.putImageData(img, 0, 0)

    if (debugMode) {
      updateMonitor(cpu.getPC())
      updateStack()

      fps++
      if (fpssec !== Math.floor(t / 1000)) {
        document.querySelector("#fps").textContent = vsyncfps + "/" + fps + " fps"
        fps = 0
        vsyncfps = 0
        fpssec = Math.floor(t / 1000)
      }
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
      mem[0x4b09] = Math.max(0, (e.offsetX / e.target.clientWidth) * 255)
      mem[0x4b0a] = Math.max(0, (e.offsetY / e.target.clientHeight) * 144)
      if (mem[0x4b0b] = e.buttons) {
        kbEnabled = true
        canvas.style.cursor = "none"
      }
    }

    if (e.type === "keyup") {
      mem[0x4b07] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
    }
    if (e.type === "keydown") {
      if (kbEnabled) {
        mem[0x4b06] = e.keyCode
        mem[0x4b07] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
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

  function handleDrive(driveNum = 0) {
    if (diskWrite) {
      let hex = ""
      let buf
      while (buf = diskReq.shift()) {
        for (let i = 0; i < buf.length; i++) {
          hex += ("0" + buf[i].toString(16)).slice(-2)
        }
      }
      localStorage.setItem(diskWrite, localStorage.getItem(diskWrite) + hex)
      return
    }
    req = diskReq.shift()
    if (!req) return
    let cmd = ""
    for (let i = 0; i < req.length; i++) {
      cmd += String.fromCharCode(req[i])
    }
    cmd = cmd.trim().split(/\s+/)
    let file = "drive" + driveNum + ":" + diskPath("" + diskCwd[driveNum] + cmd[1])
    diskBusy = true
    console.log("drive", driveNum, cmd.join(" "))
    switch (cmd[0]) {
      case "load":
        let data = localStorage.getItem(file)
        if (data) {
          diskStatus("ok  " + (data.length / 2) + " bytes")
          for (let b = 0; b < data.length; b += 510) {
            let buf = new Uint8Array(Math.min(255, (data.length - b) / 2))
            for (let i = 0; i < buf.length; i++) {
              buf[i] = parseInt(data.slice(b + i * 2, b + 2 + i * 2), 16)
            }
            diskResp.push(buf)
          }
        } else {
          diskStatus("err file not found " + file)
        }
        break

      case "save":
        diskWrite = file
        localStorage.setItem(diskWrite, "")
        diskStatus("ok  0 bytes")
        break

      case "delete":
        localStorage.removeItem(file)
        diskStatus("ok  0 bytes")
        break

      case "info":
        diskStatus("not yet implemented " + cmd[0])
        break

      case "list":
        diskStatus("not yet implemented  " + cmd[0])
        break

      case "mkdir":
        diskStatus("ok  0 bytes")
        break

      case "cd":
        diskCwd[driveNum] = file.splice(file.indexOf("/")) + "/"
        diskStatus("ok  0 bytes")
        break

      default:
        diskStatus("err unknown command " + cmd[0])
    }


    if (!diskInitialized) {
      mem.fill(0, 0x4900, 0x4b04)
      diskBusy = false
      diskCwd[driveNum] = "/"
      diskInitialized = true
      return
    }
  }

  function diskPath(path) {
    let dirs = path.split("/")
    let valid = []
    if (!dirs[dirs.length - 1]) dirs.pop()
    for (let dir of dirs) {
      if (dir === ".") {
      } else if (dir === "..") {
        valid.pop()
      } else if (dir) {
        let name = (dir.replaceAll(" ", "_") + ".").split(".")
        valid.push(name[0].toLowerCase().slice(0, 8) + ".".slice(0, name[1].length) + name[1].toLowerCase().slice(0, 3))
      } else {
        valid = []
      }
    }
    return "/" + valid.join("/")
  }

  function diskStatus(str) {
    console.log("disk status", str)
    str += "\n"
    let len = Math.min(255, str.length)
    let buf = new Uint8Array(len)
    for (let i = 0; i < len; i++) {
      buf[i] = str.charCodeAt(i)
    }
    diskResp.push(buf)
    diskBusy = false
  }

  function hwClock() {
    let now = new Date()
    mem[0x4b10] = now.getYear()
    mem[0x4b11] = now.getMonth()
    mem[0x4b12] = now.getDate()
    mem[0x4b13] = now.getDay()
    mem[0x4b14] = now.getHours()
    mem[0x4b15] = now.getMinutes()
    mem[0x4b16] = now.getSeconds()
    mem[0x4b17] = 0
    setTimeout(hwClock, 1000 - now.getMilliseconds())
  }

  function changeSpeed(e) {
    let s = eval(document.querySelector("#speedTxt").value)
    speed = Math.pow(2, s)
    localStorage.setItem("?speed", document.querySelector("#speedTxt").value)
  }

  function compileAsm(e) {
    let asm = document.querySelector("#asmTxt").value
    let file = document.querySelector("#fileTxt").value
    let offset = 0x10000
    let bin = assemble(asm)

    let hex = ""
    for (let i = 0; i < bin.length; i++) {
      hex += ("0" + bin[i].toString(16)).slice(-2)
    }
    localStorage.setItem(file, hex)

    mem.set(bin, offset)
    cpu.reset()
    console.log(dumpMem(offset, bin.length))
    localStorage.setItem("program.asm", asm)
    localStorage.setItem("?file", document.querySelector("#fileTxt").value)
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
      if (opcodes[mem[adr]] === "lit") {
        uint8.set(mem.slice(adr + 1, adr + 5))
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += 4
      }
      if (mem[adr] >= 0x40) {
        let op = mem[adr] >> 4
        let len = mem[adr] >> 6
        if (op & 2) uint8.fill(255)
        else uint8.fill(0)
        uint8.set(mem.slice(adr + 1, adr + len), 1)
        uint8[0] = mem[adr] << 4
        int32[0] = int32[0] >> 4
        if (op & 1) int32[0] = int32[0] ^ 0x40000000
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += len - 1
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
      uint8.set(mem.slice(adr, adr + 4))
      if (adr < mem.length) {
        txt += "0x" + ("00000000" + int32[0].toString(16)).slice(-8) + " " + int32[0] + " "
        if (float32[0]) txt += float32[0]
      }
      if (cs == 0) cs = int32[0]
      if (cs < 0) cs++
      len--
      adr += 4
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

  function toggleDebug(e) {
    debugMode = document.querySelector("#debugChk").checked
    if (debugMode) document.querySelector("#debugSec").classList.remove("hidden")
    else document.querySelector("#debugSec").classList.add("hidden")
    window.scrollBy(0, 320)
  }

  const font = 'MCwwLDAsMjQsMjQsMCwwLDAsMCwwLDAsMCwxNSwxNSwxNSwxNSwwLDAsMCwwLDI0MCwyNDAsMjQwLDI0MCwwLDAsMCwwLDI1NSwyNTUsMjU1LDI1NSwxNSwxNSwxNSwxNSwwLDAsMCwwLDE1LDE1LDE1LDE1LDE1LDE1LDE1LDE1LDE1LDE1LDE1LDE1LDI0MCwyNDAsMjQwLDI0MCwyNDAsMjQwLDI0MCwyNDAsMCwwLDAsMCwwLDAsMCwxNSwxNSwyNCwyNCwyNCwwLDAsMCwyNDAsMjQwLDI0LDI0LDI0LDI0LDI0LDI0LDMxLDE1LDAsMCwwLDI0LDI0LDI0LDI0OCwyNDAsMCwwLDAsMjQsMjQsMjQsMjU1LDIzMSwwLDAsMCwyNCwyNCwyNCwxNSwxNSwyNCwyNCwyNCwwLDAsMCwyMzEsMjU1LDI0LDI0LDI0LDI0LDI0LDI0LDI0MCwyNDAsMjQsMjQsMjQsMjQsMjQsMjQsMjQsMjQsMjQsMjQsMjQsMCwwLDAsMjU1LDI1NSwwLDAsMCwyNCwyNCw2MCwyNTUsMjU1LDYwLDI0LDI0LDE5NSwyMzEsMTI2LDYwLDYwLDEyNiwyMzEsMTk1LDMsNywxNCwyOCw1NiwxMTIsMjI0LDE5MiwxOTIsMjI0LDExMiw1NiwyOCwxNCw3LDMsMSwzLDcsMTUsMTUsMzEsNjMsMTI3LDEyOCwxOTIsMjI0LDI0MCwyNDAsMjQ4LDI1MiwyNTQsMTI0LDEzMCwxMzAsMTMwLDEzMCwxMzAsMTI0LDAsMCw2LDEyLDEyLDIxNiwxMjAsNDgsMCwxMjQsMjE0LDIxNCwyNTQsMjM4LDIxNCwxMjQsMCwxMjQsMjE0LDIxNCwyNTQsMTg2LDE5OCwxMjQsMCwwLDEwOCwyNTQsMjU0LDEyNCw1NiwxNiwwLDE2LDU2LDEyNCwyNTQsODQsMTYsNTYsMCwxNiw1NiwxMjQsMjU0LDEyNCw1NiwxNiwwLDU2LDU2LDU2LDI1NCwyNTQsMTYsNTYsMCwwLDAsMCwwLDAsMCwwLDAsMTYsMTYsMTYsMTYsMTYsMCwxNiwwLDY4LDY4LDAsMCwwLDAsMCwwLDM2LDEyNiwzNiwzNiwzNiwxMjYsMzYsMCwxNiw2MCw2NCw1Niw0LDEyMCwxNiwwLDY2LDE2NCw3MiwxNiwzNiw3NCwxMzIsMCwyOCwzNCwzNiwyNCwzNyw2Niw2MSwwLDgsOCwwLDAsMCwwLDAsMCw4LDE2LDMyLDMyLDMyLDE2LDgsMCwxNiw4LDQsNCw0LDgsMTYsMCwxNiw4NCw1Niw4NCwxNiwwLDAsMCwwLDE2LDE2LDEyNCwxNiwxNiwwLDAsMCwwLDAsMCw4LDgsMTYsMCwwLDAsMCwxMjYsMCwwLDAsMCwwLDAsMCwwLDAsMCwxNiwwLDIsNCw4LDE2LDMyLDY0LDEyOCwwLDU2LDY4LDY4LDY4LDY4LDY4LDU2LDAsMTYsNDgsMTYsMTYsMTYsMTYsMTI0LDAsNTYsNjgsNCwyNCwzMiw2NCwxMjQsMCw1Niw2OCw0LDI0LDQsNjgsNTYsMCwyNCw0MCw3Miw3MiwxMjQsOCw4LDAsMTI0LDY0LDEyMCw0LDQsNjgsNTYsMCw1Niw2OCw2NCwxMjAsNjgsNjgsNTYsMCwxMjQsNCw4LDE2LDE2LDE2LDE2LDAsNTYsNjgsNjgsNTYsNjgsNjgsNTYsMCw1Niw2OCw2OCw2MCw0LDY4LDU2LDAsMCwxNiwwLDAsMTYsMCwwLDAsMCw4LDAsMCw4LDE2LDAsMCw0LDgsMTYsMzIsMTYsOCw0LDAsMCwwLDEyNiwwLDEyNiwwLDAsMCwxNiw4LDQsMiw0LDgsMTYsMCw1Niw2OCw0LDI0LDE2LDAsMTYsMCw2MCw2NiwxNTMsMTY1LDE2NSwxNTgsNjQsNjAsMTYsNDAsNDAsNjgsMTI0LDEzMCwxMzAsMCwyNTIsMTMwLDEzMCwyNTIsMTMwLDEzMCwyNTIsMCwxMjQsMTMwLDEyOCwxMjgsMTI4LDEzMCwxMjQsMCwyNTIsMTMwLDEzMCwxMzAsMTMwLDEzMCwyNTIsMCwyNTQsMTI4LDEyOCwyNDgsMTI4LDEyOCwyNTQsMCwyNTQsMTI4LDEyOCwyNDgsMTI4LDEyOCwxMjgsMCwxMjQsMTMwLDEyOCwxNDIsMTMwLDEzMCwxMjQsMCwxMzAsMTMwLDEzMCwyNTQsMTMwLDEzMCwxMzAsMCwxMjQsMTYsMTYsMTYsMTYsMTYsMTI0LDAsMiwyLDIsMiwyLDEzMCwxMjQsMCwxMzAsMTMyLDEzNiwyNDAsMTM2LDEzMiwxMzAsMCwxMjgsMTI4LDEyOCwxMjgsMTI4LDEyOCwyNTQsMCwxMzAsMTk4LDE3MCwxNDYsMTMwLDEzMCwxMzAsMCwxMzAsMTk0LDE2MiwxNDYsMTM4LDEzNCwxMzAsMCwxMjQsMTMwLDEzMCwxMzAsMTMwLDEzMCwxMjQsMCwyNTIsMTMwLDEzMCwxMzAsMjUyLDEyOCwxMjgsMCwxMjQsMTMwLDEzMCwxMzAsMTMwLDEzOCwxMjQsMiwyNTIsMTMwLDEzMCwyNTIsMTMyLDEzMCwxMzAsMCwxMjQsMTMwLDEyOCwxMjQsMiwxMzAsMTI0LDAsMjU0LDE2LDE2LDE2LDE2LDE2LDE2LDAsMTMwLDEzMCwxMzAsMTMwLDEzMCwxMzAsMTI0LDAsMTMwLDEzMCwxMzAsMTMwLDY4LDQwLDE2LDAsMTMwLDEzMCwxNDYsMTQ2LDE0NiwxMDgsNjgsMCwxMzAsNjgsNDAsMTYsNDAsNjgsMTMwLDAsMTMwLDEzMCw2OCw0MCwxNiwxNiwxNiwwLDI1NCw0LDgsMTYsMzIsNjQsMjU0LDAsNTYsMzIsMzIsMzIsMzIsMzIsNTYsMCwxMjgsNjQsMzIsMTYsOCw0LDIsMCwyOCw0LDQsNCw0LDQsMjgsMCwxNiw0MCw2OCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwyNTUsMTYsOCwwLDAsMCwwLDAsMCwwLDAsNjAsMiw2Miw2Niw2MiwwLDY0LDY0LDEyNCw2Niw2Niw2NiwxMjQsMCwwLDAsNjAsNjYsNjQsNjYsNjAsMCwyLDIsNjIsNjYsNjYsNjYsNjIsMCwwLDAsNjAsNjYsMTI0LDY0LDYyLDAsMTIsMTYsNTYsMTYsMTYsMTYsMTYsMCwwLDAsNjIsNjYsNjYsNjIsMiw2MCw2NCw2NCwxMjQsNjYsNjYsNjYsNjYsMCwxNiwwLDQ4LDE2LDE2LDE2LDU2LDAsNCwwLDEyLDQsNCw0LDY4LDU2LDY0LDY0LDY2LDY4LDEyMCw2OCw2NiwwLDQ4LDE2LDE2LDE2LDE2LDE2LDE2LDAsMCwwLDI1MiwxNDYsMTQ2LDE0NiwxNDYsMCwwLDAsMTI0LDY2LDY2LDY2LDY2LDAsMCwwLDYwLDY2LDY2LDY2LDYwLDAsMCwwLDEyNCw2Niw2Niw2NiwxMjQsNjQsMCwwLDYyLDY2LDY2LDY2LDYyLDIsMCwwLDk0LDk2LDY0LDY0LDY0LDAsMCwwLDYyLDY0LDYwLDIsMTI0LDAsMTYsMTYsNTYsMTYsMTYsMTYsMTIsMCwwLDAsNjYsNjYsNjYsNjYsNjIsMCwwLDAsNjYsNjYsNjYsMzYsMjQsMCwwLDAsNjUsNzMsNzMsNzMsNTQsMCwwLDAsNjgsNDAsMTYsNDAsNjgsMCwwLDAsNjYsNjYsNjYsNjIsMiw2MCwwLDAsMTI0LDgsMTYsMzIsMTI0LDAsOCwxNiwxNiwzMiwxNiwxNiw4LDAsMTYsMTYsMTYsMTYsMTYsMTYsMTYsMTYsMTYsOCw4LDQsOCw4LDE2LDAsMCwwLDk2LDE0NiwxMiwwLDAsMCwxNiw0MCw2OCwxOTgsNjgsNjgsMTI0LDA='

})()