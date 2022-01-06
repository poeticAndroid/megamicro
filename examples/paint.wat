;;cyber asm

main:
(@vars
  $x (0)
  $y (0)
  $btn (0)
  $px (0x7000)
)

(store8 (0x6b14) (0)) ;; display mode 0

(@while (lt ($px) (0x10000)) @do( ;; clear screen
  (store8 ($px) (0))
  (set $px (add ($px) (1)))
)@end)

(set $px (0))

(@while (true) @do( ;; paint!
  (@if (not ($btn)) @do(
    (store8 (add (0x7000) ($px)) (0x0))
  )@end)
  (set $x (div (load16u(0x6b20)) (4)) )
  (set $y (div (load16u(0x6b22)) (4)) )
  (set $btn (load8u(0x6b24)) )
  (set $px (add ($x) (mult ($y) (0x100))) )
  (@if (or (lt ($px) (0)) (not (lt ($px) (0x9000)))) @do(
    (set $px (0))
  )@end)
  (@if ($btn) @do(
    (store8 (add (0x7000) ($px)) (0xff))
  )@else(
    (store8 (add (0x7000) ($px)) (0xf))
  )@end)

  (vsync)
)@end)

(return (0) (1))

