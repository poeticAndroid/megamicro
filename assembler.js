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

    return trimSize(bin)
  }

  function encode() {
    let token
    let bytes = []
    let whil, cond, then, end
    let varstate = 0 // 0=reference, 1=declaration, 2=assignment
    while (token = readToken()) {
      let opcode = opcodes.indexOf(token)
      if (token === ")") {
        return writeBytes(bytes)
      } else if (token === "(") {
        encode()
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
        writeBytes([opcodes.indexOf("const")])
        writeBytes(uint8)
        writeBytes([opcodes.indexOf("jump")])
        if (!labels[label]) {
          unrefs[label] = unrefs[label] || []
          unrefs[label].push({ pos: outpos - 5, add: -5 })
        }
      } else if (token === "@while") {
        whil = true
        cond = outpos
      } else if (token === "@if") {
        whil = false
        cond = outpos
      } else if (token === "@do") {
        writeBytes([opcodes.indexOf("const")])
        writeBytes(uint8)
        writeBytes([opcodes.indexOf("jumpifz")])
        then = outpos
      } else if (token === "@else") {
        writeBytes([opcodes.indexOf("const")])
        writeBytes(uint8)
        writeBytes([opcodes.indexOf("jump")])
        int32[0] = outpos - then
        for (let i = 0; i < uint8.length; i++) {
          bin[then - 5 + i] = uint8[i]
        }
        then = outpos
      } else if (token === "@end") {
        if (whil) {
          int32[0] = cond - (outpos + 6)
          writeBytes([opcodes.indexOf("const")])
          writeBytes(uint8)
          writeBytes([opcodes.indexOf("jump")])
        }
        int32[0] = outpos - then
        for (let i = 0; i < uint8.length; i++) {
          bin[then - 5 + i] = uint8[i]
        }
        end = outpos
      } else if (token === "@vars") {
        locals = []
        varstate = 1
      } else if (token.slice(0, 1) === "$") {
        switch (varstate) {
          case 1: // declaration
            locals.push(token)
            break
          case 2: // assignment
            int32[0] = locals.indexOf(token)
            writeBytes([opcodes.indexOf("const")])
            writeBytes(uint8)
            break
          default: // reference
            int32[0] = locals.indexOf(token)
            writeBytes([opcodes.indexOf("const")])
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
        while (token = readToken() && token !== ")") {
          let val = eval(token)
          bytes.push(val)
        }
        return writeBytes(bytes)
      } else {
        let val = eval(token)
        if (token.includes(".")) float32[0] = val
        else int32[0] = val
        if (bytes[bytes.length - 1] !== opcodes.indexOf("const"))
          bytes.push(opcodes.indexOf("const"))
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
    if (outpos + len >= bin.length) bin = doubleSize(bin)
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

  const _ = null
  const opcodes = [
    "halt", "sleep", "vsync", _, "jump", "jumpifz", _, _, "call", "sys", _, "return", _, "here", "goto", "noop",
    "const", "get", _, "load", "load16u", "load8u", "load16s", "load8s", "drop", "set", _, "store", "store16", "store8", "stacksize", "memsize",
    "add", "sub", "mult", "div", "rem", _, _, "ftoi", "fadd", "fsub", "fmult", "fdiv", _, _, "uitof", "sitof",
    "eq", "lt", "gt", "not", "and", "or", "xor", "rot", "feq", "flt", "fgt", _, _, _, _, _
  ]

  window.assemble = assemble
  window.opcodes = opcodes
})()