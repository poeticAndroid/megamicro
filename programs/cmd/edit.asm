;; z28r asm
jump main
ext cls       0x0808 0
ext printChr  0x081c 1
ext printStr  0x0820 2
ext readLn    0x0824 2
ext strLen    0x0830 2
ext openFile  0x083c 3
ext readFile  0x0840 2
ext writeFile 0x0844 2
ext memCopy   0x0834 3

fn main args
  vars len
  
  if not args
    printStr help_str -1
    return 1
  end
  if not load8u args
    printStr help_str -1
    return 1
  end
  
  let len = openFile 0x20746567 args 0 ; get
  if len
    readFile buffer len
    store add len + absadr buffer 0
  end
  if edit buffer
    let len = strLen buffer -1
    while not load8u input_str
      printStr save_str -1
      readLn input_str 4
    end
    if eq load8u input_str == 0x79
      drop openFile 0x20747570 args len ; put
      let len = writeFile buffer len
      printStr 0x40000200 256
      printChr 0x0a
      printStr saved_str -1
    else
      printStr not_saved_str -1
    end
  end

  return 0
end

fn edit dest
  vars start end done col dirty
  let start = dest
  let end = dest
  while load8u end
    inc end += 1
  end
  inc end += 1
  let dest = goto_bottom dest
  while not done
    if gt dest > end
      let dest = end
      while not load8u dest
        inc dest += -1
      end
      while load8u dest
        inc dest += 1
      end
    end
    if lt dest < start
      let dest = start
    end
    
    cursor dest
    store8 0x400003ff xor -1 load8u 0x400003ff
    store8 0x400003fe xor -1 load8u 0x400003fe
    cursor dest
    store8 0x400003ff xor -1 load8u 0x400003ff
    store8 0x400003fe xor -1 load8u 0x400003fe    
    while not load 0x40000304
      vsync
    end
    cursor dest
    
    if eq load8u 0x40000306 == 0x23 ; End
      while gt load8u dest > 0x1f
        printChrOvr load8u dest
        inc dest += 1
      end
    end
    if eq load8u 0x40000306 == 0x24 ; Home
      if gt load8u dest > 0x20
        while gt load8u dest > 0x1f
          printChr 0x08
          inc dest += -1
        end
      else
        printChr 0x08
        inc dest += -1
        while lt load8u dest < 0x21
          printChrOvr load8u dest
          inc dest += 1
        end
      end
      while lt load8u dest < 0x20
        printChr 0x20
        inc dest += 1
      end
    end
    if eq load8u 0x40000306 == 0x25 ; Left
      if gt dest > start
        printChr 0x08
        inc dest += -1
        if eq load8u dest == 0x0a
          reline dest
        end
      end
    end
    if eq load8u 0x40000306 == 0x26 ; Up
      let col = load8s 0x400003fc
      let done = load8u 0x40000002
      while done
        if gt dest > start
          printChr 0x08
          inc dest += -1
          if eq load8u dest == 0x0a
            reline dest
          end
          if eq col == load8s 0x400003fc
            let done = true
          end
        end
        inc done += -1
      end
    end
    if eq load8u 0x40000306 == 0x27 ; Right
      if load8u dest
        printChrOvr load8u dest
        inc dest += 1
      end
    end
    if eq load8u 0x40000306 == 0x28 ; Down
      let col = load8s 0x400003fc
      let done = load8u 0x40000002
      while done
        if load8u dest
          printChrOvr load8u dest
          inc dest += 1
        end
        if eq col == load8s 0x400003fc
          let done = true
        end
        inc done += -1
      end
    end
    if eq load8u 0x40000305 == 0x08 ; Backspace
      if gt dest > start
        inc dest += -1
        ; if eq load8u dest == 0x0a
        ;   cls
        ; end
        reline dest
        memCopy add dest + 1 dest sub end - dest
        inc end += -1
        endline dest
        let dirty = true
      end
    end
    if eq load8u 0x40000305 == 0x0a ; Enter
      if not load8u dest
        store dest 0
      end
      memCopy dest add dest + 1 sub end - dest
      store8 dest load8u 0x40000305
      ; cls
      ;reline dest
      endline dest
      printChrOvr load8u dest
      inc dest += 1
      inc end += 1
      store end 0
      endline dest
      let dirty = true
    end
    if eq load8u 0x40000305 == 0x1b ; Esc
      let done = true
    end
    if gt load8u 0x40000305 > 0x1f ; any printable
      if not load8u dest
        store dest 0
      end
      memCopy dest add dest + 1 sub end - dest
      store8 dest load8u 0x40000305
      printChrOvr load8u dest
      inc dest += 1
      inc end += 1
      store end 0
      endline dest
      let dirty = true
    end
    store 0x40000304 0
  end
  let dest = goto_bottom dest
  printChr 0x0a
  printChr 0x0a
  return dirty
end

fn cursor dest
  if gt load8u dest > 0x20
    printChrOvr load8u dest
  else
    printChr 0x20
  end
  printChr 0x08
end

fn printChrOvr char
  if eq char == 0x0a
    if eq load8s 0x400003fc == load8s 0x40000002
      printChr 0x0a
    end
    while lt load8s 0x400003fc < load8s 0x40000002
      printChr 0x20
    end
  end
  printChr char
end

fn reline end
  vars dest
  let dest = end
  inc dest += -1
  while gt load8u dest > 0x1f
    printChr 0x08
    inc dest += -1
  end
  store8 0x400003fc 0
  inc dest += 1
  while lt dest < end
    printChrOvr load8u dest
    inc dest += 1
  end
end

fn endline start
  vars dest
  
  if lt load8s 0x400003fd < sub load8s 0x40000003 - 3
    store8 0x400003fd sub load8s 0x400003fd - sub load8s 0x40000003 - 1
    printChr 0x20
    printChr 0x08
    store8 0x400003fd add load8s 0x400003fd + sub load8s 0x40000003 - 1
    reline start
  end
  
  let dest = start
  while gt load8u dest > 0x1f
    printChr load8u dest
    inc dest += 1
  end
  while lt load8s 0x400003fc < load8s 0x40000002
    printChr 0x20
    inc dest += 1
  end
  while gt dest > start
    printChr 0x08
    inc dest += -1
  end
end

fn goto_bottom dest
  while load8u dest
    printChrOvr load8u dest
    inc dest += 1
    if eq load8u 0x400003fd == sub load8u 0x40000003 - 1
      while gt load8u dest > 0x1f
        printChr load8u dest
        inc dest += 1
      end
      return dest
    end
  end
  return dest
end

data help_str
  "Usage:\n"
  "  edit [filename]\n"
  0
end

data save_str
  "Save changes? [y/n]: "
  0
end

data input_str
  "\0\0\0\0"
  0
end

data saved_str
  "Saved!\x9b\n"
  0
end

data not_saved_str
  "Not saved..\x9a\n"
  0
end

data buffer
  0
end
