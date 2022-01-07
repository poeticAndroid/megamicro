;;cyber asm

main:
(@vars
  $adr (0xb800)
)

(@while (lt ($adr) (0x10000)) @do(
  (store8 ($adr) ($adr))
  (set $adr (add ($adr) (1)))
)@end)

(set $adr (0xb800))

(@while (true) @do(
  (@while (lt ($adr) (0x10000)) @do(
    (store8 ($adr) (add (load8u($adr)) (1)))
    (set $adr (add ($adr) (1)))
  )@end)

  (set $adr (0xb800))
  (vsync)
)@end)

(return (0) (1))

