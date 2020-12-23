/**
******************************************************************************
* @file    ram64k_8.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Synchronous RAM 64k x 8
******************************************************************************
*/

module RAM_64Kx8(
    input  [15:0] i_addr,
    input         i_enable_x,
    input         i_write_x,
    input   [7:0] i_data,
    output  [7:0] o_data
);

parameter delay = 10;

RAM #(.delay(delay),
      .width(8),
      .depth(16))
  ram(
      .i_addr    (i_addr),
      .i_enable_x(i_enable_x),
      .i_write_x (i_write_x),
      .i_data    (i_data),
      .o_data    (o_data)
);

endmodule
