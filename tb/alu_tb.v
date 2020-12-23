/**
******************************************************************************
* @file    alu_tb.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Testbench for ALU
******************************************************************************
*/

`timescale 100ps/100ps

module ALU_Test;
wire [7:0] w_a;
wire       w_n;
wire       w_z;
wire       w_c;
wire       w_v;

reg  [7:0] r_a;
reg  [7:0] r_m;
reg        r_c;
reg        r_d;
reg        r_s;

reg        clk;

ALU dut(
    .INA (r_a),
    .INB (r_m),
    .CIN (r_c),
    .BCD (r_d),
    .SBC (r_s),
    .OUT (w_a),
    .N   (w_n),
    .Z   (w_z),
    .C   (w_c),
    .V   (w_v)
);

always #1 clk = !clk;

always @ (posedge clk) begin
    $display("result = %04b_%04b, n=%b, z=%b, c=%b, v=%b",
            w_a[7:4], w_a[3:0], w_n, w_z, w_c, w_v);
end

initial begin
    $dumpfile("vcd/ALU.vcd");
    $dumpvars(0, dut);
    clk <= 1'b0;
    r_d <= 1'b0;
    r_s <= 1'b0;

    r_a <= 8'b00001101;
    r_m <= 8'b11010011;
    r_c <= 1'b1;
    #2

    r_a <= 8'b11111110;
    r_m <= 8'b00000110;
    r_c <= 1'b1;
    #2

    r_a <= 8'b00000101;
    r_m <= 8'b00000111;
    r_c <= 1'b0;
    #2

    r_a <= 8'b01111111;
    r_m <= 8'b00000010;
    r_c <= 1'b1;
    #2

    r_a <= 8'b00000101;
    r_m <= 8'b11111101;
    r_c <= 1'b0;
    #2

    r_a <= 8'b00000101;
    r_m <= 8'b11111001;
    r_c <= 1'b0;
    #2

    r_a <= 8'b11111011;
    r_m <= 8'b11111001;
    r_c <= 1'b0;
    #2

    r_a <= 8'b10111110;
    r_m <= 8'b10111111;
    r_c <= 1'b0;
    #2

    r_a <= 8'b01111001;
    r_m <= 8'b00010100;
    r_c <= 1'b0;
    r_d <= 1'b1;
    #2

    r_a <= 8'b00000101;
    r_m <= 8'b00000011;
    r_c <= 1'b1;
    r_d <= 1'b0;
    r_s <= 1'b1;
    #2

    r_a <= 8'b00000101;
    r_m <= 8'b00000110;
    r_c <= 1'b1;
    #2

    r_a <= 8'b01000100;
    r_m <= 8'b00101001;
    r_c <= 1'b1;
    r_d <= 1'b1;
    #2
    $finish;
end
endmodule
