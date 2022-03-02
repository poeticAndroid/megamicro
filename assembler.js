(() => {
  let inpos = 0
  let outpos = 0
  let tokens = []
  let bin = new Uint8Array(1024)

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  let labels = {},
    unrefs = {},
    locals = []

  function assemble(asm) {
    inpos = 0
    outpos = 0
    labels = {}
    unrefs = {}
    locals = []

    asm = asm.replaceAll(/;;.*\n/g, "\n").replaceAll("(", " ( ").replaceAll(")", " ) ").trim()
    tokens = asm.split(/\s+/)
    tokens.push(")")
    encode()

    return window.bin = trimSize(bin)
  }

  function encode() {
    let token
    let bytes = []
    let iff = -1, whil = -1, cond, then, end
    let label, params = -1, results = -1
    let varstate = 0 // 0=reference, 1=declaration, 2=assignment
    while (token = readToken()) {
      let opcode = opcodes.indexOf(token)
      if (token === ")") {
        if (params >= 0 || results >= 0) {
          if (params >= 0) {
            int32[0] = labels[label] - (outpos + 11)
            writeBytes([opcodes.indexOf("lit")])
            writeBytes(uint8)
          }
          int32[0] = Math.max(params, results)
          writeBytes([opcodes.indexOf("lit")])
          writeBytes(uint8)
          writeBytes([opcodes.indexOf(params >= 0 ? "call" : "return")])
          if (params >= 0) {
            if (!labels[label]) {
              unrefs[label] = unrefs[label] || []
              unrefs[label].push({ pos: outpos - 10, add: -10 })
            }
          }
        }
        return writeBytes(bytes)
      } else if (token === "(") {
        if (params >= 0) params++
        if (results >= 0) results++
        if (whil >= 0) whil++
        if (iff >= 0) iff++
        encode()
        if (iff === 1 || whil === 1) {
          int32[0] = 0
          writeBytes([opcodes.indexOf("lit")])
          writeBytes(uint8)
          writeBytes([opcodes.indexOf("jumpifz")])
          then = outpos
        }
        if (iff === 2 || whil === 2) {
          if (whil > 0) {
            int32[0] = cond - (outpos + 6)
            writeBytes([opcodes.indexOf("lit")])
            writeBytes(uint8)
            writeBytes([opcodes.indexOf("jump")])
          }
          int32[0] = 0
          writeBytes([opcodes.indexOf("lit")])
          writeBytes(uint8)
          writeBytes([opcodes.indexOf("jump")])
          int32[0] = outpos - then
          for (let i = 0; i < uint8.length; i++) {
            bin[then - 5 + i] = uint8[i]
          }
          then = outpos
        }
        if (iff === 3) {
          int32[0] = outpos - then
          for (let i = 0; i < uint8.length; i++) {
            bin[then - 5 + i] = uint8[i]
          }
          end = outpos
        }
      } else if (opcode >= 0) {
        bytes.push(opcode)
        varstate = 2
      } else if (token.slice(-1) === ":") {
        let label = token.replace(":", "")
        labels[label] = outpos
        if (unrefs[label]) {
          let o
          while (o = unrefs[label].pop()) {
            int32[0] = outpos - o.pos + o.add
            for (let i = 0; i < uint8.length; i++) {
              bin[o.pos + i] = uint8[i]
            }
          }
        }
      } else if (token === "@jump") {
        let label = readToken()
        int32[0] = labels[label] - (outpos + 6)
        writeBytes([opcodes.indexOf("lit")])
        writeBytes(uint8)
        writeBytes([opcodes.indexOf("jump")])
        if (!labels[label]) {
          unrefs[label] = unrefs[label] || []
          unrefs[label].push({ pos: outpos - 5, add: -5 })
        }
      } else if (token === "@call") {
        label = readToken()
        params = 0
      } else if (token === "@return") {
        results = 0
      } else if (token === "@while") {
        whil = 0
        cond = outpos
      } else if (token === "@if") {
        iff = 0
        cond = outpos
      } else if (token === "@vars") {
        locals = []
        varstate = 1
      } else if (token.slice(0, 1) === "$") {
        switch (varstate) {
          case 1: // declaration
            locals.push(token)
            int32[0] = 0
            writeBytes([opcodes.indexOf("lit")])
            writeBytes(uint8)
            break
          case 2: // assignment
            int32[0] = locals.indexOf(token)
            writeBytes([opcodes.indexOf("lit")])
            writeBytes(uint8)
            break
          default: // reference
            int32[0] = locals.indexOf(token)
            writeBytes([opcodes.indexOf("lit")])
            writeBytes(uint8)
            writeBytes([opcodes.indexOf("get")])
            break
        }
      } else if (token === "@skipto") {
        let min = eval(readToken())
        let len = min - outpos
        if (len >= 0) {
          let a = []
          a.length = len
          writeBytes(a)
        } else {
          console.error("@skipto: already past", min)
        }
      } else if (token === "@bytes") {
        while ((token = readToken()) && token !== ")") {
          bytes.push(eval(token))
        }
        return writeBytes(bytes)
      } else if (token === "@string") {
        let str = ""
        let len = eval(readToken())
        while ((token = readToken()) && token !== ")") {
          str += token + " "
        }
        str = eval(str)
        for (let i = 0; i < len; i++) {
          bytes.push(str.charCodeAt(i))
        }
        return writeBytes(bytes, len)
      } else {
        let val = eval(token)
        if (token.includes(".")) float32[0] = val
        else int32[0] = val
        if (bytes[bytes.length - 1] !== opcodes.indexOf("lit"))
          bytes.push(opcodes.indexOf("lit"))
        for (let i = 0; i < uint8.length; i++) {
          bytes.push(uint8[i])
        }
      }
    }
  }

  function readToken() {
    return tokens[inpos++]
  }

  function writeBytes(data, len = data.length) {
    while (outpos + len >= bin.length) bin = doubleSize(bin)
    let i = 0
    while (i < len) {
      bin[outpos++] = data[i++] || 0
    }
  }
  function doubleSize(oldArr) {
    let newArr = new Uint8Array(oldArr.length * 2)
    newArr.set(oldArr)
    return newArr
  }
  function trimSize(oldArr, size = outpos) {
    return oldArr.slice(0, size)
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

  const opcodes = [
    "halt", "sleep", "vsync", null, "jump", "jumpifz", null, "endcall", "call", "return", "exec", "break", "reset", "absadr", "cpuver", "noop",
    "lit", "get", "stackptr", "memsize", null, "loadbit", "load", "loadu", "drop", "set", "inc", "dec", null, "storebit", "store", null,
    "add", "sub", "mult", "div", "rem", null, "itof", "uitof", "fadd", "fsub", "fmult", "fdiv", "ffloor", null, null, "ftoi",
    "eq", "lt", "gt", "eqz", "and", "or", "xor", "rot", "feq", "flt", "fgt", null, null, null, null, null
  ]

  window.assemble = assemble
  window.opcodes = opcodes
  window.dumpBin = dumpBin
})()