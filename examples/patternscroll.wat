;;Peti asm

(main:
  (@vars $adr )
  (set $adr (0xb800))

  (@while (lt ($adr) (0x10000)) (
    (store8 ($adr) ($adr))
    (set $adr (add ($adr) (1)))
  ) )

  (set $adr (0xb800))

  (@while (true) (
    (@if (load8u (0xb4f4)) (
      (store8 (0xb4f8) (and (sub (load8u (0xb4f5) ) (0x30) ) (0x7) ))
      (store (0xb4f4) (0))
    ))

    (@while (lt ($adr) (0x10000)) (
      (store8 ($adr) (add (load8u($adr)) (1)))
      (set $adr (add ($adr) (1)))
    ))

    (set $adr (0xb800))
    (vsync)
  ))

  (@return (0))
)
