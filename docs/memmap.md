Memory layout
=============

\          | +0                  | +1                | +2            | +3
-----------|---------------------|-------------------|---------------|--------------
**0x0000** | display mode        | bits per pixel    | columns       | rows
**0x0004** | visible display ptr | _(32bit address)_ |               |
**0x0008** | active display ptr  | _(32bit address)_ |               |
**0x0080** | *audio              | _(128 bytes)_     |               |
**0x0100** | disk req            | _(256 bytes)_     |               |
**0x0200** | disk resp           | _(256 bytes)_     |               |
**0x0300** | disk open           | disk req new      | disk resp new |
**0x0304** | char queue          | key char          | key code      | key mods
**0x0308** |                     | mouse x           | mouse y       | mouse buttons
**0x030c** | *player 1           | *player 2         | *player 3     | *player 4
**0x0310** | 1/250 second        | second            | minute        | hour
**0x0314** | weekday             | date              | month         | year
...        |                     |                   |               |
**0x03f8** | active drive        |                   |               |
**0x03fc** | cursor col          | cursor row        | text bg       | text fg
**0x0400** | system font         | _(1 KB)_          |               |
**0x0800** | kernal              |                   |               |
...        |                     |                   |               |
**-0x5000**| default display     | _(18 KB)_         |               |
**-0x0800**| stack               | _(2 KB)_          |               |

*not yet implemented
