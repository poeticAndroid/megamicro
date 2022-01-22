;;cyber asm

;; requires kernal at 0x400

(main:
  (@vars $x $y $mx $my $btn)

  (store8 (0xb214) (6)) ;; display mode 6

  (@while (true) ( ;; paint!
    (@if (eqz ($btn)) (
      (sys (0x10) ($x) ($y) (0) (0x400) (4))
    ))
    (sys (0x10) ($mx) ($my) (0) (0x400) (4))
    (set $mx (mult (load8u(0xb220)) (1)) )
    (set $my (div (load8u(0xb221)) (1)) )
    (set $btn (load8u(0xb222)) )

    (@if (lt ($mx) ($x)) (set $x (sub ($x) (1))))
    (@if (gt ($mx) ($x)) (set $x (add ($x) (1))))
    (@if (lt ($my) ($y)) (set $y (sub ($y) (1))))
    (@if (gt ($my) ($y)) (set $y (add ($y) (1))))

    ;; (@if ($btn) (
      (sys (0x10) ($x) ($y) (2) (0x400) (4))
    ;; ))
      (sys (0x10) ($mx) ($my) (1) (0x400) (4))
    ;;))

    (vsync)
  ))

  (@return (0))
)