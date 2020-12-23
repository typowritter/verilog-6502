/**
******************************************************************************
* @file    register_file_tb.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Testbench for Register File
******************************************************************************
*/

`timescale 100ps/100ps

module RegisterFile_Test;
wire [15:0] w_rf2mc_pc;
wire [ 7:0] w_rf2mc_a;
wire [ 7:0] w_rf2mc_x;
wire [ 7:0] w_rf2mc_y;
wire [ 7:0] w_rf2mc_s;
wire [ 7:0] w_rf2ex_a;
wire        w_rf2ex_c;
wire        w_rf2ex_d;
wire        w_rf2ex_n;
wire        w_rf2ex_v;
wire        w_rf2ex_z;

reg         clk;
reg         rst_x;
reg  [ 7:0] r_it2rf_data;
reg         r_it2rf_set_pcl;
reg         r_it2rf_set_pch;
reg         r_mc2rf_fetched;

RegisterFile dut(
    .clk          (clk),
    .rst_x        (rst_x),
    .intr_set_i   (1'b0),
    .intr_set_b   (1'b0),
    .intr_data    (r_it2rf_data),
    .intr_set_pcl (r_it2rf_set_pcl),
    .intr_set_pch (r_it2rf_set_pch),
    .intr_pushed  (1'b0),
    .mem_fetched  (1'b1),
    .mem_pushed   (1'b0),
    .mem_pull     (1'b0),
    .mem_pc_in    (16'h0000),
    .mem_set_pc   (1'b0),
    .mem_psr_in   (8'h00),
    .mem_set_psr  (1'b0),
    .mem_pc       (w_rf2mc_pc),
    .mem_a        (w_rf2mc_a),
    .mem_x        (w_rf2mc_x),
    .mem_y        (w_rf2mc_y),
    .mem_s        (w_rf2mc_s),
    .exec_c_in    (1'b0),
    .exec_set_c   (1'b0),
    .exec_i_in    (1'b0),
    .exec_set_i   (1'b0),
    .exec_v_in    (1'b0),
    .exec_set_v   (1'b0),
    .exec_d_in    (1'b0),
    .exec_set_d   (1'b0),
    .exec_n_in    (1'b0),
    .exec_set_n   (1'b0),
    .exec_z_in    (1'b0),
    .exec_set_z   (1'b0),
    .exec_data    (8'h00),
    .exec_set_a   (1'b0),
    .exec_set_x   (1'b0),
    .exec_set_y   (1'b0),
    .exec_set_s   (1'b0),
    .exec_set_pcl (1'b0),
    .exec_set_pch (1'b0),
    .exec_a       (w_rf2ex_a),
    .exec_c       (w_rf2ex_c),
    .exec_d       (w_rf2ex_d),
    .exec_n       (w_rf2ex_n),
    .exec_v       (w_rf2ex_v),
    .exec_z       (w_rf2ex_z)
);

always #1 clk = !clk;

always @ (posedge clk) begin
    if (rst_x) begin
      $display("pc = $%04x", w_rf2mc_pc);
    end
end

initial begin
    $dumpfile("vcd/RegisterFile.vcd");
    $dumpvars(0, dut);
    clk             <= 1'b0;
    rst_x           <= 1'b0;
    r_it2rf_data    <= 8'h00;
    r_it2rf_set_pcl <= 1'b0;
    r_it2rf_set_pch <= 1'b0;
    #2
    rst_x           <= 1'b1;
    #2
    r_it2rf_data    <= 8'hef;
    r_it2rf_set_pcl <= 1'b1;
    #2
    r_it2rf_data    <= 8'hbe;
    r_it2rf_set_pcl <= 1'b0;
    r_it2rf_set_pch <= 1'b1;
    #2
    r_it2rf_set_pch <= 1'b0;
    #4
    $finish;
end
endmodule
