Display modes
=============

**Display memory:** 18 KB

Mode  | Bits per pixel | Pixels per byte | Colors | Total pixels | Width | Height | Pixel ratio
------|----------------|-----------------|--------|--------------|-------|--------|------------
**0** | 1              | 8               | 2      | 147456       | 512   | 288    | 1
**1** | 2              | 4               | 4      | 73728        | 512   | 144    | 0,5
**2** | 4              | 2               | 16     | 36864        | 256   | 144    | 1
**3** | 8              | 1               | 256    | 18432        | 256   | 72     | 0,5
**4** | 1              | 8               | 2      | 147456       | 512   | 288    | 1
**5** | 2              | 4               | 4      | 73728        | 256   | 288    | 2
**6** | 4              | 2               | 16     | 36864        | 256   | 144    | 1
**7** | 8              | 1               | 256    | 18432        | 128   | 144    | 2

Color palettes
--------------
The color for each value can be calculated thusly; The available bits per pixel will be devided into three groups for green, red and blue, in that order, prioritizing more bits for green, then red, then blue. For less than three bits, some bits will be shared.

Bits/pixel | Grouping
-----------|----------------
1          | GRB
2          | GR GB
4          | G G R B
8          | G G G R R R B B

### Alternate palettes
To prevent having identical display modes, modes 4 and 6 will have alternate palettes. In mode 4, color 0 will be a dark green and color 1 an even darker green. In mode 6, the colors will be 16 shades of gray from black to white.
