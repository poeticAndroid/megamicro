(() => {
  let mem = new Uint8Array(1024 * 64)

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  let
    srcpos = 0,
    litpos = 0,
    exepos = 0,
    state = 0x42
  // 0:keywords
  // 1:opcodes
  // 2:source
  // 3:global list
  // 4:external list
  // 5:function list
  // 6:data list
  // 7:local list
  // 8:lit lengths
  // 9:executable

  function assemble(asm) {
    let adr, tries, maxlit

    adr = item(state, 0)//keywords
    store(adr - 4, 4, loadWordList(keywords, adr))
    adr = item(state, 1)//opcodes
    store(adr - 4, 4, loadWordList(opcodes, adr))
    adr = item(state, 2)//source
    store(adr - 4, 4, loadFile(asm, adr))
    toLowerCase(adr)
    removeComments(adr)
    removeOptionals(adr)

    adr = item(state, 3)//globals
    store(adr - 4, 4, listGlobals())
    adr = item(state, 4)//externals
    store(adr - 4, 4, listExt())
    adr = item(state, 5)//functions
    store(adr - 4, 4, listFn())
    adr = item(state, 6)//data list
    store(adr - 4, 4, listData())
    adr = item(state, 7)//local list
    store(adr - 4, 4, listLocals())
    adr = item(state, 8)//lit lengths
    store(adr - 4, 4, 0)
    adr = item(state, 9)//executable
    store(adr - 4, 4, 0)

    srcpos = item(state, 2)//source
    litpos = item(state, 8)//lits
    exepos = item(state, 9)//exe
    maxlit = 0
    tries = 8
    while (tries && compile()) {
      if (litpos > maxlit) {
        maxlit = litpos + 4
        store(litpos, 4, 0)
        litpos = item(state, 8)//lits
        while (litpos < maxlit) {
          store(litpos, 4, 0)
          litpos += 4
        }
        litpos = item(state, 8)//lits
        store(litpos - 4, 4, maxlit - litpos)
      }
      srcpos = item(state, 2)//source
      litpos = item(state, 8)//lits
      exepos = item(state, 9)//exe
      tries--
    }

    return mem.slice(item(state, 9), exepos)
  }

  function compile() {
    let kw, kwid, name, i
    let changes = 0
    kw = item(state, 0)
    while (loadu(srcpos, 1)) {
      srcpos = skipWS(srcpos)

      kwid = indexOf(kw, srcpos)
      if (kwid < 0) {
        changes += compileLine()
      }
      if (kwid === 0) {//ext
        srcpos = nextWord(srcpos)
        name = srcpos
        srcpos = nextWord(srcpos)
        setValueOf(item(state, 4), name, 0, strToInt(srcpos, 10, -1) | 0x40000000)
        srcpos = nextWord(srcpos)
        setValueOf(item(state, 4), name, 1, strToInt(srcpos, 10, -1))
      }
      if (kwid === 1) {//fn
        store(item(state, 7), 4, 0)
        srcpos = nextWord(srcpos)
        name = srcpos
        setValueOf(item(state, 5), name, 0, exepos)
        i = 0
        srcpos = nextWord(srcpos)
        while (loadu(srcpos, 1) > 0x20) {
          i++
          addTo(item(state, 7), srcpos, 0)
          srcpos = nextWord(srcpos)
        }
        setValueOf(item(state, 5), name, 1, i)
        changes += compile()
        changes += vstore(exepos, 1, 0x07)//endcall
        exepos++
      }
      if (kwid === 2) {//vars
        srcpos = nextWord(srcpos)
        while (loadu(srcpos, 1) > 0x20) {
          addTo(item(state, 7), srcpos, 0)
          srcpos = nextWord(srcpos)
          changes += vstore(exepos, 1, 0x40)// false
          exepos++
        }
      }
      if (kwid === 3) {//data
        srcpos = nextWord(srcpos)
        name = srcpos
        srcpos = nextWord(srcpos)
        setValueOf(item(state, 6), name, 0, exepos)
        srcpos = nextWord(srcpos)
        changes += compileData()
      }
      if (kwid === 4) {//globals
        srcpos = nextWord(srcpos)
        while (loadu(srcpos, 1) > 0x20) {
          setValueOf(item(state, 3), srcpos, 0, exepos)
          changes += vstore(exepos, 4, 0)
          exepos += 4
          srcpos = nextWord(srcpos)
        }
      }
      if (kwid === 6) {//skipby
        srcpos = nextWord(srcpos)
        i = strToInt(srcpos, 10, -1)
        while (i) {
          changes += vstore(exepos, 1, 0)
          exepos++
          i--
        }
      }
      if (kwid === 7) {//skipto
        srcpos = nextWord(srcpos)
        i = item(state, 9)
        i += strToInt(srcpos, 10, -1)
        while (exepos < i) {
          changes += vstore(exepos, 1, 0)
          exepos++
        }
      }
      if (kwid === 8) {//while
        srcpos = nextWord(srcpos)
        changes += compileWhile()
      }
      if (kwid === 9) {//if
        srcpos = nextWord(srcpos)
        changes += compileIf()
      }
      if (kwid === 10) {//else
        return changes
      }
      if (kwid === 11) {//end
        srcpos = nextWord(srcpos)
        return changes
      }
      if (kwid === 12) {//let
        srcpos = nextWord(srcpos)
        name = srcpos
        srcpos = nextWord(srcpos)
        changes += compileLine()
        i = indexOf(item(state, 7), name)
        if (i > -1) {
          changes += compileLit(i * -1 - 1)
          changes += vstore(exepos, 1, 0x19) //set
          exepos++
        } else {
          changes += vstore(exepos, 1, 0x44) //lit 4
          exepos++
          changes += compileRef(valueOf(item(state, 3), name, 0))
          changes += vstore(exepos, 1, 0x1e) //store
          exepos++
        }
      }
      if (kwid === 13) {//inc
        srcpos = nextWord(srcpos)
        name = srcpos
        i = indexOf(item(state, 7), name)
        if (i > -1) {
          changes += compileLit(i * -1 - 1)
          changes += vstore(exepos, 1, 0x1a) //inc
          exepos++
        } else {
          changes += vstore(exepos, 1, 0x41) //lit 1
          exepos++

          changes += vstore(exepos, 1, 0x44) //lit 4
          exepos++
          changes += compileRef(valueOf(item(state, 3), name, 0))
          changes += vstore(exepos, 1, 0x16) //load
          exepos++

          changes += vstore(exepos, 1, 0x20) //add
          exepos++

          changes += vstore(exepos, 1, 0x44) //lit 4
          exepos++
          changes += compileRef(valueOf(item(state, 3), name, 0))
          changes += vstore(exepos, 1, 0x1e) //store
          exepos++
        }
      }
      if (kwid === 14) {//dec
        srcpos = nextWord(srcpos)
        name = srcpos
        i = indexOf(item(state, 7), name)
        if (i > -1) {
          changes += compileLit(i * -1 - 1)
          changes += vstore(exepos, 1, 0x1b) //dec
          exepos++
        } else {
          changes += vstore(exepos, 1, 0x41) //lit 1
          exepos++

          changes += vstore(exepos, 1, 0x44) //lit 4
          exepos++
          changes += compileRef(valueOf(item(state, 3), name, 0))
          changes += vstore(exepos, 1, 0x16) //load
          exepos++

          changes += vstore(exepos, 1, 0x21) //sub
          exepos++

          changes += vstore(exepos, 1, 0x44) //lit 4
          exepos++
          changes += compileRef(valueOf(item(state, 3), name, 0))
          changes += vstore(exepos, 1, 0x1e) //store
          exepos++
        }
      }
      if (kwid === 15) {//jump
        srcpos = nextWord(srcpos)
        name = srcpos
        if (!valueOf(item(state, 5), name, 0)) setValueOf(item(state, 5), name, 0, exepos)
        changes += compileRef(valueOf(item(state, 5), name, 0))
        changes += vstore(exepos, 1, 0x04) //jump
        exepos++
      }

      srcpos = nextLine(srcpos)
    }
    return changes
  }
  function compileData() {
    let kw, char
    let changes = 0
    kw = item(state, 0)
    while (loadu(srcpos, 1)) {
      srcpos = skipWS(srcpos)

      if (indexOf(kw, srcpos) === 11) {//end
        srcpos = nextWord(srcpos)
        return changes
      }
      while (loadu(srcpos, 1) > 0x20) {
        if (isNumber(srcpos)) {
          changes += vstore(exepos, 1, strToInt(srcpos, 10, -1))
          exepos++
        }
        if (loadu(srcpos, 1) === 0x22) { // "
          srcpos++
          while (loadu(srcpos, 1) !== 0x22) { // "
            char = loadu(srcpos, 1)
            if (char === 0x5c) { // \
              srcpos++
              char = loadu(srcpos, 1)
              if (char > 0x2f && char < 0x38) { // octal code
                char = strToInt(srcpos, 8, 3)
                if (char > 0o7) srcpos++
                if (char > 0o77) srcpos++
              }
              if (char === 0x62) char = 0x08 // b -> backspace
              if (char === 0x66) char = 0x0c // f -> formfeed
              if (char === 0x6e) char = 0x0a // n -> linefeed
              if (char === 0x72) char = 0x0d // r -> carriage return
              if (char === 0x74) char = 0x09 // t -> tab
              if (char === 0x78) { // x -> hex code
                srcpos++
                char = strToInt(srcpos, 16, 2)
                srcpos++
              }
            }
            changes += vstore(exepos, 1, char)
            exepos++
            srcpos++
          }
        }
        srcpos = nextWord(srcpos)
      }
      srcpos = nextLine(srcpos)
    }
    return changes
  }
  function compileWhile() {
    let cond, jumplit, loopEnd
    let oldlit, newlit
    let changes = 0
    cond = exepos
    changes += compileLine()

    jumplit = exepos
    oldlit = litpos
    exepos += load(litpos, 1)
    litpos++
    changes += vstore(exepos, 1, 0x05) //jumpifz
    exepos++

    changes += compile()
    changes += compileRef(cond)
    changes += vstore(exepos, 1, 0x04) //jump
    exepos++
    loopEnd = exepos

    newlit = litpos
    litpos = oldlit
    exepos = jumplit
    changes += compileRef(loopEnd)
    litpos = newlit
    exepos = loopEnd

    return changes
  }
  function compileIf() {
    let kw, elsjumplit, endjumplit
    let blockStart, blockEnd, elseEnd
    let elslit, endlit, newlit
    let changes = 0
    kw = item(state, 0)
    changes += compileLine()

    elsjumplit = exepos
    elslit = litpos
    exepos += load(litpos, 1)
    litpos++
    changes += vstore(exepos, 1, 0x05) //jumpifz
    exepos++

    blockStart = exepos
    changes += compile()

    if (indexOf(kw, srcpos) === 10) { // else
      endjumplit = exepos
      endlit = litpos
      exepos += load(litpos, 1)
      litpos++
      changes += vstore(exepos, 1, 0x04) //jump
      exepos++
      blockEnd = exepos
      changes += compile()
    } else { // end
      endjumplit = elsjumplit
      endlit = elslit
      blockEnd = exepos
    }
    elseEnd = exepos

    newlit = litpos
    litpos = elslit
    exepos = elsjumplit
    changes += compileRef(blockEnd)

    litpos = endlit
    exepos = endjumplit
    changes += compileRef(blockEnd)
    litpos = newlit
    exepos = elseEnd

    return changes
  }
  function compileLine() {
    let ops, vars, datas, fns, exts, globals
    let changes = 0, start, end, i
    ops = item(state, 1)
    vars = item(state, 7)
    datas = item(state, 6)
    fns = item(state, 5)
    exts = item(state, 4)
    globals = item(state, 3)

    end = srcpos - 1
    while (load(srcpos, 1) > 0x20) {
      start = srcpos
      srcpos = nextWord(srcpos)
    }
    srcpos = start
    while (srcpos > end) {
      i = -1
      if (isNumber(srcpos)) {
        changes += compileLit(strToInt(srcpos, 10, -1))
        i = -2
      }
      if (i === -1) i = indexOf(ops, srcpos)
      if (i > -1) {
        changes += vstore(exepos, 1, i)
        exepos++
        i = -2
      }
      if (i === -1) i = indexOf(vars, srcpos)
      if (i > -1) {
        changes += compileLit(i * -1 - 1)
        changes += vstore(exepos, 1, 0x11) //get
        exepos++
        i = -2
      }
      if (i === -1) i = indexOf(datas, srcpos)
      if (i > -1) {
        if (!valueOf(datas, srcpos, 0)) setValueOf(datas, srcpos, 0, exepos)
        changes += compileRef(valueOf(datas, srcpos, 0))
        changes += vstore(exepos, 1, 0x0d) //absadr
        exepos++
        i = -2
      }
      if (i === -1) i = indexOf(fns, srcpos)
      if (i > -1) {
        if (!valueOf(fns, srcpos, 0)) setValueOf(fns, srcpos, 0, exepos)
        changes += compileLit(valueOf(fns, srcpos, 1))
        changes += compileRef(valueOf(fns, srcpos, 0))
        changes += vstore(exepos, 1, 0x08) //call
        exepos++
        i = -2
      }
      if (i === -1) i = indexOf(exts, srcpos)
      if (i > -1) {
        changes += compileLit(valueOf(exts, srcpos, 1))
        changes += compileLit(valueOf(exts, srcpos, 0))
        changes += vstore(exepos, 1, 0x08) //call
        exepos++
        i = -2
      }
      if (i === -1) i = indexOf(globals, srcpos)
      if (i > -1) {
        if (!valueOf(globals, srcpos, 0)) setValueOf(globals, srcpos, 0, exepos)
        changes += vstore(exepos, 1, 0x44) //lit 4
        exepos++
        changes += compileRef(valueOf(globals, srcpos, 0))
        changes += vstore(exepos, 1, 0x16) //load
        exepos++
        i = -2
      }
      srcpos = prevWord(srcpos)
    }

    srcpos = nextWord(start)
    return changes
  }
  function compileRef(adr) {
    let i, changes = 0
    i = exepos + load(litpos, 1) + 1
    changes += compileLit(adr - i)
    return changes
  }
  function compileLit(val) {
    let neg, abs, lownib, size
    let changes = 0
    neg = !!(val & 0x80000000)
    abs = !!(val & 0x40000000)
    if (neg) abs = !abs
    lownib = val & 0xf

    size = 1
    if (abs) val = val ^ 0x40000000
    if (neg) val = val ^ -1
    if (val > 0xf) size = 2
    if (val > 0xfff) size = 3
    if (val > 0xfffff) size = 5
    if (neg) val = val ^ -1
    if (abs) val = val ^ 0x40000000
    if (load(litpos, 1) > size) size = load(litpos, 1)
    store(litpos, 1, size)
    litpos++

    if (size < 4) {
      val = val << 4
      val = val & 0xffffff00
      val += size * 0x40
      val += neg * 0x20
      val += abs * 0x10
      val += lownib
      changes += vstore(exepos, size, val)
      exepos += size
    } else {
      changes += vstore(exepos, 1, 0x10)
      exepos++
      changes += vstore(exepos, 4, val)
      exepos += 4
    }

    return changes
  }

  function listGlobals() {
    let kw, src, globlist, globlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    globlist = item(state, 3) // global list
    globlistPos = globlist
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 4) { //globals
        pos = nextWord(pos)
        while (loadu(pos, 1) > 0x20) {
          store(globlistPos, 4, wordLen(pos) + 5)
          globlistPos += 4
          mcopy(pos, globlistPos, wordLen(pos))
          globlistPos += wordLen(pos)
          store(globlistPos, 1, 0)
          globlistPos += 1
          store(globlistPos, 4, 0)
          globlistPos += 4
          pos = nextWord(pos)
        }
      }
      pos = nextLine(pos)
    }
    store(globlistPos, 4, 0)
    globlistPos += 4

    return globlistPos - globlist
  }
  function listExt() {
    let kw, src, extlist, extlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    extlist = item(state, 4) // external list
    extlistPos = extlist
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 0) { //ext
        pos = nextWord(pos)
        store(extlistPos, 4, wordLen(pos) + 9)
        extlistPos += 4
        mcopy(pos, extlistPos, wordLen(pos))
        extlistPos += wordLen(pos)
        store(extlistPos, 1, 0)
        extlistPos += 1
        store(extlistPos, 4, 0)
        extlistPos += 4
        store(extlistPos, 4, 0)
        extlistPos += 4
      }
      pos = nextLine(pos)
    }
    store(extlistPos, 4, 0)
    extlistPos += 4

    return extlistPos - extlist
  }
  function listFn() {
    let kw, src, fnlist, fnlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    fnlist = item(state, 5) // function list
    fnlistPos = fnlist
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 1) { //fn
        pos = nextWord(pos)
        store(fnlistPos, 4, wordLen(pos) + 9)
        fnlistPos += 4
        mcopy(pos, fnlistPos, wordLen(pos))
        fnlistPos += wordLen(pos)
        store(fnlistPos, 1, 0)
        fnlistPos += 1
        store(fnlistPos, 4, 0)
        fnlistPos += 4
        store(fnlistPos, 4, 0)
        fnlistPos += 4
      }
      pos = nextLine(pos)
    }
    store(fnlistPos, 4, 0)
    fnlistPos += 4

    return fnlistPos - fnlist
  }
  function listData() {
    let kw, src, datalist, datalistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    datalist = item(state, 6) // data list
    datalistPos = datalist
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 3) { //data
        pos = nextWord(pos)
        store(datalistPos, 4, wordLen(pos) + 5)
        datalistPos += 4
        mcopy(pos, datalistPos, wordLen(pos))
        datalistPos += wordLen(pos)
        store(datalistPos, 1, 0)
        datalistPos += 1
        store(datalistPos, 4, 0)
        datalistPos += 4
      }
      pos = nextLine(pos)
    }
    store(datalistPos, 4, 0)
    datalistPos += 4

    return datalistPos - datalist
  }
  function listLocals() {
    let kw, src, varlist, varlistPos, pos, maxpos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    varlist = item(state, 7) // local list
    varlistPos = varlist
    maxpos = 0
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) < 3) { //ext fn vars
        if (indexOf(kw, pos) === 1) { //fn
          if (varlistPos > maxpos)
            maxpos = varlistPos
          varlistPos = varlist
        }
        pos = nextWord(pos)
        while (loadu(pos, 1) > 0x20) {
          store(varlistPos, 4, wordLen(pos) + 1)
          varlistPos += 4
          mcopy(pos, varlistPos, wordLen(pos))
          varlistPos += wordLen(pos)
          store(varlistPos, 1, 0)
          varlistPos += 1
          pos = nextWord(pos)
        }
      }
      pos = nextLine(pos)
    }
    store(varlistPos, 4, 0)
    if (varlistPos > maxpos)
      maxpos = varlistPos
    maxpos += 4

    return maxpos - varlist
  }
  function listLits() {
    let kw, src, litlist, litlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    litlist = item(state, 8) // lit list
    litlistPos = litlist
    while (loadu(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 2) { //vars
        while (loadu(pos, 1) > 0x20) {
          store(litlistPos, 1, 1)
          litlistPos += 1
          pos = nextWord(pos)
        }
      }
      if (indexOf(kw, pos) === 8) { //while
        store(litlistPos, 1, 1)
        litlistPos += 1
        store(litlistPos, 1, 1)
        litlistPos += 1
      }
      if (indexOf(kw, pos) === 9) { //if
        store(litlistPos, 1, 1)
        litlistPos += 1
        store(litlistPos, 1, 1)
        litlistPos += 1
      }
      while (loadu(pos, 1) > 0x20) {
        if (isNumber(pos)) {
          store(litlistPos, 1, 1)
          litlistPos += 1
        }
        pos = nextWord(pos)
      }
      pos = nextLine(pos)
    }

    return litlistPos - litlist
  }

  function skipWS(pos) {
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) < 0x21) pos++
    return pos
  }
  function nextLine(pos) {
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a) pos++
    return pos + 1
  }
  function nextWord(pos) {
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a && loadu(pos, 1) > 0x20) pos++
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a && loadu(pos, 1) < 0x21) pos++
    return pos
  }
  function prevWord(pos) {
    if (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a) pos--
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a && loadu(pos, 1) < 0x21) pos--
    while (loadu(pos, 1) !== 0 && loadu(pos, 1) !== 0x0a && loadu(pos, 1) > 0x20) pos--
    return pos + 1
  }

  function wordLen(word) {
    let len = 0
    while (loadu(word, 1) > 0x60) {
      word++
      len++
    }
    return len
  }
  function sameWord(a, b) {
    while (loadu(a, 1) === loadu(b, 1)) {
      a++
      b++
    }
    if (loadu(a, 1) < 0x60 && loadu(b, 1) < 0x60) {
      return true
    }
    return false
  }
  function isNumber(pos) {
    if (loadu(pos, 1) === 0x2d && isNumber(pos + 1)) return true
    if (loadu(pos, 1) > 0x2f && loadu(pos, 1) < 0x3a) return true
    return false
  }

  function toLowerCase(adr) {
    let inString
    while (loadu(adr, 1)) {
      while (inString && loadu(adr, 1) === 0x5c) adr += 2
      if (loadu(adr, 1) === 0x22) inString = !inString
      if (loadu(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (loadu(adr, 1) > 0x40 && loadu(adr, 1) < 0x5b) {
          store(adr, 1, loadu(adr, 1) + 0x20)
        }
      }
      adr++
    }
  }
  function removeComments(adr) {
    let inString, erase
    while (loadu(adr, 1)) {
      while (inString && loadu(adr, 1) === 0x5c) adr += 2
      if (loadu(adr, 1) === 0x22) inString = !inString
      if (loadu(adr, 1) === 0x0a) inString = false
      if (loadu(adr, 1) === 0x0a) erase = false
      if (loadu(adr, 1) === 0x3b && !inString) erase = true
      if (erase) store(adr, 1, 0x20)
      adr++
    }
  }
  function removeOptionals(adr) {
    let inString
    while (loadu(adr, 1)) {
      while (inString && loadu(adr, 1) === 0x5c) adr += 2
      if (loadu(adr, 1) === 0x22) inString = !inString
      if (loadu(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (loadu(adr, 1) === 0x21) store(adr, 1, 0x20)
        if (loadu(adr, 1) > 0x22 && loadu(adr, 1) < 0x2d) store(adr, 1, 0x20)
        if (loadu(adr, 1) === 0x2d && loadu(adr + 1, 1) < 0x21) store(adr, 1, 0x20)
        if (loadu(adr, 1) === 0x2f) store(adr, 1, 0x20)
        if (loadu(adr, 1) > 0x39 && loadu(adr, 1) < 0x61) store(adr, 1, 0x20)
      }
      adr++
    }
  }

  function item(list, index) {
    while (index && loadu(list, 4)) {
      list += 4 + loadu(list, 4)
      index--
    }
    return list + 4
  }
  function indexOf(list, word) {
    let index = 0
    while (loadu(list, 4)) {
      list += 4
      if (sameWord(list, word))
        return index
      list += loadu(list - 4, 4)
      index++
    }
    return -1
  }
  function addTo(list, word, valcount) {
    while (loadu(list, 4)) {
      list += 4
      if (sameWord(list, word))
        return
      list += loadu(list - 4, 4)
    }
    store(list, 4, wordLen(word) + 1 + (4 * valcount))
    list += 4
    mcopy(word, list, wordLen(word))
    list += wordLen(word)
    store(list, 1, 0)
    list++
    while (valcount) {
      store(list, 4, 0)
      list += 4
      valcount--
    }
    store(list, 4, 0)
  }
  function has(list, word) {
    if (indexOf(list, word) < 0) return false
    else return true
  }
  function valueOf(list, word, index) {
    while (loadu(list, 4)) {
      list += 4
      if (sameWord(list, word)) {
        list += wordLen(word) + 1
        list += index * 4
        return loadu(list, 4)
      }
      list += loadu(list - 4, 4)
    }
    return -1
  }
  function setValueOf(list, word, index, val) {
    while (loadu(list, 4)) {
      list += 4
      if (sameWord(list, word)) {
        list += wordLen(word) + 1
        list += index * 4
        store(list, 4, val)
        return
      }
      list += loadu(list - 4, 4)
    }
  }

  function mcopy(src, dest, len) {
    if (src > dest) {
      while (len) {
        store(dest, 4, loadu(src, 4))
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
        store(dest, 4, loadu(src, 4))
        len--
      }
    }
  }
  function load(adr, len) {
    if (adr < 0) throw console.error("attempting to load adr", adr)
    len = 8 * (4 - len)
    uint8.set(mem.slice(adr, adr + 4))
    int32[0] = int32[0] << len
    int32[0] = int32[0] >> len
    return int32[0]
  }
  function loadu(adr, len) {
    if (adr < 0) throw console.error("attempting to load adr", adr)
    int32[0] = 0
    uint8.set(mem.slice(adr, adr + len))
    return int32[0]
  }
  function store(adr, len, val) {
    if (adr < 0) throw console.error("attempting to load adr", adr)
    int32[0] = val
    mem.set(uint8.slice(0, len), adr)
  }
  function vstore(adr, len, val) {
    let delta = loadu(adr, len)
    if (adr < 0) throw console.error("attempting to load adr", adr)
    int32[0] = val
    mem.set(uint8.slice(0, len), adr)
    return !!(delta - loadu(adr, len))
  }
  function strToInt(str, base, maxlen) {
    let int = 0, fact = 0, i = 0, digs = 0
    digs = 0x0004
    fact = 1
    if (loadu(str, 1) === 0x2d) {//minus
      fact = -1
      str++
      if (maxlen) maxlen--
    }
    while (maxlen && loadu(str, 1)) {
      if (base === 10) {
        if (loadu(str, 1) === 0x62) { // b
          base = 2
          str++
          if (maxlen) maxlen--
        }
        if (loadu(str, 1) === 0x6f) { // o
          base = 8
          str++
          if (maxlen) maxlen--
        }
        if (loadu(str, 1) === 0x78) { // x
          base = 16
          str++
          if (maxlen) maxlen--
        }
      }
      i = 0
      while (i < base) {
        if ((loadu(str, 1) === loadu(digs + i, 1)) |
          (loadu(str, 1) + 0x20 === loadu(digs + i, 1))) {
          int = int * base
          int += i
          i = base
        }
        i++
      }
      if (i === base) {
        return int * fact
      }
      str++
      if (maxlen) maxlen--
    }
    return int * fact
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
      store(adr, 4, word.length + 1)
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
    "ext", "fn", "vars", "data", "globals", "-", "skipby", "skipto",
    "while", "if", "else", "end", "let", "inc", "dec", "jump"
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
  loadWordList(["0123456789abcdef"], 0)
  console.log(mem)


  window.assemble = assemble
  window.opcodes = opcodes
  window.dumpBin = dumpBin
})()