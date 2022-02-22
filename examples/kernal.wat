;;Peti asm

;; kernal

(syscall:
  (@vars $call $arg1 $arg2 $arg3 $arg4 $arg5)

  ;; System
  (@if (eq ($call) (0x00)) ( (return (@call reboot ) (0)) ))
  (@if (eq ($call) (0x02)) ( (return (@call printchar ($arg1)) (0)) ))
  (@if (eq ($call) (0x03)) ( (return (@call printstr ($arg1) ($arg2)) (0)) ))
  (@if (eq ($call) (0x04)) ( (return (@call memcopy ($arg1) ($arg2) ($arg3)) (0)) ))
  (@if (eq ($call) (0x05)) ( (return (@call fill ($arg1) ($arg2) ($arg3)) (0)) ))
  (@if (eq ($call) (0x08)) ( (return (@call strtoint ($arg1) ($arg2)) (1)) ))
  (@if (eq ($call) (0x09)) ( (return (@call inttostr ($arg1) ($arg2) ($arg3)) (0)) ))

  ;; Graphics
  (@if (eq ($call) (0x10)) ( (return (@call pset ($arg1) ($arg2) ($arg3)) (0)) ))

  (@if (eq ($call) (0x19)) ( (return (@call scrndepth ) (1)) ))
  (@if (eq ($call) (0x1a)) ( (return (@call scrnwidth ) (1)) ))
  (@if (eq ($call) (0x1b)) ( (return (@call scrnheight ) (1)) ))

  ;; Math
  (@if (eq ($call) (0x20)) ( (return (@call pow ($arg1) ($arg2) ) (1)) ))

  ;; Files
  (@if (eq ($call) (0x30)) ( (return (@call load ($arg1) ($arg2) ) (1)) ))
  (@if (eq ($call) (0x31)) ( (return (@call save ($arg1) ($arg2) ($arg3) ) (1)) ))
  (@if (eq ($call) (0x32)) ( (return (@call delete ($arg1) ) (1)) ))
  (@if (eq ($call) (0x34)) ( (return (@call info ($arg1) ($arg2) ) (1)) ))
  (@if (eq ($call) (0x38)) ( (return (@call list ($arg1) ($arg2) ) (1)) ))
  (@if (eq ($call) (0x39)) ( (return (@call mkdir ($arg1) ) (1)) ))
  (@if (eq ($call) (0x3a)) ( (return (@call cd ($arg1) ) (1)) ))
)

(reboot:
  (reset)
  (@vars $adr $val)
  (sleep (0x100))
  (set $adr (0xb400))
  (set $val (0x00010203))
  (@while (lt ($adr) (0x10000)) (
    (store ($adr) ($val))
    (set $val (add ($val) (0x04040404)))
    (set $adr (add ($adr) (4)))
  ))
  (@call fill (0) (0xb400) (0x10000-0xb400))

  (@call intro)
  (@call launcher)
  (@jump reboot)
)

(intro:
  (@vars
    $sec $ins)
  (store (0xaffc) (0))
  (store8 (0xafff) (-1)) ;; text fg color
  (store8 (0xb4f8) (1)) ;; display mode
  (@call printstr (@call memstart) (-1))
  (store8 (0xb4f8) (0)) ;; display mode
  (set $sec (load8u (0xb4ee)))
  (@while (eq ($sec) (load8u (0xb4ee)) ) (noop))
  (set $sec (load8u (0xb4ee)))
  (@while (eq ($sec) (load8u (0xb4ee)) ) (
    (set $ins (add ($ins) (15) ))
  ))
  (@call inttostr ($ins) (10) (add (@call memstart) (0x90) ) )
  (@call printstr (add (@call memstart) (0x90) ) (-1))
  (@call printstr (add (@call memstart) (0x190) ) (-1)) ;; ips
  (@call inttostr (sub (memsize) (0x10000)) (10) (add (@call memstart) (0x90) ) )
  (@call printstr (add (@call memstart) (0x90) ) (-1))
  (@call printstr (add (@call memstart) (0x70) ) (-1)) ;; bytes free
  (@call printchar (0x0a))
  (sleep (0x100))
  (@return)
)

(launcher:
  (@while (load (0xb4f4)) (
    (store (0xb4f4) (0))
    (vsync)
  ))
  (@call printstr (add (@call memstart) (0x40) ) (-1))
  (@call memcopy (add (@call memstart) (0x1d0) ) (add (@call memstart) (0x90) ) (0x20))
  (@while (true) (
    (@if (@call load (add (@call memstart) (0x90) ) (0x10000)) (
      (sys (0) (0x10000) (1))
    )(
      (@call printstr (add (@call memstart) (0x90) ) (-1))
      (@call printchar (0x3a))
      (@call printchar (0x20))
      (@call printstr (add (@call memstart) (0x1b0) ) (-1))
    ))
    (@call printchar (0x3e))
    (@call printchar (0x20))
    (@call memcopy (add (@call memstart) (0x1d0) ) (add (@call memstart) (0x90) ) (0x20))
    (@call readln (0x10) (add (@call memstart) (0x98) ))
  ))
  (@return)
)

(printchar:
  (@vars $char
    $x1 $y1 $x2 $y2 $x $y $adr $bits)
  (@if (eq ($char) (0x08)) ( ;; backspace
    (store8 (0xaffc) (sub (load8s (0xaffc)) (1) ) )
    (@if (lt (load8s (0xaffc)) (0)) (
      (store8 (0xaffc) (div (@call scrnwidth) (8)))
      (store8 (0xaffd) (sub (load8s (0xaffd)) (1) ) )
      (@if (lt (load8s (0xaffd)) (0)) (
        (store16 (0xaffc) (0) )
      ))
    ))
    (@return)
  ))
  (@if (eq ($char) (0x09)) ( ;; tab
    (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
    (@while (rem (load8u (0xaffc)) (8)) (
      (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
    ))
    (@return)
  ))
  (@if (eq ($char) (0x0a)) ( ;; newline
    (store8 (0xaffc) (0) )
    (store8 (0xaffd) (add (load8u (0xaffd)) (1) ) )
    (@return)
  ))
  (@if (eq ($char) (0x0d)) ( ;; carriage return
    (store8 (0xaffc) (0) )
    (@return)
  ))
  (@if (lt ($char) (0x20)) (@return))
  (set $x1 (mult (load8u (0xaffc)) (8) ))
  (@if (gt ($x1) (@call scrnwidth)) (
    (store8 (0xaffc) (0) )
    (store8 (0xaffd) (add (load8u (0xaffd)) (1) ) )
    (set $x1 (0))
  ))
  (set $x2 (add ($x1) (8)))
  (set $y1 (mult (load8u (0xaffd)) (8) ))
  (@while (gt ($y1) (@call scrnheight)) (
    (store8 (0xaffd) (sub (load8u (0xaffd)) (1) ) )
    (set $y1 (sub ($y1) (8)))
    (set $adr (add ($adr) (8)))
  ))
  (@call scroll ($adr))
  (set $y2 (add ($y1) (8)))
  (set $adr (add (0xb000) (mult (and ($char) (127)) (8))))
  (set $y ($y1))
  (@while (lt ($y) ($y2)) (
    (set $bits (rot (load8u ($adr)) (-8) ))
    (set $x ($x1))
    (@while (lt ($x) ($x2)) (
      (set $bits (rot ($bits) (1) ))
      (@call pset ($x) ($y) (load8u (add (0xaffe) (and ($bits) (1)) )))
      (set $x (add ($x) (1)))
    ))
    (set $adr (add ($adr) (1)))
    (set $y (add ($y) (1)))
  ))
  (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
  (@return)
)

(printstr:
  (@vars $str $max)
  (@while (and (eqz (eqz ($max))) (eqz (eqz (load8u ($str)) ))) (
    (@call printchar (load8u ($str)))
    (set $max (sub ($max) (1)))
    (set $str (add ($str) (1)))
  ))
  (@return)
)

(memcopy:
  (@vars $src $dest $len)
  (@if (gt ($src) ($dest)) (
    (@while (gt ($len) (3)) (
      (store ($dest) (load ($src)))
      (set $src (add ($src) (4)))
      (set $dest (add ($dest) (4)))
      (set $len (sub ($len) (4)))
    ))
    (@while ($len) (
      (store8 ($dest) (load ($src)))
      (set $src (add ($src) (1)))
      (set $dest (add ($dest) (1)))
      (set $len (sub ($len) (1)))
    ))
  ))
  (@if (lt ($src) ($dest)) (
    (set $src (add ($src) ($len)))
    (set $dest (add ($dest) ($len)))
    (@while (gt ($len) (3)) (
      (set $src (sub ($src) (4)))
      (set $dest (sub ($dest) (4)))
      (store ($dest) (load ($src)))
      (set $len (sub ($len) (4)))
    ))
    (@while ($len) (
      (set $src (sub ($src) (1)))
      (set $dest (sub ($dest) (1)))
      (store8 ($dest) (load ($src)))
      (set $len (sub ($len) (1)))
    ))
  ))
  (@return)
)

(fill:
  (@vars $val $dest $len)
  (@while (gt ($len) (3)) (
    (store ($dest) ($val))
    (set $dest (add ($dest) (4)))
    (set $len (sub ($len) (4)))
  ))
  (@while ($len) (
    (store8 ($dest) ($val))
    (set $val (rot ($val) (8)))
    (set $dest (add ($dest) (1)))
    (set $len (sub ($len) (1)))
  ))
  (@return)
)

(strtoint:
  (@vars $str $base
    $int $fact $i $digs)
  (set $digs (add (@call memstart) (0x50)))
  (set $fact (1))
  (@if (eq (load8u ($str)) (0x2d) ) ( ;; minus
    (set $fact (-1))
    (set $str (add ($str) (1)))
  ))
  (@while (load8u ($str)) (
    (@if (eq ($base) (10) ) (
      (@if (eq (load8u ($str)) (0x62) ) ( ;; b
        (set $base (2))
      ))
      (@if (eq (load8u ($str)) (0x6f) ) ( ;; o
        (set $base (8))
      ))
      (@if (eq (load8u ($str)) (0x78) ) ( ;; x
        (set $base (16))
      ))
    ))
    (set $i (0))
    (@while (lt ($i) ($base) ) (
      (@if (or 
        (eq (load8u ($str)) (load8u (add ($digs) ($i) )) )
        (eq (add (load8u ($str)) (0x20) ) (load8u (add ($digs) ($i) )) )
      ) (
        (set $int (mult ($int) ($base) ))
        (set $int (add ($int) ($i) ))
        (set $i ($base))
      ))
      (set $i (add ($i) (1) ))
    ))
    (@if (eq ($i) ($base)) (
      (@return (mult ($int) ($fact)))
    ))
    (set $str (add ($str) (1)))
  ))
  (@return (mult ($int) ($fact)))
)

(inttostr:
  (@vars $int $base $dest
    $start $len $digs)
  (set $digs (add (@call memstart) (0x50)))
  (@if (lt ($int) (0) ) ( ;; minus
    (store8 ($dest) (0x2d) )
    (set $dest (add ($dest) (1) ))
    (set $int (mult ($int) (-1) ))
  ))
  (set $start ($dest))
  (@while ($int) (
    (store8 ($dest) (load8u (add ($digs) (rem ($int) ($base) ) ) ) )
    (set $dest (add ($dest) (1) ))
    (set $int (div ($int) ($base) ))
  ))
  (@if (eq ($start) ($dest) ) (
    (store8 ($dest) (0x30) )
    (set $dest (add ($dest) (1) ))
  ))
  (store8 ($dest) (0) )
  (set $len (div (sub ($dest) ($start) ) (2) ) )
  (@while ($len) (
    (set $dest (sub ($dest) (1) ))
    (set $int (load8u ($dest)))
    (store8 ($dest) (load8u ($start) ) )
    (store8 ($start) ($int) )
    (set $start (add ($start) (1) ))
    (set $len (sub ($len) (1) ))
  ))
  (@return)
)

(strlen:
  (@vars $str $max
    $len)
  (set $str (sub ($str) (1)))
  (set $len (sub ($len) (1)))
  (@while ($max) (
    (set $str (add ($str) (1)))
    (set $len (add ($len) (1)))
    (set $max (sub ($max) (1)))
    (@if (eqz (load8u ($str))) (
      (set $max (0))
    ))
  ))
  (@return ($len))
)

(readln:
  (@vars $max $dest
    $len)
  (store8 ($dest) (0))
  (@while (lt ($len) ($max)) (
    (@call printchar (0x20))
    (@call printchar (0x08))
    (store8 (0xaffe) (xor (load8u (0xaffe)) (-1) ) )
    (@call printchar (0x20) )
    (store8 (0xaffe) (xor (load8u (0xaffe)) (-1) ) )
    (@call printchar (0x08) )
    (@while (eqz (load (0xb4f4))) (
      (vsync)
    ))
    (@if (lt (load8u (0xb4f5)) (0x20)) (
      (@call printchar (0x20))
      (@call printchar (0x08))
      (@if (eq (load8u (0xb4f5)) (0x08)) (
        (@if (gt ($len) (0)) (
          (set $len (sub ($len) (1)))
          (store8 (add ($dest) ($len) ) (0))
          (@call printchar (0x08))
        )(
          (@call printchar (0x07)) ;; bell
        ))
      ))
      (@if (eq (load8u (0xb4f5)) (0x0a)) (
        (set $len ($max))
      ))
    )(
      (@if (lt ($len) (sub ($max) (1) )) (
        (store8 (add ($dest) ($len) ) (load8u (0xb4f5)))
        (set $len (add ($len) (1)))
        (store8 (add ($dest) ($len) ) (0))
        (@call printchar (load8u (0xb4f5)) )
      )(
        (@call printchar (0x07)) ;; bell
      ))
    ))
    (store (0xb4f4) (0))
  ))

  (@call printchar (0x0a))
  (@return)
)

(pset:
  (@vars $x $y $c
    $adr $bit
  )
  (@if (lt ($x) (0)) ( (@return) ))
  (@if (lt ($y) (0)) ( (@return) ))

  (jump (mult (and (7) (load8u (0xb4f8))) (0xc6) ))
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
    (@call pset ($px) ($end) (load8u (0xaffe)))
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
  (jump (mult (and (3) (load8u (0xb4f8))) (0xb) ))
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
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
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
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
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
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
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

(access:
  (@vars $file $dest
    $drive $len)
  (store (0xb4f0) (0))
  (@while (and 
      (eqz (eq (load8u ($file)) (0x0)))
      (eqz (eq (load8u ($file)) (0x3a)))
    ) (
    (set $file (add ($file) (1)) )
  ))
  (set $file (sub ($file) (1)) )
  (set $drive (sub (load8u ($file)) (0x2f)) )
  (set $file (add ($file) (2)) )
  (vsync)
  (@call memcopy ($file) (0xb608) (255-8))
  (store8 (0xb6ff) (0))
  (store8 (0xb4f1) (@call strlen (0xb600) (255)))
  (store8 (0xb4f0) ($drive))
  (@while (eqz (load8u (0xb4f2))) (
    (@if (eqz (load8u (0xb4f0))) (
      (store (0xb4f0) (0))
      (@return (0))
    ))
  ))
  (@if (eqz (eq (load (0xb700)) (0x20206b6f))) ( ;; not ok
    (store (0xb4f0) (0))
    (@return (0))
  ))
  (set $len (@call strtoint (0xb704) (10)) )
  (store8 (0xb4f2) (0))
  (@while (gt ($len) (0)) (
    (@while (eqz (load8u (0xb4f2))) (
      (@if (eqz (load8u (0xb4f0))) (
        (store (0xb4f0) (0))
        (@return (0))
      ))
    ))
    (@call memcopy (0xb700) ($dest) (load8u (0xb4f2)))
    (set $dest (add ($dest) (load8u (0xb4f2))))
    (set $len (sub ($len) (load8u (0xb4f2))))
    (store8 (0xb4f2) (0))
  ))
  (store (0xb4f0) (0))
  (@return (1))
)

(load:
  (@vars $file $dest)
  (store (0xb600) (0x64616f6c)) ;; load
  (store (0xb604) (0x20202020)) ;; spaces
  (@return (@call access ($file) ($dest)))
)

(save:
  (@vars $file $src $len
    $drive)
  (store (0xb4f0) (0))
  (@while (and (eqz (eq (load8u ($file)) (0))) (eqz (eq (load8u ($file)) (0x3a)))) (
    (set $file (add ($file) (1)) )
  ))
  (set $file (sub ($file) (1)) )
  (set $drive (sub (load8u ($file)) (0x2f)) )
  (set $file (add ($file) (2)) )
  (vsync)
  (store (0xb600) (0x65766173)) ;; save
  (store (0xb604) (0x20202020)) ;; spaces
  (@call memcopy ($file) (0xb608) (255-8))
  (store8 (0xb6ff) (0))
  (store8 (0xb4f1) (@call strlen (0xb600) (255)))
  (store8 (add (0xb600) (load8u (0xb4f1))) (0x20))
  (@call inttostr ($len) (10) (add (0xb601) (load8u (0xb4f1))))
  (store8 (0xb4f1) (@call strlen (0xb600) (255)))

  (store8 (0xb4f0) ($drive))
  (@while (eqz (load8u (0xb4f2))) (
    (@if (eqz (load8u (0xb4f0))) (
      (store (0xb4f0) (0))
      (@return (0))
    ))
  ))
  (@if (eqz (eq (load (0xb700)) (0x20206b6f))) ( ;; not ok
    (store (0xb4f0) (0))
    (@return (0))
  ))
  (store8 (0xb4f2) (0))
  (@while (gt ($len) (0)) (
    (@while (load8u (0xb4f1)) (
      (@if (eqz (load8u (0xb4f0))) (
        (store (0xb4f0) (0))
        (@return (0))
      ))
    ))
    (@call memcopy ($src) (0xb600) (255))
    (@if (gt ($len) (255)) (
      (store8 (0xb4f1) (255))
      (set $src (add ($src) (255)))
      (set $len (sub ($len) (255)))
    )(
      (store8 (0xb4f1) ($len))
      (set $src (add ($src) ($len)))
      (set $len (sub ($len) ($len)))
    ))
  ))
  (store (0xb4f0) (0))
  (@return (1))
)

(delete:
  (@vars $file)
  (store (0xb600) (0x656c6564)) ;; dele
  (store (0xb604) (0x20206574)) ;; te spaces
  (@return (@call access ($file) (0xb700)))
)

(info:
  (@vars $file $dest)
  (store (0xb600) (0x6f666e69)) ;; info
  (store (0xb604) (0x20202020)) ;; spaces
  (@return (@call access ($file) ($dest)))
)

(list:
  (@vars $file $dest)
  (store (0xb600) (0x7473696c)) ;; list
  (store (0xb604) (0x20202020)) ;; spaces
  (@return (@call access ($file) ($dest)))
)

(mkdir:
  (@vars $file)
  (store (0xb600) (0x69646b6d)) ;; mkdi
  (store (0xb604) (0x20202072)) ;; r spaces
  (@return (@call access ($file) (0xb700)))
)

(cd:
  (@vars $file)
  (store (0xb600) (0x20206463)) ;; cd spaces
  (store (0xb604) (0x20202020)) ;; spaces
  (@return (@call access ($file) (0xb700)))
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
;; 0x0
(@string 0x40 "\t /// Peti8\x20 ///\t\t\t /// Peti R ///\n\n\n")
;; 0x40
(@string 0x10 "\nReady.\n\n")
;; 0x50
(@string 0x20 "0123456789abcdefghijklmnopqrstuvwxyz")
;; 0x70
(@string 0x20 " bytes free.\n")
;; 0x90
(@string 0x100 "{temporary string}")
;; 0x190
(@string 0x20 " ips.\n")
;; 0x1b0
(@string 0x20 "file not found!\n")
;; 0x1d0
(@string 0x20 "drive0:/main.prg\0")
;; 0x1f0
