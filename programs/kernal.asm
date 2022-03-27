;; z28r asm

fn main
   while true
     sleep 1024
     store 0x40004804 1 add load 0x40004804 1 1
   end
end
