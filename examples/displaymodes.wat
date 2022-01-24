;;petie asm

(main:

  (@while (true) (
    (store8 (0xb214) (add (load8u(0xb214)) (1)))
    (sleep (1000))
  ))

  (@return (0))
)
