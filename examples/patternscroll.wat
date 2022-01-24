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
    (@while (lt ($adr) (0x10000)) (
      (store8 ($adr) (add (load8u($adr)) (1)))
      (set $adr (add ($adr) (1)))
    ))

    (set $adr (0xb800))
    (vsync)
  ))

  (@return (0))
)
