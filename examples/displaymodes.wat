;;Peti asm

(main:

  (@while (true) (
    (store8 (0xb4f8) (add (load8u(0xb4f8)) (1)))
    (sleep (1000))
  ))

  (@return (0))
)
