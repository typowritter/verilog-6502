/**
******************************************************************************
* @file    interrupt_tb.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Testbench for Interrupt Actions
******************************************************************************
*/

`timescale 100ps/100ps

module Interrupt_Test;
reg         clk;
reg         rst_x;
reg         irq_x;
reg         nmi_x;

wire [ 7:0] mem_data_in;
wire [15:0] mem_addr;
wire        mem_read;
wire [ 7:0] rgf_data;
wire        rgf_set_pcl;
wire        rgf_set_pch;
wire        rgf_pushed;

InterruptHandler dut(
    .clk         (clk),
    .rst_x       (rst_x),
    .irq_x       (irq_x),
    .nmi_x       (nmi_x),
    .mem_data_in (mem_data_in),
    .mem_brk     (1'b0),
    .mem_addr    (mem_addr),
    .mem_read    (mem_read),
    .rgf_s       (8'h00),
    .rgf_psr     (8'h00),
    .rgf_pc      (16'h0000),
    .rgf_data    (rgf_data),
    .rgf_set_pcl (rgf_set_pcl),
    .rgf_set_pch (rgf_set_pch),
    .rgf_pushed  (rgf_pushed)
);

always #1 clk = !clk;

assign mem_data_in = 8'h89;

always @ (posedge clk) begin
    if (rst_x & mem_read & rgf_set_pcl) begin
        $display("load pcl: $%04x", mem_addr);
    end
    if (rst_x & rgf_set_pcl) begin
        $display("set pcl: $%02x", rgf_data);
    end
    if (rst_x & mem_read & rgf_set_pch) begin
        $display("load pch: $%04x", mem_addr);
    end
    if (rst_x & rgf_set_pch) begin
        $display("set pch: $%02x", rgf_data);
    end
end

initial begin
    $dumpfile("vcd/Interrupt.vcd");
    $dumpvars(0, dut);
    clk     <= 1'b0;
    rst_x   <= 1'b0;
    irq_x   <= 1'b1;
    nmi_x   <= 1'b1;
    #2
    rst_x   <= 1'b1;
    #10
    // IRQ & NMI is not complete, only check the outgoing addr for now
    irq_x   <= 1'b0;
    #2
    irq_x   <= 1'b1;
    #10
    nmi_x   <= 1'b0;
    #2
    nmi_x   <= 1'b1;
    #10
    $finish;
end
endmodule
