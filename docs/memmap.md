Memory layout
=============

\          | +0           | +1            | +2            | +3
-----------|--------------|---------------|---------------|--------------
**0x0000** | Display      | _(18 KB)_     |               |
**0x4800** | audio*       | _(256 bytes)_ |               |
**0x4900** | disk req     | _(256 bytes)_ |               |
**0x4a00** | disk resp    | _(256 bytes)_ |               |
**0x4b00** | disk open    | disk req new  | disk resp new |
**0x4b04** | char queue   | key char      | key code      | key mods
**0x4b08** | display mode | mouse x       | mouse y       | mouse buttons
**0x4b0c** | player 1*    | player 2*     | player 3*     | player 4*
**0x4b10** | year         | month         | date          | weekday
**0x4b14** | hour         | minute        | second        | second/256
...        |              |               |               |
**0xaffc** | cursor col   | cursor row    | text bg       | text fg
**0xb000** | system font  | _(1 KB)_      |               |
...        |              |               |               |
**0x0400** | kernal       |               |               |

*not yet implemented
