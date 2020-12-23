/**
  ******************************************************************************
  * @file    decoder.v
  * @author  yxnan <yxnan@pm.me>
  * @year    2020
  * @brief   Instruction Decoder
  ******************************************************************************
  */

module Decoder(
    input clk,
    input rst_x,
    // Memory Controller interfaces
    input    [7:0] mem_data,
    input          mem_valid,
    output         mem_fetch,
    output         mem_sync,
    output         mem_operand,
    output         mem_modex,
    output   [2:0] mem_mode,
    output   [1:0] mem_reg,
    output         mem_store,
    output         mem_push,
    output         mem_pop,
    output         mem_p_reg,
    output         mem_jump,
    // Execution Controller interfaces
    input          exec_done,
    output         exec_reset_c,
    output         exec_set_c,
    output         exec_reset_i,
    output         exec_set_i,
    output         exec_reset_v,
    output         exec_reset_d,
    output         exec_set_d,
    output         exec_load,
    output         exec_ops,
    output         exec_branch,
    output   [4:0] exec_opcode,
    output   [7:0] exec_data,
    output   [1:0] exec_reg
);

reg        r_sync;
reg        r_load;
reg        r_ops;
reg        r_branch;
reg        r_set_reg;
reg  [1:0] r_reg;
reg  [2:0] r_opcode;
reg  [1:0] r_opx;

wire [2:0] opcode;
wire [2:0] modified_opcode;
wire [2:0] addressing;

wire       fetch_valid;
wire       operand_valid;

wire       unknown_instruction;
wire       fmt_xxxx_xx00;
wire       fmt_xxxx_xx01;
wire       fmt_xxxx_xx10;
wire       fmt_xxxx_1x00;
wire       fmt_xxxx_0000;
wire       fmt_xxxx_1000;
wire       fmt_xxx0_0000;
wire       fmt_xxx0_1000;
wire       fmt_xxx0_1100;
wire       fmt_xxx1_0000;
wire       fmt_xxx1_1000;
wire       fmt_10xx_xxxx;

// Standard addressing mode (---X_XX--)
wire       indexed_indirect;    // (Indirect, X)
wire       zero_page;           // Zero Page
wire       immediate;           // Immediate
wire       absolute;            // Absolute
wire       indirect_index;      // (Indirect), Y
wire       zero_page_index;     // Zero Page, X
wire       absolute_indexed_y;  // Absolute, Y
wire       absolute_indexed_x;  // Absolute, X

wire       modex_immediate;
wire       modex_register;

wire       ldx_code;
wire       ldy_code;
wire       inc_code;
wire       dec_code;
wire       shift_code;
wire       bit_code;
wire       stx_code;
wire       sty_code;
wire       cpx_code;
wire       cpy_code;

wire       w_tya;
wire       w_tay;
wire       w_lda;
wire       w_ldx;
wire       w_ldy;
wire       w_sta;
wire       w_stx;
wire       w_sty;
wire       w_t;
wire       w_b;
wire       w_ops;
wire       w_inc;
wire       w_dec;
wire       w_inx;
wire       w_iny;
wire       w_dex;
wire       w_dey;
wire       w_inxy;
wire       w_dexy;
wire       w_index;
wire       w_indey;
wire       w_indexy;
wire       w_shift;
wire       w_bit;
wire       w_cpx;
wire       w_cpy;
wire       w_pla;
wire       w_plp;
wire       w_jmp_ind;
wire       w_jmp;
wire       w_j;
wire       w_jsr;
wire       w_call;
wire       w_return;
wire       w_interrupt;

wire       request_reg;
wire [1:0] from_reg;
wire [1:0] to_reg;

wire       valid_ld_mode;
wire       valid_inc_mode;
wire       valid_shift_mode;
wire       valid_bit_mode;
wire       valid_stx_mode;
wire       valid_sty_mode;
wire       valid_cp_mode;

`include "opcode.vh"

assign mem_sync           = r_sync;
assign mem_fetch          = r_sync;
assign opcode             = mem_data[7:5];
assign addressing         = mem_data[4:2];
assign mem_operand        = w_ldx | w_ldy | request_reg | w_ops | w_b |
                            w_inc | w_dec | w_shift | w_bit | w_stx |
                            w_sty | w_cpx | w_cpy | mem_push |
                            mem_pop | mem_jump;
assign mem_mode           = request_reg ? MODEX_REGISTER :
                            w_b ? MODE_IMMEDIATE :
                            w_jmp_ind ?  MODEX_INDIRECT_PC :
                            w_jsr ? MODEX_ABSOLUTE_PC :
                            addressing;
assign mem_modex          = request_reg | w_ldx | w_cpx | w_cpy |
                            w_jmp | (w_j & w_return) |
                            (w_ldy & modex_immediate) |
                            (w_shift & modex_register) |
                            (w_stx & zero_page_index);
assign mem_reg            = from_reg;
assign mem_store          = w_sta | w_stx | w_sty;
assign mem_jump           = w_jmp | w_j;

assign mem_push           = (w_j & w_call) |
                            (fmt_xxx0_1000 & ((opcode == OP_PHP) |
                                              (opcode == OP_PHA)));

assign mem_pop            = (w_j & w_return) |
                            (fmt_xxx0_1000 & ((opcode == OP_PLP) |
                                              (opcode == OP_PLA)));

assign mem_p_reg          = (w_j & w_interrupt) |
                            (fmt_xxx0_1000 & ((opcode == OP_PHP) |
                                              (opcode == OP_PLP)));

assign modified_opcode    = w_inxy ? OP_INC :
                            w_dexy ? OP_DEC :
                            (w_stx | w_sty) ? OP_STA :
                            (w_cpx | w_cpy) ? OP_CMP :
                            w_pla ? OP_LDA :
                            opcode;

assign fetch_valid        = mem_valid & r_sync;
assign operand_valid      = mem_valid & !r_sync;

assign fmt_xxxx_xx00      = fetch_valid & (mem_data[1:0] == 2'b00);
assign fmt_xxxx_xx01      = fetch_valid & (mem_data[1:0] == 2'b01);
assign fmt_xxxx_xx10      = fetch_valid & (mem_data[1:0] == 2'b10);
assign fmt_xxxx_1x00      = fmt_xxxx_xx00 & mem_data[3];
assign fmt_xxxx_0000      = fmt_xxxx_xx00 & (mem_data[3:2] == 2'b00);
assign fmt_xxxx_1000      = fmt_xxxx_1x00 & !mem_data[2];
assign fmt_xxx0_1000      = fmt_xxxx_1000 & !mem_data[4];
assign fmt_xxx0_1100      = fmt_xxxx_1x00 & !mem_data[4] & mem_data[2];
assign fmt_xxx0_0000      = fmt_xxxx_0000 & !mem_data[4];
assign fmt_xxx1_0000      = fmt_xxxx_0000 & mem_data[4];
assign fmt_xxx1_1000      = fmt_xxxx_1000 & mem_data[4];
assign fmt_10xx_xxxx      = fetch_valid & (mem_data[7:6] == 2'b10);

assign indexed_indirect   = addressing == MODE_INDEXED_INDIRECT;
assign zero_page          = addressing == MODE_ZERO_PAGE;
assign immediate          = addressing == MODE_IMMEDIATE;
assign absolute           = addressing == MODE_ABSOLUTE;
assign indirect_index     = addressing == MODE_INDIRECT_INDEX;
assign zero_page_index    = addressing == MODE_ZERO_PAGE_INDEX_X;
assign absolute_indexed_y = addressing == MODE_ABSOLUTE_INDEXED_Y;
assign absolute_indexed_x = addressing == MODE_ABSOLUTE_INDEXED_X;

assign modex_immediate    = addressing == MODEX_IMMEDIATE;
assign modex_register     = addressing == MODEX_REGISTER;

assign exec_reset_c       = fmt_xxx1_1000 & (opcode == 3'b000);
assign exec_set_c         = fmt_xxx1_1000 & (opcode == 3'b001);
assign exec_reset_i       = fmt_xxx1_1000 & (opcode == 3'b010);
assign exec_set_i         = fmt_xxx1_1000 & (opcode == 3'b011);
assign exec_reset_v       = fmt_xxx1_1000 & (opcode == 3'b101);
assign exec_reset_d       = fmt_xxx1_1000 & (opcode == 3'b110);
assign exec_set_d         = fmt_xxx1_1000 & (opcode == 3'b111);
assign exec_data          = mem_data;
assign exec_load          = operand_valid & (r_load | w_lda);
assign exec_ops           = r_ops & operand_valid;
assign exec_branch        = r_branch & operand_valid;
assign exec_opcode        = { r_opx, r_opcode };
assign exec_reg           = r_reg;

assign unknown_instruction = fetch_valid & !mem_operand & !fmt_xxx1_1000;

assign valid_ld_mode      = modex_immediate | zero_page | absolute |
                            zero_page_index | absolute_indexed_x;
assign valid_inc_mode     = zero_page | zero_page_index |
                            absolute | absolute_indexed_x;
assign valid_shift_mode   = valid_inc_mode | modex_register;
assign valid_bit_mode     = zero_page | absolute;
assign valid_stx_mode     = zero_page | absolute | zero_page_index;
assign valid_sty_mode     = zero_page | absolute | zero_page_index;
assign valid_cp_mode      = modex_immediate | zero_page | absolute;

assign ldx_code           = fmt_xxxx_xx10 & (opcode == OP_LDX);
assign ldy_code           = fmt_xxxx_xx00 & (opcode == OP_LDY);
assign inc_code           = fmt_xxxx_xx10 & (opcode == OP_INC);
assign dec_code           = fmt_xxxx_xx10 & (opcode == OP_DEC);
assign shift_code         = fmt_xxxx_xx10 & ((opcode == OP_ASL) |
                                             (opcode == OP_ROL) |
                                             (opcode == OP_LSR) |
                                             (opcode == OP_ROR));
assign bit_code           = fmt_xxxx_xx00 & (opcode == OP_BIT);
assign stx_code           = fmt_xxxx_xx10 & (opcode == OP_STX);
assign sty_code           = fmt_xxxx_xx00 & (opcode == OP_STY);
assign cpx_code           = fmt_xxxx_xx00 & (opcode == OP_CPX);
assign cpy_code           = fmt_xxxx_xx00 & (opcode == OP_CPY);
assign w_ldx              = ldx_code & valid_ld_mode;
assign w_ldy              = ldy_code & valid_ld_mode;
assign w_tya              = fmt_xxx1_1000 & (opcode == 3'b100);
assign w_tay              = fmt_xxx0_1000 & (opcode == OP_TAY);
assign w_lda              = r_ops & (r_opx == 2'b01) &
                            (r_opcode == OP_LDA);
assign w_t                = w_tya | w_tay |
                            (fmt_10xx_xxxx & (mem_data[3:0] == 4'b1010));
assign w_b                = fmt_xxx1_0000;
assign w_ops              = fmt_xxxx_xx01;
assign w_inc              = inc_code & valid_inc_mode;
assign w_dec              = dec_code & valid_inc_mode;
assign w_shift            = shift_code & valid_shift_mode;
assign w_bit              = bit_code & valid_bit_mode;
assign w_sta              = w_ops & (opcode == OP_STA) & !immediate;
assign w_stx              = stx_code & valid_stx_mode;
assign w_sty              = sty_code & valid_sty_mode;
assign w_inx              = fmt_xxx0_1000 & (opcode == OP_INX);
assign w_iny              = fmt_xxx0_1000 & (opcode == OP_INY);
assign w_dex              = inc_code & immediate;
assign w_dey              = fmt_xxx0_1000 & (opcode == OP_DEY);
assign w_inxy             = w_inx | w_iny;
assign w_dexy             = w_dex | w_dey;
assign w_index            = w_inx | w_dex;
assign w_indey            = w_iny | w_dey;
assign w_indexy           = w_inx | w_iny | w_dex | w_dey;
assign w_cpx              = cpx_code & valid_cp_mode;
assign w_cpy              = cpy_code & valid_cp_mode;
assign w_pla              = fmt_xxx0_1000 & (opcode == OP_PLA);
assign w_plp              = fmt_xxx0_1000 & (opcode == OP_PLP);
assign w_jmp_ind          = fmt_xxx0_1100 & (opcode == OP_JMP_IND);
assign w_jmp              = fmt_xxx0_1100 & ((opcode == OP_JMP_ABS) |
                                             (opcode == OP_JMP_IND));
assign w_j                = fmt_xxx0_0000 & !mem_data[7];
assign w_jsr              = fmt_xxx0_0000 & (opcode == OP_JSR);
assign w_call             = (opcode == OP_BRK) | (opcode == OP_JSR);
assign w_return           = (opcode == OP_RTI) | (opcode == OP_RTS);
assign w_interrupt        = (opcode == OP_BRK) | (opcode == OP_RTI);

assign request_reg        = w_t | w_indexy;
assign from_reg           = (w_tya | w_indey | w_sty) ? REG_Y :
                            (w_tay | w_shift | w_sta) ? REG_A :
                            (!mem_data[5] | w_index | w_stx) ? REG_X :
                            mem_data[4] ? REG_S :
                            REG_A;
assign to_reg             = w_tya ? REG_A :
                            (w_tay | w_indey) ? REG_Y :
                            (mem_data[5] | w_index) ? REG_X :
                            mem_data[4] ? REG_S :
                            REG_A;

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_sync    <= 1'b1;
        r_load    <= 1'b0;
        r_ops     <= 1'b0;
        r_branch  <= 1'b0;
        r_reg     <= 2'b00;
        r_opcode  <= 3'b000;
        r_opx     <= 2'b00;
    end else begin
        r_sync    <= exec_done | (r_sync & !mem_valid);
        if (fetch_valid) begin
            r_load   <= w_ldx | w_ldy | w_t | w_indexy |
                        (w_shift & modex_register);
            r_ops    <= w_ops | w_inc | w_dec | w_shift | w_indexy | w_bit |
                        w_stx | w_sty | w_cpx | w_cpy | mem_push | mem_pop |
                        mem_jump;
            r_branch <= w_b;
            r_reg    <= (w_ldx | w_cpx) ? REG_X :
                        (w_ldy | w_cpy) ? REG_Y :
                        request_reg ? to_reg : REG_A;
            r_opcode <= modified_opcode;
            r_opx    <= w_indexy ? 2'b10 :
                        w_plp ? 2'b11 :
                        (w_stx | w_sty | w_cpx | w_cpy | w_pla) ? 2'b01 :
                        mem_data[1:0];
        end
    end
end
endmodule
