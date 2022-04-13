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
    pxadrlens = [3, 2, 1, 0]

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
    if (t - nextFrame > 1024) nextFrame = Math.floor(t / 20) * 20
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
      mem[0x4b17] += 5
      switch (opcode) {
        case 0x00: // halt
          running = false
          console.log("halt!")
          if (!debugMode) document.querySelector("#debugChk").click()
          break
        case 0x01: // sleep
          running = false
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
      if ((mode & 7) === 4) canvas.style.backgroundColor = "#241"
      else canvas.style.backgroundColor = "#000"
      g.fillRect(0, 0, canvas.width, canvas.height)
      img = g.getImageData(0, 0, canvas.width, canvas.height)
      mem[0x4801] = pxadrlens[mode & 3]
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
        img.data[iadr + 2] = ((byte & bm) ? 3 : 15)
        byte = byte >> bs
        img.data[iadr + 0] = ((byte & rm) ? 7 : 31)
        byte = byte >> rs
        img.data[iadr + 1] = ((byte & gm) ? 15 : 63)
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
    document.querySelector("#stackPre").textContent = "Stack size: " + toHex(cpu.getVS()) + "\n" + dumpStack(10)
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

  const font = localStorage.getItem("drive0:/font.prg") || '0000001818000000000000000f0f0f0f00000000f0f0f0f000000000ffffffff0f0f0f0f000000000f0f0f0f0f0f0f0f0f0f0f0ff0f0f0f0f0f0f0f0000000000000000f0f181818000000f0f01818181818181f0f000000181818f8f0000000181818ffe70000001818180f0f181818000000e7ff181818181818f0f01818181818181818181818000000ffff00000018183cffff3c1818c3e77e3c3c7ee7c303070e1c3870e0c0c0e070381c0e07030103070f0f1f3f7f80c0e0f0f0f8fcfe7c82828282827c0000060c0cd87830007cd6d6feeed67c007cd6d6febac67c00006cfefe7c38100010387cfe5410380010387cfe7c381000383838fefe103800000000000000000010101010100010004444000000000000247e2424247e2400103c40380478100042a44810244a84001c22241825423d0008080000000000000810202020100800100804040408100010543854100000000010107c1010000000000000080810000000007e000000000000000000001000020408102040800038444444444438001030101010107c003844041820407c003844041804443800182848487c0808007c4078040444380038444078444438007c0408101010100038444438444438003844443c0444380000100000100000000008000008100000040810201008040000007e007e000000100804020408100038440418100010003c4299a5a59e403c102828447c828200fc8282fc8282fc007c82808080827c00fc8282828282fc00fe8080f88080fe00fe8080f8808080007c82808e82827c00828282fe828282007c10101010107c000202020202827c00828488f088848200808080808080fe0082c6aa928282820082c2a2928a8682007c82828282827c00fc828282fc8080007c828282828a7c02fc8282fc848282007c82807c02827c00fe101010101010008282828282827c00828282824428100082829292926c440082442810284482008282442810101000fe0408102040fe00382020202020380080402010080402001c04040404041c00102844000000000000000000000000ff100800000000000000003c023e423e0040407c4242427c0000003c4240423c0002023e4242423e0000003c427c403e000c1038101010100000003e42423e023c40407c4242424200100030101010380004000c0404044438404042447844420030101010101010000000fc929292920000007c424242420000003c4242423c0000007c4242427c4000003e4242423e0200005e604040400000003e403c027c001010381010100c000000424242423e0000004242422418000000414949493600000044281028440000004242423e023c00007c0810207c00081010201010080010101010101010101008080408081000000060920c000000102844c644447c00'
  const kernal = localStorage.getItem("drive0:/kernal.prg") || '8703040000000000000000000000000040800a6f11314c056f1141802f08416f1aadfe0441810105d5b00414418e2d0840d4b0041b02abfe0407d08004134120d080041b80100140860f08408d040840adfb080709202020204d6567612020202020202f2f2f09092f2f2f204d6567614d6963726f202f2f2f0a0a0a004d656d6f72793a20002062797465730a0053706565643a2000206970730a00404040406f428c10084141850f08408e09086fa2fa0d42833c084041840e086faefb0d42863b08506f19120d6f11314705c000106f1a6204506f11366f198a5e0d4a6f1143814a086f8f5d0d428d38086fa6f90d428538086fa6f90d428d3708d6b104146d19d6b104146d113042056504d6b104146d19d6b104146d113045054c6e1a6204835a0d4a6e11438a45086f88590d428634086faff50d428e33084a418e1c0807883fd4800440438e4d080740404040d880041350356f19c080046f11206e19debf04146d1980026c196c114f056f6c1a6d11406c1143840408adfe046f11136d196e116f11314b056d116f111b446f1aaefe0440dcbf041c40ddbf041c076f11d0800414304105076f11d080041c02076f11dfbf041c6e11debf041c07406f1131410507406e113141050740d280041448226c19416c11216f113241050740d380041448226b19416b11216e1132410507404043d1800414346a196a11d880041337503569196c116e11226f1120691a6d116911426a1122041c071d071e071f0707406f113142054009406e11314205400940d280041448226d19416d11216f11324205400940d380041448226c19416c11216e113242054009404043d1800414346b196b11d88004133750356a196d116e11226f11206a1a6a11426b1122041409150916091709076f1133410507404040404040d880041350356e19c080046e11206c19d380041448226b196b11c08004236f11226d19debf04146a198002691969114f056f691a6a1140691143abee08adfe046e11136a196d1140216c1a6c116e11314f056d116e1120136e111b446e1aaafe046d116c1a6c116e11314b056a116e111b446e1aaefe04074040dcbf04256e19ddbf04256d19486f11308f02056f6e1a406e11318e01056e11d2800414206e196f6d1a406d11314605406e19406d196d11ddbf041c6e11dcbf041c07496f1130850105416e1a486e11244505416e1a65046e11dcbf041c074a6f1130830105406e19416d1a6e11dcbf041c6d11ddbf041c074d6f11304a05406e196e11dcbf041c0780026f1131410507404040404040404040404040debf04146c19dfbf04146b1941d2800414216a1941d38004142169196f118f07344822d0c0042062196a116e11324f05416d1a6f6e1a6a1140216e1aaafe0469116d11324f0569116d1121482241ade80869116d196e11482266196d114822651948661120641948651120631965116719631167113184040568621114376119661168196411681131880205416111376119416111344c056b116711681143a0d7084a046c116711681143a4d60841681aa0fd0441621a41671aa4fb04416e1a6e11dcbf041c6d11ddbf041c07406f11146d196e1133336d113333348401056d1141ade708416f1a6f11146d196f6e1aa0fe0407303132333435363738396162636465660040404040a8fe0d6919416b198d026f1114304d056f6b19416f1a6d1143056f6d1a406f111432406d1132348f09054a6e113080040582066f1114304d05426e19416f1a6d1143056f6d1a8f066f1114304d05486e19416f1a6d1143056f6d1a88076f1114304e0580016e19416f1a6d1143056f6d1a406a196e116a11318303056a116911201480026f111420306a11691120146f111430358201056e116c11226c196a116c11206c196e116a19416a1aa5fc046e116a113046056b116c112209416f1a6d1143056f6d1aa4f5046b116c11220907404040a5f10d6a19406f11314e058d026d111c416d1a6f6f11226f196d116c196f118901056e116f11246a1120146d111c416d1a6e116f11236f19a2fe046d116c1130480580036d111c416d1a406d111c426c116d1121236b196b118f0105416d11216d196d11146f196c11146d111c6f116c111c416c1a6f6b1aacfd0407406f6f1a6f6d1a6e11850105416f1a416d1a6f6e1a6f1114334305406e19a6fe046d110907436d11324e056f116e111b446e1a6c6d1aacfe046d114b056f116e111c416e1a6f6d1a09076e116f1132800305436d11328201056f11136e111b446f1a446e1a6c6d1aa7fe046d118201056f11146e111c416f1a416e1a6f6d1aa9fe046e116f11318803056d116f1a6d116e1a436d11328201056c6f1a6c6e1a6f11136e111b6c6d1aa7fe046d118201056f6f1a6f6e1a6f11146e111c6f6d1aa9fe040700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
})()