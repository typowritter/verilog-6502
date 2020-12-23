/**
  ******************************************************************************
  * @file    alu.v
  * @author  yxnan <yxnan@pm.me>
  * @year    2020
  * @brief   Arithmetic unit (no Logical part) for Accumulator Register
  ******************************************************************************
  */

module ALU(
    input  [7:0] INA,
    input  [7:0] INB,
    input        SBC,   // perform subtraction?
    input        CIN,   // processor status flag C
    input        BCD,   // processor status flag D
    output [7:0] OUT,   // data out
    output       N,     // PSF Negative
    output       Z,     // PSF Zero
    output       C,     // PSF Carry
    output       V      // PSF Overflow
);

wire   [7:0] num_b;
wire   [4:0] sum_lo;
wire   [4:0] sum_hi;
wire         bcd_over_lo;
wire   [4:0] bcd_sum_lo;
wire   [4:0] bcd_sum_hi;
wire   [3:0] bcd_fix;
wire   [4:0] sum_low;
wire   [4:0] sum_high;
wire         carry;

assign num_b        = SBC ? ~INB : INB;
assign bcd_fix      = SBC ? 4'ha : 4'h6;
assign sum_lo       = INA[3:0] + num_b[3:0] + { 3'b000, CIN };
assign bcd_over_lo  = sum_lo > 5'h9;
assign bcd_sum_lo   = bcd_over_lo ? (sum_lo + bcd_fix) : sum_lo;
assign sum_low      = BCD ? bcd_sum_lo : sum_lo;
assign carry        = BCD ? bcd_over_lo ^ SBC : sum_low[4];
assign sum_hi       = INA[7:4] + num_b[7:4] + { 3'b000, carry };
assign bcd_sum_hi   = (sum_hi[3:0] < 4'ha) ? sum_hi : (sum_hi + bcd_fix);
assign sum_high     = BCD ? bcd_sum_hi : sum_hi;
assign OUT          = { sum_high[3:0], sum_low[3:0] };
assign N            = OUT[7];
assign Z            = OUT == 8'h00;
assign C            = sum_high[4];
assign V            = (!(INA[7] ^ num_b[7]) & (INA[7] ^ OUT[7]));

endmodule
