(module
  (import "pcb" "ram" (memory 1))

  (global $pc (mut i32) (i32.const 0x400)) ;; program counter
  (global $cs (mut i32) (i32.const 0x0)) ;; call stack counter
  (global $vs (mut i32) (i32.const 0x0)) ;; value stack counter

  (func $getPC (result i32) (global.get $pc) )
  (export "getPC" (func $getPC))
  (func $setPC (param $val i32) (global.set $pc (local.get $val)) )
  (export "setPC" (func $setPC))

  (func $getCS (result i32) (global.get $cs) )
  (export "getCS" (func $getCS))
  (func $setCS (param $val i32) (global.set $cs (local.get $val)) )
  (export "setCS" (func $setCS))

  (func $getVS (result i32) (global.get $vs) )
  (export "getVS" (func $getVS))
  (func $setVS (param $val i32) (global.set $vs (local.get $val)) )
  (export "setVS" (func $setVS))

  (func $push (param $val i32)
    (i32.store (global.get $vs) (local.get $val))
    (global.set $vs (i32.add (global.get $vs) (i32.const 4)))
  )
  (func $pop (result i32)
    (if (i32.le_s (global.get $vs) (global.get $cs)) (then
      (global.set $vs (global.get $cs))
      (call $push (i32.const 0))
    ))
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4)))
    (i32.load (global.get $vs))
  )
  (func $fpush (param $val f32)
    (f32.store (global.get $vs) (local.get $val))
    (global.set $vs (i32.add (global.get $vs) (i32.const 4)))
  )
  (func $fpop (result f32)
    (if (i32.le_s (global.get $vs) (global.get $cs)) (then
      (global.set $vs (global.get $cs))
      (call $fpush (f32.const 0))
    ))
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4)))
    (f32.load (global.get $vs))
  )
  (func $call (param $offset i32) (param $params i32)
    (call $sys (i32.add (global.get $pc) (local.get $offset)) (local.get $params))
  )
  (func $sys (param $adr i32) (param $params i32)
    (local $paramstart i32)
    (local $paramend i32)
    (local.set $paramstart (i32.add (global.get $vs) (i32.const 8)))
    (local.set $paramend (local.get $paramstart))
    (block(loop (br_if 1 (i32.eqz (local.get $params)))
      (if (i32.ge_s (local.get $paramstart) (i32.const 4)) (then
        (local.set $paramstart (i32.sub (local.get $paramstart) (i32.const 4)))
      ))
      (i32.store (local.get $paramstart) (call $pop))
      (local.set $params (i32.sub (local.get $params) (i32.const 1)))
      (br 0)
    ))

    (call $push (global.get $pc))
    (call $push (global.get $cs))
    (global.set $cs (global.get $vs))
    (global.set $pc (local.get $adr))
    (global.set $vs (local.get $paramend))
  )
  (func $return (param $results i32)
    (local $resultstart i32)
    (local.set $resultstart (i32.sub (global.get $vs) (i32.mul (local.get $results) (i32.const 4))))
    (global.set $vs (global.get $cs))
    (global.set $cs (i32.const 0))
    (global.set $cs (call $pop))
    (global.set $pc (call $pop))
    (block(loop (br_if 1 (i32.eqz (local.get $results)))
      (call $push (i32.load (local.get $resultstart)))
      (local.set $resultstart (i32.add (local.get $resultstart) (i32.const 4)))
      (local.set $results (i32.sub (local.get $results) (i32.const 1)))
      (br 0)
    ))
  )

  (func $run (param $count i32) (result i32)
    (local $opcode i32)
    (block(loop (br_if 1 (i32.eqz (local.get $count)))
      (local.set $count (i32.sub (local.get $count) (i32.const 1)))
      (local.set $opcode (call $step))
      (br_if 1 (i32.lt_u (local.get $opcode) (i32.const 0x04))) 
      (br 0)
    ))
    (local.get $opcode)
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

    (local.set $opcode (i32.load8_u (global.get $pc)))

    ;; Flow
    (if (i32.eqz (i32.and (local.get $opcode) (i32.const 0xf0))) (then
      (if (i32.eqz (i32.and (local.get $opcode) (i32.const 0x08))) (then
        (if (i32.eq (local.get $opcode) (i32.const 0x00)) (then ;; halt
          (global.set $pc (i32.sub (global.get $pc) (i32.const 1)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x01)) (then ;; sleep
          (drop (call $pop))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x04)) (then ;; jump
          (global.set $pc (i32.add (global.get $pc) (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x05)) (then ;; jumpifz
          (local.set $b (call $pop)) ;; offset
          (local.set $a (call $pop)) ;; val
          (if (i32.eqz (local.get $a)) (then
            (global.set $pc (i32.add (global.get $pc) (local.get $b)))
          ))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x07)) (then ;; cpuver
          (call $push (i32.const 1))
          (br 2)
        ))
      )(else
        (if (i32.eq (local.get $opcode) (i32.const 0x08)) (then ;; call
          (local.set $b (call $pop)) ;; params
          (local.set $a (call $pop)) ;; offset
          (call $call (local.get $a) (local.get $b))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x09)) (then ;; sys
          (local.set $b (call $pop)) ;; params
          (local.set $a (call $pop)) ;; adr
          (call $sys (local.get $a) (local.get $b))
          (global.set $pc (i32.sub (global.get $pc) (i32.const 1)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x0b)) (then ;; return
          (call $return (call $pop))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x0c)) (then ;; reset
          (global.set $cs (i32.const 0))
          (global.set $vs (i32.const 0))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x0d)) (then ;; here
          (call $push (global.get $pc))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x0e)) (then ;; goto
          (global.set $pc (i32.sub (call $pop) (i32.const 1)))
          (br 2)
        ))
      ))
    ))

    ;; Memory
    (if (i32.eq (i32.and (local.get $opcode) (i32.const 0xf0)) (i32.const 0x10)) (then
      (if (i32.eqz (i32.and (local.get $opcode) (i32.const 0x08))) (then
        (if (i32.eq (local.get $opcode) (i32.const 0x10)) (then ;; const
          (call $push (i32.load (i32.add (global.get $pc) (i32.const 1))))
          (global.set $pc (i32.add (global.get $pc) (i32.const 4)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x11)) (then ;; get
          (local.set $a (call $pop)) ;; index
          (if (i32.lt_s (local.get $a) (i32.const 0)) (then
            (call $push (i32.load (i32.add (global.get $vs) (i32.mul (local.get $a) (i32.const 4)))))
          )(else
            (call $push (i32.load (i32.add (global.get $cs) (i32.mul (local.get $a) (i32.const 4)))))
          ))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x13)) (then ;; load
          (call $push (i32.load (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x14)) (then ;; load16u
          (call $push (i32.load16_u (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x15)) (then ;; load8u
          (call $push (i32.load8_u (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x16)) (then ;; load16s
          (call $push (i32.load16_s (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x17)) (then ;; load8s
          (call $push (i32.load8_s (call $pop)))
          (br 2)
        ))
      )(else
        (if (i32.eq (local.get $opcode) (i32.const 0x18)) (then ;; drop
          (drop (call $pop))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x19)) (then ;; set
          (local.set $b (call $pop)) ;; val
          (local.set $a (call $pop)) ;; index
          (if (i32.lt_s (local.get $a) (i32.const 0)) (then
            (i32.store (i32.add (global.get $vs) (i32.mul (local.get $a) (i32.const 4))) (local.get $b))
          )(else
            (i32.store (i32.add (global.get $cs) (i32.mul (local.get $a) (i32.const 4))) (local.get $b))
          ))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x1b)) (then ;; store
          (local.set $b (call $pop)) ;; val
          (local.set $a (call $pop)) ;; adr
          (i32.store (local.get $a) (local.get $b))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x1c)) (then ;; store16
          (local.set $b (call $pop)) ;; val
          (local.set $a (call $pop)) ;; adr
          (i32.store16 (local.get $a) (local.get $b))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x1d)) (then ;; store8
          (local.set $b (call $pop)) ;; val
          (local.set $a (call $pop)) ;; adr
          (i32.store8 (local.get $a) (local.get $b))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x1e)) (then ;; stacksize
          (call $push (global.get $vs))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x1f)) (then ;; memsize
          (call $push (i32.mul (i32.const 0x10000) (memory.size)))
          (br 2)
        ))
      ))
    ))

    ;; Math
    (if (i32.eq (i32.and (local.get $opcode) (i32.const 0xf0)) (i32.const 0x20)) (then
      (if (i32.eqz (i32.and (local.get $opcode) (i32.const 0x08))) (then
        (if (i32.eq (local.get $opcode) (i32.const 0x20)) (then ;; add
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.add (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x21)) (then ;; sub
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.sub (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x22)) (then ;; mult
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.mul (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x23)) (then ;; div
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.div_s (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x24)) (then ;; rem
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.rem_s (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x27)) (then ;; ftoi
          (call $push (i32.trunc_f32_s (call $fpop)))
          (br 2)
        ))
      )(else
        (if (i32.eq (local.get $opcode) (i32.const 0x28)) (then ;; fadd
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $fpush (f32.add (local.get $fa) (local.get $fb)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x29)) (then ;; fsub
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $fpush (f32.sub (local.get $fa) (local.get $fb)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x2a)) (then ;; fmult
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $fpush (f32.mul (local.get $fa) (local.get $fb)))
          (br 2)
        )) 
        (if (i32.eq (local.get $opcode) (i32.const 0x2b)) (then ;; fdiv
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $fpush (f32.div (local.get $fa) (local.get $fb)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x2e)) (then ;; uitof
          (call $fpush (f32.convert_i32_u (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x2f)) (then ;; sitof
          (call $fpush (f32.convert_i32_s (call $pop)))
          (br 2)
        ))
      ))
    ))

    ;; Logic
    (if (i32.eq (i32.and (local.get $opcode) (i32.const 0xf0)) (i32.const 0x30)) (then
      (if (i32.eqz (i32.and (local.get $opcode) (i32.const 0x08))) (then
        (if (i32.eq (local.get $opcode) (i32.const 0x30)) (then ;; eq
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.eq (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x31)) (then ;; lt
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.lt_s (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x32)) (then ;; gt
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.gt_s (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x33)) (then ;; eqz
          (call $push (i32.eqz (call $pop)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x34)) (then ;; and
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.and (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x35)) (then ;; or
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.or (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x36)) (then ;; xor
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.xor (local.get $a) (local.get $b)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x37)) (then ;; rot
          (local.set $b (call $pop)) ;; b
          (local.set $a (call $pop)) ;; a
          (call $push (i32.rotl (local.get $a) (local.get $b)))
          (br 2)
        ))
      )(else
        (if (i32.eq (local.get $opcode) (i32.const 0x38)) (then ;; feq
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $push (f32.eq (local.get $fa) (local.get $fb)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x39)) (then ;; flt
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $push (f32.lt (local.get $fa) (local.get $fb)))
          (br 2)
        ))
        (if (i32.eq (local.get $opcode) (i32.const 0x3a)) (then ;; fgt
          (local.set $fb (call $fpop)) ;; b
          (local.set $fa (call $fpop)) ;; a
          (call $push (f32.gt (local.get $fa) (local.get $fb)))
          (br 2)
        ))
      ))
    ))

    (global.set $pc (i32.add (global.get $pc) (i32.const 1)))
    (local.get $opcode)
  )
)