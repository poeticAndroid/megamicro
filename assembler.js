(() => {
  let inpos = 0
  let outpos = 0
  let tokens = []
  let bin = new Uint8Array(1024)

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  function assemble(asm) {
    inpos = 0
    outpos = 0
    labels = {}
    refs = {}

    asm = asm.replaceAll(/;;.*\n/g, "\n").replaceAll("(", " ( ").replaceAll(")", " ) ").trim()
    tokens = asm.split(/\s+/)
    tokens.push(")")
    encode()

    return trimSize(bin)
  }

  function encode() {
    let token
    let bytes = []
    while (token = readToken()) {
      let opcode = opcodes.indexOf(token)
      if (token === ")") {
        return writeBytes(bytes)
      } else if (token === "(") {
        encode()
      } else if (opcode >= 0) {
        bytes.push(opcode)
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