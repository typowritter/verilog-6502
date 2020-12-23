/**
******************************************************************************
* @file    interrupt.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Interrupt Actions
******************************************************************************
*/

module InterruptHandler(
    input         clk,
    input         rst_x,
    input         irq_x,
    input         nmi_x,
    // Memory Controller interfaces.
    input  [ 7:0] mem_data_in,
    input         mem_brk,
    output [15:0] mem_addr,
    output        mem_read,
    output        mem_write,
    output [ 7:0] mem_data,
    // Register File interfaces.
    input  [ 7:0] rgf_s,
    input  [ 7:0] rgf_psr,
    input  [15:0] rgf_pc,
    output        rgf_set_i,
    output        rgf_set_b,
    output [ 7:0] rgf_data,
    output        rgf_set_pcl,
    output        rgf_set_pch,
    output        rgf_pushed
);

reg [1:0] r_res_state;
reg [1:0] r_int_state;
reg [1:0] r_vector;

wire      read_pcl;
wire      read_pch;

localparam VECTOR_NMI = 2'b01;
localparam VECTOR_RES = 2'b10;
localparam VECTOR_IRQ = 2'b11;
localparam VECTOR_BRK = 2'b11;

localparam S_RES_IDLE     = 2'b00;
localparam S_RES_LOAD_PCL = 2'b01;
localparam S_RES_LOAD_PCH = 2'b11;

localparam S_INT_IDLE     = 2'b00;
localparam S_INT_PUSH_PCL = 2'b01;
localparam S_INT_PUSH_PSR = 2'b10;

assign mem_addr   = mem_write ? { 8'h01, rgf_s } :
                    { 12'hfff, 1'b1, r_vector, read_pch };
assign mem_read   = read_pcl | read_pch;
assign mem_write  = mem_brk | (r_int_state == S_INT_PUSH_PCL) |
                    (r_int_state == S_INT_PUSH_PSR);
assign mem_data   = mem_brk ? rgf_pc[15:8] :
                    (r_int_state == S_INT_PUSH_PCL) ? rgf_pc[7:0] :
                    (r_int_state == S_INT_PUSH_PSR) ? rgf_psr :
                    8'hxx;
assign rgf_set_i   = (r_int_state == S_INT_PUSH_PSR) | (!irq_x) | (!nmi_x);
assign rgf_set_b   = r_int_state == S_INT_PUSH_PSR;
assign rgf_data    = mem_data_in;
assign rgf_set_pcl = read_pcl;
assign rgf_set_pch = read_pch;
assign rgf_pushed  = mem_write;

assign read_pcl  = r_res_state == S_RES_LOAD_PCL;
assign read_pch  = r_res_state == S_RES_LOAD_PCH;

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_res_state  <= S_RES_LOAD_PCL;
        r_vector     <= VECTOR_RES;
    end else begin
        case (r_res_state)
            S_RES_IDLE: begin
                if (!irq_x | (r_int_state == S_INT_PUSH_PSR)) begin
                    r_res_state  <= S_RES_LOAD_PCL;
                    r_vector     <= VECTOR_IRQ;
                end else if (!nmi_x) begin
                    r_res_state  <= S_RES_LOAD_PCL;
                    r_vector     <= VECTOR_NMI;
                end
            end

            S_RES_LOAD_PCL: begin
                r_res_state  <= S_RES_LOAD_PCH;
            end

            S_RES_LOAD_PCH: begin
                r_res_state  <= S_RES_IDLE;
            end
        endcase
    end
end

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_int_state <= S_INT_IDLE;
    end else begin
        case (r_int_state)
            S_INT_IDLE: begin
                if (mem_brk) begin
                    r_int_state <= S_INT_PUSH_PCL;
                end
            end

            S_INT_PUSH_PCL: begin
                r_int_state <= S_INT_PUSH_PSR;
            end

            S_INT_PUSH_PSR: begin
                r_int_state <= S_INT_IDLE;
            end
        endcase
    end
end
endmodule
