;;cyber asm

main:

(@while (true) (
  (store8 (0xb214) (add (load8u(0xb214)) (1)))
  (sleep (0x400))
) )

(return (0) (1))

