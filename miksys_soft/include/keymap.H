.macro C a v V
    .const v | (V<<8)
.endmacro

        //code char CHAR
.words 0xD
        C 0x0D, '\t', '\t'
        C 0x0E,  '`', '~'
.words 0x14 - 0x0E
        C 0x15,  'q', 'Q'
        C 0x16,  '1', '!'
.words 3
        C 0x1A,  'z', 'Z'
        C 0x1B,  's', 'S'
        C 0x1C,  'a', 'A'
        C 0x1D,  'w', 'W'
        C 0x1E,  '2', '@'
.words 2
        C 0x21,  'c', 'C'
        C 0x22,  'x', 'X'
        C 0x23,  'd', 'D'
        C 0x24,  'e', 'E'
        C 0x25,  '4', '$'
        C 0x26,  '3', '#'
.words 2
        C 0x29,  ' ', ' '
        C 0x2A,  'v', 'V'
        C 0x2B,  'f', 'F'
        C 0x2C,  't', 'T'
        C 0x2D,  'r', 'R'
        C 0x2E,  '5', '%'
.words 2
        C 0x31,  'n', 'N'
        C 0x32,  'b', 'B'
        C 0x33,  'h', 'H'
        C 0x34,  'g', 'G'
        C 0x35,  'y', 'Y'
        C 0x36,  '6', '^'
.words 3
        C 0x3A,  'm', 'M'
        C 0x3B,  'j', 'J'
        C 0x3C,  'u', 'U'
        C 0x3D,  '7', '&'
        C 0x3E,  '8', '*'
.words 2
        C 0x41,  ',', '<'
        C 0x42,  'k', 'K'
        C 0x43,  'i', 'I'
        C 0x44,  'o', 'O'
        C 0x45,  '0', ')'
        C 0x46,  '9', '('
.words 2
        C 0x49,  '.', '>'
        C 0x4A,  '/', '?'
        C 0x4B,  'l', 'L'
        C 0x4C,  ';', ':'
        C 0x4D,  'p', 'P'
        C 0x4E,  '-', '_'
.words 3
        C 0x52, '\'', '"'
.words 1
        C 0x54,  '[', '{'
        C 0x55,  '=', '+'
.words 4
        C 0x5A, '\n', '\n'
        C 0x5B,  ']', '}'
.words 1
        C 0x5D,  '\\', '|'

