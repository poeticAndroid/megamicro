;;cyber asm

main:
(@vars
  $adr (const 0x7000)
)

(@while (lt ($adr) (0x10000)) @do(
  (store8 ($adr) ($adr))
  (set $adr (add ($adr) (1)))
)@end)

(set $adr (0x6fff))

(@while (true) @do(
  (@while (lt ($adr) (0x10000)) @do(
    (store8 ($adr) (add (load8u($adr)) (1)))
    (set $adr (add ($adr) (1)))
  )@end)

  (set $adr (0x7000))
  (vsync)
)@end)

(return (0) (1))

