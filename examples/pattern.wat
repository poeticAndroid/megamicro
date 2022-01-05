;;cyber asm
(drop drop drop)

(const 0x7000) ;; get(0)

cond1:
(jumpifz (lt (get(0)) (0x10000)) (37)) ;;18
loop1:
(store8 (get(0)) (get(0))) ;;13
(set (0) (add (get(0)) (1))) ;;18
@jump cond1

(set (0) (0x6fff)) ;;11

cond2:
(jumpifz (lt (get(0)) (0x10000)) (44)) ;;18
(store8 (get(0)) (add (load8u(get(0))) (1))) ;;20
(set (0) (add (get(0)) (1))) ;;18
@jump cond2

(set (0) (0x7000)) ;;11
(vsync) ;;1
@jump cond2

(return (0) (1)) ;;11

