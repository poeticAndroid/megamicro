;;Peti asm

;; requires kernal at 0x400

(main:
  (@vars $argv
    $x $y $mx $my $btn)

  (store8 (0xb4f8) (7)) ;; display mode 6

  (@while (true) ( ;; paint!
    (@if (eqz ($btn)) (
      (sys (0x10) ($x) ($y) (0) (0x400) (4))
      (sys (0x10) ($mx) ($my) (0) (0x400) (4))
    ))
    (set $mx (div (load8u(0xb4f9)) (2)) )
    (set $my (div (load8u(0xb4fa)) (1)) )
    (set $btn (load8u(0xb4fb)) )

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

  (@return (0)) ;; return to dos with no error
)