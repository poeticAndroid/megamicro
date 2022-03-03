(() => {
  let mem = new Uint8Array(1024 * 64)

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  function assemble(asm) {
    let state, adr
    state = 0x42

    adr = item(state, 0)//keywords
    store(adr - 4, 4, loadWordList(keywords, adr))
    adr = item(state, 1)//opcodes
    store(adr - 4, 4, loadWordList(opcodes, adr))
    adr = item(state, 2)//source
    store(adr - 4, 4, loadFile(asm + "\n", adr))
    toLowerCase(adr)
    removeComments(adr)
    removeOptionals(adr)

    adr = item(state, 3)//functions
    store(adr - 4, 4, listFn(item(state, 2), adr))

    return mem.slice(bin, bin + binLen)
  }

  function listFn(src, list) {
    let len
    while (load(src, 1)) {
      src++
    }

    return len
  }

  function skipChar(adr, char, dir) {
    while (load(adr, 1) === char) {
      adr += dir
    }
    return adr
  }
  function skipToChar(adr, char, dir) {
    while (load(adr, 1) !== char) {
      adr += dir
    }
    return adr
  }
  function skipWS(adr, dir) {
    while (load(adr, 1) < 0x21) {
      adr += dir
    }
    return adr
  }
  function skipToWS(adr, dir) {
    while (load(adr, 1) > 0x20) {
      adr += dir
    }
    return adr
  }

  function sameWord(a, b) {
    while (load(a, 1) === load(b, 1)) {
      a++
      b++
    }
    if (load(a, 1) < 0x60 && load(b, 1) < 0x60) {
      return true
    }
    return false
  }

  function toLowerCase(adr) {
    let inString
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (load(adr, 1) > 0x40 && load(adr, 1) < 0x5b) {
          store(adr, 1, load(adr, 1) + 0x20)
        }
      }
      adr++
    }
  }
  function removeComments(adr) {
    let inString, erase
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (load(adr, 1) === 0x0a) erase = false
      if (load(adr, 1) === 0x3b && !inString) erase = true
      if (erase) store(adr, 1, 0x20)
      adr++
    }
  }
  function removeOptionals(adr) {
    let inString
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (load(adr, 1) === 0x21) store(adr, 1, 0x20)
        if (load(adr, 1) > 0x22 && load(adr, 1) < 0x2d) store(adr, 1, 0x20)
        if (load(adr, 1) === 0x2d && load(adr + 1, 1) < 0x21) store(adr, 1, 0x20)
        if (load(adr, 1) === 0x2f) store(adr, 1, 0x20)
        if (load(adr, 1) > 0x39 && load(adr, 1) < 0x61) store(adr, 1, 0x20)
      }
      adr++
    }
  }

  function item(list, index) {
    while (index && load(list, 4)) {
      list += 4 + load(list, 4)
      index--
    }
    return list + 4
  }
  function indexOf(list, word) {
    let index = 0
    while (load(list, 4)) {
      list += 4
      if (sameWord(list, word))
        return index
      list += load(list - 4, 4)
      index++
    }
    return -1
  }
  function has(list, word) {
    if (indexOf(list, word) < 0) return false
    else return true
  }

  function mcopy(src, dest, len) {
    if (src > dest) {
      while (len) {
        store(dest, 4, load(src, 4))
        dest++
        src++
        len--
      }
    } else {
      src += len
      dest += len
      while (len) {
        dest--
        src--
        store(dest, 4, load(src, 4))
        len--
      }
    }
  }
  function load(adr, len) {
    len = 8 * (4 - len)
    uint8.set(mem.slice(adr, adr + 4))
    int32[0] = int32[0] << len
    int32[0] = int32[0] >> len
    return int32[0]
  }
  function store(adr, len, val) {
    int32[0] = val
    mem.set(uint8.slice(0, len), adr)
  }

  function loadFile(data, adr) {
    for (let i = 0; i < data.length; i++) {
      if (typeof data === "string") mem[adr + i] = data.charCodeAt(i)
      else mem[adr + i] = data[i]
    }
    mem[adr + data.length] = 0
    return data.length + 1
  }
  function loadWordList(words, adr) {
    let start = adr
    for (let word of words) {
      store(adr, 4, word.length)
      adr += 4
      adr += loadFile(word, adr)
    }
    store(adr, 4, 0)
    adr += 4
    return adr - start
  }

  function dumpBin(bin, pc = -1) {
    let adr = 0
    let txt = ""
    let end = bin.length
    while (adr < end) {
      txt += (adr == pc ? "> " : "  ")
      txt += ("000000" + adr.toString(16)).slice(-5) + " "
      txt += ("00" + bin[adr].toString(16)).slice(-2) + " "
      txt += (opcodes[bin[adr]] || "") + " "
      if (opcodes[bin[adr]] === "lit") {
        uint8.set(bin.slice(adr + 1, adr + 5))
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += 4
      }
      if (bin[adr] >= 0x40) {
        let op = bin[adr] >> 4
        let len = bin[adr] >> 6
        if (op & 2) uint8.fill(255)
        else uint8.fill(0)
        uint8.set(bin.slice(adr + 1, adr + len), 1)
        uint8[0] = bin[adr] << 4
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

  const keywords = [
    "fn", "vars", "global", "data", "import", "if", "else", "while", "end"
  ]

  const opcodes = [
    "halt", "sleep", "vsync", "-", "jump", "jumpifz", "-", "endcall", "call", "return", "exec", "break", "reset", "absadr", "cpuver", "noop",
    "lit", "get", "stackptr", "memsize", "-", "loadbit", "load", "loadu", "drop", "set", "inc", "dec", "-", "storebit", "store", "-",
    "add", "sub", "mult", "div", "rem", "-", "itof", "uitof", "fadd", "fsub", "fmult", "fdiv", "ffloor", "-", "-", "ftoi",
    "eq", "lt", "gt", "eqz", "and", "or", "xor", "rot", "feq", "flt", "fgt", "-", "-", "-", "-", "-",
    "false", "true"
  ]

  for (let i = 0; i < mem.length; i++) {
    mem[i] = Math.random() * 255
  }

  window.assemble = assemble
  window.opcodes = opcodes
  window.dumpBin = dumpBin
})()