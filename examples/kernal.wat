;;Peti asm

;; kernal

(syscall:
  (@vars $call $arg1 $arg2 $arg3 $arg4 $arg5)

  (@if (eq ($call) (0x00)) ( (return (@call reboot ) (0)) ))

  (@if (eq ($call) (0x10)) ( (return (@call pset ($arg1) ($arg2) ($arg3)) (0)) ))
  (@if (eq ($call) (0x12)) ( (return (@call printchar ($arg1)) (0)) ))
  (@if (eq ($call) (0x13)) ( (return (@call printstr ($arg1)) (0)) ))

  (@if (eq ($call) (0x19)) ( (return (@call scrndepth ) (1)) ))
  (@if (eq ($call) (0x1a)) ( (return (@call scrnwidth ) (1)) ))
  (@if (eq ($call) (0x1b)) ( (return (@call scrnheight ) (1)) ))
)

(reboot:
  (reset)
  (@vars $adr)
  (sleep (0x400))
  (set $adr (0xb200))
  (@while (lt ($adr) (0x10000)) (
    (store ($adr) (0))
    (set $adr (add ($adr) (4)))
  ))

  (@call intro)
  (@if (eq (load8u (0x10000)) (0x10) ) (
    (sys (0) (0x10000) (1))
  ))
  (@call typist)
  (@jump reboot)
)

(intro:
  (store8 (0xb283) (-1)) ;; text fg color
  (store8 (0xb240) (1)) ;; display mode
  (@call printstr (@call memstart))
  (store8 (0xb240) (0)) ;; display mode
  (sleep (0x400))
  (@return)
)

(typist:
  (@call printstr (add (@call memstart) (0x20) ))
  (@while (true) (
    (@while (eqz (load8u (0xb210))) (
      (vsync)
    ))
    (@call printchar (load8u (0xb211)) )
    (store (0xb210) (0))
  ))
  (@return)
)

(pset:
  (@vars $x $y $c
    $adr $bit
  )
  (@if (lt ($x) (0)) ( (@return) ))
  (@if (lt ($y) (0)) ( (@return) ))

  (jump (mult (and (7) (load8u (0xb240))) (0xc6) ))
  ;; mode 0
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (1) (rem ($adr) (8) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (8) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-1)) ) ;; 8 - bits/pixel
    (and (-2) ) ;; -colors
    (xor (and ($c) (1)) ) ;; colors-1
    (rot (sub (8-1) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 1
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (2) (rem ($adr) (4) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (4) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-2)) ) ;; 8 - bits/pixel
    (and (-4) ) ;; -colors
    (xor (and ($c) (3)) ) ;; colors-1
    (rot (sub (8-2) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 2
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (4) (rem ($adr) (2) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (2) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-4)) ) ;; 8 - bits/pixel
    (and (-16) ) ;; -colors
    (xor (and ($c) (15)) ) ;; colors-1
    (rot (sub (8-4) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 3
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (71)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (8) (rem ($adr) (1) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (1) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-8)) ) ;; 8 - bits/pixel
    (and (-256) ) ;; -colors
    (xor (and ($c) (255)) ) ;; colors-1
    (rot (sub (8-8) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)

  ;; mode 4
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (1) (rem ($adr) (8) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (8) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-1)) ) ;; 8 - bits/pixel
    (and (-2) ) ;; -colors
    (xor (and ($c) (1)) ) ;; colors-1
    (rot (sub (8-1) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 5
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (2) (rem ($adr) (4) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (4) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-2)) ) ;; 8 - bits/pixel
    (and (-4) ) ;; -colors
    (xor (and ($c) (3)) ) ;; colors-1
    (rot (sub (8-2) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 6
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (4) (rem ($adr) (2) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (2) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-4)) ) ;; 8 - bits/pixel
    (and (-16) ) ;; -colors
    (xor (and ($c) (15)) ) ;; colors-1
    (rot (sub (8-4) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 7
  (@if (gt ($x) (127)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (128) ($y))) ) ;; width
  (set $bit (mult (8) (rem ($adr) (1) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (1) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-8)) ) ;; 8 - bits/pixel
    (and (-256) ) ;; -colors
    (xor (and ($c) (255)) ) ;; colors-1
    (rot (sub (8-8) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
)

(printchar:
  (@vars $char
    $x1 $y1 $x2 $y2 $x $y $adr $bits)
  (@if (eq ($char) (0x08)) ( ;; backspace
    (store8 (0xb280) (sub (load8s (0xb280)) (1) ) )
    (@if (lt (load8s (0xb280)) (0)) (
      (store8 (0xb280) (div (@call scrnwidth) (8)))
      (store8 (0xb281) (sub (load8s (0xb281)) (1) ) )
      (@if (lt (load8s (0xb281)) (0)) (
        (store16 (0xb280) (0) )
      ))
    ))
    (@return)
  ))
  (@if (eq ($char) (0x09)) ( ;; tab
    (store8 (0xb280) (add (load8u (0xb280)) (1) ) )
    (@while (rem (load8u (0xb280)) (8)) (
      (store8 (0xb280) (add (load8u (0xb280)) (1) ) )
    ))
    (@return)
  ))
  (@if (eq ($char) (0x0a)) ( ;; newline
    (store8 (0xb280) (0) )
    (store8 (0xb281) (add (load8u (0xb281)) (1) ) )
    (@return)
  ))
  (@if (eq ($char) (0x0d)) ( ;; carriage return
    (store8 (0xb280) (0) )
    (@return)
  ))
  (@if (lt ($char) (0x20)) (@return))
  (set $x1 (mult (load8u (0xb280)) (8) ))
  (@if (gt ($x1) (@call scrnwidth)) (
    (store8 (0xb280) (0) )
    (store8 (0xb281) (add (load8u (0xb281)) (1) ) )
    (set $x1 (0))
  ))
  (set $x2 (add ($x1) (8)))
  (set $y1 (mult (load8u (0xb281)) (8) ))
  (@while (gt ($y1) (@call scrnheight)) (
    (store8 (0xb281) (sub (load8u (0xb281)) (1) ) )
    (set $y1 (sub ($y1) (8)))
    (set $adr (add ($adr) (8)))
  ))
  (@call scroll ($adr))
  (set $y2 (add ($y1) (8)))
  (set $adr (add (0xae00) (mult (and ($char) (127)) (8))))
  (set $y ($y1))
  (@while (lt ($y) ($y2)) (
    (set $bits (rot (load8u ($adr)) (-8) ))
    (set $x ($x1))
    (@while (lt ($x) ($x2)) (
      (set $bits (rot ($bits) (1) ))
      (@call pset ($x) ($y) (load8u (add (0xb282) (and ($bits) (1)) )))
      (set $x (add ($x) (1)))
    ))
    (set $adr (add ($adr) (1)))
    (set $y (add ($y) (1)))
  ))
  (store8 (0xb280) (add (load8u (0xb280)) (1) ) )
  (@return)
)

(printstr:
  (@vars $str)
  (@while (load8u ($str)) (
    (@call printchar (load8u ($str)))
    (set $str (add ($str) (1)))
  ))
  (@return)
)

(scroll:
  (@vars $px
    $adr $offset $end)
  (@if (eqz ($px)) (@return))
  (set $adr (0xb800))
  (set $offset (mult ($px) (@call scrnbytew)))
  (set $end (sub (0x10000) ($offset) ))
  (@while (lt ($adr) ($end)) (
    (store ($adr) (load (add ($adr) ($offset))))
    (set $adr (add ($adr) (4)))
  ))
  (set $end (@call scrnheight))
  (set $px (@call scrnwidth))
  (set $offset (32))
  (@while ($offset) (
    (@call pset ($px) ($end) (load8u (0xb282)))
    (set $px (sub ($px) (1)))
    (set $offset (sub ($offset) (1)))
  ))
  (@while (lt ($adr) (0xfffc)) (
    (store ($adr) (load (0xfffc)))
    (set $adr (add ($adr) (4)))
  ))
  (@return)
)

(scrndepth:
  (jump (mult (and (3) (load8u (0xb240))) (0xb) ))
  ;; modes 0 and 4
  (@return (1))
  ;; modes 1 and 5
  (@return (3))
  ;; modes 2 and 6
  (@return (15))
  ;; modes 3 and 7
  (@return (255))
)

(scrnwidth:
  (jump (mult (and (7) (load8u (0xb240))) (0xb) ))
  ;; mode 0
  (@return (511))
  ;; mode 1
  (@return (511))
  ;; mode 2
  (@return (255))
  ;; mode 3
  (@return (255))

  ;; mode 4
  (@return (511))
  ;; mode 5
  (@return (255))
  ;; mode 6
  (@return (255))
  ;; mode 7
  (@return (127))
)

(scrnheight:
  (jump (mult (and (7) (load8u (0xb240))) (0xb) ))
  ;; mode 0
  (@return (287))
  ;; mode 1
  (@return (143))
  ;; mode 2
  (@return (143))
  ;; mode 3
  (@return (71))

  ;; mode 4
  (@return (287))
  ;; mode 5
  (@return (287))
  ;; mode 6
  (@return (143))
  ;; mode 7
  (@return (143))
)


(scrnbytew:
  (jump (mult (and (7) (load8u (0xb240))) (0xb) ))
  ;; mode 0
  (@return (512/8))
  ;; mode 1
  (@return (512/4))
  ;; mode 2
  (@return (256/2))
  ;; mode 3
  (@return (256/1))

  ;; mode 4
  (@return (512/8))
  ;; mode 5
  (@return (256/4))
  ;; mode 6
  (@return (256/2))
  ;; mode 7
  (@return (128/1))
)


(pow:
  (@vars $a $b $z)
  (set $z (1))
  (@while (gt ($b) (0)) (
    (set $z (mult ($z) ($a)))
    (set $b (sub ($b) (1)))
  ) )
  (@return ($z))
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
;; 0x0
(@string 0x20 "\t /// Peti-9 ///\n\n")
;; 0x20
(@string 0x10 "\nReady.\n")
;; 0x30

(@skipto 0xaa00)
(@bytes ;; system font
  ;; g00
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g01
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  ;; g02
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  ;; g03
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  ;; g04
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g05
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  ;; g06
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  ;; g07
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  ;; g08
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g09
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  ;; g0a
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  ;; g0b
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  ;; g0c
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g0d
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b00001111
  0b00001111
  0b00001111
  0b00001111
  ;; g0e
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b11110000
  0b11110000
  0b11110000
  0b11110000
  ;; g0f
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  0b11111111
  ;; g10
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g11
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; g12
  0b00000000
  0b00000000
  0b00000000
  0b00001111
  0b00001111
  0b00000000
  0b00000000
  0b00000000
  ;; g13
  0b00011000
  0b00011000
  0b00011000
  0b00011111
  0b00001111
  0b00000000
  0b00000000
  0b00000000
  ;; g14
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  ;; g15
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  ;; g16
  0b00000000
  0b00000000
  0b00000000
  0b00001111
  0b00011111
  0b00011000
  0b00011000
  0b00011000
  ;; g17
  0b00011000
  0b00011000
  0b00011000
  0b00011111
  0b00011111
  0b00011000
  0b00011000
  0b00011000
  ;; g18
  0b00000000
  0b00000000
  0b00000000
  0b11110000
  0b11110000
  0b00000000
  0b00000000
  0b00000000
  ;; g19
  0b00011000
  0b00011000
  0b00011000
  0b11111000
  0b11110000
  0b00000000
  0b00000000
  0b00000000
  ;; g1a
  0b00000000
  0b00000000
  0b00000000
  0b11111111
  0b11111111
  0b00000000
  0b00000000
  0b00000000
  ;; g1b
  0b00011000
  0b00011000
  0b00011000
  0b11111111
  0b11111111
  0b00000000
  0b00000000
  0b00000000
  ;; g1c
  0b00000000
  0b00000000
  0b00000000
  0b11110000
  0b11111000
  0b00011000
  0b00011000
  0b00011000
  ;; g1d
  0b00011000
  0b00011000
  0b00011000
  0b11111000
  0b11111000
  0b00011000
  0b00011000
  0b00011000
  ;; g1e
  0b00000000
  0b00000000
  0b00000000
  0b11111111
  0b11111111
  0b00011000
  0b00011000
  0b00011000
  ;; g1f
  0b00011000
  0b00011000
  0b00011000
  0b11111111
  0b11111111
  0b00011000
  0b00011000
  0b00011000
  ;; space
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; !
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  0b00011000
  0b00000000
  ;; "
  0b01100110
  0b01100110
  0b01100110
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; #
  0b00110110
  0b01111111
  0b00110110
  0b00110110
  0b00110110
  0b01111111
  0b00110110
  0b00000000
  ;; $
  0b00011000
  0b00111110
  0b01100000
  0b00111100
  0b00000110
  0b01111100
  0b00011000
  0b00000000
  ;; %
  0b01100010
  0b01100110
  0b00001100
  0b00011000
  0b00110000
  0b01100110
  0b01000110
  0b00000000
  ;; &
  0b00011100
  0b00110110
  0b00110110
  0b00011100
  0b00110111
  0b01100110
  0b00111111
  0b00000000
  ;; '
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; (
  0b00001100
  0b00011000
  0b00110000
  0b00110000
  0b00110000
  0b00011000
  0b00001100
  0b00000000
  ;; )
  0b00110000
  0b00011000
  0b00001100
  0b00001100
  0b00001100
  0b00011000
  0b00110000
  0b00000000
  ;; *
  0b01101100
  0b00111000
  0b11111110
  0b00111000
  0b01101100
  0b00000000
  0b00000000
  0b00000000
  ;; +
  0b00000000
  0b00001000
  0b00001000
  0b00111110
  0b00001000
  0b00001000
  0b00000000
  0b00000000
  ;; ,
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00011000
  0b00011000
  0b00110000
  0b00000000
  ;; -
  0b00000000
  0b00000000
  0b00000000
  0b01111110
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; .
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00011000
  0b00011000
  0b00000000
  ;; /
  0b00000010
  0b00000110
  0b00001100
  0b00011000
  0b00110000
  0b01100000
  0b01000000
  0b00000000
  ;; 0
  0b00111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; 1
  0b00011000
  0b00111000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b01111110
  0b00000000
  ;; 2
  0b00111100
  0b01100110
  0b00000110
  0b00011100
  0b00110000
  0b01100000
  0b01111110
  0b00000000
  ;; 3
  0b00111100
  0b01100110
  0b00000110
  0b00011100
  0b00000110
  0b01100110
  0b00111100
  0b00000000
  ;; 4
  0b00011100
  0b00111100
  0b01101100
  0b01101100
  0b01111110
  0b00001100
  0b00011110
  0b00000000
  ;; 5
  0b01111110
  0b01100000
  0b01111100
  0b00000110
  0b00000110
  0b01100110
  0b00111100
  0b00000000
  ;; 6
  0b00111100
  0b01100110
  0b01100000
  0b01111100
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; 7
  0b01111110
  0b00000110
  0b00001100
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  ;; 8
  0b00111100
  0b01100110
  0b01100110
  0b00111100
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; 9
  0b00111100
  0b01100110
  0b01100110
  0b00111110
  0b00000110
  0b01100110
  0b00111100
  0b00000000
  ;; :
  0b00000000
  0b00011000
  0b00011000
  0b00000000
  0b00011000
  0b00011000
  0b00000000
  0b00000000
  ;; ;
  0b00000000
  0b00011000
  0b00011000
  0b00000000
  0b00011000
  0b00011000
  0b00010000
  0b00000000
  ;; <
  0b00000110
  0b00001100
  0b00011000
  0b00110000
  0b00011000
  0b00001100
  0b00000110
  0b00000000
  ;; =
  0b00000000
  0b00000000
  0b01111110
  0b00000000
  0b01111110
  0b00000000
  0b00000000
  0b00000000
  ;; >
  0b00110000
  0b00011000
  0b00001100
  0b00000110
  0b00001100
  0b00011000
  0b00110000
  0b00000000
  ;; ?
  0b00111100
  0b01000110
  0b00000110
  0b00011100
  0b00011000
  0b00000000
  0b00011000
  0b00000000
  ;; @
  0b00111100
  0b01000010
  0b10011001
  0b10100101
  0b10100101
  0b10011110
  0b01000000
  0b00111100
  ;; A
  0b00111100
  0b01100110
  0b01100110
  0b01111110
  0b01100110
  0b01100110
  0b01100110
  0b00000000
  ;; B
  0b01111100
  0b01100110
  0b01100110
  0b01111100
  0b01100110
  0b01100110
  0b01111100
  0b00000000
  ;; C
  0b00111100
  0b01100110
  0b01100000
  0b01100000
  0b01100000
  0b01100110
  0b00111100
  0b00000000
  ;; D
  0b01111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01111100
  0b00000000
  ;; E
  0b01111110
  0b01100000
  0b01100000
  0b01111000
  0b01100000
  0b01100000
  0b01111110
  0b00000000
  ;; F
  0b01111110
  0b01100000
  0b01100000
  0b01111000
  0b01100000
  0b01100000
  0b01100000
  0b00000000
  ;; G
  0b00111100
  0b01100110
  0b01100000
  0b01101110
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; H
  0b01100110
  0b01100110
  0b01100110
  0b01111110
  0b01100110
  0b01100110
  0b01100110
  0b00000000
  ;; I
  0b00111100
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00111100
  0b00000000
  ;; J
  0b00000110
  0b00000110
  0b00000110
  0b00000110
  0b00000110
  0b01100110
  0b00111100
  0b00000000
  ;; K
  0b01100110
  0b01101100
  0b01111000
  0b01110000
  0b01111000
  0b01101100
  0b01100110
  0b00000000
  ;; L
  0b01100000
  0b01100000
  0b01100000
  0b01100000
  0b01100000
  0b01100000
  0b01111110
  0b00000000
  ;; M
  0b11000110
  0b11101110
  0b11111110
  0b11010110
  0b11000110
  0b11000110
  0b11000110
  0b00000000
  ;; N
  0b01100110
  0b01100110
  0b01110110
  0b01111110
  0b01101110
  0b01100110
  0b01100110
  0b00000000
  ;; O
  0b00111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; P
  0b01111100
  0b01100110
  0b01100110
  0b01111100
  0b01100000
  0b01100000
  0b01100000
  0b00000000
  ;; Q
  0b00111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00000110
  ;; R
  0b01111100
  0b01100110
  0b01100110
  0b01111100
  0b01111000
  0b01101100
  0b01100110
  0b00000000
  ;; S
  0b00111100
  0b01100110
  0b01100000
  0b00111100
  0b00000110
  0b01100110
  0b00111100
  0b00000000
  ;; T
  0b01111110
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  ;; U
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; V
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00011000
  0b00000000
  ;; W
  0b11000110
  0b11000110
  0b11000110
  0b11010110
  0b11111110
  0b11101110
  0b11000110
  0b00000000
  ;; X
  0b01100110
  0b01100110
  0b00111100
  0b00011000
  0b00111100
  0b01100110
  0b01100110
  0b00000000
  ;; Y
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  ;; Z
  0b01111110
  0b00000110
  0b00001100
  0b00011000
  0b00110000
  0b01100000
  0b01111110
  0b00000000
  ;; [
  0b00111100
  0b00110000
  0b00110000
  0b00110000
  0b00110000
  0b00110000
  0b00111100
  0b00000000
  ;; \
  0b01000000
  0b01100000
  0b00110000
  0b00011000
  0b00001100
  0b00000110
  0b00000010
  0b00000000
  ;; ]
  0b00111100
  0b00001100
  0b00001100
  0b00001100
  0b00001100
  0b00001100
  0b00111100
  0b00000000
  ;; ^
  0b00001000
  0b00011100
  0b00110110
  0b00100010
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; _
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b11111111
  ;; `
  0b00011000
  0b00001100
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  0b00000000
  ;; a
  0b00000000
  0b00000000
  0b00111100
  0b00000110
  0b00111110
  0b01100110
  0b00111110
  0b00000000
  ;; b
  0b01100000
  0b01100000
  0b01111100
  0b01100110
  0b01100110
  0b01100110
  0b01111100
  0b00000000
  ;; c
  0b00000000
  0b00000000
  0b00111100
  0b01100110
  0b01100000
  0b01100110
  0b00111100
  0b00000000
  ;; d
  0b00000110
  0b00000110
  0b00111110
  0b01100110
  0b01100110
  0b01100110
  0b00111110
  0b00000000
  ;; e
  0b00000000
  0b00000000
  0b00111100
  0b01100110
  0b01111100
  0b01100000
  0b00111110
  0b00000000
  ;; f
  0b00001110
  0b00011000
  0b00111100
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00000000
  ;; g
  0b00000000
  0b00000000
  0b00111110
  0b01100110
  0b01100110
  0b00111110
  0b00000110
  0b00111100
  ;; h
  0b01100000
  0b01100000
  0b01111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00000000
  ;; i
  0b00011000
  0b00000000
  0b00111000
  0b00011000
  0b00011000
  0b00011000
  0b00111100
  0b00000000
  ;; j
  0b00000110
  0b00000000
  0b00001110
  0b00000110
  0b00000110
  0b00000110
  0b01100110
  0b00111100
  ;; k
  0b01100000
  0b01100000
  0b01100110
  0b01101100
  0b01111000
  0b01101100
  0b01100110
  0b00000000
  ;; l
  0b00011100
  0b00001100
  0b00001100
  0b00001100
  0b00001100
  0b00001100
  0b00011110
  0b00000000
  ;; m
  0b00000000
  0b00000000
  0b11101100
  0b11111110
  0b11010110
  0b11010110
  0b11010110
  0b00000000
  ;; n
  0b00000000
  0b00000000
  0b01111100
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00000000
  ;; o
  0b00000000
  0b00000000
  0b00111100
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00000000
  ;; p
  0b00000000
  0b00000000
  0b01111100
  0b01100110
  0b01100110
  0b01100110
  0b01111100
  0b01100000
  ;; q
  0b00000000
  0b00000000
  0b00111110
  0b01100110
  0b01100110
  0b01100110
  0b00111110
  0b00000110
  ;; r
  0b00000000
  0b00000000
  0b01101110
  0b01110000
  0b01100000
  0b01100000
  0b01100000
  0b00000000
  ;; s
  0b00000000
  0b00000000
  0b00111110
  0b01100000
  0b00111100
  0b00000110
  0b01111100
  0b00000000
  ;; t
  0b00011000
  0b00011000
  0b00111100
  0b00011000
  0b00011000
  0b00011000
  0b00001100
  0b00000000
  ;; u
  0b00000000
  0b00000000
  0b01100110
  0b01100110
  0b01100110
  0b01100110
  0b00111110
  0b00000000
  ;; v
  0b00000000
  0b00000000
  0b01100110
  0b01100110
  0b01100110
  0b00111100
  0b00011000
  0b00000000
  ;; w
  0b00000000
  0b00000000
  0b11010110
  0b11010110
  0b11111110
  0b01111100
  0b01101100
  0b00000000
  ;; x
  0b00000000
  0b00000000
  0b01100110
  0b00111100
  0b00011000
  0b00111100
  0b01100110
  0b00000000
  ;; y
  0b00000000
  0b00000000
  0b01100110
  0b01100110
  0b01100110
  0b00111110
  0b00000110
  0b00111100
  ;; z
  0b00000000
  0b00000000
  0b01111110
  0b00001100
  0b00011000
  0b00110000
  0b01111110
  0b00000000
  ;; {
  0b00001100
  0b00011000
  0b00011000
  0b00110000
  0b00011000
  0b00011000
  0b00001100
  0b00000000
  ;; |
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  0b00011000
  ;; }
  0b00110000
  0b00011000
  0b00011000
  0b00001100
  0b00011000
  0b00011000
  0b00110000
  0b00000000
  ;; ~
  0b00000000
  0b00000000
  0b00110000
  0b01101011
  0b00000110
  0b00000000
  0b00000000
  0b00000000
)
