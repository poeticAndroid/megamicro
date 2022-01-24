;;Peti asm

(main:

  (@while (true) (
    (store8 (0xb240) (add (load8u(0xb240)) (1)))
    (sleep (1000))
  ))

  (@return (0))
)
