;;cyber asm

main:
(@vars
  $adr (0xb800)
  $loops (0x100)
)

(@while ($loops) @do(
  (@while (lt ($adr) (0x10000)) @do(
    (@if (load8u($adr)) @do(
      (store8 ($adr) (sub (load8u($adr)) (1)))
    )@end)
    (set $adr (add ($adr) (1)))
  )@end)

  (set $adr (0xb800))
  (set $loops (sub ($loops) (1)))
  (vsync)
)@end)

(return (0) (1))

