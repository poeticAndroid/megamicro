;;Peti asm

;; requires kernal at 0x400

(main: ;; must be the first function
  (@vars $argv
    )
  (store8 (0xb282) (2)) ;; text bg color
  ;; (store8 (0xb283) (-1)) ;; text fg color
  
  (sys (0x13) (@call memstart) (0x400) (2))

  (@return (0)) ;; return to dos with no error
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)


(@string 0x10 "Hello world!\n")
