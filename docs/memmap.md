\           | x0              | x1             | x2              | x3      | x4
------------|-----------------|----------------|-----------------|---------|-------------
**0x0000**  | Stack           |                |                 |         |
**0x0400**  | kernal          |                |                 |         |
...         |                 |                |                 |         |
**0xae00**  | system font     |                |                 |         |
**0xb200**  | disk open       | disk input new | disk output new |         |
**0xb210**  | key new         | key char       | key code        |         | display mode
**0xb220**  | mouse x         | mouse y        | mouse buttons   |         |
**0xb230**  | player 1        | player 2       | player 3        | ...     |
...         |                 |                |                 |         |
**0xb280**  | cursor col      | cursor row     | text bg         | text fg |
...         |                 |                |                 |         |
**0xb400**  | disk input      |                |                 |         |
**0xb500**  | disk output     |                |                 |         |
**0xb600**  | pcm sound left  |                |                 |         |
**0xb700**  | pcm sound right |                |                 |         |
**0xb800**  | Display         |                |                 |         |
**0x10000** | user space      |                |                 |         |
