(module
  (import "pcb" "ram" (memory 1))

  (global $pc (mut i32) (i32.const 0x400)) ;; program counter
  (global $cs (mut i32) (i32.const 0x0)) ;; call stack counter
  (global $vs (mut i32) (i32.const 0x0)) ;; value stack counter

  (func $getPC (result i32) (get_global $pc) )
  (export "getPC" (func $getPC))
  (func $setPC (param $val i32) (set_global $pc (get_local $val)) )
  (export "setPC" (func $setPC))

  (func $getCS (result i32) (get_global $cs) )
  (export "getCS" (func $getCS))
  (func $setCS (param $val i32) (set_global $cs (get_local $val)) )
  (export "setCS" (func $setCS))

  (func $getVS (result i32) (get_global $vs) )
  (export "getVS" (func $getVS))
  (func $setVS (param $val i32) (set_global $vs (get_local $val)) )
  (export "setVS" (func $setVS))

  (func $push (param $val i32)
    (i32.store (get_global $vs) (get_local $val))
    (set_global $vs (i32.add (get_global $vs) (i32.const 4)))
  )
  (func $pop (result i32)
    (if (i32.le_s (get_global $vs) (get_global $cs)) (then
      (set_global $vs (get_global $cs))
      (call $push (i32.const 0))
    ))
    (set_global $vs (i32.sub (get_global $vs) (i32.const 4)))
    (i32.load (get_global $vs))
  )
  (func $fpush (param $val f32)
    (f32.store (get_global $vs) (get_local $val))
    (set_global $vs (i32.add (get_global $vs) (i32.const 4)))
  )
  (func $fpop (result f32)
    (if (i32.le_s (get_global $vs) (get_global $cs)) (then
      (set_global $vs (get_global $cs))
      (call $fpush (f32.const 0))
    ))
    (set_global $vs (i32.sub (get_global $vs) (i32.const 4)))
    (f32.load (get_global $vs))
  )
  (func $call (param $offset i32) (param $params i32)
    (call $sys (i32.add (get_global $pc) (get_local $offset)) (get_local $params))
  )
  (func $sys (param $adr i32) (param $params i32)
    (local $paramstart i32)
    (local $paramend i32)
    (set_local $paramstart (i32.add (get_global $vs) (i32.const 8)))
    (set_local $paramend (get_local $paramstart))
    (block(loop (br_if 1 (i32.eqz (get_local $params)))
      (if (i32.ge_s (get_local $paramstart) (i32.const 4)) (then
        (set_local $paramstart (i32.sub (get_local $paramstart) (i32.const 4)))
      ))
      (i32.store (get_local $paramstart) (call $pop))
      (set_local $params (i32.sub (get_local $params) (i32.const 1)))
      (br 0)
    ))

    (call $push (get_global $pc))
    (call $push (get_global $cs))
    (set_global $cs (get_global $vs))
    (set_global $pc (get_local $adr))
    (set_global $vs (get_local $paramend))
  )
  (func $return (param $results i32)
    (local $resultstart i32)
    (set_local $resultstart (i32.sub (get_global $vs) (i32.mul (get_local $results) (i32.const 4))))
    (if (i32.lt_s (get_global $vs) (i32.const 0)) (then
      (set_local $resultstart (i32.const 0))
    ))
    (set_global $vs (get_global $cs))
    (set_global $cs (call $pop))
    (set_global $pc (call $pop))
    (block(loop (br_if 1 (i32.eqz (get_local $results)))
      (call $push (i32.load (get_local $resultstart)))
      (set_local $resultstart (i32.add (get_local $resultstart) (i32.const 4)))
      (set_local $results (i32.sub (get_local $results) (i32.const 1)))
      (br 0)
    ))
  )

  (func $run (param $count i32) (result i32)
    (local $opcode i32)
    (block(loop (br_if 1 (i32.eqz (get_local $count)))
      (set_local $count (i32.sub (get_local $count) (i32.const 1)))
      (set_local $opcode (call $step))
      (br_if 1 (i32.lt_u (get_local $opcode) (i32.const 0x04))) 
      (br 0)
    ))
    (get_local $opcode)
  )
  (export "run" (func $run))

  (func $step (result i32)
    (local $opcode i32)
    (local $a i32)
    (local $b i32)
    (local $c i32)
    (local $d i32)
    (local $fa f32)
    (local $fb f32)

    (set_local $opcode (i32.load8_u (get_global $pc)))

    ;; Flow
    (if (i32.eq (get_local $opcode) (i32.const 0x00)) (then ;; halt
      (set_global $pc (i32.sub (get_global $pc) (i32.const 1)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x01)) (then ;; sleep
      (drop (call $pop))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x04)) (then ;; jump
      (set_global $pc (i32.add (get_global $pc) (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x05)) (then ;; jumpifz
      (set_local $b (call $pop)) ;; offset
      (set_local $a (call $pop)) ;; val
      (if (i32.eqz (get_local $a)) (then
        (set_global $pc (i32.add (get_global $pc) (get_local $b)))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x08)) (then ;; call
      (set_local $b (call $pop)) ;; params
      (set_local $a (call $pop)) ;; offset
      (call $call (get_local $a) (get_local $b))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x09)) (then ;; sys
      (set_local $b (call $pop)) ;; params
      (set_local $a (call $pop)) ;; adr
      (call $sys (get_local $a) (get_local $b))
      (set_global $pc (i32.sub (get_global $pc) (i32.const 1)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x0b)) (then ;; return
      (call $return (call $pop))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x0c)) (then ;; reset
      (set_global $cs (i32.const 0))
      (set_global $vs (i32.const 0))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x0d)) (then ;; here
      (call $push (get_global $pc))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x0e)) (then ;; goto
      (set_global $pc (i32.sub (call $pop) (i32.const 1)))
    ))

    ;; Memory
    (if (i32.eq (get_local $opcode) (i32.const 0x10)) (then ;; const
      (call $push (i32.load (i32.add (get_global $pc) (i32.const 1))))
      (set_global $pc (i32.add (get_global $pc) (i32.const 4)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x11)) (then ;; get
      (set_local $a (call $pop)) ;; index
      (if (i32.lt_s (get_local $a) (i32.const 0)) (then
        (call $push (i32.load (i32.add (get_global $vs) (i32.mul (get_local $a) (i32.const 4)))))
      )(else
        (call $push (i32.load (i32.add (get_global $cs) (i32.mul (get_local $a) (i32.const 4)))))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x13)) (then ;; load
      (call $push (i32.load (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x14)) (then ;; load16u
      (call $push (i32.load16_u (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x15)) (then ;; load8u
      (call $push (i32.load8_u (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x16)) (then ;; load16s
      (call $push (i32.load16_s (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x17)) (then ;; load8s
      (call $push (i32.load8_s (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x18)) (then ;; drop
      (drop (call $pop))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x19)) (then ;; set
      (set_local $b (call $pop)) ;; val
      (set_local $a (call $pop)) ;; index
      (if (i32.lt_s (get_local $a) (i32.const 0)) (then
        (i32.store (i32.add (get_global $vs) (i32.mul (get_local $a) (i32.const 4))) (get_local $b))
      )(else
        (i32.store (i32.add (get_global $cs) (i32.mul (get_local $a) (i32.const 4))) (get_local $b))
      ))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1b)) (then ;; store
      (set_local $b (call $pop)) ;; val
      (set_local $a (call $pop)) ;; adr
      (i32.store (get_local $a) (get_local $b))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1c)) (then ;; store16
      (set_local $b (call $pop)) ;; val
      (set_local $a (call $pop)) ;; adr
      (i32.store16 (get_local $a) (get_local $b))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1d)) (then ;; store8
      (set_local $b (call $pop)) ;; val
      (set_local $a (call $pop)) ;; adr
      (i32.store8 (get_local $a) (get_local $b))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1e)) (then ;; stacksize
      (call $push (get_global $vs))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x1f)) (then ;; memsize
      (call $push (i32.mul (i32.const 0x10000) (memory.size)))
    ))

    ;; Math
    (if (i32.eq (get_local $opcode) (i32.const 0x20)) (then ;; add
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.add (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x21)) (then ;; sub
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.sub (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x22)) (then ;; mult
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.mul (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x23)) (then ;; div
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.div_s (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x24)) (then ;; rem
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.rem_s (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x27)) (then ;; ftoi
      (call $push (i32.trunc_f32_s (call $fpop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x28)) (then ;; fadd
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $fpush (f32.add (get_local $fa) (get_local $fb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x29)) (then ;; fsub
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $fpush (f32.sub (get_local $fa) (get_local $fb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x2a)) (then ;; fmult
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $fpush (f32.mul (get_local $fa) (get_local $fb)))
    )) 
    (if (i32.eq (get_local $opcode) (i32.const 0x2b)) (then ;; fdiv
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $fpush (f32.div (get_local $fa) (get_local $fb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x2e)) (then ;; uitof
      (call $fpush (f32.convert_i32_u (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x2f)) (then ;; sitof
      (call $fpush (f32.convert_i32_s (call $pop)))
    ))

    ;; Logic
    (if (i32.eq (get_local $opcode) (i32.const 0x30)) (then ;; eq
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.eq (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x31)) (then ;; lt
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.lt_s (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x32)) (then ;; gt
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.gt_s (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x33)) (then ;; eqz
      (call $push (i32.eqz (call $pop)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x34)) (then ;; and
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.and (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x35)) (then ;; or
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.or (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x36)) (then ;; xor
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.xor (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x37)) (then ;; rot
      (set_local $b (call $pop)) ;; b
      (set_local $a (call $pop)) ;; a
      (call $push (i32.rotr (get_local $a) (get_local $b)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x38)) (then ;; feq
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $push (f32.eq (get_local $fa) (get_local $fb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x39)) (then ;; flt
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $push (f32.lt (get_local $fa) (get_local $fb)))
    ))
    (if (i32.eq (get_local $opcode) (i32.const 0x3a)) (then ;; fgt
      (set_local $fb (call $fpop)) ;; b
      (set_local $fa (call $fpop)) ;; a
      (call $push (f32.gt (get_local $fa) (get_local $fb)))
    ))

    (set_global $pc (i32.add (get_global $pc) (i32.const 1)))
    (get_local $opcode)
  )
)