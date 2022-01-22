;;cyber asm

;; requires kernal at 0x400

(main:
  (@vars $x $y $btn)

  (store8 (0xb214) (1)) ;; display mode 2

  (@while (true) ( ;; paint!
    (@if (eqz ($btn)) (
      (sys (0x10) ($x) ($y) (0) (0x400) (4))
    ))
    (set $x (add (load8u(0xb220)) (128)) )
    (set $y (div (load8u(0xb221)) (1)) )
    (set $btn (load8u(0xb222)) )
    (@if ($btn) (
      (sys (0x10) ($x) ($y) (2) (0x400) (4))
    )(
      (sys (0x10) ($x) ($y) (1) (0x400) (4))
    ))

    (vsync)
  ))

  (@return (0))
)