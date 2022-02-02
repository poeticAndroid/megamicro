;;Peti asm

;; requires kernal at 0x400

(main:
  (@vars $argv
    )
  (store8 (0xb4f8) (1)) ;; display mode
  (store8 (0xaffe) (1)) ;; text bg color
  (store8 (0xafff) (-1)) ;; text fg color
  
  (sys (0x02) (0x0a) (0x400) (2))
  (sys (0x02) (0x83) (0x400) (2))
  (sys (0x02) (0x08) (0x400) (2))

  (@while (true) (
    (@while (eqz (load (0xb4f4))) (
      (vsync)
    ))
    (@if (lt (load8u (0xb4f5)) (0x20)) (
      (sys (0x02) (0x20) (0x400) (2))
      (sys (0x02) (0x08) (0x400) (2))
    ))
    (sys (0x02) (load8u (0xb4f5)) (0x400) (2))
    (@if (eq (load8u (0xb4f5)) (0x0a)) (
      (sys (0x02) (0x21) (0x400) (2))
      (sys (0x02) (0x08) (0x400) (2))
    ))
    (store8 (0xaffe) (add (load8u (0xaffe)) (1) ))
    (sys (0x02) (0x20) (0x400) (2))
    (store8 (0xaffe) (sub (load8u (0xaffe)) (1) ))
    (sys (0x02) (0x08) (0x400) (2))
    (store (0xb4f4) (0))
  ))


  (@return (0)) ;; return to dos with no error
)