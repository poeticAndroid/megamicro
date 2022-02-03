;;Peti asm

(main: ;; must be the first function
  (@vars $argv
    $mode $cols $i)
  (sys (0x03) (add (@call memstart) (0x10)) (-1) (0x400) (3))
  (@while (true) (
    (@while (eqz (load8u (0xb4f4))) (
      (vsync)
    ))
    (set $mode (and (sub (load8u (0xb4f5) ) (0x30) ) (0x7) ) )
    (store8 (0xb4f8) ($mode))
    (store8 (0xaffd) (100))
    (sys (0x03) (@call memstart) (-1) (0x400) (3))
    (@call printhex ($mode) (1))
    (sys (0x02) (0x0a) (0x400) (2))
    (set $cols (add (sys (0x19) (0x400) (1)) (1) ))
    (set $i (0))
    (@while (lt ($i) ($cols) ) (
      (store8 (0xaffe) ($i))
      (store8 (0xafff) (xor ($i) (-1) ))
      (@call printhex ($i) (@if (eq (and ($mode) (3)) (3)) (2) (1) ) )
      (set $i (add ($i) (1) ))
    ))
    (store8 (0xaffe) (0))
    (store8 (0xafff) (-1))
    (sys (0x02) (0x0a) (0x400) (2))

    (store (0xb4f4) (0))
  ))

  (@return (0)) ;; return to dos with no error
)

(printhex:
  (@vars $int $digs
    $i)
  (@while (lt ($i) ($digs) ) (
    (store (add (add (@call memstart) (0x400) ) ($i) ) (0x30303030) )
    (set $i (add ($i) (1) ))
  ))
  (@while (load8u (add (add (@call memstart) (0x400) ) ($digs) )) (
    (sys (0x09) ($int) (16) (add (add (@call memstart) (0x400) ) ($i) ) (0x400) (4))
    (set $i (sub ($i) (1) ))
  ))
  (sys (0x03) (add (@call memstart) (0x400) ) (-1) (0x400) (3))
  (@return)
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)

;; 0x0
(@string 0x10 "Mode ")
;; 0x10
(@string 0x10 "Press a number\n")
;; 0x20
