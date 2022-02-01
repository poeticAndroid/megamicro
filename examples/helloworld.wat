;;Peti asm

(main: ;; must be the first function
  (@vars $argv
    )
  (sys (0x03) (@call memstart) (-1) (0x400) (3)) ;; printstr syscall

  (@return (0)) ;; return to dos with no error
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
(@string 0xe "Hello world!\n")
