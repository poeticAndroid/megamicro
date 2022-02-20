(module
  (import "env" "ram" (memory 1))

  (global $cycles (mut i32) (i32.const 0x10)) ;; cycles left

  (global $pc (mut i32) (i32.const 0x0)) ;; program counter
  (global $sp (mut i32) (i32.const 0x0)) ;; stack pointer

  (global $a (mut i32) (i32.const 0x0)) ;; A register
  (global $x (mut i32) (i32.const 0x0)) ;; X register
  (global $y (mut i32) (i32.const 0x0)) ;; Y register

  (global $c (mut i32) (i32.const 0x0)) ;; Carry flag
  (global $z (mut i32) (i32.const 0x0)) ;; Zero flag
  (global $i (mut i32) (i32.const 0x0)) ;; Interupt disable flag
  (global $d (mut i32) (i32.const 0x0)) ;; Decimal flag
  (global $b (mut i32) (i32.const 0x1)) ;; Break flag
  (global $u (mut i32) (i32.const 0x1)) ;; Unused flag
  (global $v (mut i32) (i32.const 0x0)) ;; oVerflow flag
  (global $n (mut i32) (i32.const 0x0)) ;; Negative flag

  (func $getPC (result i32) (global.get $pc) )
  (export "getPC" (func $getPC))
  (func $setPC (param $val i32) (global.set $pc (i32.and (i32.const 0xffff) (local.get $val))) )
  (export "setPC" (func $setPC))

  (func $getSP (result i32) (global.get $sp) )
  (export "getSP" (func $getSP))
  (func $setSP (param $val i32) (global.set $sp (i32.and (i32.const 0xff) (local.get $val)) ))
  (export "setSP" (func $setSP))


  (func $getA (result i32) (global.get $a) )
  (export "getA" (func $getA))
  (func $setA (param $val i32) (global.set $a (i32.and (i32.const 0xff) (local.get $val)) ))
  (export "setA" (func $setA))

  (func $getX (result i32) (global.get $x) )
  (export "getX" (func $getX))
  (func $setX (param $val i32) (global.set $x (i32.and (i32.const 0xff) (local.get $val)) ))
  (export "setX" (func $setX))

  (func $getY (result i32) (global.get $y) )
  (export "getY" (func $getY))
  (func $setY (param $val i32) (global.set $y (i32.and (i32.const 0xff) (local.get $val)) ))
  (export "setY" (func $setY))


  (func $getC (result i32) (global.get $c) )
  (export "getC" (func $getC))
  (func $setC (param $val i32) (global.set $c (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setC" (func $setC))

  (func $getZ (result i32) (global.get $z) )
  (export "getZ" (func $getZ))
  (func $setZ (param $val i32) (global.set $z (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setZ" (func $setZ))

  (func $getI (result i32) (global.get $i) )
  (export "getI" (func $getI))
  (func $setI (param $val i32) (global.set $i (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setI" (func $setI))

  (func $getD (result i32) (global.get $d) )
  (export "getD" (func $getD))
  (func $setD (param $val i32) (global.set $d (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setD" (func $setD))

  (func $getB (result i32) (global.get $b) )
  (export "getB" (func $getB))
  (func $setB (param $val i32) (global.set $b (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setB" (func $setB))

  (func $getU (result i32) (global.get $u) )
  (export "getU" (func $getU))
  (func $setU (param $val i32) (global.set $u (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setU" (func $setU))

  (func $getV (result i32) (global.get $v) )
  (export "getV" (func $getV))
  (func $setV (param $val i32) (global.set $v (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setV" (func $setV))

  (func $getN (result i32) (global.get $n) )
  (export "getN" (func $getN))
  (func $setN (param $val i32) (global.set $n (i32.eqz (i32.eqz (local.get $val)) )))
  (export "setN" (func $setN))

  (func $getSR (result i32)
    (i32.const 0)
    (i32.or (global.get $n))
    (i32.shl (i32.const 1))
    (i32.or (global.get $v))
    (i32.shl (i32.const 1))
    (i32.or (global.get $u))
    (i32.shl (i32.const 1))
    (i32.or (global.get $b))
    (i32.shl (i32.const 1))
    (i32.or (global.get $d))
    (i32.shl (i32.const 1))
    (i32.or (global.get $i))
    (i32.shl (i32.const 1))
    (i32.or (global.get $z))
    (i32.shl (i32.const 1))
    (i32.or (global.get $c))
  )
  (export "getSR" (func $getSR))
  (func $setSR (param $val i32) 
    (call $setN (i32.and (i32.const 0x80) (local.get $val) ))
    (call $setV (i32.and (i32.const 0x40) (local.get $val) ))
    (call $setU (i32.and (i32.const 0x20) (local.get $val) ))
    (call $setB (i32.and (i32.const 0x10) (local.get $val) ))
    (call $setD (i32.and (i32.const 0x08) (local.get $val) ))
    (call $setI (i32.and (i32.const 0x04) (local.get $val) ))
    (call $setZ (i32.and (i32.const 0x02) (local.get $val) ))
    (call $setC (i32.and (i32.const 0x01) (local.get $val) ))
  )
  (export "setSR" (func $setSR))

  (func $push (param $val i32)
    (i32.store (global.get $sp) (local.get $val))
    (global.set $sp (i32.add (global.get $sp) (i32.const 2)))
  )
  (func $pop (result i32)
    (if (i32.le_s (global.get $sp) (i32.const 0x100)) (then
      (global.set $sp (i32.const 0x100))
      (call $push (i32.const 0))
    ))
    (global.set $sp (i32.sub (global.get $sp) (i32.const 2)))
    (i32.load (global.get $sp))
  )

  (func $illegal (param $opcode i32)
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
    (local $addressmode i32)
    (local $instruction i32)

    ;; fetch opcode
    (local.set $opcode (i32.load8_u (global.get $pc)))
    (global.set $pc (i32.add (global.get $pc) (i32.const 1)))

    ;; lookup opcode
    (if (i32.and (local.get $opcode) (i32.const 0x80) ) (then ;; $80 - $FF
      (if (i32.and (local.get $opcode) (i32.const 0x40) ) (then ;; $C0 - $FF
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $E0 - $FF
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $F0 - $FF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $F8 - $FF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $FC - $FF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $FE - $FF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $FE

                    (local.set $instruction (i32.const 0x20)) ;; INC
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $FC - $FD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FD

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $FC

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $F8 - $FB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $FA - $FB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FB

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $FA

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $F8 - $F9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F9

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $F8

                    (local.set $instruction (i32.const 0x0B)) ;; SED
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $F0 - $F7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $F4 - $F7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $F6 - $F7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $F6

                    (local.set $instruction (i32.const 0x20)) ;; INC
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $F4 - $F5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F5

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $F4

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $F0 - $F3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $F2 - $F3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $F2

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $F0 - $F1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F1

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $F0

                    (local.set $instruction (i32.const 0x33)) ;; BEQ
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $E0 - $EF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $E8 - $EF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $EC - $EF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $EE - $EF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $EF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $EE

                    (local.set $instruction (i32.const 0x20)) ;; INC
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $EC - $ED
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $ED

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $EC

                    (local.set $instruction (i32.const 0x26)) ;; CPX
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $E8 - $EB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $EA - $EB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $EB

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $EA

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $E8 - $E9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E9

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $E8

                    (local.set $instruction (i32.const 0x1F)) ;; INX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $E0 - $E7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $E4 - $E7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $E6 - $E7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $E6

                    (local.set $instruction (i32.const 0x20)) ;; INC
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $E4 - $E5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E5

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $E4

                    (local.set $instruction (i32.const 0x26)) ;; CPX
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $E0 - $E3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $E2 - $E3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $E2

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $E0 - $E1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E1

                    (local.set $instruction (i32.const 0x0D)) ;; SBC
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $E0

                    (local.set $instruction (i32.const 0x26)) ;; CPX
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        )(else ;; $C0 - $DF
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $D0 - $DF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $D8 - $DF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $DC - $DF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $DE - $DF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $DF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $DE

                    (local.set $instruction (i32.const 0x24)) ;; DEC
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $DC - $DD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $DD

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $DC

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $D8 - $DB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $DA - $DB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $DB

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $DA

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $D8 - $D9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D9

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $D8

                    (local.set $instruction (i32.const 0x2A)) ;; CLD
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $D0 - $D7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $D4 - $D7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $D6 - $D7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $D6

                    (local.set $instruction (i32.const 0x24)) ;; DEC
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $D4 - $D5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D5

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $D4

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $D0 - $D3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $D2 - $D3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $D2

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $D0 - $D1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D1

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $D0

                    (local.set $instruction (i32.const 0x30)) ;; BNE
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $C0 - $CF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $C8 - $CF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $CC - $CF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $CE - $CF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $CF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $CE

                    (local.set $instruction (i32.const 0x24)) ;; DEC
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $CC - $CD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $CD

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $CC

                    (local.set $instruction (i32.const 0x25)) ;; CPY
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $C8 - $CB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $CA - $CB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $CB

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $CA

                    (local.set $instruction (i32.const 0x23)) ;; DEX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $C8 - $C9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C9

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $C8

                    (local.set $instruction (i32.const 0x1E)) ;; INY
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $C0 - $C7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $C4 - $C7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $C6 - $C7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $C6

                    (local.set $instruction (i32.const 0x24)) ;; DEC
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $C4 - $C5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C5

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $C4

                    (local.set $instruction (i32.const 0x25)) ;; CPY
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $C0 - $C3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $C2 - $C3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $C2

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $C0 - $C1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C1

                    (local.set $instruction (i32.const 0x27)) ;; CMP
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $C0

                    (local.set $instruction (i32.const 0x25)) ;; CPY
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      )(else ;; $80 - $BF
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $A0 - $BF
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $B0 - $BF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $B8 - $BF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $BC - $BF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $BE - $BF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $BF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $BE

                    (local.set $instruction (i32.const 0x1A)) ;; LDX
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                )(else ;; $BC - $BD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $BD

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $BC

                    (local.set $instruction (i32.const 0x19)) ;; LDY
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $B8 - $BB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $BA - $BB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $BB

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $BA

                    (local.set $instruction (i32.const 0x04)) ;; TSX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $B8 - $B9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B9

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $B8

                    (local.set $instruction (i32.const 0x28)) ;; CLV
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $B0 - $B7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $B4 - $B7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $B6 - $B7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $B6

                    (local.set $instruction (i32.const 0x1A)) ;; LDX
                    (local.set $addressmode (i32.const 0x7)) ;; ZPY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                )(else ;; $B4 - $B5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B5

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $B4

                    (local.set $instruction (i32.const 0x19)) ;; LDY
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $B0 - $B3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $B2 - $B3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $B2

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $B0 - $B1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B1

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $B0

                    (local.set $instruction (i32.const 0x34)) ;; BCS
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $A0 - $AF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $A8 - $AF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $AC - $AF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $AE - $AF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $AF

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $AE

                    (local.set $instruction (i32.const 0x1A)) ;; LDX
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                )(else ;; $AC - $AD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $AD

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $AC

                    (local.set $instruction (i32.const 0x19)) ;; LDY
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $A8 - $AB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $AA - $AB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $AB

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $AA

                    (local.set $instruction (i32.const 0x06)) ;; TAX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $A8 - $A9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A9

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $A8

                    (local.set $instruction (i32.const 0x05)) ;; TAY
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $A0 - $A7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $A4 - $A7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $A6 - $A7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A7

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $A6

                    (local.set $instruction (i32.const 0x1A)) ;; LDX
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                )(else ;; $A4 - $A5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A5

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $A4

                    (local.set $instruction (i32.const 0x19)) ;; LDY
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $A0 - $A3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $A2 - $A3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A3

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $A2

                    (local.set $instruction (i32.const 0x1A)) ;; LDX
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $A0 - $A1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A1

                    (local.set $instruction (i32.const 0x1B)) ;; LDA
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $A0

                    (local.set $instruction (i32.const 0x19)) ;; LDY
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        )(else ;; $80 - $9F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $90 - $9F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $98 - $9F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $9C - $9F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $9E - $9F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $9F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $9E

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $9C - $9D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $9D

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $9C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                ))
              )(else ;; $98 - $9B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $9A - $9B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $9B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $9A

                    (local.set $instruction (i32.const 0x02)) ;; TXS
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $98 - $99
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $99

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $98

                    (local.set $instruction (i32.const 0x01)) ;; TYA
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $90 - $97
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $94 - $97
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $96 - $97
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $97

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $96

                    (local.set $instruction (i32.const 0x08)) ;; STX
                    (local.set $addressmode (i32.const 0x7)) ;; ZPY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                )(else ;; $94 - $95
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $95

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $94

                    (local.set $instruction (i32.const 0x07)) ;; STY
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $90 - $93
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $92 - $93
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $93

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $92

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $90 - $91
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $91

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $90

                    (local.set $instruction (i32.const 0x35)) ;; BCC
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $80 - $8F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $88 - $8F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $8C - $8F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $8E - $8F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $8F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $8E

                    (local.set $instruction (i32.const 0x08)) ;; STX
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                )(else ;; $8C - $8D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $8D

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $8C

                    (local.set $instruction (i32.const 0x07)) ;; STY
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $88 - $8B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $8A - $8B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $8B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $8A

                    (local.set $instruction (i32.const 0x03)) ;; TXA
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $88 - $89
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $89

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $88

                    (local.set $instruction (i32.const 0x22)) ;; DEY
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $80 - $87
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $84 - $87
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $86 - $87
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $87

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $86

                    (local.set $instruction (i32.const 0x08)) ;; STX
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                )(else ;; $84 - $85
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $85

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $84

                    (local.set $instruction (i32.const 0x07)) ;; STY
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $80 - $83
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $82 - $83
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $83

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $82

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $80 - $81
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $81

                    (local.set $instruction (i32.const 0x09)) ;; STA
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $80

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      ))
    )(else ;; $00 - $7F
      (if (i32.and (local.get $opcode) (i32.const 0x40) ) (then ;; $40 - $7F
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $60 - $7F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $70 - $7F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $78 - $7F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $7C - $7F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $7E - $7F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $7F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $7E

                    (local.set $instruction (i32.const 0x10)) ;; ROR
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $7C - $7D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $7D

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $7C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $78 - $7B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $7A - $7B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $7B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $7A

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $78 - $79
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $79

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $78

                    (local.set $instruction (i32.const 0x0A)) ;; SEI
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $70 - $77
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $74 - $77
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $76 - $77
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $77

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $76

                    (local.set $instruction (i32.const 0x10)) ;; ROR
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $74 - $75
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $75

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $74

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $70 - $73
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $72 - $73
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $73

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $72

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $70 - $71
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $71

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $70

                    (local.set $instruction (i32.const 0x2C)) ;; BVS
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $60 - $6F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $68 - $6F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $6C - $6F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $6E - $6F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $6F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $6E

                    (local.set $instruction (i32.const 0x10)) ;; ROR
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $6C - $6D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $6D

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $6C

                    (local.set $instruction (i32.const 0x1D)) ;; JMP
                    (local.set $addressmode (i32.const 0x2)) ;; IND
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                ))
              )(else ;; $68 - $6B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $6A - $6B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $6B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $6A

                    (local.set $instruction (i32.const 0x10)) ;; ROR
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $68 - $69
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $69

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $68

                    (local.set $instruction (i32.const 0x13)) ;; PLA
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $60 - $67
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $64 - $67
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $66 - $67
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $67

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $66

                    (local.set $instruction (i32.const 0x10)) ;; ROR
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $64 - $65
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $65

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $64

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $60 - $63
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $62 - $63
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $63

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $62

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $60 - $61
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $61

                    (local.set $instruction (i32.const 0x38)) ;; ADC
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $60

                    (local.set $instruction (i32.const 0x0E)) ;; RTS
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        )(else ;; $40 - $5F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $50 - $5F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $58 - $5F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $5C - $5F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $5E - $5F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $5F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $5E

                    (local.set $instruction (i32.const 0x18)) ;; LSR
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $5C - $5D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $5D

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $5C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $58 - $5B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $5A - $5B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $5B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $5A

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $58 - $59
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $59

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $58

                    (local.set $instruction (i32.const 0x29)) ;; CLI
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $50 - $57
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $54 - $57
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $56 - $57
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $57

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $56

                    (local.set $instruction (i32.const 0x18)) ;; LSR
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $54 - $55
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $55

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $54

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $50 - $53
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $52 - $53
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $53

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $52

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $50 - $51
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $51

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $50

                    (local.set $instruction (i32.const 0x2D)) ;; BVC
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $40 - $4F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $48 - $4F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $4C - $4F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $4E - $4F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $4F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $4E

                    (local.set $instruction (i32.const 0x18)) ;; LSR
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $4C - $4D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $4D

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $4C

                    (local.set $instruction (i32.const 0x1D)) ;; JMP
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $48 - $4B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $4A - $4B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $4B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $4A

                    (local.set $instruction (i32.const 0x18)) ;; LSR
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $48 - $49
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $49

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $48

                    (local.set $instruction (i32.const 0x15)) ;; PHA
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $40 - $47
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $44 - $47
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $46 - $47
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $47

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $46

                    (local.set $instruction (i32.const 0x18)) ;; LSR
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $44 - $45
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $45

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $44

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $40 - $43
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $42 - $43
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $43

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $42

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $40 - $41
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $41

                    (local.set $instruction (i32.const 0x21)) ;; EOR
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $40

                    (local.set $instruction (i32.const 0x0F)) ;; RTI
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      )(else ;; $00 - $3F
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $20 - $3F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $30 - $3F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $38 - $3F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $3C - $3F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $3E - $3F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $3E

                    (local.set $instruction (i32.const 0x11)) ;; ROL
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $3C - $3D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3D

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $3C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $38 - $3B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $3A - $3B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $3A

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $38 - $39
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $39

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $38

                    (local.set $instruction (i32.const 0x0C)) ;; SEC
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $30 - $37
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $34 - $37
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $36 - $37
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $37

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $36

                    (local.set $instruction (i32.const 0x11)) ;; ROL
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $34 - $35
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $35

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $34

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $30 - $33
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $32 - $33
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $33

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $32

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $30 - $31
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $31

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $30

                    (local.set $instruction (i32.const 0x31)) ;; BMI
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $20 - $2F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $28 - $2F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $2C - $2F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2E - $2F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $2E

                    (local.set $instruction (i32.const 0x11)) ;; ROL
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $2C - $2D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2D

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $2C

                    (local.set $instruction (i32.const 0x32)) ;; BIT
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $28 - $2B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2A - $2B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $2A

                    (local.set $instruction (i32.const 0x11)) ;; ROL
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $28 - $29
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $29

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $28

                    (local.set $instruction (i32.const 0x12)) ;; PLP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $20 - $27
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $24 - $27
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $26 - $27
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $27

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $26

                    (local.set $instruction (i32.const 0x11)) ;; ROL
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $24 - $25
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $25

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $24

                    (local.set $instruction (i32.const 0x32)) ;; BIT
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $20 - $23
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $22 - $23
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $23

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $22

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $20 - $21
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $21

                    (local.set $instruction (i32.const 0x37)) ;; AND
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $20

                    (local.set $instruction (i32.const 0x1C)) ;; JSR
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        )(else ;; $00 - $1F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $10 - $1F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $18 - $1F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $1C - $1F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1E - $1F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $1E

                    (local.set $instruction (i32.const 0x36)) ;; ASL
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                )(else ;; $1C - $1D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1D

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x4)) ;; ABX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $1C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $18 - $1B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1A - $1B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  )(else ;; $1A

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $18 - $19
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $19

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x3)) ;; ABY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $18

                    (local.set $instruction (i32.const 0x2B)) ;; CLC
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $10 - $17
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $14 - $17
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $16 - $17
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $17

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $16

                    (local.set $instruction (i32.const 0x36)) ;; ASL
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $14 - $15
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $15

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x8)) ;; ZPX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $14

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $10 - $13
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $12 - $13
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $13

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $12

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $10 - $11
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $11

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x0)) ;; IZY
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $10

                    (local.set $instruction (i32.const 0x2F)) ;; BPL
                    (local.set $addressmode (i32.const 0x6)) ;; REL
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $00 - $0F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $08 - $0F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $0C - $0F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0E - $0F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0F

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $0E

                    (local.set $instruction (i32.const 0x36)) ;; ASL
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  ))
                )(else ;; $0C - $0D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0D

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x5)) ;; ABS
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  )(else ;; $0C

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 4)))
                    (br 7)

                  ))
                ))
              )(else ;; $08 - $0B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0A - $0B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0B

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $0A

                    (local.set $instruction (i32.const 0x36)) ;; ASL
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $08 - $09
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $09

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  )(else ;; $08

                    (local.set $instruction (i32.const 0x14)) ;; PHP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $00 - $07
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $04 - $07
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $06 - $07
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $07

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  )(else ;; $06

                    (local.set $instruction (i32.const 0x36)) ;; ASL
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 5)))
                    (br 7)

                  ))
                )(else ;; $04 - $05
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $05

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x9)) ;; ZP0
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  )(else ;; $04

                    (local.set $instruction (i32.const 0x17)) ;; NOP
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 3)))
                    (br 7)

                  ))
                ))
              )(else ;; $00 - $03
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $02 - $03
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $03

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 8)))
                    (br 7)

                  )(else ;; $02

                    (local.set $instruction (i32.const 0x00)) ;; XXX
                    (local.set $addressmode (i32.const 0xb)) ;; IMP
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 2)))
                    (br 7)

                  ))
                )(else ;; $00 - $01
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $01

                    (local.set $instruction (i32.const 0x16)) ;; ORA
                    (local.set $addressmode (i32.const 0x1)) ;; IZX
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 6)))
                    (br 7)

                  )(else ;; $00

                    (local.set $instruction (i32.const 0x2E)) ;; BRK
                    (local.set $addressmode (i32.const 0xa)) ;; IMM
                    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 7)))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      ))
    ))

    ;; resolve address
    (if (i32.and (local.get $addressmode) (i32.const 0x08) ) (then ;; $8 - $f
      (if (i32.and (local.get $addressmode) (i32.const 0x04) ) (then ;; $c - $f
        (nop)
      )(else ;; $8 - $b
        (if (i32.and (local.get $addressmode) (i32.const 0x02) ) (then ;; $a - $b
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $b

            ;; IMP
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $a

            ;; IMM
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        )(else ;; $8 - $9
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $9

            ;; ZP0
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $8

            ;; ZPX
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        ))
      ))
    )(else ;; $0 - $7
      (if (i32.and (local.get $addressmode) (i32.const 0x04) ) (then ;; $4 - $7
        (if (i32.and (local.get $addressmode) (i32.const 0x02) ) (then ;; $6 - $7
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $7

            ;; ZPY
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $6

            ;; REL
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        )(else ;; $4 - $5
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $5

            ;; ABS
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $4

            ;; ABX
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        ))
      )(else ;; $0 - $3
        (if (i32.and (local.get $addressmode) (i32.const 0x02) ) (then ;; $2 - $3
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $3

            ;; ABY
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $2

            ;; IND
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        )(else ;; $0 - $1
          (if (i32.and (local.get $addressmode) (i32.const 0x01) ) (then ;; $1

            ;; IZX
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          )(else ;; $0

            ;; IZY
            ;;                             NOT YET IMPLEMENTED
            (br 3)

          ))
        ))
      ))
    ))

    ;; execute instruction
    (if (i32.and (local.get $instruction) (i32.const 0x80) ) (then ;; $80 - $FF
      (nop)
    )(else ;; $00 - $7F
      (if (i32.and (local.get $instruction) (i32.const 0x40) ) (then ;; $40 - $7F
        (nop)
      )(else ;; $00 - $3F
        (if (i32.and (local.get $instruction) (i32.const 0x20) ) (then ;; $20 - $3F
          (if (i32.and (local.get $instruction) (i32.const 0x10) ) (then ;; $30 - $3F
            (if (i32.and (local.get $instruction) (i32.const 0x08) ) (then ;; $38 - $3F
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $3C - $3F
                (nop)
              )(else ;; $38 - $3B
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $3A - $3B
                  (nop)
                )(else ;; $38 - $39
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $39
                    (nop)
                  )(else ;; $38

                    ;; ADC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $30 - $37
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $34 - $37
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $36 - $37
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $37

                    ;; AND
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $36

                    ;; ASL
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $34 - $35
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $35

                    ;; BCC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $34

                    ;; BCS
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $30 - $33
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $32 - $33
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $33

                    ;; BEQ
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $32

                    ;; BIT
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $30 - $31
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $31

                    ;; BMI
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $30

                    ;; BNE
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $20 - $2F
            (if (i32.and (local.get $instruction) (i32.const 0x08) ) (then ;; $28 - $2F
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $2C - $2F
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $2E - $2F
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $2F

                    ;; BPL
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $2E

                    ;; BRK
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $2C - $2D
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $2D

                    ;; BVC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $2C

                    ;; BVS
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $28 - $2B
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $2A - $2B
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $2B

                    ;; CLC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $2A

                    ;; CLD
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $28 - $29
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $29

                    ;; CLI
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $28

                    ;; CLV
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $20 - $27
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $24 - $27
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $26 - $27
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $27

                    ;; CMP
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $26

                    ;; CPX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $24 - $25
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $25

                    ;; CPY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $24

                    ;; DEC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $20 - $23
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $22 - $23
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $23

                    ;; DEX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $22

                    ;; DEY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $20 - $21
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $21

                    ;; EOR
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $20

                    ;; INC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        )(else ;; $00 - $1F
          (if (i32.and (local.get $instruction) (i32.const 0x10) ) (then ;; $10 - $1F
            (if (i32.and (local.get $instruction) (i32.const 0x08) ) (then ;; $18 - $1F
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $1C - $1F
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $1E - $1F
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $1F

                    ;; INX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $1E

                    ;; INY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $1C - $1D
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $1D

                    ;; JMP
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $1C

                    ;; JSR
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $18 - $1B
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $1A - $1B
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $1B

                    ;; LDA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $1A

                    ;; LDX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $18 - $19
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $19

                    ;; LDY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $18

                    ;; LSR
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $10 - $17
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $14 - $17
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $16 - $17
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $17

                    ;; NOP
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $16

                    ;; ORA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $14 - $15
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $15

                    ;; PHA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $14

                    ;; PHP
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $10 - $13
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $12 - $13
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $13

                    ;; PLA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $12

                    ;; PLP
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $10 - $11
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $11

                    ;; ROL
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $10

                    ;; ROR
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            ))
          )(else ;; $00 - $0F
            (if (i32.and (local.get $instruction) (i32.const 0x08) ) (then ;; $08 - $0F
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $0C - $0F
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $0E - $0F
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $0F

                    ;; RTI
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $0E

                    ;; RTS
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $0C - $0D
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $0D

                    ;; SBC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $0C

                    ;; SEC
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $08 - $0B
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $0A - $0B
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $0B

                    ;; SED
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $0A

                    ;; SEI
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $08 - $09
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $09

                    ;; STA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $08

                    ;; STX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $00 - $07
              (if (i32.and (local.get $instruction) (i32.const 0x04) ) (then ;; $04 - $07
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $06 - $07
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $07

                    ;; STY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $06

                    ;; TAX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $04 - $05
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $05

                    ;; TAY
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $04

                    ;; TSX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              )(else ;; $00 - $03
                (if (i32.and (local.get $instruction) (i32.const 0x02) ) (then ;; $02 - $03
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $03

                    ;; TXA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $02

                    ;; TXS
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                )(else ;; $00 - $01
                  (if (i32.and (local.get $instruction) (i32.const 0x01) ) (then ;; $01

                    ;; TYA
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  )(else ;; $00

                    ;; XXX
                    ;;                             NOT YET IMPLEMENTED
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      ))
    ))


  
    (local.get $opcode)
  )
)