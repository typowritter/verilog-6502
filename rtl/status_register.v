/**
******************************************************************************
* @file    status_register.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Processor Status Register
******************************************************************************
*/

module StatusRegister(
    input clk,
    input rst_x,
    input c_carry,      // C
    input i_intr,       // I
    input v_overflow,   // V
    input d_bcd,        // D
    input n_negative,   // N
    input z_zero,       // Z
    input b_brk,        // B
    input set_c,
    input set_i,
    input set_v,
    input set_d,
    input set_n,
    input set_z,
    input set_b,
    output [7:0] o_psr
);

reg   r_n;
reg   r_v;
reg   r_b;
reg   r_d;
reg   r_i;
reg   r_z;
reg   r_c;

assign o_psr = { r_n, r_v, 1'b1, r_b, r_d, r_i, r_z, r_c };

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_n <= 1'b0;
        r_v <= 1'b0;
        r_b <= 1'b0;
        r_d <= 1'b0;
        r_i <= 1'b0;
        r_z <= 1'b0;
        r_c <= 1'b0;
    end else begin
        if (set_c) begin
            r_c <= c_carry;
        end
        if (set_i) begin
            r_i <= i_intr;
        end
        if (set_v) begin
            r_v <= v_overflow;
        end
        if (set_d) begin
            r_d <= d_bcd;
        end
        if (set_n) begin
            r_n <= n_negative;
        end
        if (set_z) begin
            r_z <= z_zero;
        end
        if (set_b) begin
            r_b <= b_brk;
        end
    end
end
endmodule
