;; z28r asm
jump main
ext printStr 0x5020 2
ext readLn 0x5024 2
ext openFile 0x503c 3
ext readFile 0x5040 2

data prompt_str "\nProgram: \0"
end
fn main args
  vars len
  let len = true
  while len
    let len = openFile 0x20726964 buffer 0
    readFile buffer len
    printStr buffer -1
    printStr prompt_str -1
    store buffer 0
    readLn buffer 16
    let len = openFile 0x20746567 buffer 0
    if len
      readFile buffer len
      drop run
    end
  end

  return 404
end
fn run
  -1
  return exec buffer 1 0
end

data buffer ".\0"
end
