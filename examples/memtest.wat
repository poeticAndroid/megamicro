;;cyber asm

(main:
  (@vars $adr $val )

  (set $val (0x00))
  (@while (lt ($val) (0x7f7f7f7f)) (
    (set $adr (0xb210))
    (@while (lt ($adr) (0x10000)) (
      (store ($adr) ($val))
      (@if (xor (load ($adr)) ($val) ) (halt) ) ;; memory error!
      (set $adr (add ($adr) (4)))
    ))
    (set $val (add ($val) (0x01010101)))
  ))
  (@return (0))
)
