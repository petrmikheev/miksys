#define FPS30 // FPS30 or FPS60
#define FPS 30

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

/*** CACHE *** 16384 (0x4000) words
0x0000 - 0x0080     global variables
0x0080 - 0x0180     div_table
0x0180 - 0x0400     color1 buffer
0x0400 - 0x0680     color2 buffer
0x0680 - 0x0900     depth buffer
0x0900 - 0x0980     stack
0x0980 - 0x1000     faces (416*4)  //(512 * 4)
0x1000 - 0x2000     vertices (819 * 5 + 1)
0x2000 - 0x4000     textures */
#define COLOR1_ROW_BUF 0x180
#define COLOR2_ROW_BUF 0x400
#define DEPTH_ROW_BUF 0x680
#define DIV_TABLE 0x80
#define STACK_BUF 0x900
#define FACES_BUF 0x980
#define VERTICES_BUF 0x1000
#define STR_BUF FACES_BUF

/*** REGISTERS ****/
#define ZERO r14 // global variables offset/zero
#define SP r15 // stack pointer

/*** MEMORY (0x0 - 0x400000) ***
0x000000 - 0x04b000     color_buf1
0x04b000 - 0x096000     color_buf2
0x096000 - 0x097400     text_buf1
0x097400 - 0x098800     text_buf2
0x100000 - 0x101000     main code
0x101000 - 0x101080     global variables (initial values)
0x101080 - 0x101180     div_table
0x101180 - 0x101280     sin_table
0x101280 - 0x101380     str_data
0x101380 - 0x101800     RESERVED
0x101980 - 0x102000     faces
0x102000 - 0x103000     vertices
0x103000 - 0x105000     textures
*/
#define MEMORY_BASE_ADDR 0x100000
#define MEMORY_VARIABLES_OFFSET 0x1000
#define MEMORY_COLOR_BUF1 0x0
#define MEMORY_COLOR_BUF2 0x4b000
#define MEMORY_TEXT_BUF1 0x96000
#define MEMORY_TEXT_BUF2 0x97400
#define MEMORY_DIV_TABLE_OFFSET 0x1080
#define MEMORY_SIN_TABLE_OFFSET 0x1180
#define MEMORY_STR_DATA_OFFSET 0x1280
#define MEMORY_FACES_OFFSET 0x1980
#define MEMORY_VERTICES_OFFSET 0x2000
#define MEMORY_TEXTURES_OFFSET 0x3000

#define FACES_COUNT (faces_list_end/4)
#define VERTICES_COUNT (vertices_list_end/5)

#define MATERIAL_Brick 0x20
#define MATERIAL_Roof 0x21
#define MATERIAL_Wood 0x22
#define MATERIAL_Window 0x3b

