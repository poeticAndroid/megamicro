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
    textEnabled = false,
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
    bitsprpx = [1, 2, 4, 8],
    pasteBinEl = document.querySelector("#pasteBin")

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  async function init() {
    addEventListener("resize", resize); resize()
    addEventListener("keydown", onUser)
    addEventListener("keyup", onUser)
    pasteBinEl.addEventListener("mousedown", onUser)
    pasteBinEl.addEventListener("mouseup", onUser)
    pasteBinEl.addEventListener("mousemove", onUser)
    pasteBinEl.addEventListener("mouseout", e => pasteBinEl.style.cursor = "crosshair")

    pasteBinEl.addEventListener("focus", e => textEnabled = false)
    pasteBinEl.addEventListener("keydown", pasteBin)

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
    setTimeout(resize, 1024)
    setTimeout(resize, 8192)
  } init()

  async function loadCPU(path, imports) {
    let bin = await (await fetch(path)).arrayBuffer()
    let wasm = await WebAssembly.instantiate(bin, imports)
    cpu = wasm.instance.exports
    window.cpu = cpu
    cpu.reset()
  }

  function loadROM() {
    mem.set(hexToBin(font), 0x0400)
    mem.set(hexToBin(kernal), 0x0800)
    mem.set([0x00, 0x08, 0, 0], mem.length - 8)
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
      if (kbBuffer.length && mem[0x0304] === 0) {
        mem[0x0305] = kbBuffer.shift()
        mem[0x0304] = Math.min(255, 1 + kbBuffer.length)
      }
      if (mem[0x0300]) {
        if (mem[0x0301]) {
          diskReq.push(mem.slice(0x0100, 0x0100 + mem[0x0301]))
          mem[0x0301] = 0
        }
        handleDrive(mem[0x0300] - 1)
        if (!mem[0x0302]) {
          if (diskResp.length) {
            mem[0x0302] = diskResp[0].length
            mem.set(diskResp.shift(), 0x0200)
          } else if (!diskBusy && !diskWrite) {
            mem[0x0300] = 0
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
        mem[0x0000]--
        console.error("CPU CRASH!! OH NOEZ!! O_O", err)
        running = false
        nextFrame = Math.floor(t / 20) * 20
        opcode = 0
        let d = 1
        let blink = setInterval(() => {
          mem[0x0000] += d
          d *= -1
        }, 512)
        setTimeout(() => {
          clearInterval(blink)
          delete cpu
          loadCPU("z28r_cpu.wasm", { env: { ram: ram } })
        }, 16384)
      }
      if (mem[0x0310] < 251) mem[0x0310] += 5
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
    let mode = mem[0x0000] & 7,
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
      mem[0x0001] = bitsprpx[mode & 3]
      mem[0x0002] = w / 8
      mem[0x0003] = h / 8
      pixelCache[mode] = pixelCache[mode] || []
      gmode = mode
    }
    if (t < nextFrame) {
      uint8.set(mem.slice(0x0004, 0x0008))
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
      mem[0x0309] = Math.max(0, (e.offsetX / e.target.clientWidth) * 255)
      mem[0x030a] = Math.max(0, (e.offsetY / e.target.clientHeight) * 144)
      if (mem[0x030b] = e.buttons) {
        kbEnabled = true
        //textEnabled = true
        pasteBinEl.style.cursor = "none"
      }
    }

    if (e.type === "keyup") {
      mem[0x0306] = 0
      mem[0x0307] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
      if (!e.shiftKey) kbGfx = false
    }
    if (e.type === "keydown") {
      if (kbEnabled) {
        mem[0x0306] = e.keyCode
        mem[0x0307] = e.shiftKey + 2 * e.altKey + 4 * e.ctrlKey + 4 * e.metaKey
        if (!e.ctrlKey && !e.metaKey) {
          if (e.altKey && e.shiftKey) kbGfx = true
          if (e.key === "Backspace") {
            kbBuffer.push(0x08)
          }
          if (e.key === "Escape") {
            kbBuffer.push(0x1b)
          }
          if (e.key === "Tab") {
            kbBuffer.push(0x09)
            e.preventDefault()
          }
          if (textEnabled) {
            if (e.key === "Enter") {
              kbBuffer.push(0x0a)
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
      }
      if ((e.ctrlKey || e.metaKey || e.altKey) && e.key === "q") {
        kbBuffer.pop()
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
      mem.fill(0, 0x0100, 0x0304)
      diskBusy = false
      diskCwd[driveNum] = "/"
      diskInitialized = true
      return
    }
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
    mem[0x0310] = 0
    mem[0x0311] = now.getSeconds()
    mem[0x0312] = now.getMinutes()
    mem[0x0313] = now.getHours()
    mem[0x0314] = now.getDay()
    mem[0x0315] = now.getDate()
    mem[0x0316] = now.getMonth() + 1
    mem[0x0317] = now.getYear()
    setTimeout(hwClock, 1000 - now.getMilliseconds())
  }

  function pasteBin(e) {
    setTimeout(() => {
      kbBuffer.push(...(e.target.value.split("").map(c => c.charCodeAt(0))))
      e.target.value = ""
    })
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

  let _dumpStackLen = 0
  setInterval(() => {
    _stackSize = 0
    if (_dumpStackLen > 16) _dumpStackLen = 16
  }, 4096)
  function dumpStack() {
    let len = 0
    let adr = cpu.getVS()
    let cs = cpu.getCS()
    let txt = ""
    while (adr >= 0 && adr < mem.length) {
      if (cs === adr) {
        txt += "--------\n"
        cs = -1
        len++
      }
      uint8.set(mem.slice(adr, adr + 4))
      if (cs == 0) cs = int32[0]
      if (cs < 0) cs++

      txt += toHex(int32[0], 8) + " " + int32[0] + " "
      if (float32[0]) txt += float32[0]
      txt += "\n"
      len++

      adr += 4
    }
    while (len < _dumpStackLen) {
      txt = "\n" + txt
      len++
    }
    _dumpStackLen = Math.max(_dumpStackLen, len)
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
    txt = txt.split("\n").slice(0, _dumpStackLen + 1).join("\n")
    document.querySelector("#monitorPre").textContent = txt
  }

  let _stackSize = 0
  function updateStack() {
    _stackSize = Math.max(_stackSize, mem.length - cpu.getVS())
    document.querySelector("#stackPre").textContent = "Stack size: " + ("00000000" + _stackSize).slice(-6) + " bytes\n" + dumpStack(20)
  }

  function resize(e) {
    if (window.innerWidth < 1070 || window.innerHeight < 700) {
      maxwidth = 512
    } else {
      maxwidth = 1024
    }
    gmode = -1
    setTimeout(() => {
      pasteBinEl.style.left = canvas.offsetLeft + "px"
      pasteBinEl.style.top = canvas.offsetTop + "px"
      pasteBinEl.style.width = canvas.offsetWidth + "px"
      pasteBinEl.style.height = canvas.offsetHeight + "px"
    }, 20)
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
  const kernal = localStorage.getItem("D0:/kernal.prg") || '8d04040084360400853704008c3d04008a4104008b450400884904008f5b04008d6e04008071040080970400cfa30004caab0004c2b00004c7ad0004c3b70004cec00004c0c70004000000000000000050134120501b801001408e3008408f230840820b08074c6f6164696e672000202e2e2e20006d61696e2e707267002f000a0a0909889191919191919191919191919191919191919191919191919191919191919191890a09099020496e7365727420626f6f7461626c65206d6564696120696e746f20616e7920900a09099020647269766520616e6420707265737320416c742b5120746f207265626f6f74900a09098a91919191919191919191919191919191919191919191919191919191919191918b0a004040446e196e118a01056f6e1a6e11983f1b40a1f50d106364202043cca7000818a1fe04446e1131860a056e11983f1b9c3f1445054a418d48086fa1f10d42875b088404418f4708c7bb000d4a6e114385900844cbba000d428d59088a03418546086fa1f00d428f58086fa0ef0d428758086fa2ee0d428f570840a0ee0d106765742043c4a100086f196f11840305c0b7000d4a6f11438e8b088001c3b6000d428555086f890d0d428d54084a418641086f11ccb4000d42cfa7000818408a020848048f0f9020428e5208416e1aa3f5046fa4e90d42805208000c070a52657475726e20636f64653a2000404041c1b1000d08ccb0000d1b4088150840418a1b08406f42821c08c8af000d4ac3af000d13438384086fa3fc0d428c4d088001c0ae000d42824d084a418b39084a418639080709202020204d6567612020202020202f2f2f09092f2f2f204d6567614d6963726f202f2f2f0a0a0a004350553a202020207a323872200053706565643a202000206970730a004d656d6f72793a20002062797465730a00404040406f428713084141841208408e0c086fa3f90d4286450840418311086faffa0d42894408cfa4000d4a0e438e79086fc4a4000d428643084a418f2f086fadf90d428942089131146d19486e199131146d1130420566049131146d199131146d113045054c6e1a6304cba0000d4a6e11438975086fcf9f000d42813f086fa6f60d42893e086fa4f60d42813e08802001506f19120d6f11314705c000106f1a6204506f11366f19cd9c000d4a6f11438b71086fc19c000d42833b086fa7f30d428b3a084a41842708078c30544043807a08f666fb0d541bf666fb0d581b0740404040581350356f196f11581bc080046f11206e199e3f146d1980026c196c114f056f6c1a6d11406c11438c0308adfe046f11136d196e116f11314b056d116f111b446f1aaefe04409c3f1c409d3f1c076f115014304105076f11501c02076f119f3f1c6e119e3f1c07406f1131410507406e113141050740521448226c19416c11216f113241050740531448226b19416b11216e1132410507511458131d6c116e11226f11201e6d111f07406f113142054009406e11314205400940521448226d19416d11216f11324205400940531448226c19416c11216e11324205400951145413156d116e11226f112016170907404040406d116f112068196c116e112067196e11691967116911318202056f116a1968116a11318001056b1169116a1143a5f408416a1aa8fe0441691aa6fd0407404040406d116f112068196c116e112067196e11691967116911318601056f116a1968116a11314505416a1a640441691aa2fe04076f11334105074040404040404040581350356e19c080046e11206c195314482269196911c08004236f11226b196b11c08004216a199e3f146819406b1132880505c080046b11324f059c3f13681940a6e40868119c3f1b078002671967114f056f671a681140671143a7e908adfe046e111368196b116e11206d196a116e116d11438d5c086a116e11206d196b116d116811438559088c05046f6b11226b19c080046b11324f059c3f13681940a8de0868119c3f1b076b11c08004216a196b116e11206d196a116d116e11438358088002671967114f056f671a681140671143a0e208adfe046e111368196b116e116811438653080740409c3f256e199d3f256d19486f11308e01056f6e1a406e11314f0552146e1a6f6d1a6d119d3f1cabfe046e119c3f1c07496f1130840105416e1a486e11244505416e1a65046e119c3f1c074a6f1130810105406e19416d1a6e119c3f1c6d119d3f1c074d6f11304905406e196e119c3f1c0780026f113141050740404040404040521448226719486711216619415214216c19415314216b196f118f0734482290402068196c116e11324f05416d1a6f6e1a6c1140216e1aaafe04406d11314b056d11482241a0e408406d196b116d11324f056b116d1121482241abe2086b116d196e1148226a196d1148226919511458131d67116911226a11201e4168111548691969118b0105486a196a114b05179e3f20141f6f6a1a610466111e6f691aa0fe04416e1a6e119c3f1c6d119d3f1c07406f11146d196e1133336d113333348401056d1141a6eb08416f1a6f11146d196f6e1aa0fe04074040406f116d19416e116f1120216c198f016f1114324505416f1a63046c116f11314905406f111c416f1a6004406f111c6d116f196f11144d056f111441a6e608416f1aaefe046b1133871e05800241a4e5084841afe4089f3f146f369f3f1c9e3f146f369e3f1c6f111449056f111441a3e3084604800241abe2089f3f146f369f3f1c9e3f146f369e3f1c4841a6e1089430133343050267048302963014308201056f11144d056f111441a8df08416f1aaefe048402963014308b02056f111449056f111441addd084604800241a5dd084841a0dd086d116f11324b054841a4dc086f6f1aaefe048502963014308902056d116f11328102056f111449056f111441a1da084604800241a9d9084841a4d9084841afd8086f6f1a86029630143087030552146b196f111449056f111441a3d7084604800241abd6084841a6d6086b118501056d116f113248054841a5d5086f6f1a6f6b1aa6fe048702963014304f056f11144a056f111441a8d308416f1a8802963014308e010552146b196b118501056f11144a056f111441a7d108416f1a6f6b1aa6fe0448953014308704056d116f11328f03054841a9cf08800241a3cf086f111449056f111441a7ce084604800241afcd084841aacd084841a5cd086f11144a056f6f1a80026f111c47046f6f1a406f111c4a953014308c01056f111449056f111441abca084604800241a3ca084841aec908416b198f01953014328801056c116f11318001059530146f111c6f111441adc708416f1a4094301ba3e1048f016f1114324d056f111441a4c608416f1aabfe04406f111c4a41a5c50807303132333435363738396162636465660040404040a8fe0d6919416b198d026f1114304d056f6b19416f1a6d1143056f6d1a406f111432406d1132348f09054a6e113080040582066f1114304d05426e19416f1a6d1143056f6d1a8f066f1114304d05486e19416f1a6d1143056f6d1a88076f1114304e0580016e19416f1a6d1143056f6d1a406a196e116a11318303056a116911201480026f111420306a11691120146f111430358201056e116c11226c196a116c11206c196e116a19416a1aa5fc046e116a113046056b116c112209416f1a6d1143056f6d1aa4f5046b116c11220907404040a5f10d6a19406f11314e058d026d111c416d1a6f6f11226f196d116c196f118901056e116f11246a1120146d111c416d1a6e116f11236f19a2fe046d116c1130480580036d111c416d1a406d111c426c116d1121236b196b118f0105416d11216d196d11146f196c11146d111c6f116c111c416c1a6f6b1aacfd0407406f6f1a6f6d1a6e11850105416f1a416d1a6f6e1a6f1114334305406e19a6fe046d110907436d11324e056f116e111b446e1a6c6d1aacfe046d114e056f116e111c416e1a6f6d1aaefe04076e116f1132800305436d11328201056f11136e111b446f1a446e1a6c6d1aa7fe046d118201056f11146e111c416f1a416e1a6f6d1aa9fe046e116f11318803056d116f1a6d116e1a436d11328201056c6f1a6c6e1a6f11136e111b6c6d1aa7fe046d118201056f6f1a6f6e1a6f11146e111c6f6d1aa9fe040740842090104043a6f508026f1190101b8a0f6e1142a3f20894106e1143a7f60880028a0f901042a1f1089010201b8a0f901042a5f0089010204a6d1143ace7088f0f901042a3ef0891301c983f14412090301c9030138f03059030143344054091301c9230148c0205106f6b2020902013308c01058a0f4a942043aad6086d194092301c6d1145056d11094204410944044090301babfb044009070000000040902067133144059020601b9030138005059030143344054091301c6e118b03059230148e0205a2fd13146f111c416f1a41a7fc1320a3fc1b416d1a6f6e1a419230143045059020a1fb1b419230142192301c45049020a2fa1b43046d1109aafa046d110907409030148705056e118c0405913014338304058f0f6e11318002056e1190106f1143ade5086e1191301c6e116d1a6e116f1a6e1140216e1a8b01048f0f90106f1143ade3088f0f91301c8f0f6d1a8f0f6f1aa1f06e1a43046d1109a3fa046d110907'

  if (!localStorage.getItem("D0:/main.prg")) fetch("./megados.json").then(resp => resp.ok && console.log(resp.text().then(data => {
    let json = JSON.parse(data)
    for (const key in json) {
      localStorage.setItem(key, json[key])
    }
  })))

})()