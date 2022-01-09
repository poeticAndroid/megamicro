;;cyber asm

main:
(@vars
  $adr (0xb800)
  $loops (0x100)
)

(@while ($loops) (
  (@while (lt ($adr) (0x10000)) (
    (@if (load8u($adr)) (
      (store8 ($adr) (sub (load8u($adr)) (1)))
    ) )
    (set $adr (add ($adr) (1)))
  ) )

  (set $adr (0xb800))
  (set $loops (sub ($loops) (1)))
  (vsync)
) )

(return (0) (1))

