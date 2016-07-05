#define V(x) (VERTICES_BUF + x*5)
.data 0x0 MEMORY_FACES_OFFSET
    .const V(0), V(1), V(2), RGB("10 10 10")
    .const V(1), V(4), V(2), 0x0020
    .const V(1), V(3), V(4), 0x0020
    
    .const V(5), V(7), V(6), RGB("10 10 10")
    .const V(6), V(7), V(9), 0x0020
    .const V(6), V(9), V(8), 0x0020
    
    .const V(2), V(4), V(9), 0x0020 //RGB("10 10 5")
    .const V(2), V(9), V(7), 0x0020 //RGB("10 10 15")
    .const V(1), V(8), V(3), 0x0020 //RGB("10 10 5")
    .const V(1), V(6), V(8), 0x0020 //RGB("10 10 15")
    
    .const V(0), V(2), V(7), RGB("15 15 15")
    .const V(7), V(5), V(0), RGB("15 15 15")
    .const V(1), V(0), V(5), RGB("8 8 8")
    .const V(5), V(6), V(1), RGB("8 8 8")
faces_list_end:

.data 0x0 MEMORY_VERTICES_OFFSET
    .const 0, 140, -100, 300, 100 // 0
    .const -100, 40, -100, 200, 200 // 1
    .const 100, 40, -100, 400, 200 // 2
    .const -100, -100, -100, 200, 340 // 3
    .const 100, -100, -100, 400, 340 // 4
    
    .const 0, 140, 100, 500, 100 // 5
    .const -100, 40, 100, 400, 200 // 6
    .const 100, 40, 100, 600, 200 // 7
    .const -100, -100, 100, 400, 340 // 8
    .const 100, -100, 100, 600, 340 // 9
vertices_list_end:

.data 0x0 MEMORY_TEXTURES_OFFSET




