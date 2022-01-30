;;Peti asm

(main: ;; must be the first function
  (@vars $argv
    $i $cache)
  (set $i (-1))
  (set $cache (add (@call memstart) (0x400) ) )
  (@while (true) (
    (@while (lt ($i) (7) ) (
      (store8 (add ($cache) ($i) ) (load8u (add (0xb4e8) ($i) ) ) )
      (sys (0x09) (load8u (add ($cache) ($i) ) ) (10) (add (@call memstart) (0x300) ) (0x400) (4)) ;; inttostr
      (sys (0x02) (0x3a) (0x400) (2)) ;; printchar syscall
      (@if (eqz (load8u (add (@call memstart) (0x301) )) ) (
        (sys (0x02) (0x30) (0x400) (2)) ;; printchar syscall
      ))
      (sys (0x03) (add (@call memstart) (0x300) ) (0x400) (2)) ;; printstr syscall
      (set $i (add ($i) (1) ) )
    ))
    (set $i (sub ($i) (1) ) )
    (@while (eq (load8u (add ($cache) ($i) ) ) (load8u (add (0xb4e8) ($i) ) ) ) (
      (vsync)
    ))
    (@while (eqz (eq (load8u (add ($cache) ($i) ) ) (load8u (add (0xb4e8) ($i) ) ) ) ) (
      (sys (0x02) (0x08) (0x400) (2)) ;; printchar syscall
      (sys (0x02) (0x08) (0x400) (2)) ;; printchar syscall
      (sys (0x02) (0x08) (0x400) (2)) ;; printchar syscall
      (set $i (sub ($i) (1) ) )
    ))
    (set $i (add ($i) (1) ) )
  ))

  (@return (0)) ;; return to dos with no error
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
(@string 0x100 "Jan\0Feb\0Mar\0Apr\0May\0Jun\0Jul\0Aug\0Sep\0Oct\0Nov\0Dec\0")
(@string 0x100 "Sun\0Mon\0Tue\0Wed\0Thu\0Fri\0Sat\0")
(@string 0x400 "\0")
