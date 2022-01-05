;;cyber asm

main:
(const 0x7000) ;; get(0)

(@while (lt (get(0)) (0x10000)) @do(
  (store8 (get(0)) (get(0)))
  (set (0) (add (get(0)) (1)))
)@end)

(set (0) (0x6fff))

(@while (true) @do(
  (@while (lt (get(0)) (0x10000)) @do(
    (store8 (get(0)) (add (load8u(get(0))) (1)))
    (set (0) (add (get(0)) (1)))
  )@end)

  (set (0) (0x7000))
  (vsync)
)@end)

(return (0) (1))

