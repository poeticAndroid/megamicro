.       | x0              | x1              | x2            | x3  | x4
--------|-----------------|-----------------|---------------|-----|-------------
0x0000  | Stack           |                 |               |     |
0x0400  | kernal          |                 |               |     |
        |                 |                 |               |     |
0xae00  | system font     |                 |               |     |
0xb200  | disk input new  | disk output new | key new       |     |
0xb210  |                 |                 | key           |     | display mode
0xb220  | mouse x         | mouse y         | mouse buttons |     |
0xb230  | player 1        | player 2        | player 3      | ... |
0xb240  |                 |                 |               |     |
0xb250  |                 |                 |               |     |
0xb260  |                 |                 |               |     |
        |                 |                 |               |     |
0xb400  | disk input      |                 |               |     |
0xb500  | disk output     |                 |               |     |
0xb600  | pcm sound left  |                 |               |     |
0xb700  | pcm sound right |                 |               |     |
0xb800  | Display         |                 |               |     |
0x10000 | user space      |                 |               |     |
