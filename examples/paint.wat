;;cyber asm

main:
(@vars
  $x (0)
  $y (0)
  $btn (0)
  $px (0xb800)
)

(store8 (0xb214) (2)) ;; display mode 2

(@while (lt ($px) (0x10000)) @do( ;; clear screen
  (store8 ($px) (0))
  (set $px (add ($px) (1)))
)@end)

(set $px (0))

(@while (true) @do( ;; paint!
  (@if (not ($btn)) @do(
    (store8 (add (0xb800) ($px)) (0x0))
  )@end)
  (set $x (div (load8u(0xb220)) (2)) )
  (set $y (div (load8u(0xb221)) (1)) )
  (set $btn (load8u(0xb222)) )
  (set $px (add ($x) (mult ($y) (0x80))) )
  (@if (or (lt ($px) (0)) (not (lt ($px) (0x4800)))) @do(
    (set $px (0))
  )@end)
  (@if ($btn) @do(
    (store8 (add (0xb800) ($px)) (0xff))
  )@else(
    (store8 (add (0xb800) ($px)) (0xf))
  )@end)

  (vsync)
)@end)

(return (0) (1))

