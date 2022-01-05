;;cyber asm

main:
(const 0x6fff) ;; get(0)
(const 0x100) ;; get(1)

(@while (get(1)) @do(
  (@while (lt (get(0)) (0x10000)) @do(
    (@if (load8u(get(0))) @do(
      (store8 (get(0)) (sub (load8u(get(0))) (1)))
    )@end)
    (set (0) (add (get(0)) (1)))
  )@end)

  (set (0) (0x7000))
  (set (1) (sub (get(1)) (1)))
  (vsync)
)@end)

(return (0) (1))

