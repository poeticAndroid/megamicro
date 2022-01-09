;;cyber asm

main:
(@vars $x $y $btn $px)
(set $px (0xb800))

(store8 (0xb214) (2)) ;; display mode 2

(@while (lt ($px) (0x10000)) ( ;; clear screen
  (store8 ($px) (0))
  (set $px (add ($px) (1)))
) )

(set $px (0))

(@while (true) ( ;; paint!
  (@if (not ($btn)) (
    (store8 (add (0xb800) ($px)) (0x0))
  ) )
  (set $x (div (load8u(0xb220)) (2)) )
  (set $y (div (load8u(0xb221)) (1)) )
  (set $btn (load8u(0xb222)) )
  (set $px (add ($x) (mult ($y) (0x80))) )
  (@if (or (lt ($px) (0)) (not (lt ($px) (0x4800)))) (
    (set $px (0))
  ) )
  (@if ($btn) (
    (store8 (add (0xb800) ($px)) (0xff))
  )@else(
    (store8 (add (0xb800) ($px)) (0xf))
  ) )

  (vsync)
) )

(@return (0))

