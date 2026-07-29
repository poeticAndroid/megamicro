;; z28r asm
jump main
ext printChr    0x081c 1 0 ; printChr char
ext printStr    0x0820 2 0 ; printStr str max
ext strToInt    0x0828 3 1 ; strToInt:int str base max
ext intToStr    0x082c 3 0 ; intToStr int base dest
ext strLen      0x0830 2 1 ; strLen:len str max
ext memCopy     0x0834 3 0 ; memCopy src dest len
ext fill        0x0838 3 0 ; fill val dest len
ext openFile    0x083c 3 1 ; open:bytes cmd path bytes
ext readFile    0x0840 2 1 ; read:bytes dest max
ext writeFile   0x0844 2 1 ; write:bytes src len

globals srcpos litpos exepos changes state

fn main(args)
  vars len, adr
  let state = keywords
  
  if not args
    return 400
  end
  if not load8u(args)
    return 400
  end
  memCopy(args, filename, 250)
  
  let len = openFile(0x20746567, filename, 0) ; get
  if len
    let adr = item(state, 2) ; source
    store(sub(adr - 4), add(len + 1))
    store(add(adr + len), 0)
    drop readFile(adr, len)

    let len = assemble()
    let adr = filename
    while gt(load8u(adr) > 0x20)
      inc adr += 1
    end
    store(sub(adr - 4), 0x6772702e) ; .prg

    drop openFile 0x20747570 filename len ; put
    let len = writeFile item(state, 10) len
  else
    printStr(0x40000200, 256)
    printChr(0x0a)
    return 1
  end

  return 0
end
  ; 0:keywords
  ; 1:opcodes
  ; 2:source
  ; 3:global list
  ; 4:external list
  ; 5:function list
  ; 6:data list
  ; 7:const list
  ; 8:local list
  ; 9:lit lengths
  ; 10:executable


fn assemble()
  vars adr, tries, maxlit

  let adr = item(state, 2) ; source
  toLowerCase(adr)
  removeComments(adr)
  removeOptionals(adr)

  let adr = item(state, 3) ; globals
  store(sub(adr - 4), listGlobals())
  let adr = item(state, 4) ; externals
  store(sub(adr - 4), listExt())
  let adr = item(state, 5) ; functions
  store(sub(adr - 4), listFn())
  let adr = item(state, 6) ; data list
  store(sub(adr - 4), listData())
  let adr = item(state, 7) ; const list
  store(sub(adr - 4), listConst())
  let adr = item(state, 8) ; local list
  store(sub(adr - 4), listLocals())
  let adr = item(state, 9) ; lit lengths
  store(adr, 0)
  store(sub(adr - 4), 4)
  let adr = item(state, 10) ; executable
  store(sub(adr - 4), 0)

  let litpos = item(state, 9) ; lits
  let changes = 1
  let maxlit = 0
  let tries = 8
  while and(not not tries && not not changes)
    if gt(litpos > maxlit)
      let maxlit = add(litpos + 4)
      store(litpos, 0)
      let litpos = item(state, 9) ; lits
      while lt(litpos < maxlit)
        store(litpos, 0)
        inc litpos += 4
      end
      let litpos = item(state, 9) ; lits
      store(sub(litpos - 4), sub(maxlit - litpos))
    end
    let srcpos = item(state, 2) ; source
    let litpos = item(state, 9) ; lits
    let exepos = item(state, 10) ; exe
    let changes = 0
    compile()
    inc tries += -1
  end
  if not tries
    printStr(ran_out_of_patience_str, -1)
  end

  return sub(exepos - item(state, 10))
end

fn compile()
  vars kw, kwid, name, i
  let kw = item(state, 0)
  while (load8u(srcpos))
    let srcpos = skipWS(srcpos)
    let kwid = indexOf(kw, srcpos)
    if lt(kwid < 0)
      compileLine()
    end
    if eq(kwid === 0) ; ext
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let srcpos = nextWord(srcpos)
      let setValueOf(item(state, 4), name, 0, or(strToInt(srcpos, 10, -1) | 0x40000000))
      let srcpos = nextWord(srcpos)
      setValueOf(item(state, 4), name, 1, strToInt(srcpos, 10, -1))
    end
    if eq(kwid === 1) ; fn
      store(item(state, 8), 0)
      let srcpos = nextWord(srcpos)
      let name = srcpos
      setValueOf(item(state, 5), name, 0, exepos)
      let i = 0
      let srcpos = nextWord(srcpos)
      while gt(load8u(srcpos) > 0x20)
        inc i += 1
        addTo(item(state, 8), srcpos, 0)
        let srcpos = nextWord(srcpos)
      end
      setValueOf(item(state, 5), name, 1, i)
      compile()
      vstore8(exepos, 0x07) ; endcall
      exepos++
    end
    if eq(kwid === 2) ; vars
      let srcpos = nextWord(srcpos)
      while gt(load8u(srcpos) > 0x20)
        addTo(item(state, 8), srcpos, 0)
        let srcpos = nextWord(srcpos)
        vstore8(exepos, 0x40) ; null
        inc exepos += 1
      end
    end
    if eq(kwid === 3) ; data
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let srcpos = nextWord(srcpos)
      setValueOf(item(state, 6), name, 0, exepos)
      compileData()
    end
    if eq(kwid === 4) ; globals
      let srcpos = nextWord(srcpos)
      while gt(load8u(srcpos) > 0x20)
        setValueOf(item(state, 3), srcpos, 0, exepos)
        vstore(exepos, 0)
        inc exepos += 4
        let srcpos = nextWord(srcpos)
      end
    end
    if eq(kwid === 5) ; const
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let srcpos = nextWord(srcpos)
      setValueOf(item(state, 7), name, 0, strToInt(srcpos, 10, -1))
    end
    if eq(kwid === 6) ; skipby
      let srcpos = nextWord(srcpos)
      let i = strToInt(srcpos, 10, -1)
      while i
        vstore8(exepos, 0)
        inc exepos += 1
        inc i += -1
      end
    end
    if eq(kwid === 7) ; skipto
      let srcpos = nextWord(srcpos)
      let i = item(state, 10)
      inc i += strToInt(srcpos, 10, -1)
      while lt(exepos < i)
        vstore8(exepos, 0)
        inc exepos += 1
      end
    end
    if eq(kwid === 8) ; while
      let srcpos = nextWord(srcpos)
      compileWhile()
    end
    if eq(kwid === 9) ; if
      let srcpos = nextWord(srcpos)
      compileIf()
    end
    if eq(kwid === 10) ; else
      endcall
    end
    if eq(kwid === 11) ; end
      let srcpos = nextWord(srcpos)
      endcall
    end
    if eq(kwid === 12) ; let
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let srcpos = nextWord(srcpos)
      compileLine()
      let i = indexOf(item(state, 8), name)
      if gt(i > -1)
        compileLit(sub(mult(i * -1) - 1))
        vstore8(exepos, 0x19) ; set
        inc exepos += 1
      else
        if not valueOf(item(state, 3), name, 0)
          setValueOf(item(state, 3), name, 0, exepos)
        end
        compileRef(valueOf(item(state, 3), name, 0))
        vstore8(exepos, 0x1b) ; store
        inc exepos += 1
      end
    end
    if eq(kwid === 13) ; inc
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let srcpos = nextWord(srcpos)
      compileLine()
      let i = indexOf(item(state, 8), name)
      if gt(i > -1)
        compileLit(sub(mult(i * -1) - 1))
        vstore8(exepos, 0x1a) ; inc
        inc exepos += 1
      else
        if not valueOf(item(state, 3), name, 0)
          setValueOf(item(state, 3), name, 0, exepos)
        end
        compileRef(valueOf(item(state, 3), name, 0))
        vstore8(exepos, 0x13) ; load
        inc exepos += 1
        vstore8(exepos, 0x20) ; add
        inc exepos += 1
        compileRef(valueOf(item(state, 3), name, 0))
        vstore8(exepos, 0x1b) ; store
        inc exepos += 1
      end
    end
    if eq(kwid === 15) ; jump
      let srcpos = nextWord(srcpos)
      let name = srcpos
      let i = indexOf(item(state, 5), name)
      if lt(i < 0)
        compileLine()
        vstore8(exepos, 0x04) ; jump
        inc exepos += 1
      else
        if not valueOf(item(state, 5), name, 0)
          setValueOf(item(state, 5), name, 0, exepos)
        end
        compileRef(valueOf(item(state, 5), name, 0))
        vstore8(exepos, 0x04) ; jump
        inc exepos += 1
      end
    end
    let srcpos = nextLine(srcpos)
  end
end

fn compileData()
  vars kw, char
  let kw = item(state, 0)
  while load8u(srcpos)
    let srcpos = skipWS(srcpos)
    if eq(indexOf(kw, srcpos) === 11) ; end
      let srcpos = nextWord(srcpos)
      endcall
    end
    while gt(load8u(srcpos) > 0x20)
      if isNumber(srcpos)
        vstore8(exepos, strToInt(srcpos, 10, -1))
        inc exepos += 1
      end
      if eq(load8u(srcpos) === 0x22) ; "
        inc srcpos += 1
        while not eq(load8u(srcpos) == 0x22) ; "
          let char = load8u(srcpos)
          if eq(char === 0x5c) ; \
            inc srcpos += 1
            let char = load8u(srcpos)
            if and(gt(char > 0x2f) && lt(char < 0x38)) ; octal code
              let char = strToInt(srcpos, 8, 3)
              if gt(char > 0o7)
                inc srcpos += 1
              end
              if gt(char > 0o77)
                inc srcpos += 1
              end
            end
            if eq(char === 0x62)
              let char = 0x08 ; b -> backspace
            end
            if eq(char === 0x66)
              let char = 0x0c ; f -> formfeed
            end
            if eq(char === 0x6e)
              let char = 0x0a ; n -> linefeed
            end
            if eq(char === 0x72)
              let char = 0x0d ; r -> carriage return
            end
            if eq(char === 0x74)
              let char = 0x09 ; t -> tab
            end
            if eq(char === 0x78) ; x -> hex code
              inc srcpos += 1
              let char = strToInt(srcpos, 16, 2)
              inc srcpos += 1
            end
          end
          vstore8(exepos, char)
          inc exepos += 1
          inc srcpos += 1
        end
      end
      let srcpos = nextWord(srcpos)
    end
    let srcpos = nextLine(srcpos)
  end
end
fn compileWhile()
  vars cond, jumplit, loopEnd, oldlit, newlit
  let cond = exepos
  compileLine()
  let jumplit = exepos
  let oldlit = litpos
  inc exepos += getLit()
  inc litpos += 1
  vstore8(exepos, 0x05) ; jumpifz
  inc exepos += 1
  compile()
  compileRef(cond)
  vstore8(exepos, 0x04) ; jump
  inc exepos += 1
  let loopEnd = exepos
  let newlit = litpos
  let litpos = oldlit
  let exepos = jumplit
  compileRef(loopEnd)
  let litpos = newlit
  let exepos = loopEnd
end
fn compileIf()
  vars kw, newlit, newpos
  vars ifref, iflit, ifpos
  vars elsref, elslit, elspos
  let kw = item(state, 0)
  compileLine()
  let ifref = exepos
  let iflit = litpos
  inc exepos += getLit()
  inc litpos += 1
  vstore8(exepos, 0x05) ; jumpifz
  inc exepos += 1
  compile()
  if eq(indexOf(kw, srcpos) === 10) ; else
    let srcpos = nextLine(srcpos)
    let elsref = exepos
    let elslit = litpos
    inc exepos += getLit()
    inc litpos += 1
    vstore8(exepos, 0x04) ; jump
    inc exepos += 1
    let ifpos = exepos
    compile()
    let elspos = exepos
  else ; end
    let ifpos = exepos
    let elsref = ifref
    let elslit = iflit
    let elspos = ifpos
  end
  let newlit = litpos
  let newpos = exepos
  let litpos = iflit
  let exepos = ifref
  let compileRef(ifpos)
  let litpos = elslit
  let exepos = elsref
  compileRef(elspos)
  let litpos = newlit
  let exepos = newpos
end
fn compileLine()
  vars ops, vars, datas, fns, exts, globals, consts, start, words, i
  let ops = item(state, 1)
  let vars = item(state, 8)
  let datas = item(state, 6)
  let fns = item(state, 5)
  let exts = item(state, 4)
  let globals = item(state, 3)
  let consts = item(state, 7)
  let words = 0
  while gt(load8u(srcpos) > 0x20)
    let start = srcpos
    inc words += 1
    let srcpos = nextWord(srcpos)
  end
  if not start
    endcall
  end
  let srcpos = start
  while words
    let i = -1
    if isNumber(srcpos)
      compileLit(strToInt(srcpos, 10, -1))
      let i = -2
    end
    if eq(i === -1)
      let i = indexOf(ops, srcpos)
    end
    if gt(i > -1)
      vstore8(exepos, i)
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      i = indexOf(vars, srcpos)
    end
    if gt(i > -1)
      compileLit(sub(mult(i * -1) - 1))
      vstore8(exepos, 0x11) ; get
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      i = indexOf(datas, srcpos)
    end
    if gt(i > -1)
      if not valueOf(datas, srcpos, 0)
        setValueOf(datas, srcpos, 0, exepos)
      end
      compileRef(valueOf(datas, srcpos, 0))
      vstore8(exepos, 0x0d) ; absadr
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      let i = indexOf(fns, srcpos)
    end
    if gt(i > -1)
      if not valueOf(fns, srcpos, 0)
        setValueOf(fns, srcpos, 0, exepos)
      end
      compileLit(valueOf(fns, srcpos, 1))
      compileRef(valueOf(fns, srcpos, 0))
      vstore8(exepos, 0x08) ; call
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      i = indexOf(exts, srcpos)
    end
    if gt(i > -1)
      compileLit(valueOf(exts, srcpos, 1))
      compileLit(valueOf(exts, srcpos, 0))
      vstore8(exepos, 0x08) ; call
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      i = indexOf(globals, srcpos)
    end
    if gt(i > -1)
      if not valueOf(globals, srcpos, 0)
        setValueOf(globals, srcpos, 0, exepos)
      end
      compileRef(valueOf(globals, srcpos, 0))
      vstore8(exepos, 0x13) ; load
      inc exepos += 1
      let i = -2
    end
    if eq(i === -1)
      i = indexOf(consts, srcpos)
    end
    if gt(i > -1)
      compileLit(valueOf(consts, srcpos, 0))
      let i = -2
    end
    if eq(i === -1)
      error(unknown_word_str)
    end
    let srcpos = prevWord(srcpos)
    inc words += -1
  end
  let srcpos = nextWord(start)
end
fn compileRef(adr)
  vars i
  let i = add(exepos + add(getLit() + 1))
  compileLit(sub(adr - i))
end
fn compileLit(val)
  vars neg, abs, lownib, size
  let neg = not not and(val & 0x80000000)
  let abs = not not and(val & 0x40000000)
  if neg
    let abs = not abs
  end
  let lownib = and(val & 0xf)
  let size = 1
  if abs
    let val = xor(val ^ 0x40000000)
  end
  if neg
    let val = xor(val ^ -1)
  end
  if gt(val > 0xf)
    let size = 2
  end
  if gt(val > 0xfff)
    let size = 3
  end
  if gt(val > 0xfffff)
    let size = 5
  end
  if neg
    let val = xor(val ^ -1)
  end
  if abs
    let val = xor(val ^ 0x40000000)
  end
  if gt(getLit() > size)
    let size = getLit()
  end
  store8(litpos, size)
  inc litpos += 1
  if lt(size < 4)
    let val = rot(val << 4)
    let val = and(val & 0xffffff00)
    inc val += mult(size * 0x40)
    inc val += mult(neg * 0x20)
    inc val += mult(abs * 0x10)
    inc val += lownib
    while size
      vstore8(exepos, val)
      let val = rot(val >> -8)
      inc exepos += 1
      inc size += -1
    end
  else
    vstore8(exepos, 0x10)
    inc exepos += 1
    vstore(exepos, val)
    inc exepos += 4
  end
end
fn getLit()
  vars size
  let size = load8u(litpos)
  if gt(size > 3)
    size = 5
  end
  return size
end
fn listGlobals()
  vars kw, src, globlist, globlistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let globlist = item(state, 3) ; global list
  let globlistPos = globlist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 4) ; globals
      let pos = nextWord(pos)
      while gt(load8u(pos) > 0x20)
        store(globlistPos, add(wordLen(pos) + 5))
        inc globlistPos += 4
        memCopy(pos, globlistPos, wordLen(pos))
        inc globlistPos += wordLen(pos)
        store8(globlistPos, 0)
        inc globlistPos += 1
        store(globlistPos, 0)
        inc globlistPos += 4
        let pos = nextWord(pos)
      end
    end
    let pos = nextLine(pos)
  end
  store(globlistPos, 0)
  inc globlistPos += 4
  return sub(globlistPos - globlist)
end
fn listExt()
  vars kw, src, extlist, extlistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let extlist = item(state, 4) ; external list
  let extlistPos = extlist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 0) ; ext
      let pos = nextWord(pos)
      store(extlistPos, add(wordLen(pos) + 9))
      inc extlistPos += 4
      memCopy(pos, extlistPos, wordLen(pos))
      inc extlistPos += wordLen(pos)
      store8(extlistPos, 0)
      inc extlistPos += 1
      store(extlistPos, 0)
      inc extlistPos += 4
      store(extlistPos, 0)
      inc extlistPos += 4
    end
    let pos = nextLine(pos)
  end
  store(extlistPos, 0)
  inc extlistPos += 4
  return sub(extlistPos - extlist)
end
fn listFn()
  vars kw, src, fnlist, fnlistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let fnlist = item(state, 5) ; function list
  let fnlistPos = fnlist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 1) ; fn
      let pos = nextWord(pos)
      store(fnlistPos, add(wordLen(pos) + 9))
      inc fnlistPos += 4
      memCopy(pos, fnlistPos, wordLen(pos))
      inc fnlistPos += wordLen(pos)
      store8(fnlistPos, 0)
      inc fnlistPos += 1
      store(fnlistPos, 0)
      inc fnlistPos += 4
      store(fnlistPos, 0)
      inc fnlistPos += 4
    end
    let pos = nextLine(pos)
  end
  store(fnlistPos, 0)
  inc fnlistPos += 4
  return sub(fnlistPos - fnlist)
end
fn listData()
  vars kw, src, datalist, datalistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let datalist = item(state, 6) ; data list
  let datalistPos = datalist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 3) ; data
      let pos = nextWord(pos)
      store(datalistPos, add(wordLen(pos) + 5))
      inc datalistPos += 4
      memCopy(pos, datalistPos, wordLen(pos))
      inc datalistPos += wordLen(pos)
      store8(datalistPos, 0)
      inc datalistPos += 1
      store(datalistPos, 0)
      inc datalistPos += 4
    end
    let pos = nextLine(pos)
  end
  store(datalistPos, 0)
  inc datalistPos += 4
  return sub(datalistPos - datalist)
end
fn listConst()
  vars kw, src, constlist, constlistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let constlist = item(state, 7) ; const list
  let constlistPos = constlist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 5) ; const
      let pos = nextWord(pos)
      store(constlistPos, add(wordLen(pos) + 5))
      inc constlistPos += 4
      memCopy(pos, constlistPos, wordLen(pos))
      inc constlistPos += wordLen(pos)
      store8(constlistPos, 0)
      inc constlistPos += 1
      store(constlistPos, 0)
      inc constlistPos += 4
    end
    let pos = nextLine(pos)
  end
  store(constlistPos, 0)
  inc constlistPos += 4
  return sub(constlistPos - constlist)
end
fn listLocals()
  vars kw, src, varlist, varlistPos, pos, maxpos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let varlist = item(state, 8) ; local list
  let varlistPos = varlist
  let maxpos = 0
  while load8u(pos)
    let pos = skipWS(pos)
    if lt(indexOf(kw, pos) < 3) ; ext fn vars
      if eq(indexOf(kw, pos) === 1) ; fn
        if gt(varlistPos > maxpos)
          let maxpos = varlistPos
        end
        let varlistPos = varlist
      end
      let pos = nextWord(pos)
      while gt(load8u(pos) > 0x20)
        store(varlistPos, add(wordLen(pos) + 1))
        inc varlistPos += 4
        memCopy(pos, varlistPos, wordLen(pos))
        inc varlistPos += wordLen(pos)
        store8(varlistPos, 0)
        inc varlistPos += 1
        let pos = nextWord(pos)
      end
    end
    let pos = nextLine(pos)
  end
  store(varlistPos, 0)
  if gt(varlistPos > maxpos)
    let maxpos = varlistPos
  end
  inc maxpos += 4
  return sub(maxpos - varlist)
end
fn listLits()
  vars kw, src, litlist, litlistPos, pos
  let kw = item(state, 0)
  let src = item(state, 2)
  let pos = src
  let litlist = item(state, 9) ; lit list
  let litlistPos = litlist
  while load8u(pos)
    let pos = skipWS(pos)
    if eq(indexOf(kw, pos) === 2) ; vars
      while gt(load8u(pos) > 0x20)
        store8(litlistPos, 1)
        inc litlistPos += 1
        let pos = nextWord(pos)
      end
    end
    if eq(indexOf(kw, pos) === 8) ; while
      store8(litlistPos, 1)
      inc litlistPos += 1
      store8(litlistPos, 1)
      inc litlistPos += 1
    end
    if eq(indexOf(kw, pos) === 9) ; if
      store8(litlistPos, 1)
      inc litlistPos += 1
      store8(litlistPos, 1)
      inc litlistPos += 1
    end
    while gt(load8u(pos) > 0x20)
      if isNumber(pos)
        store8(litlistPos, 1)
        inc litlistPos += 1
      end
      let pos = nextWord(pos)
    end
    let pos = nextLine(pos)
  end
  return sub(litlistPos - litlist)
end
fn skipWS(pos)
  while and(gt(load8u(pos) > 0) && lt(load8u(pos) < 0x21))
    inc pos += 1
  end
  return pos
end
fn nextLine(pos)
  while and(gt(load8u(pos) > 0) && not eq(load8u(pos) == 0x0a))
    inc pos += 1
  end
  if gt(load8u(pos) > 0)
    inc pos += 1
  end
  return pos
end
fn nextWord(pos)
  while gt(load8u(pos) > 0x20)
    pos += 1
  end
  while and(and(gt(load8u(pos) > 0) && lt(load8u(pos) < 0x21)) && not eq(load8u(pos) == 0x0a))
    pos += 1
  end
  return pos
end
fn prevWord(pos)
  if and(gt(load8u(pos) > 0) && not eq(load8u(pos) == 0x0a))
    inc pos += -1
  end
  while and(and(gt(load8u(pos) > 0) && lt(load8u(pos) < 0x21)) && not eq(load8u(pos) == 0x0a))
    inc pos += -1
  end
  while gt(load8u(pos) > 0x20)
    inc pos += -1
  end
  if and(and(gt(load8u(pos) > 0) && lt(load8u(pos) < 0x21)) && not eq(load8u(pos) == 0x0a))
    inc pos += 1
  end
  return pos
end
fn wordLen(word)
  vars len
  while gt(load8u(word) > 0x20)
    inc word += 1
    inc len += 1
  end
  return len
end
fn sameWord(a, b)
  while eq(load8u(a) === load8u(b))
    inc a += 1
    inc b += 1
    if and(lt(load8u(a) < 0x21) && lt(load8u(b) < 0x21))
      return true
    end
  end
  return null
end
fn isNumber(pos)
  if and(eq(load8u(pos) === 0x2d) && isNumber(add(pos + 1))) ; -#
    return true
  end
  if and(gt(load8u(pos) > 0x2f) && lt(load8u(pos) < 0x3a)) ; 0123456789
    return true
  end
  return null
end
fn toLowerCase(adr)
  vars inString
  while load8u(adr)
    while and(inString && load8u(adr) === 0x5c) ; \
      inc adr += 2
    end
    if eq(load8u(adr) === 0x22)
      let inString = not inString
    end
    if eq(load8u(adr) === 0x0a)
      let inString = null
    end
    if not inString
      if and(gt(load8u(adr) > 0x40) && lt(load8u(adr) < 0x5b))
        store8(adr, add(load8u(adr) + 0x20))
      end
    end
    inc adr += 1
  end
end
fn removeComments(adr)
  vars inString, erase
  while load8u(adr)
    while and(inString && eq(load8u(adr) === 0x5c)) ; \
      inc adr += 2
    end
    if eq(load8u(adr) === 0x22) ; "
      let inString = not inString
    end
    if eq(load8u(adr) === 0x0a) ; \n
      let inString = null
      let erase = null
    end
    if and(eq(load8u(adr) === 0x3b) && not inString) ; ;
      let erase = true
    end
    if erase
      store8(adr, 0x20)
    end
    inc adr += 1
  end
end
fn removeOptionals(adr)
  vars inString
  while load8u(adr)
    while and(inString && eq(load8u(adr) === 0x5c)) ; \
      inc adr += 2
    end
    if eq(load8u(adr) === 0x22) ; "
      let inString = not inString
    end
    if eq(load8u(adr) === 0x0a) ; \n
      let inString = null
    end
    if not inString
      if eq(load8u(adr) === 0x21) ; !
        store8(adr, 0x20)
      end
      if and(gt(load8u(adr) > 0x22) && lt(load8u(adr) < 0x2d)) ; #$%&'()*+,
        store8(adr, 0x20)
      end
      if and(eq(load8u(adr) === 0x2d) && lt(load8u(adr + 1) < 0x21)) ; "- "
        store8(adr, 0x20)
      end
      if and(eq(load8u(adr) === 0x2e) && lt(load8u(adr + 1) < 0x21)) ; ". "
        store8(adr, 0x20)
      end
      if eq(load8u(adr) === 0x2f) ; /
        store8(adr, 0x20)
      end
      if and(gt(load8u(adr) > 0x39) && lt(load8u(adr) < 0x5f)) ; :;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^
        store8(adr, 0x20)
      end
      if gt(load8u(adr) > 0x7a) ; > {|}~
        store8(adr, 0x20)
      end
    end
    inc adr += 1
  end
end

fn item(list, index)
  while and(not not index & not not load(list))
    inc list += add(4 + load(list))
    inc index += -1
  end
  return add(list + 4)
end
fn indexOf(list, word)
  vars index
  while load(list)
    inc list += 4
    if sameWord(list, word)
      return index
    end
    inc list += load(sub(list - 4))
    inc index += 1
  end
  return -1
end
fn addTo(list, word, valcount)
  while load(list)
    inc list += 4
    if sameWord(list, word)
      endcall
    end
    list += load(sub(list - 4))
  end
  store(list, add(wordLen(word) + add(1 + mult(4 * valcount))))
  inc list += 4
  memCopy(word, list, wordLen(word))
  inc list += wordLen(word)
  store8(list, 0)
  inc list += 1
  while valcount
    store(list, 0)
    inc list += 4
    inc valcount += -1
  end
  store(list, 0)
end
fn valueOf(list, word, index)
  while load(list)
    inc list += 4
    if sameWord(list, word)
      inc list += add(wordLen(word) + 1)
      inc list += mult(index * 4)
      return load(list)
    end
    list += load(sub(list - 4))
  end
  return -1
end
fn setValueOf(list, word, index, val)
  while load(list)
    inc list += 4
    if sameWord(list, word)
      inc list += add(wordLen(word) + 1)
      inc list += mult(index * 4)
      store(list, val)
      endcall
    end
    inc list += load(sub(list - 4))
  end
end


fn error(msg)
  vars s, line, col
  printStr(msg, -1)
  let s = item(state, 2)
  let line = 1
  while lt(s < srcpos)
    col++
    if eq(load8u(s) === 0x0a)
      inc line += 1
      let col = 0
    end
    inc s += 1
  end
  printStr(on_line_str, -1)
  intToStr(line, 10, mem)
  printStr(mem, -1)
  printStr(column_str, -1)
  intToStr(col, 10, mem)
  printStr(mem, -1)
  printChr(0x21) ; !
  printChr(0x0a) ; \n
end


fn vstore(adr, val)
  if not eq(val == load(adr))
    inc changes += 1
    store(adr, val)
  end
end
fn vstore8(adr, val)
  if not eq(and(val & 0xff) == load8u(adr))
    inc changes += 1
    store8(adr, val)
  end
end






data mem
end

data filename ".\0"
end
skipby 255

data ran_out_of_patience_str "ran out of patience!\n\0"
end

data on_line_str " on line \0"
end

data column_str " column \0"
end

data unknown_word_str "unknown word\0"
end

data keywords 146 0 0 0
  4 0 0 0  "ext\0"    3 0 0 0  "fn\0"       5 0 0 0  "vars\0"
  5 0 0 0  "data\0"   8 0 0 0  "globals\0"  6 0 0 0  "const\0"
  7 0 0 0  "skipby\0" 7 0 0 0  "skipto\0"
  6 0 0 0  "while\0"  3 0 0 0  "if\0"       5 0 0 0  "else\0"
  4 0 0 0  "end\0"    4 0 0 0  "let\0"      4 0 0 0  "inc\0"
  2 0 0 0  "-\0"      5 0 0 0  "jump\0"
  0 0 0 0
end

data opcodes 92 2 0 0
  5 0 0 0  "halt\0"  6 0 0 0  "sleep\0"   6 0 0 0  "vsync\0"
  2 0 0 0  "-\0"     5 0 0 0  "jump\0"    8 0 0 0  "jumpifz\0"
  2 0 0 0  "-\0"          8 0 0 0  "endcall\0"
  5 0 0 0  "call\0"  7 0 0 0  "return\0"  5 0 0 0  "exec\0"
  6 0 0 0  "break\0" 6 0 0 0  "reset\0"   7 0 0 0  "absadr\0"
  7 0 0 0  "cpuver\0"     5 0 0 0  "noop\0"
  4 0 0 0  "lit\0"   4 0 0 0  "get\0"     9 0 0 0  "stackptr\0"
  5 0 0 0  "load\0"  7 0 0 0  "load8u\0"  8 0 0 0  "setread\0"
  9 0 0 0  "skipread\0"   5 0 0 0  "read\0"
  5 0 0 0  "drop\0"  4 0 0 0  "set\0"     4 0 0 0  "inc\0"
  6 0 0 0  "store\0" 7 0 0 0  "store8\0"  9 0 0 0  "setwrite\0"
 10 0 0 0  "skipwrite\0"  6 0 0 0  "write\0"
  4 0 0 0  "add\0"   4 0 0 0  "sub\0"     5 0 0 0  "mult\0"
  4 0 0 0  "div\0"   4 0 0 0  "rem\0"     7 0 0 0  "load8s\0"
  8 0 0 0  "load16s\0"    5 0 0 0  "itof\0"
  5 0 0 0  "fadd\0"  5 0 0 0  "fsub\0"    6 0 0 0  "fmult\0"
  5 0 0 0  "fdiv\0"  7 0 0 0  "ffloor\0"  2 0 0 0  "-\0"
  8 0 0 0  "store16\0"    5 0 0 0  "ftoi\0"
  3 0 0 0  "eq\0"    3 0 0 0  "lt\0"      3 0 0 0  "gt\0"
  4 0 0 0  "not\0"   4 0 0 0  "and\0"     3 0 0 0  "or\0"
  4 0 0 0  "xor\0"        4 0 0 0  "rot\0"
  4 0 0 0  "feq\0"   4 0 0 0  "flt\0"     4 0 0 0  "fgt\0"
  2 0 0 0  "-\0"     2 0 0 0  "-\0"       2 0 0 0  "-\0"
  2 0 0 0  "-\0"          2 0 0 0  "-\0"
  5 0 0 0  "null\0"  5 0 0 0  "true\0"
  0 0 0 0
end
