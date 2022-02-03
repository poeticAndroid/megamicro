;;Peti asm

(main: ;; must be the first function
  (@vars $argv
    $chr)

  (store8 (0xb4f8) (3)) ;; display mode

  (sys (0x03) (@call memstart) (-1) (0x400) (3)) ;; printstr syscall
  (@while (lt ($chr) (0xa0) ) (
    (sys (0x02) ($chr) (0x400) (2)) ;; printchr syscall
    (set $chr (add ($chr) (1) ))
  ))

  (@return (0)) ;; return to dos with no error
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
(@string 0x10 "Hello world!\x9b\n\n")
