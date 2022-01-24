;;petie asm

;; requires kernal at 0x400

(main:
  (@vars $argv
    )
  (store8 (0xb214) (1)) ;; display mode
  ;; (store8 (0xb282) (2)) ;; text bg color
  ;; (store8 (0xb283) (-1)) ;; text fg color
  
  (sys (0x12) (0x0a) (0x400) (2))
  (sys (0x12) (0x83) (0x400) (2))
  (sys (0x12) (0x08) (0x400) (2))

  (@while (true) (
    (@while (eqz (load8u (0xb210))) (
      (vsync)
    ))
    (@if (lt (load8u (0xb211)) (0x20)) (
      (sys (0x12) (0x20) (0x400) (2))
      (sys (0x12) (0x08) (0x400) (2))
    ))
    (sys (0x12) (load8u (0xb211)) (0x400) (2))
    (@if (eq (load8u (0xb211)) (0x0a)) (
      (sys (0x12) (0x21) (0x400) (2))
      (sys (0x12) (0x08) (0x400) (2))
    ))
    (store8 (0xb282) (add (load8u (0xb282)) (1) ))
    (sys (0x12) (0x20) (0x400) (2))
    (store8 (0xb282) (sub (load8u (0xb282)) (1) ))
    (sys (0x12) (0x08) (0x400) (2))
    (store (0xb210) (0))
  ))


  (@return (0)) ;; return to dos with no error
)