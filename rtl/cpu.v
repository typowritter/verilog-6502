// Copyright (c) 2014 Takashi Toyoshima <toyoshim@gmail.com>.
// All rights reserved.  Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

module CPU(
    input         clk,
    input         rst_x,
    input         i_rdy,
    input         i_irq_x,
    input         i_nmi_x,
    inout   [7:0] io_db,    // Data Bus
    output        o_clk1,   // Dual phase
    output        o_clk2,
    output        o_sync,
    output        o_rw,     // R/W Select
    output [15:0] o_ab      // Addr Bus
);

// Interrupt Handler <=> Memory Controller
wire   [ 7:0] mc2it_data;
wire          mc2it_brk;
wire   [15:0] it2mc_addr;
wire          it2mc_read;
wire          it2mc_write;
wire   [ 7:0] it2mc_data;

// Interrupt Handler <=> Register File
wire   [ 7:0] rf2it_s;
wire   [ 7:0] rf2it_psr;
wire   [15:0] rf2it_pc;
wire          it2rf_set_i;
wire          it2rf_set_b;
wire   [ 7:0] it2rf_data;
wire          it2rf_set_pcl;
wire          it2rf_set_pch;
wire          it2rf_pushed;

// Register File <=> Memory Controller
wire   [15:0] rf2mc_pc;
wire   [ 7:0] rf2mc_a;
wire   [ 7:0] rf2mc_x;
wire   [ 7:0] rf2mc_y;
wire   [ 7:0] rf2mc_s;
wire   [ 7:0] rf2mc_psr;
wire          mc2rf_fetched;
wire          mc2rf_pushed;
wire          mc2rf_pull;
wire   [15:0] mc2rf_pc;
wire          mc2rf_set_pc;
wire   [ 7:0] mc2rf_psr;
wire          mc2rf_set_psr;

// Decoder <=> Memory Controller
wire   [ 7:0] mc2dc_data;
wire          mc2dc_valid;
wire          dc2mc_fetch;
wire          dc2mc_sync;
wire          dc2mc_operand;
wire   [ 2:0] dc2mc_mode;
wire          dc2mc_modex;
wire   [ 1:0] dc2mc_reg;
wire          dc2mc_store;
wire          dc2mc_push;
wire          dc2mc_pop;
wire          dc2mc_p_reg;
wire          dc2mc_jump;

// Decoder <=> Execution Controller
wire          dc2ex_reset_c;
wire          dc2ex_set_c;
wire          dc2ex_reset_i;
wire          dc2ex_set_i;
wire          dc2ex_reset_v;
wire          dc2ex_reset_d;
wire          dc2ex_set_d;
wire          dc2ex_load;
wire          dc2ex_ops;
wire          dc2ex_branch;
wire   [ 4:0] dc2ex_opcode;
wire   [ 7:0] dc2ex_data;
wire   [ 1:0] dc2ex_reg;
wire          ex2dc_done;

// Execution Controller <=> Register File
wire   [ 7:0] rf2ex_pcl;
wire   [ 7:0] rf2ex_pch;
wire   [ 7:0] rf2ex_a;
wire   [ 7:0] rf2ex_x;
wire   [ 7:0] rf2ex_y;
wire          rf2ex_c;
wire          rf2ex_d;
wire          rf2ex_n;
wire          rf2ex_v;
wire          rf2ex_z;
wire          ex2rf_c;
wire          ex2rf_set_c;
wire          ex2rf_i;
wire          ex2rf_set_i;
wire          ex2rf_v;
wire          ex2rf_set_v;
wire          ex2rf_d;
wire          ex2rf_set_d;
wire          ex2rf_n;
wire          ex2rf_set_n;
wire          ex2rf_z;
wire          ex2rf_set_z;
wire   [ 7:0] ex2rf_data;
wire          ex2rf_set_a;
wire          ex2rf_set_x;
wire          ex2rf_set_y;
wire          ex2rf_set_s;
wire          ex2rf_set_pcl;
wire          ex2rf_set_pch;

// ExecutionController <=> MemoryController
wire   [ 7:0] ex2mc_data;
wire          ex2mc_store;

// Global wires
wire   [ 7:0] i_db;
wire   [ 7:0] o_db;

assign o_clk1  = clk;
assign o_clk2  = !clk;
assign io_db   = o_rw ? 8'hzz : o_db;
assign i_db    = o_rw ? io_db : 8'hzz;

MemoryController mem_controller(
    .clk          (clk),
    .rst_x        (rst_x),
    .i_rdy        (i_rdy),
    .i_db         (i_db),
    .o_db         (o_db),
    .o_ab         (o_ab),
    .o_rw         (o_rw),
    .o_sync       (o_sync),
    .intr_addr    (it2mc_addr),
    .intr_read    (it2mc_read),
    .intr_write   (it2mc_write),
    .intr_data_in (it2mc_data),
    .intr_data    (mc2it_data),
    .intr_brk     (mc2it_brk),
    .rgf_pc_in    (rf2mc_pc),
    .rgf_a        (rf2mc_a),
    .rgf_x        (rf2mc_x),
    .rgf_y        (rf2mc_y),
    .rgf_s        (rf2mc_s),
    .rgf_psr_in   (rf2mc_psr),
    .rgf_fetched  (mc2rf_fetched),
    .rgf_pushed   (mc2rf_pushed),
    .rgf_pull     (mc2rf_pull),
    .rgf_pc       (mc2rf_pc),
    .rgf_set_pc   (mc2rf_set_pc),
    .rgf_psr      (mc2rf_psr),
    .rgf_set_psr  (mc2rf_set_psr),
    .dec_fetch    (dc2mc_fetch),
    .dec_sync     (dc2mc_sync),
    .dec_operand  (dc2mc_operand),
    .dec_mode     (dc2mc_mode),
    .dec_modex    (dc2mc_modex),
    .dec_reg      (dc2mc_reg),
    .dec_store    (dc2mc_store),
    .dec_push     (dc2mc_push),
    .dec_pop      (dc2mc_pop),
    .dec_p_reg    (dc2mc_p_reg),
    .dec_jump     (dc2mc_jump),
    .dec_data     (mc2dc_data),
    .dec_valid    (mc2dc_valid),
    .exec_data    (ex2mc_data),
    .exec_store   (ex2mc_store)
);

InterruptHandler int_handler(
    .clk         (clk),
    .rst_x       (rst_x),
    .irq_x       (i_irq_x),
    .nmi_x       (i_nmi_x),
    .mem_data_in (mc2it_data),
    .mem_brk     (mc2it_brk),
    .mem_addr    (it2mc_addr),
    .mem_read    (it2mc_read),
    .mem_write   (it2mc_write),
    .mem_data    (it2mc_data),
    .rgf_s       (rf2it_s),
    .rgf_psr     (rf2it_psr),
    .rgf_pc      (rf2it_pc),
    .rgf_set_i   (it2rf_set_i),
    .rgf_set_b   (it2rf_set_b),
    .rgf_data    (it2rf_data),
    .rgf_set_pcl (it2rf_set_pcl),
    .rgf_set_pch (it2rf_set_pch),
    .rgf_pushed  (it2rf_pushed)
);

RegisterFile regfile(
    .clk          (clk),
    .rst_x        (rst_x),
    .intr_set_i   (it2rf_set_i),
    .intr_set_b   (it2rf_set_b),
    .intr_data    (it2rf_data),
    .intr_set_pcl (it2rf_set_pcl),
    .intr_set_pch (it2rf_set_pch),
    .intr_pushed  (it2rf_pushed),
    .intr_s       (rf2it_s),
    .intr_psr     (rf2it_psr),
    .intr_pc      (rf2it_pc),
    .mem_fetched  (mc2rf_fetched),
    .mem_pushed   (mc2rf_pushed),
    .mem_pull     (mc2rf_pull),
    .mem_pc_in    (mc2rf_pc),
    .mem_set_pc   (mc2rf_set_pc),
    .mem_psr_in   (mc2rf_psr),
    .mem_set_psr  (mc2rf_set_psr),
    .mem_pc       (rf2mc_pc),
    .mem_a        (rf2mc_a),
    .mem_x        (rf2mc_x),
    .mem_y        (rf2mc_y),
    .mem_s        (rf2mc_s),
    .mem_psr      (rf2mc_psr),
    .exec_c_in    (ex2rf_c),
    .exec_set_c   (ex2rf_set_c),
    .exec_i_in    (ex2rf_i),
    .exec_set_i   (ex2rf_set_i),
    .exec_v_in    (ex2rf_v),
    .exec_set_v   (ex2rf_set_v),
    .exec_d_in    (ex2rf_d),
    .exec_set_d   (ex2rf_set_d),
    .exec_n_in    (ex2rf_n),
    .exec_set_n   (ex2rf_set_n),
    .exec_z_in    (ex2rf_z),
    .exec_set_z   (ex2rf_set_z),
    .exec_data    (ex2rf_data),
    .exec_set_a   (ex2rf_set_a),
    .exec_set_x   (ex2rf_set_x),
    .exec_set_y   (ex2rf_set_y),
    .exec_set_s   (ex2rf_set_s),
    .exec_set_pcl (ex2rf_set_pcl),
    .exec_set_pch (ex2rf_set_pch),
    .exec_pcl     (rf2ex_pcl),
    .exec_pch     (rf2ex_pch),
    .exec_a       (rf2ex_a),
    .exec_x       (rf2ex_x),
    .exec_y       (rf2ex_y),
    .exec_c       (rf2ex_c),
    .exec_d       (rf2ex_d),
    .exec_n       (rf2ex_n),
    .exec_v       (rf2ex_v),
    .exec_z       (rf2ex_z)
);

Decoder decoder(
    .clk          (clk),
    .rst_x        (rst_x),
    .mem_data     (mc2dc_data),
    .mem_valid    (mc2dc_valid),
    .mem_fetch    (dc2mc_fetch),
    .mem_sync     (dc2mc_sync),
    .mem_operand  (dc2mc_operand),
    .mem_mode     (dc2mc_mode),
    .mem_modex    (dc2mc_modex),
    .mem_reg      (dc2mc_reg),
    .mem_store    (dc2mc_store),
    .mem_push     (dc2mc_push),
    .mem_pop      (dc2mc_pop),
    .mem_p_reg    (dc2mc_p_reg),
    .mem_jump     (dc2mc_jump),
    .exec_reset_c (dc2ex_reset_c),
    .exec_set_c   (dc2ex_set_c),
    .exec_reset_i (dc2ex_reset_i),
    .exec_set_i   (dc2ex_set_i),
    .exec_reset_v (dc2ex_reset_v),
    .exec_reset_d (dc2ex_reset_d),
    .exec_set_d   (dc2ex_set_d),
    .exec_load    (dc2ex_load),
    .exec_ops     (dc2ex_ops),
    .exec_branch  (dc2ex_branch),
    .exec_opcode  (dc2ex_opcode),
    .exec_data    (dc2ex_data),
    .exec_reg     (dc2ex_reg),
    .exec_done    (ex2dc_done));

ExecutionController exec_controller(
    .clk         (clk),
    .rst_x       (rst_x),
    .dec_reset_c (dc2ex_reset_c),
    .dec_set_c   (dc2ex_set_c),
    .dec_reset_i (dc2ex_reset_i),
    .dec_set_i   (dc2ex_set_i),
    .dec_reset_v (dc2ex_reset_v),
    .dec_reset_d (dc2ex_reset_d),
    .dec_set_d   (dc2ex_set_d),
    .dec_load    (dc2ex_load),
    .dec_ops     (dc2ex_ops),
    .dec_branch  (dc2ex_branch),
    .dec_opcode  (dc2ex_opcode),
    .dec_data    (dc2ex_data),
    .dec_reg     (dc2ex_reg),
    .dec_done    (ex2dc_done),
    .rgf_pcl     (rf2ex_pcl),
    .rgf_pch     (rf2ex_pch),
    .rgf_a       (rf2ex_a),
    .rgf_x       (rf2ex_x),
    .rgf_y       (rf2ex_y),
    .rgf_c_in    (rf2ex_c),
    .rgf_d_in    (rf2ex_d),
    .rgf_n_in    (rf2ex_n),
    .rgf_v_in    (rf2ex_v),
    .rgf_z_in    (rf2ex_z),
    .rgf_c       (ex2rf_c),
    .rgf_set_c   (ex2rf_set_c),
    .rgf_i       (ex2rf_i),
    .rgf_set_i   (ex2rf_set_i),
    .rgf_v       (ex2rf_v),
    .rgf_set_v   (ex2rf_set_v),
    .rgf_d       (ex2rf_d),
    .rgf_set_d   (ex2rf_set_d),
    .rgf_n       (ex2rf_n),
    .rgf_set_n   (ex2rf_set_n),
    .rgf_z       (ex2rf_z),
    .rgf_set_z   (ex2rf_set_z),
    .rgf_data    (ex2rf_data),
    .rgf_set_a   (ex2rf_set_a),
    .rgf_set_x   (ex2rf_set_x),
    .rgf_set_y   (ex2rf_set_y),
    .rgf_set_s   (ex2rf_set_s),
    .rgf_set_pcl (ex2rf_set_pcl),
    .rgf_set_pch (ex2rf_set_pch),
    .mem_data    (ex2mc_data),
    .mem_store   (ex2mc_store)
);

endmodule  // MC6502
