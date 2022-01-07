;;cyber asm

main:
(@vars
)

(@while (true) @do(
  (store8 (0x6b14) (add (load8u(0x6b14)) (1)))
  (sleep (0x400))
)@end)

(return (0) (1))

