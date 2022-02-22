(module
  (import "env" "read" (func $read (param $adr i32) (result i32) ))
  (import "env" "write" (func $write (param $adr i32) (param $val i32) ))
  (import "env" "illegal" (func $illegal (param $val i32) ))

  (global $cycles (mut i32) (i32.const 1)) ;; cycles to wait
  (global $adr (mut i32) (i32.const 0)) ;; address for operand

  (global $pc (mut i32) (i32.const 0)) ;; program counter
  (global $sp (mut i32) (i32.const 0)) ;; stack pointer

  (global $a (mut i32) (i32.const 0)) ;; A register
  (global $x (mut i32) (i32.const 0)) ;; X register
  (global $y (mut i32) (i32.const 0)) ;; Y register

  (global $c (mut i32) (i32.const 0)) ;; Carry flag
  (global $z (mut i32) (i32.const 0)) ;; Zero flag
  (global $i (mut i32) (i32.const 0)) ;; Interupt disable flag
  (global $d (mut i32) (i32.const 0)) ;; Decimal flag
  (global $b (mut i32) (i32.const 1)) ;; Break flag
  (global $u (mut i32) (i32.const 1)) ;; Unused flag
  (global $v (mut i32) (i32.const 0)) ;; oVerflow flag
  (global $n (mut i32) (i32.const 0)) ;; Negative flag

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

  (func $reset
    ;; not yet implemented!
  )
  (export "reset" (func $reset))

  (func $irq
    ;; not yet implemented!
  )
  (export "irq" (func $irq))

  (func $nmi
    ;; not yet implemented!
  )
  (export "nmi" (func $nmi))


  (func $run (param $clocks i32) (result i32)
    (local $opcode i32)
    (local.set $opcode (call $read (global.get $pc)))
    (block(loop (br_if 1 (i32.eqz (local.get $clocks) ))
      (if (i32.eqz (call $clock)) (then (local.set $opcode (call $read (global.get $pc))) ))
      (local.set $clocks (i32.sub (local.get $clocks) (i32.const 1)))
      ;; (br_if 1 (i32.lt_u (local.get $opcode) (i32.const 0x04))) 
      (br 0)
    ))
    (local.get $opcode)
  )
  (export "run" (func $run))

  (func $clock (result i32)
    (local $opcode i32)
    (local $addressmode i32)
    (local $instruction i32)

    (global.set $cycles (i32.sub (global.get $cycles) (i32.const 1)))
    (if (global.get $cycles) (return (i32.const 0)))

    ;; fetch opcode
    (local.set $opcode (call $read (global.get $pc)))
    (global.set $pc (i32.add (global.get $pc) (i32.const 1)))

    ;; handle opcode
    (if (i32.and (local.get $opcode) (i32.const 0x80) ) (then ;; $80 - $FF
      (if (i32.and (local.get $opcode) (i32.const 0x40) ) (then ;; $C0 - $FF
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $E0 - $FF
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $F0 - $FF
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $F8 - $FF
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $FC - $FF
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $FE - $FF
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FF

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $FE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $INC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $FC - $FD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FD

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $FC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $F8 - $FB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $FA - $FB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $FB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $FA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $F8 - $F9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $F8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $SED_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $F0 - $F7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $F4 - $F7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $F6 - $F7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $F6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $INC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $F4 - $F5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $F4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $F0 - $F3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $F2 - $F3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $F2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $F0 - $F1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $F1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $F0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BEQ_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $EE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $INC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $EC - $ED
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $ED

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $EC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $CPX_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $E8 - $EB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $EA - $EB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $EB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $EA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $E8 - $E9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $E8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $INX_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $E0 - $E7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $E4 - $E7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $E6 - $E7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $E6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $INC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $E4 - $E5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $E4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $CPX_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $E0 - $E3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $E2 - $E3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $E2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $E0 - $E1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $E1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $SBC_instr)
                    ))))
                    (br 7)

                  )(else ;; $E0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $CPX_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $DE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $DEC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $DC - $DD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $DD

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $DC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $D8 - $DB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $DA - $DB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $DB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $DA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $D8 - $D9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $D8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $CLD_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $D0 - $D7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $D4 - $D7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $D6 - $D7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $D6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $DEC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $D4 - $D5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $D4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $D0 - $D3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $D2 - $D3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $D2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $D0 - $D1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $D1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $D0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BNE_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $CE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $DEC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $CC - $CD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $CD

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $CC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $CPY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $C8 - $CB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $CA - $CB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $CB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $CA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $DEX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $C8 - $C9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $C8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $INY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $C0 - $C7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $C4 - $C7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $C6 - $C7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $C6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $DEC_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $C4 - $C5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $C4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $CPY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $C0 - $C3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $C2 - $C3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $C2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $C0 - $C1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $C1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $CMP_instr)
                    ))))
                    (br 7)

                  )(else ;; $C0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $CPY_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $BE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $LDX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $BC - $BD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $BD

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $BC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $LDY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $B8 - $BB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $BA - $BB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $BB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $BA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TSX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $B8 - $B9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $B8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $CLV_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $B0 - $B7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $B4 - $B7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $B6 - $B7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $B6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPY_adrmode)
                      (call $LDX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $B4 - $B5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $B4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $LDY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $B0 - $B3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $B2 - $B3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $B2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $B0 - $B1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $B1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $B0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BCS_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $AE

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $LDX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $AC - $AD
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $AD

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $AC

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $LDY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $A8 - $AB
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $AA - $AB
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $AB

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $AA

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TAX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $A8 - $A9
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A9

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $A8

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TAY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $A0 - $A7
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $A4 - $A7
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $A6 - $A7
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A7

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $A6

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $LDX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $A4 - $A5
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A5

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $A4

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $LDY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $A0 - $A3
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $A2 - $A3
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A3

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $A2

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $LDX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $A0 - $A1
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $A1

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $LDA_instr)
                    ))))
                    (br 7)

                  )(else ;; $A0

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $LDY_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $9E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $9C - $9D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $9D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ABX_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $9C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $98 - $9B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $9A - $9B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $9B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $9A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TXS_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $98 - $99
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $99

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ABY_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $98

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TYA_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $90 - $97
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $94 - $97
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $96 - $97
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $97

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $96

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPY_adrmode)
                      (call $STX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $94 - $95
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $95

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $94

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $STY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $90 - $93
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $92 - $93
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $93

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $92

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $90 - $91
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $91

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZY_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $90

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BCC_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $8E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $STX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $8C - $8D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $8D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $8C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $STY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $88 - $8B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $8A - $8B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $8B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $8A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $TXA_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $88 - $89
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $89

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  )(else ;; $88

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $DEY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $80 - $87
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $84 - $87
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $86 - $87
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $87

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $86

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $STX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $84 - $85
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $85

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $84

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $STY_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $80 - $83
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $82 - $83
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $83

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $82

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $80 - $81
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $81

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $STA_instr)
                    ))))
                    (br 7)

                  )(else ;; $80

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $7E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $ROR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $7C - $7D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $7D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $7C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $78 - $7B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $7A - $7B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $7B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $7A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $78 - $79
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $79

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $78

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $SEI_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $70 - $77
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $74 - $77
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $76 - $77
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $77

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $76

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $ROR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $74 - $75
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $75

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $74

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $70 - $73
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $72 - $73
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $73

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $72

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $70 - $71
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $71

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $70

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BVS_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $6E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $ROR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $6C - $6D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $6D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $6C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IND_adrmode)
                      (call $JMP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $68 - $6B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $6A - $6B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $6B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $6A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $ROR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $68 - $69
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $69

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $68

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $PLA_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $60 - $67
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $64 - $67
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $66 - $67
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $67

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $66

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $ROR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $64 - $65
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $65

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $64

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $60 - $63
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $62 - $63
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $63

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $62

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $60 - $61
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $61

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $ADC_instr)
                    ))))
                    (br 7)

                  )(else ;; $60

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $RTS_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $5E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $LSR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $5C - $5D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $5D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $5C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $58 - $5B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $5A - $5B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $5B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $5A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $58 - $59
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $59

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $58

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $CLI_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $50 - $57
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $54 - $57
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $56 - $57
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $57

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $56

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $LSR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $54 - $55
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $55

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $54

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $50 - $53
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $52 - $53
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $53

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $52

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $50 - $51
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $51

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $50

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BVC_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $4E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $LSR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $4C - $4D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $4D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $4C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ABS_adrmode)
                      (call $JMP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $48 - $4B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $4A - $4B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $4B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $4A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $LSR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $48 - $49
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $49

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $48

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $PHA_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $40 - $47
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $44 - $47
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $46 - $47
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $47

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $46

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $LSR_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $44 - $45
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $45

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $44

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $40 - $43
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $42 - $43
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $43

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $42

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $40 - $41
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $41

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $EOR_instr)
                    ))))
                    (br 7)

                  )(else ;; $40

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $RTI_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $3E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $ROL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $3C - $3D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $3C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $38 - $3B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $3A - $3B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $3A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $38 - $39
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $39

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $38

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $SEC_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $30 - $37
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $34 - $37
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $36 - $37
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $37

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $36

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $ROL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $34 - $35
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $35

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $34

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $30 - $33
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $32 - $33
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $33

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $32

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $30 - $31
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $31

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $30

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BMI_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $2E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $ROL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $2C - $2D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $2C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $BIT_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $28 - $2B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2A - $2B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $2A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $ROL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $28 - $29
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $29

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $28

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $PLP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $20 - $27
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $24 - $27
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $26 - $27
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $27

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $26

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $ROL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $24 - $25
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $25

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $24

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $BIT_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $20 - $23
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $22 - $23
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $23

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $22

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $20 - $21
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $21

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $AND_instr)
                    ))))
                    (br 7)

                  )(else ;; $20

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $JSR_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $1E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $ABX_adrmode)
                      (call $ASL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $1C - $1D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABX_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $1C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $18 - $1B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1A - $1B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $1A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $18 - $19
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $19

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABY_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $18

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $CLC_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $10 - $17
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $14 - $17
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $16 - $17
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $17

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $16

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ZPX_adrmode)
                      (call $ASL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $14 - $15
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $15

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ZPX_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $14

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $10 - $13
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $12 - $13
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $13

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $12

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $10 - $11
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $11

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IZY_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $10

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $REL_adrmode)
                      (call $BPL_instr)
                    ))))
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

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $0E

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $ABS_adrmode)
                      (call $ASL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $0C - $0D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0D

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $ABS_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $0C

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 4) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $08 - $0B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0A - $0B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0B

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $0A

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $ASL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $08 - $09
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $09

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMM_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $08

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $PHP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            )(else ;; $00 - $07
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $04 - $07
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $06 - $07
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $07

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $06

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 5) (i32.and
                      (call $ZP0_adrmode)
                      (call $ASL_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $04 - $05
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $05

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $ZP0_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $04

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 3) (i32.and
                      (call $IMP_adrmode)
                      (call $NOP_instr)
                    ))))
                    (br 7)

                  ))
                ))
              )(else ;; $00 - $03
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $02 - $03
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $03

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 8) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  )(else ;; $02

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 2) (i32.and
                      (call $IMP_adrmode)
                      (call $XXX_instr)
                    ))))
                    (br 7)

                  ))
                )(else ;; $00 - $01
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $01

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 6) (i32.and
                      (call $IZX_adrmode)
                      (call $ORA_instr)
                    ))))
                    (br 7)

                  )(else ;; $00

                    (global.set $cycles (i32.add (global.get $cycles) (i32.add (i32.const 7) (i32.and
                      (call $IMM_adrmode)
                      (call $BRK_instr)
                    ))))
                    (br 7)

                  ))
                ))
              ))
            ))
          ))
        ))
      ))
    ))
  
    (i32.const 1)
  )
  (export "clock" (func $clock))


  (func $IMP_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 0))
    (i32.const 0)
  )

  (func $IMM_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 1))
    (i32.const 0)
  )

  (func $ZP0_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 2))
    (i32.const 0)
  )

  (func $ZPX_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 3))
    (i32.const 0)
  )

  (func $ZPY_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 4))
    (i32.const 0)
  )

  (func $REL_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 5))
    (i32.const 0)
  )

  (func $ABS_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 6))
    (i32.const 0)
  )

  (func $ABX_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 7))
    (i32.const 0)
  )

  (func $ABY_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 8))
    (i32.const 0)
  )

  (func $IND_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 9))
    (i32.const 0)
  )

  (func $IZX_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 10))
    (i32.const 0)
  )

  (func $IZY_adrmode (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 11))
    (i32.const 0)
  )


  (func $ADC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 0))
    (i32.const 0)
  )

  (func $AND_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 1))
    (i32.const 0)
  )

  (func $ASL_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 2))
    (i32.const 0)
  )

  (func $BCC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 3))
    (i32.const 0)
  )

  (func $BCS_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 4))
    (i32.const 0)
  )

  (func $BEQ_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 5))
    (i32.const 0)
  )

  (func $BIT_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 6))
    (i32.const 0)
  )

  (func $BMI_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 7))
    (i32.const 0)
  )

  (func $BNE_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 8))
    (i32.const 0)
  )

  (func $BPL_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 9))
    (i32.const 0)
  )

  (func $BRK_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 10))
    (i32.const 0)
  )

  (func $BVC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 11))
    (i32.const 0)
  )

  (func $BVS_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 12))
    (i32.const 0)
  )

  (func $CLC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 13))
    (i32.const 0)
  )

  (func $CLD_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 14))
    (i32.const 0)
  )

  (func $CLI_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 15))
    (i32.const 0)
  )

  (func $CLV_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 16))
    (i32.const 0)
  )

  (func $CMP_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 17))
    (i32.const 0)
  )

  (func $CPX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 18))
    (i32.const 0)
  )

  (func $CPY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 19))
    (i32.const 0)
  )

  (func $DEC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 20))
    (i32.const 0)
  )

  (func $DEX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 21))
    (i32.const 0)
  )

  (func $DEY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 22))
    (i32.const 0)
  )

  (func $EOR_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 23))
    (i32.const 0)
  )

  (func $INC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 24))
    (i32.const 0)
  )

  (func $INX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 25))
    (i32.const 0)
  )

  (func $INY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 26))
    (i32.const 0)
  )

  (func $JMP_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 27))
    (i32.const 0)
  )

  (func $JSR_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 28))
    (i32.const 0)
  )

  (func $LDA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 29))
    (i32.const 0)
  )

  (func $LDX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 30))
    (i32.const 0)
  )

  (func $LDY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 31))
    (i32.const 0)
  )

  (func $LSR_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 32))
    (i32.const 0)
  )

  (func $NOP_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 33))
    (i32.const 0)
  )

  (func $ORA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 34))
    (i32.const 0)
  )

  (func $PHA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 35))
    (i32.const 0)
  )

  (func $PHP_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 36))
    (i32.const 0)
  )

  (func $PLA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 37))
    (i32.const 0)
  )

  (func $PLP_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 38))
    (i32.const 0)
  )

  (func $ROL_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 39))
    (i32.const 0)
  )

  (func $ROR_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 40))
    (i32.const 0)
  )

  (func $RTI_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 41))
    (i32.const 0)
  )

  (func $RTS_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 42))
    (i32.const 0)
  )

  (func $SBC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 43))
    (i32.const 0)
  )

  (func $SEC_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 44))
    (i32.const 0)
  )

  (func $SED_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 45))
    (i32.const 0)
  )

  (func $SEI_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 46))
    (i32.const 0)
  )

  (func $STA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 47))
    (i32.const 0)
  )

  (func $STX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 48))
    (i32.const 0)
  )

  (func $STY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 49))
    (i32.const 0)
  )

  (func $TAX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 50))
    (i32.const 0)
  )

  (func $TAY_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 51))
    (i32.const 0)
  )

  (func $TSX_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 52))
    (i32.const 0)
  )

  (func $TXA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 53))
    (i32.const 0)
  )

  (func $TXS_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 54))
    (i32.const 0)
  )

  (func $TYA_instr (result i32)
    ;;                             NOT YET IMPLEMENTED
    (call $illegal (i32.const 55))
    (i32.const 0)
  )

  (func $XXX_instr (result i32)
    (call $illegal (i32.const 56))
    (i32.const 0)
  )

)