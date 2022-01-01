(module
  (import "pcb" "ram" (memory 1))

  (global $reg0 (mut i32) (i32.const 0))
  (global $reg1 (mut i32) (i32.const 0))
  (global $reg2 (mut i32) (i32.const 0))
  (global $reg3 (mut i32) (i32.const 0))
  (global $reg4 (mut i32) (i32.const 0))
  (global $reg5 (mut i32) (i32.const 0))
  (global $reg6 (mut i32) (i32.const 0))
  (global $reg7 (mut i32) (i32.const 0))
  (global $reg8 (mut i32) (i32.const 0))
  (global $reg9 (mut i32) (i32.const 0))
  (global $reg10 (mut i32) (i32.const 0))
  (global $reg11 (mut i32) (i32.const 0))
  (global $reg12 (mut i32) (i32.const 0))
  (global $reg13 (mut i32) (i32.const 0))
  (global $reg14 (mut i32) (i32.const 0))
  (global $reg15 (mut i32) (i32.const 0))

  (func $setReg (param $reg i32) (param $val i32)
    (if (i32.eq (get_local $reg) (i32.const  0))(then (set_global $reg0  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  1))(then (set_global $reg1  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  2))(then (set_global $reg2  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  3))(then (set_global $reg3  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  4))(then (set_global $reg4  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  5))(then (set_global $reg5  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  6))(then (set_global $reg6  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  7))(then (set_global $reg7  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  8))(then (set_global $reg8  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const  9))(then (set_global $reg9  (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 10))(then (set_global $reg10 (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 11))(then (set_global $reg11 (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 12))(then (set_global $reg12 (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 13))(then (set_global $reg13 (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 14))(then (set_global $reg14 (get_local $val)) ))
    (if (i32.eq (get_local $reg) (i32.const 15))(then (set_global $reg15 (get_local $val)) ))
  )
  (export "setReg" (func $setReg))

  (func $getReg (param $reg i32) (result i32)
    (local $val i32)
    (if (i32.eq (get_local $reg) (i32.const  0))(then (set_local $val (get_global $reg0  ) )))
    (if (i32.eq (get_local $reg) (i32.const  1))(then (set_local $val (get_global $reg1  ) )))
    (if (i32.eq (get_local $reg) (i32.const  2))(then (set_local $val (get_global $reg2  ) )))
    (if (i32.eq (get_local $reg) (i32.const  3))(then (set_local $val (get_global $reg3  ) )))
    (if (i32.eq (get_local $reg) (i32.const  4))(then (set_local $val (get_global $reg4  ) )))
    (if (i32.eq (get_local $reg) (i32.const  5))(then (set_local $val (get_global $reg5  ) )))
    (if (i32.eq (get_local $reg) (i32.const  6))(then (set_local $val (get_global $reg6  ) )))
    (if (i32.eq (get_local $reg) (i32.const  7))(then (set_local $val (get_global $reg7  ) )))
    (if (i32.eq (get_local $reg) (i32.const  8))(then (set_local $val (get_global $reg8  ) )))
    (if (i32.eq (get_local $reg) (i32.const  9))(then (set_local $val (get_global $reg9  ) )))
    (if (i32.eq (get_local $reg) (i32.const 10))(then (set_local $val (get_global $reg10 ) )))
    (if (i32.eq (get_local $reg) (i32.const 11))(then (set_local $val (get_global $reg11 ) )))
    (if (i32.eq (get_local $reg) (i32.const 12))(then (set_local $val (get_global $reg12 ) )))
    (if (i32.eq (get_local $reg) (i32.const 13))(then (set_local $val (get_global $reg13 ) )))
    (if (i32.eq (get_local $reg) (i32.const 14))(then (set_local $val (get_global $reg14 ) )))
    (if (i32.eq (get_local $reg) (i32.const 15))(then (set_local $val (get_global $reg15 ) )))
    (get_local $val)
  )
  (export "getReg" (func $getReg))

  (func $run (param $count i32) (result i32)
    (local $opcode i32)
    (block(loop (br_if 1 (i32.eqz (get_local $count)))
      (set_local $count (i32.sub (get_local $count) (i32.const 1)))
      (set_local $opcode (call $step))
      (br_if 1 (i32.eqz (get_local $opcode)))
      (br_if 1 (i32.eq (get_local $opcode) (i32.const 0x0c))) ;; sleep
      (br_if 1 (i32.eq (get_local $opcode) (i32.const 0x0d))) ;; waitforuser
      (br_if 1 (i32.eq (get_local $opcode) (i32.const 0x0e))) ;; hsync
      (br_if 1 (i32.eq (get_local $opcode) (i32.const 0x0f))) ;; vsync
      (br 0)
    ))
    (get_local $opcode)
  )
  (export "run" (func $run))

  (func $step (result i32)
    (local $opcode i32)
    (local $rega i32)
    (local $regb i32)
    (local $regc i32)
    (local $data i32)

    (local $i i32)

    (set_local $opcode (i32.load8_u (i32.add (get_global $reg0) (i32.const 0))))
    (set_local $rega   (i32.load8_s (i32.add (get_global $reg0) (i32.const 1))))
    (set_local $regb   (i32.load8_u (i32.add (get_global $reg0) (i32.const 2))))
    (set_local $regc   (i32.load8_u (i32.add (get_global $reg0) (i32.const 3))))

    (set_local $data (get_local $rega))
    (set_local $data (i32.shr_s (get_local $data) (i32.const 4)))
    (set_local $data (i32.shl (get_local $data) (i32.const 8)))
    (set_local $data (i32.or (get_local $data) (get_local $regb)))
    (set_local $data (i32.shl (get_local $data) (i32.const 8)))
    (set_local $data (i32.or (get_local $data) (get_local $regc)))

    (set_local $rega (i32.and (get_local $rega) (i32.const 0xf)))
    (set_local $regb (i32.and (get_local $regb) (i32.const 0xf)))
    (set_local $regc (i32.and (get_local $regc) (i32.const 0xf)))

    ;; Flow
    (if (i32.eq (get_local $opcode) (i32.const 0x00)) (then ;; halt
      (set_global $reg0 (i32.sub (get_global $reg0) (i32.const 4)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x01)) (then ;; noop
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x02)) (then ;; goto
      (if (i32.eqz (get_local $rega)) (then
        (set_global $reg0 (i32.sub (get_local $data) (i32.const 4)))
      )(else
        (set_global $reg0 (i32.sub (call $getReg (get_local $rega)) (i32.const 4)))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x04)) (then ;; fifzero
      (if (i32.eqz (call $getReg (get_local $rega))) (then
        (set_global $reg0 (i32.add (get_global $reg0) (get_local $data)))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x05)) (then ;; rifzero
      (if (i32.eqz (call $getReg (get_local $rega))) (then
        (set_global $reg0 (i32.sub (get_global $reg0) (get_local $data)))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x08)) (then ;; pushreg
      (set_local $i (i32.const 15))
      (block(loop (br_if 1 (i32.eq (get_local $i) (get_local $rega)))
        (set_local $i (i32.sub (get_local $i) (i32.const 1)))
        (call $setReg (i32.add (get_local $i) (i32.const 1)) (get_local $i))
        (br 0)
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x09)) (then ;; popreg
      (set_local $i (get_local $rega))
      (block(loop (br_if 1 (i32.eq (get_local $i) (i32.const 15)))
        (call $setReg (get_local $i) (i32.add (get_local $i) (i32.const 1)))
        (set_local $i (i32.add (get_local $i) (i32.const 1)))
        (br 0)
      ))
      (set_global $reg15 (i32.const 0))
    ))

    ;; Memory
    (if (i32.eq (get_local $opcode) (i32.const 0x10)) (then ;; load8
      (call $setReg (get_local $rega) (i32.load8_u (get_local $data)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x11)) (then ;; load16
      (call $setReg (get_local $rega) (i32.load16_u (get_local $data)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x12)) (then ;; load32
      (call $setReg (get_local $rega) (i32.load (get_local $data)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x14)) (then ;; load
      (call $setReg (get_local $rega) (get_local $data))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x15)) (then ;; loadreg
      (call $setReg (get_local $rega) (call $getReg (get_local $regb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x18)) (then ;; store8
      (i32.store8 (get_local $data) (call $getReg (get_local $rega)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x19)) (then ;; store16
      (i32.store16 (get_local $data) (call $getReg (get_local $rega)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1a)) (then ;; store32
      (i32.store (get_local $data) (call $getReg (get_local $rega)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1c)) (then ;; copy
      (memory.copy (call $getReg (get_local $regc)) (call $getReg (get_local $rega)) (call $getReg (get_local $regb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1d)) (then ;; fill
      (memory.fill (call $getReg (get_local $regc)) (call $getReg (get_local $rega)) (call $getReg (get_local $regb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1f)) (then ;; memsize
      (call $setReg (get_local $rega) (i32.mul (i32.const 0x100) (memory.size)))
    ))

    ;; Math
    (if (i32.eq (get_local $opcode) (i32.const 0x20)) (then ;; add
      (call $setReg (get_local $rega) (i32.add (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x21)) (then ;; sub
      (call $setReg (get_local $rega) (i32.sub (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x22)) (then ;; mult
      (call $setReg (get_local $rega) (i32.mul (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x23)) (then ;; div
      (call $setReg (get_local $rega) (i32.div_s (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x24)) (then ;; rem
      (call $setReg (get_local $rega) (i32.rem_s (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))

    ;; Logic
    (if (i32.eq (get_local $opcode) (i32.const 0x30)) (then ;; eq
      (call $setReg (get_local $rega) (i32.eq (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x31)) (then ;; lt
      (call $setReg (get_local $rega) (i32.lt_s (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x32)) (then ;; gt
      (call $setReg (get_local $rega) (i32.gt_s (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x34)) (then ;; and
      (call $setReg (get_local $rega) (i32.and (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x35)) (then ;; or
      (call $setReg (get_local $rega) (i32.or (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x36)) (then ;; xor
      (call $setReg (get_local $rega) (i32.xor (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x37)) (then ;; rot
      (call $setReg (get_local $rega) (i32.rotl (call $getReg (get_local $regb)) (call $getReg (get_local $regc))))
    ))

    (set_global $reg0 (i32.add (get_global $reg0) (i32.const 4)))
    (get_local $opcode)
  )
)