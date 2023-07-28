(() => {
  let cpu,
    ram = new WebAssembly.Memory({ initial: 1 }),
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
    kbGfx,
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
    gmode = -1,
    nextFrame = 1024,
    pixelCache = [],
    bitsprpx = [1, 2, 4, 8]

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
    cpu.reset()
  }

  function loadROM() {
    mem.set(hexToBin(font), 0x4c00)
    mem.set(hexToBin(kernal), 0x5000)
    mem.set([0x00, 0x50, 0, 0], mem.length - 8)
    cpu.reset()
    running = true
  }

  function render(t = 0) {
    requestAnimationFrame(render)
    if (t < nextFrame) return
    if (t - nextFrame > 256) nextFrame = Math.floor(t / 20) * 20
    nextFrame += 20
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
        mem[0x4800]--
        console.error("CPU CRASH!! OH NOEZ!! O_O", err)
        running = false
        nextFrame = Math.floor(t / 20) * 20
        opcode = 0
        let d = 1
        let blink = setInterval(() => {
          mem[0x4800] += d
          d *= -1
        }, 512)
        setTimeout(() => {
          clearInterval(blink)
          delete cpu
          loadCPU("z28r_cpu.wasm", { env: { ram: ram } })
        }, 16384)
      }
      if (mem[0x4b10] < 251) mem[0x4b10] += 5
      switch (opcode) {
        case 0x00: // halt
          running = false
          console.log("halt!")
          if (!debugMode) document.querySelector("#debugChk").click()
          break
        case 0x01: // sleep
          running = false
          nextFrame = Math.floor(t / 20) * 20
          sleep = setTimeout(() => {
            running = true
          }, cpu.getSleep())
          break
        case 0x02: // vsync
          vsyncfps++
          break
      }
    }

    // rendering
    let mode = mem[0x4800] & 7,
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
      if ((mode & 7) === 4) canvas.style.backgroundColor = "#593"
      else canvas.style.backgroundColor = "#000"
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
      mem[0x4801] = bitsprpx[mode & 3]
      mem[0x4802] = w / 8
      mem[0x4803] = h / 8
      pixelCache[mode] = pixelCache[mode] || []
      gmode = mode
    }
    if (t < nextFrame) {
      uint8.set(mem.slice(0x4804, 0x4808))
      let start = int32[0] & (mem.length - 1)
      let end = start + 0x4800
      let i = 0
      for (let m = start; m < end; m++) {
        let byte = mem[m & mem.length - 1]
        if (pixelCache[mode][byte]) {
          img.data.set(pixelCache[mode][byte], i)
          i += pixelCache[mode][byte].length
        } else {
          let len = renderbyte(m, i, bpp, mode & 4)
          pixelCache[mode][byte] = img.data.slice(i, i + len)
          i += len
        }
      }
      g.putImageData(img, 0, 0)
    }


    if (debugMode) {
      updateMonitor(cpu.getPC())
      updateStack()
    }

    fps++
    if (fpssec !== Math.floor(t / 1000)) {
      document.querySelector("#fps").textContent = vsyncfps + "/" + fps + " fps"
      fps = 0
      vsyncfps = 0
      fpssec = Math.floor(t / 1000)
    }

  }

  function renderbyte(madr, iadr, bpp, alt) {
    madr &= mem.length - 1
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
        img.data[iadr + 2] = ((byte & bm) ? 0x11 : 0x22)
        byte = byte >> bs
        img.data[iadr + 0] = ((byte & rm) ? 0x22 : 0x44)
        byte = byte >> rs
        img.data[iadr + 1] = ((byte & gm) ? 0x44 : 0x88)
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
      mem[0x4b06] = 0
      mem[0x4b07] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
      if (!e.shiftKey) kbGfx = false
    }
    if (e.type === "keydown") {
      if (kbEnabled) {
        mem[0x4b06] = e.keyCode
        mem[0x4b07] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
        if (!e.ctrlKey && !e.metaKey) {
          if (e.altKey && e.shiftKey) kbGfx = true
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
            if (kbGfx) {
              let char = e.keyCode
              if (char < 0x40) {
                char += 0x8
              }
              while (char < 0x80) {
                char += 0x20
              }
              kbBuffer.push(char)
            } else {
              kbBuffer.push(e.key.charCodeAt(0))
            }
          }
        }
      }
      if ((e.ctrlKey || e.metaKey) && e.key === "q") {
        cpu.break()
        running = true
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
    let file = "D" + driveNum + ":" + diskPath("" + diskCwd[driveNum] + cmd[1])
    let dir = file + "/"
    dir = dir.replace("//", "/")
    diskBusy = true
    console.log("drive", driveNum, cmd.join(" "))
    console.log("File:", file, dir)
    switch (cmd[0]) {
      case "get":
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
          diskStatus("err file not found")
        }
        break

      case "put":
        diskWrite = file
        localStorage.setItem(diskWrite, "")
        localStorage.setItem("date:" + diskWrite, Date.now())
        diskStatus("ok  0 bytes")
        break

      case "del":
        sessionStorage.removeItem(file)
        localStorage.removeItem(file)
        localStorage.removeItem("date:" + file)
        for (let i = 0; i < sessionStorage.length; i++) {
          let entry = sessionStorage.key(i)
          if (entry.slice(0, dir.length) === dir) {
            sessionStorage.removeItem(entry)
          }
        }
        for (let i = 0; i < localStorage.length; i++) {
          let entry = localStorage.key(i)
          if (entry.slice(0, dir.length) === dir) {
            localStorage.removeItem(entry)
            localStorage.removeItem("date:" + entry)
          }
        }
        diskStatus("ok  0 bytes")
        break

      case "inf":
        if (localStorage.getItem(file)) {
          diskStatus("ok  41 bytes")
          sendFileInfo(file.slice(0, file.lastIndexOf("/") + 1), file.slice(file.lastIndexOf("/") + 1))
          diskResp.push(new Uint8Array(1))
        } else {
          diskStatus("err file not found")
        }
        break

      case "dir":
        let entries = []
        for (let i = 0; i < sessionStorage.length; i++) {
          let entry = sessionStorage.key(i)
          if (entry.slice(0, dir.length) === dir) {
            entry = entry.slice(dir.length)
            if (entry.includes("/")) {
              entry = entry.slice(0, entry.indexOf("/") + 1)
            }
            if (!entries.includes(entry)) entries.push(entry)
          }
        }
        for (let i = 0; i < localStorage.length; i++) {
          let entry = localStorage.key(i)
          if (entry.slice(0, 10) === "date:date:") localStorage.removeItem(entry)
          if (entry.slice(0, dir.length) === dir) {
            console.log(entry)
            entry = entry.slice(dir.length)
            if (entry.includes("/")) {
              entry = entry.slice(0, entry.indexOf("/") + 1)
            }
            if (!entries.includes(entry)) entries.push(entry)
          }
        }
        entries.sort()
        diskStatus("ok  " + (entries.length * 40 + 1) + " bytes")
        for (let entry of entries) {
          sendFileInfo(dir, entry)
        }
        diskResp.push(new Uint8Array(1))
        break

      case "md":
        sessionStorage.setItem(dir, Date.now())
        diskStatus("ok  0 bytes")
        break

      case "cd":
        let found
        for (let i = 0; i < sessionStorage.length; i++) {
          let entry = sessionStorage.key(i)
          if (entry.slice(0, dir.length) === dir) {
            found = true
          }
        }
        for (let i = 0; i < localStorage.length; i++) {
          let entry = localStorage.key(i)
          if (entry.slice(0, dir.length) === dir) {
            found = true
          }
        }
        if (found) {
          diskCwd[driveNum] = file.slice(file.indexOf("/")) + "/"
          diskStatus("ok  " + (diskCwd[driveNum].length + 1) + " bytes")
          let buf = new Uint8Array(diskCwd[driveNum].length + 1)
          for (let i = 0; i < diskCwd[driveNum].length; i++) {
            buf[i] = diskCwd[driveNum].charCodeAt(i)
          }
          diskResp.push(buf)
        } else {
          diskStatus("err dir not found")
        }
        break

      default:
        diskStatus("err unknown command")
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
      } else if (dir.includes(":")) {
        valid = []
      } else if (dir) {
        let name = (dir.replaceAll(" ", "_") + ".").split(".")
        valid.push(name[0].toLowerCase().slice(0, 8) + ".".slice(0, name[1].length) + name[1].toLowerCase().slice(0, 3))
      } else {
        valid = []
      }
    }
    return "/" + valid.join("/")
  }

  function sendFileInfo(dir, entry) {
    // filename.ext/ 9876543210 yyymmddhhmmss
    let buf = new Uint8Array(40)
    let int, now = new Date()
    let i = 0
    for (let j = 0; j < entry.length; j++) {
      buf[i++] = entry.charCodeAt(j)
    }
    while (i < 14) {
      buf[i++] = 0x20
    }
    if (localStorage.getItem(dir + entry)) {
      int = (localStorage.getItem(dir + entry).length / 2).toString()
    } else {
      int = "<dir>"
    }
    for (let j = 0; j < int.length; j++) {
      buf[i++] = int.charCodeAt(j)
    }
    while (i < 25) {
      buf[i++] = 0x20
    }
    if (localStorage.getItem("date:" + dir + entry)) {
      now.setTime(parseInt(localStorage.getItem("date:" + dir + entry)))
      int = now.getYear()
      int *= 100
      int += now.getMonth() + 1
      int *= 100
      int += now.getDate()
      int *= 100
      int += now.getHours()
      int *= 100
      int += now.getMinutes()
      int *= 100
      int += now.getSeconds()
      int = ("00000000" + int).slice(-13)
      for (let j = 0; j < int.length; j++) {
        buf[i++] = int.charCodeAt(j)
      }
    }
    while (i < buf.length - 1) {
      buf[i++] = 0x20
    }
    buf[i++] = 0x0a
    diskResp.push(buf)
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
    mem[0x4b10] = 0
    mem[0x4b11] = now.getSeconds()
    mem[0x4b12] = now.getMinutes()
    mem[0x4b13] = now.getHours()
    mem[0x4b14] = now.getDay()
    mem[0x4b15] = now.getDate()
    mem[0x4b16] = now.getMonth() + 1
    mem[0x4b17] = now.getYear()
    setTimeout(hwClock, 1000 - now.getMilliseconds())
  }

  function changeSpeed(e) {
    let s = eval(document.querySelector("#speedTxt").value)
    speed = Math.pow(2, s)
    localStorage.setItem("?speed", document.querySelector("#speedTxt").value)
  }

  function dumpMem(adr, len, pc) {
    adr = Math.max(0, adr)
    let txt = ""
    let end = adr + len
    while (adr < end) {
      txt += (adr == pc ? "> " : "  ")
      txt += toHex(adr, 5, "") + " "
      txt += toHex(mem[adr], 2, "") + " "
      txt += (opcodes[mem[adr]] || "") + " "
      if (opcodes[mem[adr]] === "lit") {
        uint8.set(mem.slice(adr + 1, adr + 5))
        txt += toHex(int32[0]) + " " + int32[0]
        adr += 4
      } else if (mem[adr] >= 0x40) {
        let op = mem[adr] >> 4
        let len = mem[adr] >> 6
        if (op & 2) uint8.fill(255)
        else uint8.fill(0)
        uint8.set(mem.slice(adr + 1, adr + len), 1)
        uint8[0] = mem[adr] << 4
        int32[0] = int32[0] >> 4
        if (op & 1) int32[0] = int32[0] ^ 0x40000000
        txt += toHex(int32[0]) + " " + int32[0]
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
    let first = true
    while (first || len > 0) {
      if (cs === adr) {
        txt += "--------\n"
        cs = -1
        len--
        first = false
      }
      uint8.set(mem.slice(adr, adr + 4))
      if (adr < mem.length) {
        txt += toHex(int32[0], 8) + " " + int32[0] + " "
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
    while (i < 64 && !txt.includes(">"))
      txt = dumpMem(pc - i++, 64, pc)
    txt = txt.slice(0, txt.indexOf(">"))
    txt = txt.split("\n").slice(-6).join("\n")
    txt += dumpMem(pc, 64, pc)
    txt = txt.split("\n").slice(0, 17).join("\n")
    document.querySelector("#monitorPre").textContent = txt
  }

  function updateStack() {
    document.querySelector("#stackPre").textContent = "Stack ptr: " + toHex(cpu.getVS()) + "\n" + dumpStack(10)
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
    let scr = setInterval(() => {
      document.querySelector("#debugSec").scrollIntoView(false)
    }, 16)
    setTimeout(() => {
      clearTimeout(scr)
    }, 1024)
  }

  function hexToBin(hex) {
    let out = new Uint8Array(hex.length / 2)
    for (let i = 0; i < hex.length; i += 2) {
      out[i / 2] = parseInt(hex.slice(i, i + 2), 16)
    }
    return out
  }

  const font = localStorage.getItem("D0:/font.prg") || '0000001818000000000000000f0f0f0f00000000f0f0f0f000000000ffffffff0f0f0f0f000000000f0f0f0f0f0f0f0f0f0f0f0ff0f0f0f0f0f0f0f0000000000000000f0f181818000000f0f01818181818181f0f000000181818f8f0000000181818ffe70000001818180f0f181818000000e7ff181818181818f0f01818181818181818181818000000ffff00000018183cffff3c1818c3e77e3c3c7ee7c303070e1c3870e0c0c0e070381c0e07030103070f0f1f3f7f80c0e0f0f0f8fcfe7c82828282827c0000060c0cd87830007cd6d6feeed67c007cd6d6febac67c00006cfefe7c38100010387cfe5410380010387cfe7c381000383838fefe103800000000000000000010101010100010004444000000000000247e2424247e2400103c40380478100042a44810244a84001c22241825423d0008080000000000000810202020100800100804040408100010543854100000000010107c1010000000000000080810000000007e000000000000000000001000020408102040800038444444444438001030101010107c003844041820407c003844041804443800182848487c0808007c4078040444380038444078444438007c0408101010100038444438444438003844443c0444380000100000100000000008000008100000040810201008040000007e007e000000100804020408100038440418100010003c4299a5a59e403c102828447c828200fc8282fc8282fc007c82808080827c00fc8282828282fc00fe8080f88080fe00fe8080f8808080007c82808e82827c00828282fe828282007c10101010107c000202020202827c00828488f088848200808080808080fe0082c6aa928282820082c2a2928a8682007c82828282827c00fc828282fc8080007c828282828a7c02fc8282fc848282007c82807c02827c00fe101010101010008282828282827c00828282824428100082829292926c440082442810284482008282442810101000fe0408102040fe00382020202020380080402010080402001c04040404041c00102844000000000000000000000000ff100800000000000000003c023e423e0040407c4242427c0000003c4240423c0002023e4242423e0000003c427c403e000c1038101010100000003e42423e023c40407c4242424200100030101010380004000c0404044438404042447844420030101010101010000000fc929292920000007c424242420000003c4242423c0000007c4242427c4000003e4242423e0200005e604040400000003e403c027c001010381010100c000000424242423e0000004242422418000000414949493600000044281028440000004242423e023c00007c0810207c00081010201010080010101010101010101008080408081000000060920c000000102844c644447c00'
  const kernal = localStorage.getItem("D0:/kernal.prg") || '8d0404008037040081380400853f04008b43040084480400814c040086570400886b04008b6d04008395040083a20400cda90004c2ae0004caab0004c3b50004c1c00004cfc600040000000000000000d08004134120d080041b801001408631084083240840820b08074c6f6164696e672000202e2e2e20006d61696e2e707267002f000a0a0909889191919191919191919191919191919191919191919191919191919191919191890a09099020496e7365727420626f6f7461626c65206d6564696120696e746f20616e7920900a090990647269766520616e64207072657373204374726c2b5120746f207265626f6f74900a09098a91919191919191919191919191919191919191919191919191919191919191918b0a004040446e196e118b01056f6e1a6e11d8bf041b40a0f50d106364202043c7a5000818a0fe04446e1131890a056e11d8bf041bdcbf041445054a418d43086faef00d428b57088404418f4208c5bb000d4a6e1143818e0844c9ba000d428156088a03418541086faeef0d428355086fadee0d428b54086fafed0d4283540840aded0d106765742043cd9e00086f196f11840305ceb6000d4a6f11438a89088001c1b6000d428951086f8a0d0d428151084a41863c086f11cab4000d42cba6000818408b020849048f0fd0a00442814f08416e1aa0f5046fa0e90d42834e08000c070a52657475726e20636f64653a2000404041ceb0000d08c9b0000d1b408c15084041851c08406f42811d08c5af000d4ac0af000d13438e81086fa3fc0d428f49088001cdad000d428549084a418a34084a418534080709202020204d6567612020202020202f2f2f09092f2f2f204d6567614d6963726f202f2f2f0a0a0a004350553a202020207a323872200053706565643a202000206970730a004d656d6f72793a20002062797465730a00404040406f4286140841418f120840820d086fa3f90d4289410840418e11086faffa0d428c4008cca4000d4a0e438977086fc1a4000d42893f084a418e2a086fadf90d428c3e08d1b104146d19486e19d1b104146d113042056504d1b104146d19d1b104146d113045054c6e1a6204c4a0000d4a6e11438073086fc89f000d42803b086fa2f60d42883a086fa0f60d42803a08802001506f19120d6f11314705c000106f1a6204506f11366f19c69c000d4a6f1143826f086fca9b000d428237086fa3f30d428a36084a418f2108078c30d48004404385770850d480041b50d880041b0740404040d880041350356f196f11d880041bc080046f11206e19debf04146d1980026c196c114f056f6c1a6d11406c1143840408adfe046f11136d196e116f11314b056d116f111b446f1aaefe0440dcbf041c40ddbf041c076f11d0800414304105076f11d080041c02076f11dfbf041c6e11debf041c07406f1131410507406e113141050740d280041448226c19416c11216f113241050740d380041448226b19416b11216e1132410507d1800414d88004131d6c116e11226f11201e6d111f07406f113142054009406e11314205400940d280041448226d19416d11216f11324205400940d380041448226c19416c11216e113242054009d1800414d4800413156d116e11226f112016170907404040406d116f112068196c116e112067196e11691967116911318202056f116a1968116a11318001056b1169116a1143a5f308416a1aa8fe0441691aa6fd0407404040406d116f112068196c116e112067196e11691967116911318601056f116a1968116a11314505416a1a640441691aa2fe04076f1133410507404040404040d880041350356e19c080046e11206c19d380041448226b196b11c08004236f11226d19debf04146a198002691969114f056f691a6a1140691143aaea08adfe046e11136a196d1140216c1a6c116e11314f056d116e1120136e111b446e1aaafe046d116c1a6c116e11314b056a116e111b446e1aaefe04074040dcbf04256e19ddbf04256d19486f11308f02056f6e1a406e11318e01056e11d2800414206e196f6d1a406d11314605406e19406d196d11ddbf041c6e11dcbf041c07496f1130850105416e1a486e11244505416e1a65046e11dcbf041c074a6f1130830105406e19416d1a6e11dcbf041c6d11ddbf041c074d6f11304a05406e196e11dcbf041c0780026f113141050740404040404040d28004144822671948671121661941d2800414216c1941d3800414216b196f118f07344822d0c0042068196c116e11324f05416d1a6f6e1a6c1140216e1aaafe046b116d11324f056b116d1121482241a0e9086b116d196e1148226a196d1148226919d1800414d88004131d67116911226a11201e4168111548691969118c0105486a196a114c0517debf0420141f6f6a1a600466111e6f691aaffd04416e1a6e11dcbf041c6d11ddbf041c07406f11146d196e1133336d113333348401056d1141a2ea08416f1a6f11146d196f6e1aa0fe04074040406f116d19416e116f1120216c198f016f1114324505416f1a63046c116f11314905406f111c416f1a6004406f111c6d116f196f11144d056f111441a2e508416f1aaefe046b11338f1f05800241a0e4084841abe308dfbf04146f36dfbf041cdebf04146f36debf041c6f111449056f111441abe1084604800241a3e108dfbf04146f36dfbf041cdebf04146f36debf041c4841aadf08d4b004133343050266048302d6b00414308201056f11144d056f111441aadd08416f1aaefe048402d6b00414308b02056f111449056f111441aedb084604800241a6db084841a1db086d116f11324b054841a5da086f6f1aaefe048502d6b00414308902056d116f11328102056f111449056f111441a1d8084604800241a9d7084841a4d7084841afd6086f6f1a8602d6b0041430890305d28004146b196f111449056f111441a0d5084604800241a8d4084841a3d4086b118501056d116f113248054841a2d3086f6f1a6f6b1aa6fe048702d6b00414304f056f11144a056f111441a4d108416f1a8802d6b0041430800205d28004146b196b118501056f11144a056f111441a0cf08416f1a6f6b1aa6fe0448d5b00414308704056d116f11328f03054841a1cd08800241abcc086f111449056f111441afcb084604800241a7cb084841a2cb084841adca086f11144a056f6f1a80026f111c47046f6f1a406f111c4ad5b00414308c01056f111449056f111441a2c8084604800241aac7084841a5c708416b198f01d5b00414328901056c116f1131810105d5b004146f111c6f111441a2c508416f1a40d4b0041babdf048f016f1114324d056f111441a8c308416f1aabfe04406f111c4a41a9c20807303132333435363738396162636465660040404040a8fe0d6919416b198d026f1114304d056f6b19416f1a6d1143056f6d1a406f111432406d1132348f09054a6e113080040582066f1114304d05426e19416f1a6d1143056f6d1a8f066f1114304d05486e19416f1a6d1143056f6d1a88076f1114304e0580016e19416f1a6d1143056f6d1a406a196e116a11318303056a116911201480026f111420306a11691120146f111430358201056e116c11226c196a116c11206c196e116a19416a1aa5fc046e116a113046056b116c112209416f1a6d1143056f6d1aa4f5046b116c11220907404040a5f10d6a19406f11314e058d026d111c416d1a6f6f11226f196d116c196f118901056e116f11246a1120146d111c416d1a6e116f11236f19a2fe046d116c1130480580036d111c416d1a406d111c426c116d1121236b196b118f0105416d11216d196d11146f196c11146d111c6f116c111c416c1a6f6b1aacfd0407406f6f1a6f6d1a6e11850105416f1a416d1a6f6e1a6f1114334305406e19a6fe046d110907436d11324e056f116e111b446e1a6c6d1aacfe046d114b056f116e111c416e1a6f6d1a076e116f1132800305436d11328201056f11136e111b446f1a446e1a6c6d1aa7fe046d118201056f11146e111c416f1a416e1a6f6d1aa9fe046e116f11318803056d116f1a6d116e1a436d11328201056c6f1a6c6e1a6f11136e111b6c6d1aa7fe046d118201056f6f1a6f6e1a6f11146e111c6f6d1aa9fe0407408420d090044043a8f508026f11d090041b8a0f6e1142a4f208d490046e1143a4f60880028a0fd0900442a0f108d09004201b8a0fd0900442a2f008d09004204a6d1143a8e7088f0fd0900442aeee08d1b0041cd8bf04144120d0b0041cd0b00413860405d0b0041433450540d1b0041cd2b00414800305106f6b2020d0a00413308e01058a0f4ad4a00443acd5086d1940d2b0041c6d1145056d110942044109450440d0b0041ba3fb044009070000000040d0a0046613314605d0a004adfe1bd0b00413880505d0b0041433450540d1b0041c6e11810405d2b00414820305abfc13146f111c416f1a41a0fc1320acfb1b416d1a6f6e1a41d2b00414304605d0a004a8fa1b41d2b0041421d2b0041c4604d0a004a6f91b43046d1109a1fa046d11090740d0b004148c05056e11810505d1b00414338704058f0f6e11318202056e11d090046f1143abe3086e11d1b0041c6e116d1a6e116f1a6e1140216e1a8d01048f0fd090046f1143a9e1088f0fd1b0041c8f0f6d1a8f0f6f1aa1f06e1a43046d1109adf9046d110907'
})()