#define V(x) (VERTICES_BUF + x*5)
.data 0x0 MEMORY_FACES_OFFSET
    .const V(  1), V(  3), V(  2), RGB("2 1 1") // 0
    .const V(  1), V(  2), V(  0), RGB("2 1 1") // 1
    .const V(  4), V(  7), V(  6), (6*0x20)|MATERIAL_Window // 2
    .const V(  4), V(  6), V(  5), (6*0x20)|MATERIAL_Window // 3
    .const V(  9), V(  8), V( 11), (8*0x20)|MATERIAL_Window // 4
    .const V(  9), V( 11), V( 10), (8*0x20)|MATERIAL_Window // 5
    .const V( 15), V( 14), V( 12), (5*0x20)|MATERIAL_Window // 6
    .const V( 15), V( 12), V( 13), (5*0x20)|MATERIAL_Window // 7
    .const V( 19), V( 18), V( 16), (5*0x20)|MATERIAL_Window // 8
    .const V( 19), V( 16), V( 17), (5*0x20)|MATERIAL_Window // 9
    .const V( 21), V( 23), V( 22), RGB("0 8 3") // 10
    .const V( 21), V( 22), V( 20), RGB("0 8 3") // 11
    .const V( 25), V( 27), V( 26), RGB("0 8 3") // 12
    .const V( 25), V( 26), V( 24), RGB("0 8 3") // 13
    .const V( 25), V( 24), V( 26), RGB("0 17 5") // 14
    .const V( 25), V( 26), V( 27), RGB("0 17 5") // 15
    .const V( 21), V( 20), V( 22), RGB("0 17 5") // 16
    .const V( 21), V( 22), V( 23), RGB("0 17 5") // 17
    .const V( 31), V( 32), V( 29), RGB("2 2 2") // 18
    .const V( 31), V( 29), V( 28), RGB("2 2 2") // 19
    .const V( 35), V( 36), V( 40), RGB("3 3 3") // 20
    .const V( 35), V( 40), V( 39), RGB("3 3 3") // 21
    .const V( 31), V( 28), V( 30), RGB("3 3 3") // 22
    .const V( 31), V( 30), V( 34), RGB("3 3 3") // 23
    .const V( 34), V( 33), V( 32), RGB("3 3 3") // 24
    .const V( 34), V( 32), V( 31), RGB("3 3 3") // 25
    .const V( 33), V( 34), V( 36), RGB("4 4 4") // 26
    .const V( 33), V( 36), V( 35), RGB("4 4 4") // 27
    .const V( 39), V( 40), V( 38), RGB("4 4 4") // 28
    .const V( 39), V( 38), V( 37), RGB("4 4 4") // 29
    .const V( 36), V( 30), V( 38), RGB("3 3 3") // 30
    .const V( 36), V( 38), V( 40), RGB("3 3 3") // 31
    .const V( 50), V( 47), V( 52), RGB("2 2 2") // 32
    .const V( 50), V( 52), V( 53), RGB("2 2 2") // 33
    .const V( 46), V( 50), V( 53), RGB("2 2 2") // 34
    .const V( 46), V( 53), V( 51), RGB("2 2 2") // 35
    .const V( 48), V( 49), V( 56), RGB("2 2 2") // 36
    .const V( 48), V( 56), V( 55), RGB("2 2 2") // 37
    .const V( 49), V( 45), V( 54), RGB("2 2 2") // 38
    .const V( 49), V( 54), V( 56), RGB("2 2 2") // 39
    .const V( 44), V( 42), V( 57), RGB("2 2 2") // 40
    .const V( 44), V( 57), V( 58), RGB("2 2 2") // 41
    .const V( 41), V( 43), V( 60), RGB("2 2 2") // 42
    .const V( 41), V( 60), V( 59), RGB("2 2 2") // 43
    .const V( 63), V( 64), V( 69), (5*0x20)|MATERIAL_Brick // 44
    .const V( 63), V( 69), V( 68), (5*0x20)|MATERIAL_Brick // 45
    .const V( 62), V( 63), V( 68), (8*0x20)|MATERIAL_Brick // 46
    .const V( 62), V( 68), V( 67), (8*0x20)|MATERIAL_Brick // 47
    .const V( 64), V( 61), V( 66), (6*0x20)|MATERIAL_Brick // 48
    .const V( 64), V( 66), V( 69), (6*0x20)|MATERIAL_Brick // 49
    .const V( 65), V( 62), V( 67), (11*0x20)|MATERIAL_Brick // 50
    .const V( 65), V( 67), V( 70), (11*0x20)|MATERIAL_Brick // 51
    .const V( 78), V( 79), V( 81), (11*0x20)|MATERIAL_Wood // 52
    .const V( 78), V( 81), V( 80), (11*0x20)|MATERIAL_Wood // 53
    .const V( 77), V( 76), V( 80), (8*0x20)|MATERIAL_Wood // 54
    .const V( 77), V( 80), V( 81), (8*0x20)|MATERIAL_Wood // 55
    .const V( 71), V( 75), V( 79), (6*0x20)|MATERIAL_Wood // 56
    .const V( 71), V( 79), V( 78), (6*0x20)|MATERIAL_Wood // 57
    .const V( 82), V( 72), V( 85), (6*0x20)|MATERIAL_Wood // 58
    .const V( 83), V( 85), V( 72), (6*0x20)|MATERIAL_Wood // 59
    .const V( 73), V( 83), V( 72), (6*0x20)|MATERIAL_Wood // 60
    .const V( 83), V( 73), V( 84), (6*0x20)|MATERIAL_Wood // 61
    .const V( 84), V( 73), V( 74), (6*0x20)|MATERIAL_Wood // 62
    .const V( 87), V( 90), V( 91), (8*0x20)|MATERIAL_Wood // 63
    .const V( 88), V( 87), V( 91), (8*0x20)|MATERIAL_Wood // 64
    .const V( 91), V( 92), V( 88), (8*0x20)|MATERIAL_Wood // 65
    .const V( 88), V( 92), V( 86), (8*0x20)|MATERIAL_Wood // 66
    .const V( 89), V( 86), V( 92), (8*0x20)|MATERIAL_Wood // 67
    .const V( 94), V( 93), V( 95), (10*0x20)|MATERIAL_Wood // 68
    .const V( 94), V( 95), V( 96), (10*0x20)|MATERIAL_Wood // 69
    .const V( 98), V( 97), V( 99), (6*0x20)|MATERIAL_Wood // 70
    .const V( 98), V( 99), V(100), (6*0x20)|MATERIAL_Wood // 71
    .const V(111), V(108), V( 44), (10*0x20)|MATERIAL_Roof // 72
    .const V(111), V( 44), V(109), (10*0x20)|MATERIAL_Roof // 73
    .const V( 46), V(101), V(102), (12*0x20)|MATERIAL_Roof // 74
    .const V( 46), V(102), V( 50), (12*0x20)|MATERIAL_Roof // 75
    .const V(103), V( 47), V( 50), (7*0x20)|MATERIAL_Roof // 76
    .const V(103), V( 50), V(102), (7*0x20)|MATERIAL_Roof // 77
    .const V(101), V(104), V(105), (12*0x20)|MATERIAL_Roof // 78
    .const V(101), V(105), V(102), (12*0x20)|MATERIAL_Roof // 79
    .const V(106), V(103), V(102), (7*0x20)|MATERIAL_Roof // 80
    .const V(106), V(102), V(105), (7*0x20)|MATERIAL_Roof // 81
    .const V(104), V( 45), V( 49), (12*0x20)|MATERIAL_Roof // 82
    .const V(104), V( 49), V(105), (12*0x20)|MATERIAL_Roof // 83
    .const V( 48), V(106), V(105), (7*0x20)|MATERIAL_Roof // 84
    .const V( 48), V(105), V( 49), (7*0x20)|MATERIAL_Roof // 85
    .const V(110), V( 42), V(108), (10*0x20)|MATERIAL_Roof // 86
    .const V(110), V(108), V(111), (10*0x20)|MATERIAL_Roof // 87
    .const V(107), V(111), V(109), (10*0x20)|MATERIAL_Roof // 88
    .const V(107), V(109), V( 43), (10*0x20)|MATERIAL_Roof // 89
    .const V( 41), V(110), V(111), (10*0x20)|MATERIAL_Roof // 90
    .const V( 41), V(111), V(107), (10*0x20)|MATERIAL_Roof // 91
    .const V(116), V( 75), V(112), RGB("4 4 4") // 92
    .const V(116), V(112), V(113), RGB("4 4 4") // 93
    .const V(113), V(114), V(119), RGB("3 3 3") // 94
    .const V(113), V(119), V(116), RGB("3 3 3") // 95
    .const V(114), V(115), V(118), RGB("2 2 2") // 96
    .const V(114), V(118), V(119), RGB("2 2 2") // 97
    .const V(112), V( 61), V( 64), RGB("2 2 2") // 98
    .const V(112), V( 64), V(115), RGB("2 2 2") // 99
    .const V( 65), V(117), V(116), RGB("4 4 4") // 100
    .const V( 65), V(116), V( 62), RGB("4 4 4") // 101
    .const V( 13), V( 12), V(118), RGB("2 2 2") // 102
    .const V( 13), V(118), V(121), RGB("2 2 2") // 103
    .const V(121), V( 64), V( 63), RGB("2 2 2") // 104
    .const V(121), V( 63), V(120), RGB("2 2 2") // 105
    .const V( 17), V( 16), V( 14), RGB("2 2 2") // 106
    .const V( 17), V( 14), V( 15), RGB("2 2 2") // 107
    .const V(120), V(119), V( 18), RGB("2 2 2") // 108
    .const V(120), V( 18), V( 19), RGB("2 2 2") // 109
    .const V(119), V( 63), V(  1), RGB("3 3 3") // 110
    .const V(119), V(  1), V(  0), RGB("3 3 3") // 111
    .const V( 62), V(116), V(  2), RGB("3 3 3") // 112
    .const V( 62), V(  2), V(  3), RGB("3 3 3") // 113
faces_list_end:

.data 0x0 MEMORY_VERTICES_OFFSET
    .const -1003,  149, -2240,    0,    0 // 0
    .const -1009, -1116, -2240,    0,    0 // 1
    .const -351,  147, -2240,    0,    0 // 2
    .const -351, -1116, -2240,    0,    0 // 3
    .const -561, 1129, 2241,    1/(2-(MATERIAL_Window>>4)%2),   64/(2-(MATERIAL_Window>>3)%2) // 4
    .const -1037, 1129, 2241,   63/(2-(MATERIAL_Window>>4)%2),   64/(2-(MATERIAL_Window>>3)%2) // 5
    .const -1037,  636, 2241,   63/(2-(MATERIAL_Window>>4)%2),    0/(2-(MATERIAL_Window>>3)%2) // 6
    .const -561,  636, 2241,    1/(2-(MATERIAL_Window>>4)%2),    0/(2-(MATERIAL_Window>>3)%2) // 7
    .const -561,  636, -2240,   62/(2-(MATERIAL_Window>>4)%2),    0/(2-(MATERIAL_Window>>3)%2) // 8
    .const -1037,  636, -2240,    0/(2-(MATERIAL_Window>>4)%2),    0/(2-(MATERIAL_Window>>3)%2) // 9
    .const -1037, 1129, -2240,    0/(2-(MATERIAL_Window>>4)%2),   64/(2-(MATERIAL_Window>>3)%2) // 10
    .const -561, 1129, -2240,   62/(2-(MATERIAL_Window>>4)%2),   64/(2-(MATERIAL_Window>>3)%2) // 11
    .const -2480,  152, 1230,   -1/(2-(MATERIAL_Window>>4)%2),   63/(2-(MATERIAL_Window>>3)%2) // 12
    .const -2480, -589, 1230,   -1/(2-(MATERIAL_Window>>4)%2),    1/(2-(MATERIAL_Window>>3)%2) // 13
    .const -2480,  152,  475,   63/(2-(MATERIAL_Window>>4)%2),   63/(2-(MATERIAL_Window>>3)%2) // 14
    .const -2480, -590,  475,   63/(2-(MATERIAL_Window>>4)%2),    1/(2-(MATERIAL_Window>>3)%2) // 15
    .const -2480,  152, -473,   -1/(2-(MATERIAL_Window>>4)%2),   63/(2-(MATERIAL_Window>>3)%2) // 16
    .const -2480, -591, -473,   -1/(2-(MATERIAL_Window>>4)%2),    1/(2-(MATERIAL_Window>>3)%2) // 17
    .const -2480,  152, -1228,   63/(2-(MATERIAL_Window>>4)%2),   63/(2-(MATERIAL_Window>>3)%2) // 18
    .const -2480, -591, -1228,   63/(2-(MATERIAL_Window>>4)%2),    1/(2-(MATERIAL_Window>>3)%2) // 19
    .const -1415, -1587, 2468,    0,    0 // 20
    .const -1415, -905, 2468,    0,    0 // 21
    .const -1415, -1587, 2936,    0,    0 // 22
    .const -1415, -995, 2936,    0,    0 // 23
    .const  310, -1587, 2468,    0,    0 // 24
    .const  310, -905, 2468,    0,    0 // 25
    .const  310, -1587, 2936,    0,    0 // 26
    .const  310, -980, 2936,    0,    0 // 27
    .const -1136, -1587, -2918,    0,    0 // 28
    .const -1136, -1587, -2246,    0,    0 // 29
    .const -227, -1587, -2918,    0,    0 // 30
    .const -1136, -1139, -2918,    0,    0 // 31
    .const -1136, -1139, -2246,    0,    0 // 32
    .const -227, -1139, -2246,    0,    0 // 33
    .const -227, -1139, -2918,    0,    0 // 34
    .const -227, -1363, -2246,    0,    0 // 35
    .const -227, -1363, -2918,    0,    0 // 36
    .const  323, -1587, -2246,    0,    0 // 37
    .const  323, -1587, -2918,    0,    0 // 38
    .const  323, -1363, -2246,    0,    0 // 39
    .const  323, -1363, -2918,    0,    0 // 40
    .const  863,  279, 2367,  374/(2-(MATERIAL_Roof>>4)%2),  292/(2-(MATERIAL_Roof>>3)%2) // 41
    .const  863,  279, -999, -326/(2-(MATERIAL_Roof>>4)%2),  292/(2-(MATERIAL_Roof>>3)%2) // 42
    .const 3323, -143, 2367,  374/(2-(MATERIAL_Roof>>4)%2), -228/(2-(MATERIAL_Roof>>3)%2) // 43
    .const 3323, -143, -999, -326/(2-(MATERIAL_Roof>>4)%2), -228/(2-(MATERIAL_Roof>>3)%2) // 44
    .const 1085,  528, 2513, -410/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 45
    .const 1085,  528, -2513,  468/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 46
    .const -2685,  528, -2513,  468/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 47
    .const -2685,  528, 2513, -410/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 48
    .const -800, 1785, 2513, -410/(2-(MATERIAL_Roof>>4)%2),  220/(2-(MATERIAL_Roof>>3)%2) // 49
    .const -800, 1785, -2513,  468/(2-(MATERIAL_Roof>>4)%2),  220/(2-(MATERIAL_Roof>>3)%2) // 50
    .const 1085,  528,  382,    0,    0 // 51
    .const -2685,  528,  414,    0,    0 // 52
    .const -800, 1785, -2113,    0,    0 // 53
    .const 1085,  528,  -29,    0,    0 // 54
    .const -2685,  528, -234,    0,    0 // 55
    .const -800, 1785, 2186,    0,    0 // 56
    .const  863,  279, -702,    0,    0 // 57
    .const 3323, -143, -702,    0,    0 // 58
    .const  863,  279, 2079,    0,    0 // 59
    .const 3323, -143, 2079,    0,    0 // 60
    .const  880, -1116, 2240, 1482/(2-(MATERIAL_Brick>>4)%2),  -54/(2-(MATERIAL_Brick>>3)%2) // 61
    .const  880, -1116, -2240, -1102/(2-(MATERIAL_Brick>>4)%2),  -54/(2-(MATERIAL_Brick>>3)%2) // 62
    .const -2480, -1116, -2240, -327/(2-(MATERIAL_Brick>>4)%2),  -54/(2-(MATERIAL_Brick>>3)%2) // 63
    .const -2480, -1116, 2240,  707/(2-(MATERIAL_Brick>>4)%2),  -54/(2-(MATERIAL_Brick>>3)%2) // 64
    .const  880, -1116, -873, -1418/(2-(MATERIAL_Brick>>4)%2),  -54/(2-(MATERIAL_Brick>>3)%2) // 65
    .const  880, -1599, 2240, 1482/(2-(MATERIAL_Brick>>4)%2),   57/(2-(MATERIAL_Brick>>3)%2) // 66
    .const  880, -1599, -2240, -1102/(2-(MATERIAL_Brick>>4)%2),   57/(2-(MATERIAL_Brick>>3)%2) // 67
    .const -2480, -1599, -2240, -327/(2-(MATERIAL_Brick>>4)%2),   57/(2-(MATERIAL_Brick>>3)%2) // 68
    .const -2480, -1599, 2240,  707/(2-(MATERIAL_Brick>>4)%2),   57/(2-(MATERIAL_Brick>>3)%2) // 69
    .const  880, -1599, -873, -1418/(2-(MATERIAL_Brick>>4)%2),   57/(2-(MATERIAL_Brick>>3)%2) // 70
    .const  880, -1600, 2240,  -84/(2-(MATERIAL_Wood>>4)%2), -470/(2-(MATERIAL_Wood>>3)%2) // 71
    .const -561, 1129, 2241,  119/(2-(MATERIAL_Wood>>4)%2),  -12/(2-(MATERIAL_Wood>>3)%2) // 72
    .const -1037, 1129, 2241,  119/(2-(MATERIAL_Wood>>4)%2),   54/(2-(MATERIAL_Wood>>3)%2) // 73
    .const -1037,  632, 2241,  187/(2-(MATERIAL_Wood>>4)%2),   54/(2-(MATERIAL_Wood>>3)%2) // 74
    .const  880,  266, 2239,  148/(2-(MATERIAL_Wood>>4)%2), -470/(2-(MATERIAL_Wood>>3)%2) // 75
    .const  880, -1600, -873,  -84/(2-(MATERIAL_Wood>>4)%2),  486/(2-(MATERIAL_Wood>>3)%2) // 76
    .const  880,  266, -873,  148/(2-(MATERIAL_Wood>>4)%2),  486/(2-(MATERIAL_Wood>>3)%2) // 77
    .const 3154, -1600, 2240,  -84/(2-(MATERIAL_Wood>>4)%2), -186/(2-(MATERIAL_Wood>>3)%2) // 78
    .const 3154, -125, 2239,  100/(2-(MATERIAL_Wood>>4)%2), -186/(2-(MATERIAL_Wood>>3)%2) // 79
    .const 3154, -1600, -873,  -84/(2-(MATERIAL_Wood>>4)%2),  202/(2-(MATERIAL_Wood>>3)%2) // 80
    .const 3154, -125, -873,  100/(2-(MATERIAL_Wood>>4)%2),  202/(2-(MATERIAL_Wood>>3)%2) // 81
    .const -561,  632, 2241,  187/(2-(MATERIAL_Wood>>4)%2),  -11/(2-(MATERIAL_Wood>>3)%2) // 82
    .const -800, 1760, 2241,   32/(2-(MATERIAL_Wood>>4)%2),   21/(2-(MATERIAL_Wood>>3)%2) // 83
    .const -2480,  632, 2241,  187/(2-(MATERIAL_Wood>>4)%2),  253/(2-(MATERIAL_Wood>>3)%2) // 84
    .const  879,  632, 2241,  187/(2-(MATERIAL_Wood>>4)%2), -210/(2-(MATERIAL_Wood>>3)%2) // 85
    .const  879,  632, -2240, -123/(2-(MATERIAL_Wood>>4)%2), -210/(2-(MATERIAL_Wood>>3)%2) // 86
    .const -2480,  632, -2239, -123/(2-(MATERIAL_Wood>>4)%2),  253/(2-(MATERIAL_Wood>>3)%2) // 87
    .const -800, 1760, -2240,   32/(2-(MATERIAL_Wood>>4)%2),   22/(2-(MATERIAL_Wood>>3)%2) // 88
    .const -561,  632, -2240, -123/(2-(MATERIAL_Wood>>4)%2),  -11/(2-(MATERIAL_Wood>>3)%2) // 89
    .const -1037,  632, -2240, -123/(2-(MATERIAL_Wood>>4)%2),   54/(2-(MATERIAL_Wood>>3)%2) // 90
    .const -1037, 1129, -2240,  -55/(2-(MATERIAL_Wood>>4)%2),   54/(2-(MATERIAL_Wood>>3)%2) // 91
    .const -561, 1129, -2240,  -55/(2-(MATERIAL_Wood>>4)%2),  -11/(2-(MATERIAL_Wood>>3)%2) // 92
    .const  309, -1307, 2658,  191/(2-(MATERIAL_Wood>>4)%2),   21/(2-(MATERIAL_Wood>>3)%2) // 93
    .const -1414, -1307, 2658, -127/(2-(MATERIAL_Wood>>4)%2),   21/(2-(MATERIAL_Wood>>3)%2) // 94
    .const  309, -1307, 2920,  191/(2-(MATERIAL_Wood>>4)%2),   70/(2-(MATERIAL_Wood>>3)%2) // 95
    .const -1414, -1307, 2920, -127/(2-(MATERIAL_Wood>>4)%2),   70/(2-(MATERIAL_Wood>>3)%2) // 96
    .const  309, -941, 2482,  191/(2-(MATERIAL_Wood>>4)%2),  -46/(2-(MATERIAL_Wood>>3)%2) // 97
    .const -1414, -941, 2482, -127/(2-(MATERIAL_Wood>>4)%2),  -46/(2-(MATERIAL_Wood>>3)%2) // 98
    .const  309, -1288, 2598,  191/(2-(MATERIAL_Wood>>4)%2),   21/(2-(MATERIAL_Wood>>3)%2) // 99
    .const -1414, -1288, 2598, -127/(2-(MATERIAL_Wood>>4)%2),   21/(2-(MATERIAL_Wood>>3)%2) // 100
    .const 1085,  528, -776,  164/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 101
    .const -800, 1785, -818,  172/(2-(MATERIAL_Roof>>4)%2),  220/(2-(MATERIAL_Roof>>3)%2) // 102
    .const -2685,  528, -792,  167/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 103
    .const 1085,  528,  895, -128/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 104
    .const -800, 1785,  785, -108/(2-(MATERIAL_Roof>>4)%2),  220/(2-(MATERIAL_Roof>>3)%2) // 105
    .const -2685,  528, 1048, -154/(2-(MATERIAL_Roof>>4)%2), -176/(2-(MATERIAL_Roof>>3)%2) // 106
    .const 2133,   61, 2367,  374/(2-(MATERIAL_Roof>>4)%2),   23/(2-(MATERIAL_Roof>>3)%2) // 107
    .const 2146,   59, -999, -326/(2-(MATERIAL_Roof>>4)%2),   21/(2-(MATERIAL_Roof>>3)%2) // 108
    .const 3323, -143,  606,    7/(2-(MATERIAL_Roof>>4)%2), -228/(2-(MATERIAL_Roof>>3)%2) // 109
    .const  863,  279,  721,   32/(2-(MATERIAL_Roof>>4)%2),  292/(2-(MATERIAL_Roof>>3)%2) // 110
    .const 2140,   60,  661,   19/(2-(MATERIAL_Roof>>4)%2),   22/(2-(MATERIAL_Roof>>3)%2) // 111
    .const  880,  640, 2239,    0,    0 // 112
    .const  879,  640, -2240,    0,    0 // 113
    .const -2480,  640, -2239,    0,    0 // 114
    .const -2480,  640, 2240,    0,    0 // 115
    .const  879,  130, -2240,    0,    0 // 116
    .const  880,  192, -873,    0,    0 // 117
    .const -2480,  130, 2240,    0,    0 // 118
    .const -2480,  130, -2239,    0,    0 // 119
    .const -2480, -578, -2240,    0,    0 // 120
    .const -2480, -573, 2240,    0,    0 // 121
vertices_list_end:

.data 0x0 MEMORY_TEXTURES_OFFSET
