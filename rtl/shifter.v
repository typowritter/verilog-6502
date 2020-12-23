/**
******************************************************************************
* @file    shifter.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Shifter
******************************************************************************
*/

module Shifter(
    input  [7:0] i_data,
    input        i_rotate,
    input        i_right,
    input        i_c,
    output [7:0] o_data,
    output       o_n,
    output       o_z,
    output       o_c
);

wire   [8:0] to_left;
wire   [8:0] to_right;

assign o_data     = i_right ? to_right[8:1] : to_left[7:0];
assign o_n        = o_data[7];
assign o_z        = o_data == 8'h00;
assign o_c        = i_right ? to_right[0] : to_left[8];

assign to_left  = { i_data, i_rotate ? i_c : 1'b0 };
assign to_right = { i_rotate ? i_c : 1'b0, i_data };

endmodule
