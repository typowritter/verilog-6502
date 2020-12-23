/**
  ******************************************************************************
  * @file    exec_controller.v
  * @author  yxnan <yxnan@pm.me>
  * @year    2020
  * @brief   Execution Controller
  ******************************************************************************
  */

module ExecutionController(
    input        clk,
    input        rst_x,
    // Decoder interfaces
    input        dec_reset_c,
    input        dec_set_c,
    input        dec_reset_i,
    input        dec_set_i,
    input        dec_reset_v,
    input        dec_reset_d,
    input        dec_set_d,
    input        dec_load,
    input        dec_ops,
    input        dec_branch,
    input  [4:0] dec_opcode,
    input  [7:0] dec_data,
    input  [1:0] dec_reg,
    output       dec_done,
    // Register File interfaces
    input  [7:0] rgf_pcl,
    input  [7:0] rgf_pch,
    input  [7:0] rgf_a,
    input  [7:0] rgf_x,
    input  [7:0] rgf_y,
    input        rgf_c_in,
    input        rgf_d_in,
    input        rgf_n_in,
    input        rgf_v_in,
    input        rgf_z_in,
    output       rgf_c,
    output       rgf_set_c,
    output       rgf_i,
    output       rgf_set_i,
    output       rgf_v,
    output       rgf_set_v,
    output       rgf_d,
    output       rgf_set_d,
    output       rgf_n,
    output       rgf_set_n,
    output       rgf_z,
    output       rgf_set_z,
    output [7:0] rgf_data,
    output       rgf_set_a,
    output       rgf_set_x,
    output       rgf_set_y,
    output       rgf_set_s,
    output       rgf_set_pcl,
    output       rgf_set_pch,
    // Memory Controller interfaces
    output [7:0] mem_data,
    output       mem_store
);

reg          r_done;
reg          r_branch;
reg          r_shift;
reg          r_inc;
reg    [7:0] r_data;
reg    [1:0] r_m2m_cnt;

wire         update_flag;

wire   [2:0] opcode;
wire         opx_10;
wire         opx_11;
wire         opx_01;
wire         opx_00;

wire   [7:0] w_ora;
wire   [7:0] w_and;
wire   [7:0] w_eor;

wire         use_alu;
wire         ops_set_nz;
wire         shift_set_cnz;
wire         w_cmp;
wire         w_sbc;
wire         w_inc;
wire         w_dec;
wire         w_shift_rotate;
wire         w_shift_right;
wire         w_shift_a;
wire         w_shift;
wire         w_dexy;
wire         w_indexy;
wire         w_bit;
wire         w_plp;

wire         m2m_done;

wire   [7:0] alu_in_a;
wire   [7:0] alu_in_b;
wire   [7:0] alu_out;
wire         alu_cin;
wire         alu_sbc;
wire         alu_n;
wire         alu_z;
wire         alu_c;
wire         alu_v;

wire   [7:0] shift_in;
wire   [7:0] shift_out;
wire         shift_n;
wire         shift_z;
wire         shift_c;

wire   [7:0] bit_out;
wire         bit_n;
wire         bit_z;
wire         bit_v;
wire         bit_set_nzv;

wire         taken;
wire         b_carry;
wire         b_inc;
wire         b_dec;

`include "opcode.vh"

assign dec_done       = r_done | r_branch | dec_load | m2m_done |
                        (dec_ops & !opx_10) |
                        (dec_branch & !b_carry);

assign rgf_c          = w_plp ? dec_data[0] :
                        use_alu ? alu_c :
                        shift_set_cnz ? shift_c :
                        dec_set_c;
assign rgf_set_c      = w_plp | use_alu | shift_set_cnz |
                        dec_set_c | dec_reset_c;
assign rgf_i          = w_plp ? dec_data[2] : dec_set_i;
assign rgf_set_i      = w_plp | dec_set_i | dec_reset_i;
assign rgf_v          = w_plp ? dec_data[6] :
                        use_alu ? alu_v :
                        bit_set_nzv ? bit_v :
                        1'b0;
assign rgf_set_v      = w_plp | dec_reset_v | bit_set_nzv |
                        (use_alu & (opcode != OP_CMP));
assign rgf_d          = w_plp ? dec_data[3] : dec_set_d;
assign rgf_set_d      = w_plp | dec_set_d | dec_reset_d;
assign rgf_n          = w_plp ? dec_data[7] :
                        shift_set_cnz ? shift_n :
                        bit_set_nzv ? bit_n :
                        (use_alu | m2m_done) ? alu_n :
                        rgf_data[7];
assign rgf_set_n      = w_plp | use_alu | m2m_done | ops_set_nz;
assign rgf_z          = w_plp ? dec_data[1] :
                        shift_set_cnz ? shift_z :
                        bit_set_nzv ? bit_z :
                        (use_alu | m2m_done) ? alu_z :
                        (rgf_data == 8'h00);
assign rgf_set_z      = w_plp | use_alu | m2m_done | ops_set_nz;
assign rgf_data       = (use_alu | taken | r_branch) ? alu_out :
                        ((w_inc | w_dec) & dec_load) ? alu_out :
                        w_shift_a ? shift_out :
                        (dec_ops & opx_10) ? dec_data :
                        !dec_ops ? dec_data :
                        (opcode == OP_ORA) ? w_ora :
                        (opcode == OP_AND) ? w_and :
                        (opcode == OP_EOR) ? w_eor :
                        (opcode == OP_LDA) ? dec_data :
                        8'hxx;
assign rgf_set_a      = (dec_load & (dec_reg == REG_A)) |
                        (dec_ops & opx_01 & ((opcode == OP_ORA) |
                                             (opcode == OP_AND) |
                                             (opcode == OP_EOR) |
                                             (opcode == OP_ADC) |
                                             (opcode == OP_SBC)));
assign rgf_set_x      = dec_load & (dec_reg == REG_X);
assign rgf_set_y      = dec_load & (dec_reg == REG_Y);
assign rgf_set_s      = dec_load & (dec_reg == REG_S);
assign rgf_set_pcl    = taken;
assign rgf_set_pch    = r_branch;

assign mem_data       = r_shift ? shift_out : alu_out;
assign mem_store      = m2m_done;

assign update_flag    = dec_reset_c | dec_set_c | dec_reset_i |
                        dec_set_i | dec_reset_v | dec_reset_d |
                        dec_set_d;

assign opcode         = dec_opcode[2:0];
assign opx_10         = dec_opcode[4:3] == 2'b10;
assign opx_11         = dec_opcode[4:3] == 2'b11;
assign opx_01         = dec_opcode[4:3] == 2'b01;
assign opx_00         = dec_opcode[4:3] == 2'b00;

assign w_ora          = rgf_a | dec_data;
assign w_and          = rgf_a & dec_data;
assign w_eor          = rgf_a ^ dec_data;

assign use_alu        = dec_ops & opx_01 & ((opcode == OP_ADC) |
                                            (opcode == OP_SBC) |
                                            (opcode == OP_CMP));
assign ops_set_nz     = (dec_ops & opx_01 & (opcode != OP_STA)) |
                        bit_set_nzv | w_indexy;
assign shift_set_cnz  = w_shift_a | (r_shift & m2m_done);
assign w_cmp          = dec_ops & opx_01 & (opcode == OP_CMP);
assign w_sbc          = dec_ops & opx_01 & (opcode == OP_SBC);
assign w_inc          = dec_ops & opx_10 & (opcode == OP_INC);
assign w_dec          = dec_ops & opx_10 & (opcode == OP_DEC);
assign w_shift_rotate = (opcode == OP_ROL) | (opcode == OP_ROR);
assign w_shift_right  = (opcode == OP_LSR) | (opcode == OP_ROR);
assign w_shift_a      = w_shift & dec_load;
assign w_shift        = dec_ops & opx_10 & ((opcode == OP_ASL) |
                                            (opcode == OP_ROL) |
                                            (opcode == OP_LSR) |
                                            (opcode == OP_ROR));
assign w_dexy         = w_dec & dec_load & (dec_reg != REG_A);
assign w_indexy       = (w_inc | w_dec) & dec_load & (dec_reg != REG_A);
assign w_bit          = opx_00 & (opcode == OP_BIT);
assign w_plp          = dec_ops & opx_11 & (opcode == OP_PLP);

assign m2m_done       = r_m2m_cnt == 2'b01;

assign alu_in_a       = dec_branch ? rgf_pcl :
                        r_branch ? rgf_pch :
                        w_indexy ? dec_data :
                        r_m2m_cnt[0] ? r_data :
                        (dec_reg == REG_X) ? rgf_x :
                        (dec_reg == REG_Y) ? rgf_y :
                        rgf_a;
assign alu_in_b       = r_branch ? 8'h00 :
                        r_m2m_cnt[0] ? 8'h00 :
                        w_indexy ? 8'h00 :
                        dec_data;
assign alu_cin        = r_branch ? r_inc :
                        r_m2m_cnt[0] ? r_inc :
                        (rgf_c_in | w_cmp | dec_branch | w_inc);
assign alu_sbc        = ((r_branch | (r_m2m_cnt != 2'b00)) & !r_inc) |
                        (w_dec & dec_load) | w_sbc | w_cmp;

assign shift_in       = r_m2m_cnt[0] ? r_data : dec_data;

assign taken          = !dec_branch ? 1'b0 :
                        (opcode == OP_BPL) ? !rgf_n_in :
                        (opcode == OP_BMI) ? rgf_n_in :
                        (opcode == OP_BVC) ? !rgf_v_in :
                        (opcode == OP_BVS) ? rgf_v_in :
                        (opcode == OP_BCC) ? !rgf_c_in :
                        (opcode == OP_BCS) ? rgf_c_in :
                        (opcode == OP_BNE) ? !rgf_z_in :
                        rgf_z_in;
assign b_inc          = !dec_data[7] & alu_c;
assign b_dec          = dec_data[7] & !alu_c;
assign b_carry        = taken & dec_branch & (b_inc | b_dec);

assign bit_out        = dec_data & rgf_a;
assign bit_set_nzv    = dec_ops & w_bit;
assign bit_z          = bit_out == 8'h00;
assign bit_n          = bit_out[7];
assign bit_v          = bit_out[0];

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_done    <= 1'b0;
        r_branch  <= 1'b0;
        r_shift   <= 1'b0;
        r_inc     <= 1'b0;
        r_data    <= 1'b0;
        r_m2m_cnt <= 2'b00;
    end else begin
        r_done    <= update_flag;
        r_branch  <= b_carry;
        if (dec_ops) begin
            r_shift   <= w_shift;
        end
        if (r_m2m_cnt == 2'b00) begin
            r_inc     <= b_inc | w_inc;
        end
        if ((w_inc | w_dec | w_shift) & !dec_load)  begin
            r_data    <= dec_data;
            r_m2m_cnt <= 2'b11;
        end else if (r_m2m_cnt != 2'b00) begin
            r_m2m_cnt <= { 1'b0, r_m2m_cnt[1] };
        end
    end
end

ALU alu(
    .INA (alu_in_a),
    .INB (alu_in_b),
    .CIN (alu_cin),
    .BCD (rgf_d_in),
    .SBC (alu_sbc),
    .OUT (alu_out),
    .N   (alu_n),
    .Z   (alu_z),
    .C   (alu_c),
    .V   (alu_v)
);

Shifter shifter(
    .i_data   (shift_in),
    .i_rotate (w_shift_rotate),
    .i_right  (w_shift_right),
    .i_c      (rgf_c_in),
    .o_data   (shift_out),
    .o_n      (shift_n),
    .o_z      (shift_z),
    .o_c      (shift_c)
);

endmodule
