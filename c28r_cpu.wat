(module
  (import "env" "ram" (memory 1))

  (global $pc (mut i32) (i32.const 0x0)) ;; program counter
  (global $cs (mut i32) (i32.const 0x0)) ;; call stack counter
  (global $vs (mut i32) (i32.const 0x0)) ;; value stack counter
  (global $sleep (mut i32) (i32.const 0x0)) ;; sleep duration

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

  (func $getSleep (result i32) (global.get $sleep) )
  (export "getSleep" (func $getSleep))

  (func $push (param $val i32)
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4)))
    (i32.store (global.get $vs) (local.get $val))
  )
  (func $pop (result i32)
    (if (i32.ge_s (global.get $vs) (global.get $cs)) (then
      (global.set $vs (global.get $cs))
      (call $push (i32.const 0))
    ))
    (i32.load (global.get $vs))
    (global.set $vs (i32.add (global.get $vs) (i32.const 4)))
  )
  (func $fpush (param $val f32)
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4)))
    (f32.store (global.get $vs) (local.get $val))
  )
  (func $fpop (result f32)
    (if (i32.ge_s (global.get $vs) (global.get $cs)) (then
      (global.set $vs (global.get $cs))
      (call $fpush (f32.const 0))
    ))
    (f32.load (global.get $vs))
    (global.set $vs (i32.add (global.get $vs) (i32.const 4)))
  )
  (func $abs (param $val i32) (result i32)
    (if (i32.and (local.get $val) (i32.const 0x80000000)) (then
      (if (i32.and (local.get $val) (i32.const 0x40000000)) (then
        (local.set $val (i32.add (global.get $pc) (local.get $val)))
      )(else
        (local.set $val (i32.xor (local.get $val) (i32.const 0x40000000)))
        (local.set $val (i32.add (i32.mul (i32.const 0x10000) (memory.size)) (local.get $val)))
      ))
    )(else
      (if (i32.and (local.get $val) (i32.const 0x40000000)) (then
        (local.set $val (i32.xor (local.get $val) (i32.const 0x40000000)))
      )(else
        (local.set $val (i32.add (global.get $pc) (local.get $val)))
      ))
    ))
    (local.get $val)
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

    ;; Fetch opcode
    (local.set $opcode (i32.load8_u (global.get $pc)))
    (global.set $pc (i32.add (global.get $pc) (i32.const 1)))

    ;; Execute!
    (if (i32.and (local.get $opcode) (i32.const 0xC0) ) (then ;; $40 - $FF

      (call $const_instr)
      (br 0)

    )(else ;; $00 - $3F
      (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $20 - $3F
        (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $30 - $3F
          (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $38 - $3F
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $3C - $3F

              (call $noop_instr)
              (br 4)

            )(else ;; $38 - $3B
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $3A - $3B
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3B

                  (call $noop_instr)
                  (br 6)

                )(else ;; $3A

                  (call $fgt_instr)
                  (br 6)

                ))
              )(else ;; $38 - $39
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $39

                  (call $flt_instr)
                  (br 6)

                )(else ;; $38

                  (call $feq_instr)
                  (br 6)

                ))
              ))
            ))
          )(else ;; $30 - $37
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $34 - $37
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $36 - $37
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $37

                  (call $rot_instr)
                  (br 6)

                )(else ;; $36

                  (call $xor_instr)
                  (br 6)

                ))
              )(else ;; $34 - $35
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $35

                  (call $or_instr)
                  (br 6)

                )(else ;; $34

                  (call $and_instr)
                  (br 6)

                ))
              ))
            )(else ;; $30 - $33
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $32 - $33
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $33

                  (call $eqz_instr)
                  (br 6)

                )(else ;; $32

                  (call $gt_instr)
                  (br 6)

                ))
              )(else ;; $30 - $31
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $31

                  (call $lt_instr)
                  (br 6)

                )(else ;; $30

                  (call $eq_instr)
                  (br 6)

                ))
              ))
            ))
          ))
        )(else ;; $20 - $2F
          (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $28 - $2F
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $2C - $2F
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2E - $2F
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2F

                  (call $sitof_instr)
                  (br 6)

                )(else ;; $2E

                  (call $uitof_instr)
                  (br 6)

                ))
              )(else ;; $2C - $2D

                (call $noop_instr)
                (br 5)

              ))
            )(else ;; $28 - $2B
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2A - $2B
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2B

                  (call $fdiv_instr)
                  (br 6)

                )(else ;; $2A

                  (call $fmult_instr)
                  (br 6)

                ))
              )(else ;; $28 - $29
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $29

                  (call $fsub_instr)
                  (br 6)

                )(else ;; $28

                  (call $fadd_instr)
                  (br 6)

                ))
              ))
            ))
          )(else ;; $20 - $27
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $24 - $27
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $26 - $27
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $27

                  (call $ftoi_instr)
                  (br 6)

                )(else ;; $26

                  (call $noop_instr)
                  (br 6)

                ))
              )(else ;; $24 - $25
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $25

                  (call $noop_instr)
                  (br 6)

                )(else ;; $24

                  (call $rem_instr)
                  (br 6)

                ))
              ))
            )(else ;; $20 - $23
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $22 - $23
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $23

                  (call $div_instr)
                  (br 6)

                )(else ;; $22

                  (call $mult_instr)
                  (br 6)

                ))
              )(else ;; $20 - $21
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $21

                  (call $sub_instr)
                  (br 6)

                )(else ;; $20

                  (call $add_instr)
                  (br 6)

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

                  (call $memsize_instr)
                  (br 6)

                )(else ;; $1E

                  (call $noop_instr)
                  (br 6)

                ))
              )(else ;; $1C - $1D
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1D

                  (call $noop_instr)
                  (br 6)

                )(else ;; $1C

                  (call $storebit_instr)
                  (br 6)

                ))
              ))
            )(else ;; $18 - $1B
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1A - $1B
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1B

                  (call $store_instr)
                  (br 6)

                )(else ;; $1A

                  (call $noop_instr)
                  (br 6)

                ))
              )(else ;; $18 - $19
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $19

                  (call $set_instr)
                  (br 6)

                )(else ;; $18

                  (call $drop_instr)
                  (br 6)

                ))
              ))
            ))
          )(else ;; $10 - $17
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $14 - $17
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $16 - $17
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $17

                  (call $stackptr_instr)
                  (br 6)

                )(else ;; $16

                  (call $noop_instr)
                  (br 6)

                ))
              )(else ;; $14 - $15
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $15

                  (call $loadu_instr)
                  (br 6)

                )(else ;; $14

                  (call $loadbit_instr)
                  (br 6)

                ))
              ))
            )(else ;; $10 - $13
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $12 - $13
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $13

                  (call $load_instr)
                  (br 6)

                )(else ;; $12

                  (call $noop_instr)
                  (br 6)

                ))
              )(else ;; $10 - $11
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $11

                  (call $get_instr)
                  (br 6)

                )(else ;; $10

                  (call $const_instr)
                  (br 6)

                ))
              ))
            ))
          ))
        )(else ;; $00 - $0F
          (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $08 - $0F
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $0C - $0F
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0E - $0F
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0F

                  (call $noop_instr)
                  (br 6)

                )(else ;; $0E

                  (call $cpuver_instr)
                  (br 6)

                ))
              )(else ;; $0C - $0D
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0D

                  (call $here_instr)
                  (br 6)

                )(else ;; $0C

                  (call $reset_instr)
                  (br 6)

                ))
              ))
            )(else ;; $08 - $0B
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0A - $0B

                (call $noop_instr)
                (br 5)

              )(else ;; $08 - $09
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $09

                  (call $return_instr)
                  (br 6)

                )(else ;; $08

                  (call $call_instr)
                  (br 6)

                ))
              ))
            ))
          )(else ;; $00 - $07
            (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $04 - $07
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $06 - $07

                (call $noop_instr)
                (br 5)

              )(else ;; $04 - $05
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $05

                  (call $jumpifz_instr)
                  (br 6)

                )(else ;; $04

                  (call $jump_instr)
                  (br 6)

                ))
              ))
            )(else ;; $00 - $03
              (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $02 - $03
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $03

                  (call $noop_instr)
                  (br 6)

                )(else ;; $02

                  (call $vsync_instr)
                  (br 6)

                ))
              )(else ;; $00 - $01
                (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $01

                  (call $sleep_instr)
                  (br 6)

                )(else ;; $00

                  (call $halt_instr)
                  (br 6)

                ))
              ))
            ))
          ))
        ))
      ))
    ))

    (local.get $opcode)
  )


  (func $halt_instr
  )

  (func $sleep_instr
    (global.set $sleep (call $pop))
  )

  (func $vsync_instr
  )

  (func $null_instr
  )

  (func $jump_instr
    (global.set $pc (call $abs (call $pop)))
  )

  (func $jumpifz_instr
    (if (call $pop) (then
      (global.set $pc (call $abs (call $pop)))
    ))
  )

  (func $call_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $return_instr
    (local $result i32)
    (local.set $result (call $pop))
    (global.set $vs (global.get $cs))
    (global.set $cs (i32.mul (i32.const 0x10000) (memory.size)))
    (global.set $cs (call $pop))
    (global.set $pc (call $pop))
    (call $push (local.get $result))
  )

  (func $reset_instr
    (global.set $cs (i32.mul (i32.const 0x10000) (memory.size)))
    (global.set $vs (i32.mul (i32.const 0x10000) (memory.size)))
  )(export "reset" (func $reset_instr))

  (func $here_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $cpuver_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $noop_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $const_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $get_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $load_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $loadbit_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $loadu_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $stackptr_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $drop_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $set_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $store_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $storebit_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $memsize_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $add_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $sub_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $mult_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $div_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $rem_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $ftoi_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $fadd_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $fsub_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $fmult_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $fdiv_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $uitof_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $sitof_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $eq_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $lt_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $gt_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $eqz_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $and_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $or_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $xor_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $rot_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $feq_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $flt_instr
    ;;                             NOT YET IMPLEMENTED
  )

  (func $fgt_instr
    ;;                             NOT YET IMPLEMENTED
  )

)