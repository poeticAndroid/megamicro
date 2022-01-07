;;cyber asm

main:
(@vars
)

(@while (true) @do(
  (store8 (0xb214) (add (load8u(0xb214)) (1)))
  (sleep (0x400))
)@end)

(return (0) (1))

