\           | +0           | +1              | +2               | +3
------------|--------------|-----------------|------------------|--------------
**0x0000**  | Stack        |                 |                  |
**0x0400**  | kernal       |                 |                  |
...         |              |                 |                  |
**0xaffc**  | cursor col   | cursor row      | text bg          | text fg
**0xb000**  | system font  | _(1 KB)_        |                  |
...         |              |                 |                  |
**0xb4e8**  | year*        | month*          | date*            | weekday*
**0xb4ec**  | hour*        | minute*         | second*          |
**0xb4f0**  | disk open*   | disk input new* | disk output new* |
**0xb4f4**  | char queue   | key char        | key code         | key mods
**0xb4f8**  | display mode | mouse x         | mouse y          | mouse buttons
**0xb4fc**  | player 1*    | player 2*       | player 3*        | player 4*
**0xb500**  | audio*       | _(256 bytes)_   |                  |
**0xb600**  | disk input*  | _(256 bytes)_   |                  |
**0xb700**  | disk output* | _(256 bytes)_   |                  |
**0xb800**  | Display      | _(18 KB)_       |                  |
**0x10000** | user space   | _(Rest of ram)_ |                  |

*not yet implemented
