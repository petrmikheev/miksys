.data 0x0 MEMORY_VARIABLES_OFFSET /* global variables */

face_pointer:       .const 0
last_face_pointer:  .const 0

perspective:        .const 800*16
persp_timer:        .const 0
rotate_mode:        .const 1

control_x:          .const 30
control_y:          .const 40

frame:              .const 0

keyboard_settings:  .const 4
go_forward_key:     .const 0x1d /* W */
go_backward_key:    .const 0x1b /* S */
go_left_key:        .const 0x1c /* A */
go_right_key:       .const 0x23 /* D */

counter_y:          .const 0
current_material:   .const 0

row_fx:             .const 0
row_lx:             .const 0
row_dz:             .const 0
row_dtx:            .const 0
row_dty:            .const 0
row_fz:             .const 0
row_ftx:            .const 0
row_fty:            .const 0

tmp1:               .const 0
tmp2:               .const 0

time_transform:     .const 0
time_display:       .const 0
time_idle:       .const 0

row_color_buf:      .const 0

mouse_data:         .const 0, 0, 0
mouse_pointer:      .const mouse_data

transform_matrix:
    .const 0x1000, 0, 0, 0
    .const 0, -0x1000, 0, 0
    .const 0, 0, 0x1000, 0

.data 124 0x107c
pu_addr_group:      .const 0, 0, 0, 0

#include "tables.H"

.data STR_BUF MEMORY_STR_DATA_OFFSET

str_state:   .ascii " FPS: %d\n Transform time:   %U * 0.25 ms\n Display time:   %U * 0.25 ms\n CPU idle:   %U * 0.25 ms\n Memory work:   %U/255\n Memory idle:   %U/255\n"
STR_BUF_END:
