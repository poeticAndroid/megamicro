(() => {
  let filepos = 0
  let bin = new Uint8Array(1024)

  function assemble(asm) {
    filepos = 0
    let lines = asm.split("\n")
    for (let line of lines) {
      line += ";"
      line = line.substring(0, line.indexOf(";"))
      let words = line.trim().split(/\s+/)
      switch (words[0]) {
        case "":
          break
        default:
          if (opcodes.indexOf(words[0]) < 0) console.error("unknown command", words[0])
          let instr = [opcodes.indexOf(words[0])]
          if (words[1]) {
            let val = eval(words[1])
            for (let i = 0; i < 4; i++) {
              instr.push(val & 0xff)
              val = val >> 8
            }
          }
          writeBytes(instr)
          break
      }

    }
    return trimSize(bin)
  }

  function writeBytes(data, len = data.length) {
    if (filepos + len >= bin.length) bin = doubleSize(bin)
    let i = 0
    while (i < len) {
      bin[filepos++] = data[i++] || 0
    }
  }
  function doubleSize(oldArr) {
    let newArr = new Uint8Array(oldArr.length * 2)
    newArr.set(oldArr)
    return newArr
  }
  function trimSize(oldArr, size = filepos) {
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