(module
  (import "env" "ram" (memory 1) )

  (global $pc (mut i32) (i32.const 0x0) ) ;; program counter
  (global $cs (mut i32) (i32.const 0x0) ) ;; call stack counter
  (global $vs (mut i32) (i32.const 0x0) ) ;; value stack counter
  (global $safecs (mut i32) (i32.const 0x0) ) ;; safe call stack pointer
  (global $sleep (mut i32) (i32.const 0x0) ) ;; sleep duration

  (func $getPC (result i32) (global.get $pc) )
  (export "getPC" (func $getPC) )
  (func $setPC (param $val i32) (global.set $pc (local.get $val) ) )
  (export "setPC" (func $setPC) )

  (func $getCS (result i32) (global.get $cs) )
  (export "getCS" (func $getCS) )
  (func $setCS (param $val i32) (global.set $cs (local.get $val) ) )
  (export "setCS" (func $setCS) )

  (func $getVS (result i32) (global.get $vs) )
  (export "getVS" (func $getVS) )
  (func $setVS (param $val i32) (global.set $vs (local.get $val) ) )
  (export "setVS" (func $setVS) )

  (func $getSleep (result i32) (global.get $sleep) )
  (export "getSleep" (func $getSleep) )

  (func $push (param $val i32)
    (if (i32.ge_u (global.get $vs) (global.get $cs) ) (then
      (global.set $vs (global.get $cs) )
    ) )
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4) ) )
    (i32.store (global.get $vs) (local.get $val) )
  )
  (func $pop (result i32)
    (if (i32.ge_u (global.get $vs) (global.get $cs) ) (then
      (call $push (i32.const 0) )
    ) )
    (i32.load (global.get $vs) )
    (global.set $vs (i32.add (global.get $vs) (i32.const 4) ) )
  )
  (func $fpush (param $val f32)
    (if (i32.ge_s (global.get $vs) (global.get $cs) ) (then
      (global.set $vs (global.get $cs) )
    ) )
    (global.set $vs (i32.sub (global.get $vs) (i32.const 4) ) )
    (f32.store (global.get $vs) (local.get $val) )
  )
  (func $fpop (result f32)
    (if (i32.ge_s (global.get $vs) (global.get $cs) ) (then
      (call $push (i32.const 0) )
    ) )
    (f32.load (global.get $vs) )
    (global.set $vs (i32.add (global.get $vs) (i32.const 4) ) )
  )
  (func $abs (param $val i32) (result i32)
    (if (i32.and (local.get $val) (i32.const 0x80000000) ) (then
      (if (i32.and (local.get $val) (i32.const 0x40000000) ) (then
        (local.set $val (i32.add (global.get $pc) (local.get $val) ) )
      ) (else
        (local.set $val (i32.xor (local.get $val) (i32.const 0x40000000) ) )
        (local.set $val (i32.add (i32.mul (i32.const 0x10000) (memory.size) ) (local.get $val) ) )
      ) )
    ) (else
      (if (i32.and (local.get $val) (i32.const 0x40000000) ) (then
        (local.set $val (i32.xor (local.get $val) (i32.const 0x40000000) ) )
      ) (else
        (local.set $val (i32.add (global.get $pc) (local.get $val) ) )
      ) )
    ) )
    (local.get $val)
  )

  (func $run (param $count i32) (result i32)
    (local $opcode i32)
    (block(loop (br_if 1 (i32.eqz (local.get $count) ) )
      (local.set $count (i32.sub (local.get $count) (i32.const 1) ) )
      (local.set $opcode (call $step) )
      (br_if 1 (i32.lt_u (local.get $opcode) (i32.const 0x04) ) ) 
      (br 0)
    ) )
    (local.get $opcode)
  )
  (export "run" (func $run) )

  (func $step (result i32)
    (local $opcode i32)

    ;; Fetch opcode
    (local.set $opcode (i32.load8_u (global.get $pc) ) )
    (global.set $pc (i32.add (global.get $pc) (i32.const 1) ) )

    ;; Execute!
    (if (i32.and (local.get $opcode) (i32.const 0xC0) ) (then ;; $40 - $FF

      (call $lit_instr)
      (br 0)

    ) (else ;; $00 - $7F
      (if (i32.and (local.get $opcode) (i32.const 0x40) ) (then ;; $40 - $7F

        (call $lit_instr)
        (br 1)

      ) (else ;; $00 - $3F
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then ;; $20 - $3F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $30 - $3F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $38 - $3F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $3C - $3F

                (call $noop_instr)
                (br 5)

              ) (else ;; $38 - $3B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $3A - $3B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $3B

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $3A

                    (call $fgt_instr)
                    (br 7)

                  ) )
                ) (else ;; $38 - $39
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $39

                    (call $flt_instr)
                    (br 7)

                  ) (else ;; $38

                    (call $feq_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) (else ;; $30 - $37
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $34 - $37
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $36 - $37
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $37

                    (call $rot_instr)
                    (br 7)

                  ) (else ;; $36

                    (call $xor_instr)
                    (br 7)

                  ) )
                ) (else ;; $34 - $35
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $35

                    (call $or_instr)
                    (br 7)

                  ) (else ;; $34

                    (call $and_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $30 - $33
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $32 - $33
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $33

                    (call $eqz_instr)
                    (br 7)

                  ) (else ;; $32

                    (call $gt_instr)
                    (br 7)

                  ) )
                ) (else ;; $30 - $31
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $31

                    (call $lt_instr)
                    (br 7)

                  ) (else ;; $30

                    (call $eq_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) )
          ) (else ;; $20 - $2F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $28 - $2F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $2C - $2F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2E - $2F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2F

                    (call $ftoi_instr)
                    (br 7)

                  ) (else ;; $2E

                    (call $noop_instr)
                    (br 7)

                  ) )
                ) (else ;; $2C - $2D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2D

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $2C

                    (call $ffloor_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $28 - $2B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $2A - $2B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $2B

                    (call $fdiv_instr)
                    (br 7)

                  ) (else ;; $2A

                    (call $fmult_instr)
                    (br 7)

                  ) )
                ) (else ;; $28 - $29
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $29

                    (call $fsub_instr)
                    (br 7)

                  ) (else ;; $28

                    (call $fadd_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) (else ;; $20 - $27
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $24 - $27
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $26 - $27
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $27

                    (call $uitof_instr)
                    (br 7)

                  ) (else ;; $26

                    (call $itof_instr)
                    (br 7)

                  ) )
                ) (else ;; $24 - $25
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $25

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $24

                    (call $rem_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $20 - $23
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $22 - $23
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $23

                    (call $div_instr)
                    (br 7)

                  ) (else ;; $22

                    (call $mult_instr)
                    (br 7)

                  ) )
                ) (else ;; $20 - $21
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $21

                    (call $sub_instr)
                    (br 7)

                  ) (else ;; $20

                    (call $add_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) )
          ) )
        ) (else ;; $00 - $1F
          (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then ;; $10 - $1F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $18 - $1F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $1C - $1F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1E - $1F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1F

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $1E

                    (call $store_instr)
                    (br 7)

                  ) )
                ) (else ;; $1C - $1D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1D

                    (call $storebit_instr)
                    (br 7)

                  ) (else ;; $1C

                    (call $noop_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $18 - $1B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $1A - $1B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $1B

                    (call $dec_instr)
                    (br 7)

                  ) (else ;; $1A

                    (call $inc_instr)
                    (br 7)

                  ) )
                ) (else ;; $18 - $19
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $19

                    (call $set_instr)
                    (br 7)

                  ) (else ;; $18

                    (call $drop_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) (else ;; $10 - $17
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $14 - $17
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $16 - $17
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $17

                    (call $loadu_instr)
                    (br 7)

                  ) (else ;; $16

                    (call $load_instr)
                    (br 7)

                  ) )
                ) (else ;; $14 - $15
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $15

                    (call $loadbit_instr)
                    (br 7)

                  ) (else ;; $14

                    (call $noop_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $10 - $13
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $12 - $13
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $13

                    (call $memsize_instr)
                    (br 7)

                  ) (else ;; $12

                    (call $stackptr_instr)
                    (br 7)

                  ) )
                ) (else ;; $10 - $11
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $11

                    (call $get_instr)
                    (br 7)

                  ) (else ;; $10

                    (call $lit_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) )
          ) (else ;; $00 - $0F
            (if (i32.and (local.get $opcode) (i32.const 0x08) ) (then ;; $08 - $0F
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $0C - $0F
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0E - $0F
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0F

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $0E

                    (call $cpuver_instr)
                    (br 7)

                  ) )
                ) (else ;; $0C - $0D
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0D

                    (call $absadr_instr)
                    (br 7)

                  ) (else ;; $0C

                    (call $reset_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $08 - $0B
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $0A - $0B
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $0B

                    (call $break_instr)
                    (br 7)

                  ) (else ;; $0A

                    (call $exec_instr)
                    (br 7)

                  ) )
                ) (else ;; $08 - $09
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $09

                    (call $return_instr)
                    (br 7)

                  ) (else ;; $08

                    (call $call_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) (else ;; $00 - $07
              (if (i32.and (local.get $opcode) (i32.const 0x04) ) (then ;; $04 - $07
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $06 - $07
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $07

                    (call $endcall_instr)
                    (br 7)

                  ) (else ;; $06

                    (call $noop_instr)
                    (br 7)

                  ) )
                ) (else ;; $04 - $05
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $05

                    (call $jumpifz_instr)
                    (br 7)

                  ) (else ;; $04

                    (call $jump_instr)
                    (br 7)

                  ) )
                ) )
              ) (else ;; $00 - $03
                (if (i32.and (local.get $opcode) (i32.const 0x02) ) (then ;; $02 - $03
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $03

                    (call $noop_instr)
                    (br 7)

                  ) (else ;; $02

                    (call $vsync_instr)
                    (br 7)

                  ) )
                ) (else ;; $00 - $01
                  (if (i32.and (local.get $opcode) (i32.const 0x01) ) (then ;; $01

                    (call $sleep_instr)
                    (br 7)

                  ) (else ;; $00

                    (call $halt_instr)
                    (br 7)

                  ) )
                ) )
              ) )
            ) )
          ) )
        ) )
      ) )
    ) )

    (local.get $opcode)
  )


  (func $halt_instr
  )

  (func $sleep_instr
    (global.set $sleep (call $pop) )
  )

  (func $vsync_instr
  )

  (func $null_instr
  )

  (func $jump_instr
    (global.set $pc (call $abs (call $pop) ) )
  )

  (func $jumpifz_instr
    (if (call $pop) (then
      (global.set $pc (call $abs (call $pop) ) )
    ) )
  )

  (func $endcall_instr
    (global.set $vs (global.get $cs) )
    (global.set $cs (i32.mul (i32.const 0x10000) (memory.size) ) )
    (global.set $pc (call $pop) )
    (global.set $cs (call $pop) )
  )

  (func $call_instr
    (local $adr i32)
    (local $params i32)
    (local $count i32)
    (local $oldvs i32)
    (local $newvs i32)
    (local $start i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $params (call $pop) )
    (local.set $newvs (i32.sub (global.get $vs) (i32.const 8) ) )
    (local.set $start (local.get $newvs) )

    (local.set $count (local.get $params) )
    (block(loop (br_if 1 (i32.eqz (local.get $count) ) )
      (call $pop)
      (local.set $oldvs (global.get $vs) )
      (global.set $vs (local.get $newvs) )
      (call $push)
      (local.set $newvs (global.get $vs) )
      (global.set $vs (local.get $oldvs) )

      (local.set $count (i32.sub (local.get $count) (i32.const 1) ) )
      (br 0)
    ) )

    (call $push (global.get $cs) )
    (call $push (global.get $pc) )
    (global.set $cs (global.get $vs) )

    (local.set $count (local.get $params) )
    (block(loop (br_if 1 (i32.eqz (local.get $count) ) )
      (local.set $start (i32.sub (local.get $start) (i32.const 4) ) )
      (call $push (i32.load (local.get $start) ) )

      (local.set $count (i32.sub (local.get $count) (i32.const 1) ) )
      (br 0)
    ) )

    (global.set $pc (local.get $adr) )
  )

  (func $return_instr
    (call $pop)
    (call $endcall_instr)
    (call $push)
  )

  (func $exec_instr
    (call $call_instr)
    (if (i32.eqz (global.get $safecs) ) (then
      (global.set $safecs (global.get $cs) )
    ) )
  )

  (func $break_instr
    (call $push (i32.const -1) )
    (if (global.get $safecs) (then
      (global.set $cs (global.get $safecs) )
      (global.set $safecs (i32.const 0) )
      (call $return_instr )
    ) (else
      (call $reset_instr)
    ) )
  ) (export "break" (func $break_instr) )

  (func $reset_instr
    (global.set $cs (i32.mul (i32.const 0x10000) (memory.size) ) )
    (global.set $vs (i32.mul (i32.const 0x10000) (memory.size) ) )
    (global.set $safecs (i32.const 0) )
    (call $push (i32.sub (global.get $cs) (i32.const 8) ) )
    (global.set $cs (call $pop) )
    (call $return_instr)
  ) (export "reset" (func $reset_instr) )

  (func $absadr_instr
    (call $push (i32.xor (call $abs (call $pop) ) (i32.const 0x40000000) ) )
  )

  (func $cpuver_instr
    (call $push (i32.const 2) )
  )

  (func $noop_instr
  )

  (func $lit_instr
    (local $opcode i32)
    (local $val i32)
    (local $rot i32)
    (local.set $opcode (i32.load8_u (i32.sub (global.get $pc) (i32.const 1) ) ) )
    (if (i32.eq (local.get $opcode) (i32.const 0x10) ) (then
      (call $push (i32.load (global.get $pc) ) )
      (global.set $pc (i32.add (global.get $pc) (i32.const 4) ) )
    ) (else
      (local.set $rot (i32.const 32) )
      (local.set $val (i32.and (local.get $opcode) (i32.const 0xf) ) )
      (local.set $val (i32.rotr (local.get $val) (i32.const 4) ) )
      (local.set $rot (i32.sub (local.get $rot) (i32.const 4) ) )
      (local.set $opcode (i32.sub (local.get $opcode) (i32.const 0x40) ) )
      (block(loop (br_if 1 (i32.eqz (i32.and (local.get $opcode) (i32.const 0xc0) ) ) )
        (local.set $val (i32.or (local.get $val) (i32.load8_u (global.get $pc) ) ) )
        (global.set $pc (i32.add (global.get $pc) (i32.const 1) ) )
        (local.set $val (i32.rotr (local.get $val) (i32.const 8) ) )
        (local.set $rot (i32.sub (local.get $rot) (i32.const 8) ) )
        (local.set $opcode (i32.sub (local.get $opcode) (i32.const 0x40) ) )
        (br 0)
      ) )
      (block(loop (br_if 1 (i32.eqz (local.get $rot) ) )
        (if (i32.and (local.get $opcode) (i32.const 0x20) ) (then
          (local.set $val (i32.or (local.get $val) (i32.const 0xf) ) )
        ) )
        (local.set $val (i32.rotr (local.get $val) (i32.const 4) ) )
        (local.set $rot (i32.sub (local.get $rot) (i32.const 4) ) )
        (br 0)
      ) )
      (if (i32.and (local.get $opcode) (i32.const 0x10) ) (then
        (local.set $val (i32.xor (local.get $val) (i32.const 0x40000000) ) )
      ) )
      (call $push (local.get $val) )
    ) )
  )

  (func $get_instr
    (local $index i32)
    (local.set $index (call $pop) )
    (if (i32.lt_s (local.get $index) (i32.const 0) ) (then
      (call $push (i32.load (i32.add (global.get $cs) (i32.mul (local.get $index) (i32.const 4) ) ) ) )
    ) (else
      (call $push (i32.load (i32.add (global.get $vs) (i32.mul (local.get $index) (i32.const 4) ) ) ) )
    ) )
  )

  (func $stackptr_instr
    (call $push (i32.xor (i32.sub (global.get $vs) (i32.mul (i32.const 0x10000) (memory.size) ) ) (i32.const 0x40000000) ) )
  )

  (func $memsize_instr
    (call $push (i32.mul (i32.const 0x10000) (memory.size) ) )
  )

  (func $loadbit_instr
    (local $adr i32)
    (local $bit i32)
    (local $len i32)
    (local $mask i32)
    (local $val i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $bit (call $pop) )
    (local.set $len (i32.sub (i32.const 8) (call $pop) ) )

    (local.set $adr (i32.add (local.get $adr) (i32.shr_u (local.get $bit) (i32.const 3) ) ) )
    (local.set $bit (i32.and (local.get $bit) (i32.const 0x7) ) )
    (local.set $mask (i32.shr_u (i32.const 0xff) (local.get $bit) ) )
    (local.set $val (i32.and (i32.load8_u (local.get $adr) ) (local.get $mask) ) )
    (local.set $val (i32.shl (local.get $val) (local.get $bit) ) )
    (local.set $val (i32.shr_u (local.get $val) (local.get $len) ) )

    (call $push (local.get $val) )
  )

  (func $load_instr
    (local $adr i32)
    (local $len i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $len (i32.mul (i32.const 8) (i32.sub (i32.const 4) (call $pop) ) ) )

    (call $push (i32.shr_s (i32.shl (i32.load (local.get $adr) ) (local.get $len) ) (local.get $len) ) )
  )

  (func $loadu_instr
    (local $adr i32)
    (local $len i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $len (i32.mul (i32.const 8) (i32.sub (i32.const 4) (call $pop) ) ) )

    (call $push (i32.shr_u (i32.shl (i32.load (local.get $adr) ) (local.get $len) ) (local.get $len) ) )
  )

  (func $drop_instr
    (drop (call $pop) )
  )

  (func $set_instr
    (local $index i32)
    (local.set $index (call $pop) )
    (if (i32.lt_s (local.get $index) (i32.const 0) ) (then
      (i32.store (i32.add (global.get $cs) (i32.mul (local.get $index) (i32.const 4) ) ) (call $pop) )
    ) (else
      (i32.store (i32.add (global.get $vs) (i32.mul (local.get $index) (i32.const 4) ) ) (call $pop) )
    ) )
  )

  (func $inc_instr
    (local $index i32)
    (local.set $index (call $pop) )
    (call $push (i32.const 1) )
    (call $push (local.get $index) )
    (call $get_instr)
    (call $add_instr)
    (call $push (local.get $index) )
    (call $set_instr)
  )

  (func $dec_instr
    (local $index i32)
    (local.set $index (call $pop) )
    (call $push (i32.const 1) )
    (call $push (local.get $index) )
    (call $get_instr)
    (call $sub_instr)
    (call $push (local.get $index) )
    (call $set_instr)
  )

  (func $storebit_instr
    (local $adr i32)
    (local $bit i32)
    (local $len i32)
    (local $val i32)
    (local $mask i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $bit (call $pop) )
    (local.set $len (i32.sub (i32.const 8) (call $pop) ) )
    (local.set $val (call $pop) )

    (local.set $adr (i32.add (local.get $adr) (i32.shr_u (local.get $bit) (i32.const 3) ) ) )
    (local.set $bit (i32.and (local.get $bit) (i32.const 0x7) ) )

    (local.set $mask (i32.shr_u (i32.const 0xff) (local.get $len) ) )
    (local.set $mask (i32.shl (local.get $mask) (i32.sub (local.get $len) (local.get $bit) ) ) )
    (local.set $val (i32.shl (local.get $val) (i32.sub (local.get $len) (local.get $bit) ) ) )

    (local.set $val (i32.and (i32.xor (local.get $val) (i32.load8_u (local.get $adr) ) ) (local.get $mask) ) )
    (i32.store8 (local.get $adr) (i32.xor (i32.load8_u (local.get $adr) ) (local.get $val) ) )
  )

  (func $store_instr
    (local $adr i32)
    (local $len i32)
    (local $val i32)
    (local.set $adr (call $abs (call $pop) ) )
    (local.set $len (i32.mul (i32.const 8) (i32.sub (i32.const 4) (call $pop) ) ) )
    (local.set $val (call $pop) )

    (if (i32.and (local.get $len) (i32.const 0x2) ) (then
      (if (i32.and (local.get $len) (i32.const 0x1) ) (then
        (i32.store8 (local.get $adr) (local.get $val) )
        (i32.store16 (i32.add (local.get $adr) (i32.const 1) ) (i32.shr_s (local.get $val) (i32.const 8) ) )
      ) (else
        (i32.store16 (local.get $adr) (local.get $val) )
      ) )
    ) (else
      (if (i32.and (local.get $len) (i32.const 0x1) ) (then
        (i32.store8 (local.get $adr) (local.get $val) )
      ) (else
        (i32.store (local.get $adr) (local.get $val) )
      ) )
    ) )
  )

  (func $add_instr
    (call $push (i32.add (call $pop) (call $pop) ) )
  )

  (func $sub_instr
    (call $push (i32.sub (call $pop) (call $pop) ) )
  )

  (func $mult_instr
    (call $push (i32.mul (call $pop) (call $pop) ) )
  )

  (func $div_instr
    (call $push (i32.div_s (call $pop) (call $pop) ) )
  )

  (func $rem_instr
    (call $push (i32.rem_s (call $pop) (call $pop) ) )
  )

  (func $itof_instr
    (call $fpush (f32.convert_i32_s (call $pop) ) )
  )

  (func $uitof_instr
    (call $fpush (f32.convert_i32_u (call $pop) ) )
  )

  (func $fadd_instr
    (call $fpush (f32.add (call $fpop) (call $fpop) ) )
  )

  (func $fsub_instr
    (call $fpush (f32.sub (call $fpop) (call $fpop) ) )
  )

  (func $fmult_instr
    (call $fpush (f32.mul (call $fpop) (call $fpop) ) )
  )

  (func $fdiv_instr
    (call $fpush (f32.div (call $fpop) (call $fpop) ) )
  )

  (func $ffloor_instr
    (call $fpush (f32.floor (call $fpop) ) )
  )

  (func $ftoi_instr
    (call $push (i32.trunc_f32_s (call $fpop) ) )
  )

  (func $eq_instr
    (call $push (i32.eq (call $pop) (call $pop) ) )
  )

  (func $lt_instr
    (call $push (i32.lt_s (call $pop) (call $pop) ) )
  )

  (func $gt_instr
    (call $push (i32.gt_s (call $pop) (call $pop) ) )
  )

  (func $eqz_instr
    (call $push (i32.eqz (call $pop) ) )
  )

  (func $and_instr
    (call $push (i32.and (call $pop) (call $pop) ) )
  )

  (func $or_instr
    (call $push (i32.or (call $pop) (call $pop) ) )
  )

  (func $xor_instr
    (call $push (i32.xor (call $pop) (call $pop) ) )
  )

  (func $rot_instr
    (call $push (i32.rotr (call $pop) (call $pop) ) )
  )

  (func $feq_instr
    (call $push (f32.eq (call $fpop) (call $fpop) ) )
  )

  (func $flt_instr
    (call $push (f32.lt (call $fpop) (call $fpop) ) )
  )

  (func $fgt_instr
    (call $push (f32.gt (call $fpop) (call $fpop) ) )
  )

)