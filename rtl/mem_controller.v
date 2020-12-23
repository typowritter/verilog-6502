/**
******************************************************************************
* @file    mem_controller.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Memory Controller
******************************************************************************
*/

module MemoryController(
    input         clk,
    input         rst_x,
    input         i_rdy,
    input  [ 7:0] i_db,
    output [ 7:0] o_db,
    output [15:0] o_ab,
    output        o_rw,
    output        o_sync,
    // Interrupt interfaces
    input  [15:0] intr_addr,
    input         intr_read,
    input         intr_write,
    input   [7:0] intr_data_in,
    output  [7:0] intr_data,
    output        intr_brk,
    // Register File interfaces
    input  [15:0] rgf_pc_in,
    input  [ 7:0] rgf_a,
    input  [ 7:0] rgf_x,
    input  [ 7:0] rgf_y,
    input  [ 7:0] rgf_s,
    input  [ 7:0] rgf_psr_in,
    output        rgf_fetched,
    output        rgf_pushed,
    output        rgf_pull,
    output [15:0] rgf_pc,
    output        rgf_set_pc,
    output [ 7:0] rgf_psr,
    output        rgf_set_psr,
    // Decoder interfaces
    input         dec_fetch,
    input         dec_sync,
    input         dec_operand,
    input   [2:0] dec_mode,
    input         dec_modex,
    input   [1:0] dec_reg,
    input         dec_store,
    input         dec_push,
    input         dec_pop,
    input         dec_p_reg,
    input         dec_jump,
    output  [7:0] dec_data,
    output        dec_valid,
    // Execution Controller interfaces
    input   [7:0] exec_data,
    input         exec_store
);

reg    [ 2:0] r_operand;
reg           r_modex;
reg    [ 2:0] r_mode;
reg    [15:0] r_data;
reg    [ 1:0] r_reg;
reg           r_carry;
reg           r_store;
reg           r_push;
reg           r_pop;
reg           r_jump;

wire          adder_valid;
wire   [ 8:0] adder_sum;
wire   [ 7:0] adder_in_a;
wire   [ 7:0] adder_in_b;

wire          write;
wire          push_cycle;
wire          pop_cycle;
wire          int_active;
wire   [15:0] int_addr;
wire          decoder_active;
wire   [15:0] decoder_addr;
wire          w_1t_mode;
wire          w_2t_mode;
wire          w_3t_mode;
wire          w_4t_mode;
wire          w_5t_mode;
wire          w_6t_mode;
wire          w_fetch_opcode;
wire          w_fetch_next;
wire          w_register;
wire          w_immediate;
wire          w_absolute;
wire          w_absolute_pc;
wire          w_indirect_pc;
wire          w_abs_idx;
wire          w_abs_idx_x;
wire          w_abs_idx_y;
wire          w_zero_page;
wire          w_zero_idx;
wire          w_zero_idx_x;
wire          w_zero_idx_y;
wire          w_indirect;
wire          w_indirect_x;
wire          w_indirect_y;
wire   [15:0] w_immediate_addr;
wire   [15:0] w_absolute_addr;
wire   [15:0] w_abs_idx_addr;
wire   [15:0] w_zero_page_addr;
wire   [15:0] w_zero_idx_addr;
wire   [15:0] w_indirect_addr;
wire   [15:0] w_idx_ind_addr;
wire   [15:0] w_ind_idx_addr;
wire          w_abs_idx_add;
wire          w_zero_idx_add;
wire          w_idx_ind_add;
wire          w_ind_idx_add;
wire   [ 7:0] w_register_data;
wire   [ 7:0] w_jsr_data;
wire          w_jmp;
wire          w_jsr;
wire          w_brk;
wire          w_rts;
wire          w_rti;

`include "opcode.vh"

assign o_db           = exec_store ? exec_data :
                        intr_write ? intr_data_in :
                        (r_push & r_jump) ? w_jsr_data :
                        (r_reg == REG_A) ? rgf_a :
                        (r_reg == REG_Y) ? rgf_y :
                        (r_push & !r_jump) ? rgf_psr_in :
                        rgf_x;
assign o_ab           = int_active ? int_addr :
                        exec_store ? r_data :
                        push_cycle ? { 8'h01, rgf_s } :
                        pop_cycle ? { 8'h01, rgf_s } :
                        decoder_addr;
assign o_rw           = !write;
assign o_sync         = decoder_active & dec_sync;

assign intr_data      = intr_read ? i_db : 8'hxx;
assign intr_brk       = w_brk & (r_operand == 3'b101);

assign rgf_fetched    = w_fetch_opcode | w_fetch_next;
assign rgf_pushed     = push_cycle;
assign rgf_pull       = ((w_rts | w_rti) & ((r_operand == 3'b101) |
                                            (r_operand == 3'b100))) |
                        (!w_rts & r_pop & (r_operand == 3'b011));
assign rgf_pc         = (w_jsr | w_rts | w_rti) ? r_data :
                        { i_db, r_data[15:8] };
assign rgf_set_pc     = (w_jmp & ((r_operand == 3'b001) |
                                 ((r_operand == 3'b11) & w_indirect_pc))) |
                        ((w_jsr | w_rti)& (r_operand == 3'b001)) |
                        (w_rts & (r_operand == 3'b010));
assign rgf_psr        = rgf_set_psr ? i_db : 8'hxx;
assign rgf_set_psr    = w_rti & (r_operand == 3'b100);

assign dec_data       = (!dec_valid | write) ? 8'hxx :
                        (!w_fetch_opcode & w_register) ? w_register_data :
                        i_db;
assign dec_valid      = w_fetch_opcode | (r_operand == 3'b001);

assign write          = (r_store & (r_operand == 3'b001)) |
                        exec_store | push_cycle | intr_write;
assign push_cycle     = (r_push & !r_jump & (r_operand == 3'b010)) |
                        (w_jsr & ((r_operand == 3'b011) |
                                  (r_operand == 3'b010)));
assign pop_cycle      = r_pop & ((!r_jump & ((r_operand == 3'b010) |
                                             (r_operand == 3'b001))) |
                                (r_jump & ((r_operand == 3'b100) |
                                           (r_operand == 3'b011))) |
                                (w_rti & (r_operand == 3'b010)));
assign int_active     = intr_read | intr_write;
assign int_addr       = intr_addr;

assign decoder_active = !int_active;
assign decoder_addr   = (r_operand == 3'b000) ? rgf_pc_in :
                        w_immediate ? w_immediate_addr :
                        w_absolute ? w_absolute_addr :
                        w_abs_idx ? w_abs_idx_addr :
                        w_zero_page ? w_zero_page_addr :
                        w_zero_idx ? w_zero_idx_addr :
                        w_indirect ? w_indirect_addr :
                        rgf_pc_in;

assign w_1t_mode      = !dec_push & !dec_pop &
                        ((dec_modex & (dec_mode == MODEX_IMMEDIATE)) |
                        (!dec_modex & (dec_mode == MODE_IMMEDIATE)) |
                        (dec_modex & (dec_mode == MODEX_REGISTER)));
assign w_2t_mode      = (dec_mode == MODE_ZERO_PAGE) |
                        ((dec_mode == MODEX_ABSOLUTE_PC) & dec_jump & !dec_push) |
                        (dec_push & !dec_jump);
assign w_3t_mode      = ((dec_mode == MODE_ABSOLUTE) & !dec_jump) |
                        (dec_pop & !dec_jump) |
                        (dec_mode == MODE_ZERO_PAGE_INDEX_X) |
                        (dec_mode == MODE_ABSOLUTE_INDEXED_X) |
                        (dec_mode == MODE_ABSOLUTE_INDEXED_Y);
assign w_4t_mode      = dec_mode == MODE_INDIRECT_INDEX;
assign w_5t_mode      = !dec_jump & !dec_modex &
                        (dec_mode == MODE_INDEXED_INDIRECT) |
                        (dec_jump & dec_push & !dec_p_reg) |
                        (dec_jump & dec_pop);
assign w_6t_mode      = (dec_jump & dec_push & dec_p_reg);
assign w_register     = r_modex & (r_mode == MODEX_REGISTER);
assign w_immediate    = (r_modex & (r_mode == MODEX_IMMEDIATE)) |
                        (!r_modex & (r_mode == MODE_IMMEDIATE));
assign w_absolute     = (r_mode == MODEX_ABSOLUTE) & !r_jump;
assign w_absolute_pc  = (r_mode == MODEX_ABSOLUTE_PC) &
                        (w_jmp | (r_jump & r_push));
assign w_indirect_pc  = (r_mode == MODEX_INDIRECT_PC) & w_jmp;
assign w_abs_idx      = (r_mode == MODE_ABSOLUTE_INDEXED_X) |
                        (r_mode == MODE_ABSOLUTE_INDEXED_Y);
assign w_abs_idx_x    = !r_modex && (r_mode == MODE_ABSOLUTE_INDEXED_X);
assign w_abs_idx_y    = w_abs_idx & !w_abs_idx_x;
assign w_zero_page    = r_mode == MODEX_ZERO_PAGE;
assign w_zero_idx     = r_mode == MODE_ZERO_PAGE_INDEX_X;
assign w_zero_idx_x   = !r_modex & w_zero_idx;
assign w_zero_idx_y   = r_modex & w_zero_idx;
assign w_indirect     = !r_modex & ((r_mode == MODE_INDEXED_INDIRECT) |
                                    (r_mode == MODE_INDIRECT_INDEX));
assign w_indirect_x     = !r_modex & (r_mode == MODE_INDEXED_INDIRECT);
assign w_indirect_y     = !r_modex & (r_mode == MODE_INDIRECT_INDEX);
assign w_immediate_addr = rgf_pc_in;
assign w_absolute_addr  = (r_operand != 3'b001) ? rgf_pc_in : r_data;
assign w_abs_idx_addr   = ((r_operand == 3'b010) && r_carry) ? r_data :
                          (r_operand == 3'b001) ? r_data : rgf_pc_in;
assign w_zero_page_addr = (r_operand == 3'b010) ? rgf_pc_in :
                          { 8'h00, r_data[15:8] };
assign w_zero_idx_addr  = (r_operand == 3'b010) ? { 8'h00, r_data[15:8] } :
                          (r_operand == 3'b001) ? { 8'h00, r_data[7:0] } :
                          rgf_pc_in;
assign w_idx_ind_addr   = (r_operand == 3'b100) ? { 8'h00, r_data[15:8] } :
                          (r_operand == 3'b011) ? { 8'h00, r_data[7:0] } :
                          (r_operand == 3'b010) ? { 8'h00, r_data[7:0] } :
                          (r_operand == 3'b001) ? { 8'h00, r_data[7:0] } :
                          rgf_pc_in;
assign w_ind_idx_addr   = (r_operand == 3'b011) ? { 8'h00, r_data[15:8] } :
                          (r_operand == 3'b010) ? { 8'h00, r_data[7:0] } :
                          (r_operand == 3'b001) ? r_data :
                          rgf_pc_in;
assign w_indirect_addr  = w_indirect_x ? w_idx_ind_addr : w_ind_idx_addr;
assign w_abs_idx_add    = w_abs_idx & (r_operand == 3'b010);
assign w_zero_idx_add   = w_zero_idx & (r_operand == 3'b010);
assign w_idx_ind_add    = w_indirect_x & ((r_operand == 3'b100) |
                                          (r_operand == 3'b011));
assign w_ind_idx_add    = w_indirect_y & ((r_operand == 3'b011) |
                                          (r_operand == 3'b010));
assign w_fetch_opcode   = decoder_active & dec_fetch & i_rdy;
assign w_fetch_next     = ((w_absolute | w_abs_idx) & (r_operand == 3'b011)) |
                          (w_jmp & (r_operand == 3'b010)) |
                          (w_indirect_pc & (r_operand == 3'b100)) |
                          (w_absolute_pc & (r_operand == 3'b010)) |
                          (!w_register & !r_jump & !r_push & !r_pop &
                          (r_operand == 3'b001)) |
                          (w_brk & (r_operand == 3'b110)) |
                          (w_jsr & (r_operand == 3'b101)) |
                          (w_rts & (r_operand == 3'b001));

assign adder_in_a       = (w_idx_ind_add & (r_operand == 3'b011)) ? r_data[7:0] :
                          adder_valid ? r_data[15:8] :
                          8'h00;
assign adder_in_b       = !adder_valid ? 8'h00 :
                          r_carry ? 8'h01 :
                          (w_idx_ind_add & (r_operand == 3'b011)) ? 8'h01 :
                          (w_ind_idx_add & (r_operand == 3'b011)) ? 8'h01 :
                          (w_abs_idx_x | w_zero_idx_x | w_indirect_x) ? rgf_x :
                          rgf_y;
assign adder_sum        = adder_in_a + adder_in_b;
assign adder_valid      = (w_abs_idx_add | w_zero_idx_add | w_idx_ind_add |
                          w_ind_idx_add);

assign w_register_data  = (r_reg == REG_A) ? rgf_a :
                          (r_reg == REG_X) ? rgf_x :
                          (r_reg == REG_Y) ? rgf_y :
                          rgf_s;

assign w_jsr_data       = (r_operand == 3'b011) ? rgf_pc_in[15:8] :
                          rgf_pc_in[7:0];
assign w_jmp            = r_jump & !r_push & !r_pop;
assign w_jsr            = r_jump & r_push & !r_reg[0];
assign w_brk            = r_jump & r_push & r_reg[0];
assign w_rts            = r_jump & r_pop & !r_reg[0];
assign w_rti            = r_jump & r_pop & r_reg[0];

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_operand <= 3'b000;
        r_modex   <= 1'b0;
        r_mode    <= 3'b000;
        r_data    <= 16'h00;
        r_reg     <= 2'b00;
        r_carry   <= 1'b0;
        r_store   <= 1'b0;
        r_push    <= 1'b0;
        r_pop     <= 1'b0;
        r_jump    <= 1'b0;
    end else if (dec_operand) begin
        r_operand <= w_1t_mode ? 3'b001 :
                     w_2t_mode ? 3'b010 :
                     w_3t_mode ? 3'b011 :
                     w_4t_mode ? 3'b100 :
                     w_5t_mode ? 3'b101 :
                     w_6t_mode ? 3'b110 :
                     3'bxxx;
        r_modex   <= dec_modex;
        r_mode    <= dec_mode;
        r_reg     <= (dec_push | dec_pop) ? { 1'b0, dec_p_reg } : dec_reg;
        r_store   <= dec_store;
        r_push    <= dec_push;
        r_pop     <= dec_pop;
        r_jump    <= dec_jump;
    end else if (r_operand != 3'b000) begin
        if ((w_abs_idx | w_indirect_y) & adder_sum[8] & !r_carry) begin
            r_carry   <= 1'b1;
        end else begin
            r_operand <= r_operand - 3'b001;
            r_carry   <= 1'b0;
        end
        if (r_carry) begin
            r_data    <= { adder_sum[7:0], r_data[7:0] };
        end else if (adder_valid) begin
            r_data    <= { i_db, adder_sum[7:0] };
        end else if (w_jsr & ((r_operand == 3'b011) |
                              (r_operand == 3'b010))) begin
            r_data    <= r_data;
        end else if (r_operand == 3'b001) begin
            r_data    <= o_ab;
        end else begin
            r_data    <= { i_db, r_data[15:8] };
        end
    end
end
endmodule
