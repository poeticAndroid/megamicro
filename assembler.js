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
          let instr = [opcodes.indexOf(words[0])]
          for (let i = 1; i < words.length; i++) {
            let word = words[i]
            if (word.slice(0, 1) === "r") {
              instr.push(parseInt(word.slice(1)))
            } else {
              let data = eval(word)
              instr[3] = data & 0xff
              data = data >> 8
              instr[2] = data & 0xff
              data = data >> 8
              instr[1] = instr[1] || 0
              instr[1] = instr[1] | (data << 4)
            }
          }
          writeBytes(instr, 4)
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
    "halt", "noop", "goto", _, "fwd", "rew", "fwdifz", "rewifz", "pushreg", "popreg", _, _, "sleep", "waitforuser", "hsync", "vsync",
    "load8", "load16", "load32", _, "load", "loadreg", _, _, "store8", "store16", "store32", _, "copy", "fill", _, "memsize",
    "add", "sub", "mult", "div", "rem", _, _, _, "fadd", "fsub", "fmult", "fdiv", _, _, _, _,
    "eq", "lt", "gt", _, "and", "or", "xor", "rot", "feq", "flt", "fgt", _, _, _, _, _
  ]

  window.assemble = assemble
  window.opcodes = opcodes
})()