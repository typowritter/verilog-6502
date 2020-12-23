/**
******************************************************************************
* @file    register_file.v
* @author  yxnan <yxnan@pm.me>
* @year    2020
* @brief   Register File
******************************************************************************
*/

module RegisterFile(
    input         clk,
    input         rst_x,
    // Interrupt interfaces
    input         intr_set_i,
    input         intr_set_b,
    input  [ 7:0] intr_data,
    input         intr_set_pcl,
    input         intr_set_pch,
    input         intr_pushed,
    output [ 7:0] intr_s,
    output [ 7:0] intr_psr,
    output [15:0] intr_pc,
    // Memory Controller interfaces
    input         mem_fetched,
    input         mem_pushed,
    input         mem_pull,
    input  [15:0] mem_pc_in,
    input         mem_set_pc,
    input  [ 7:0] mem_psr_in,
    input         mem_set_psr,
    output [15:0] mem_pc,
    output [ 7:0] mem_a,
    output [ 7:0] mem_x,
    output [ 7:0] mem_y,
    output [ 7:0] mem_s,
    output [ 7:0] mem_psr,
    // Execution Controller interfaces
    input         exec_c_in,
    input         exec_set_c,
    input         exec_i_in,
    input         exec_set_i,
    input         exec_v_in,
    input         exec_set_v,
    input         exec_d_in,
    input         exec_set_d,
    input         exec_n_in,
    input         exec_set_n,
    input         exec_z_in,
    input         exec_set_z,
    input   [7:0] exec_data,
    input         exec_set_a,
    input         exec_set_x,
    input         exec_set_y,
    input         exec_set_s,
    input         exec_set_pcl,
    input         exec_set_pch,
    output  [7:0] exec_pcl,
    output  [7:0] exec_pch,
    output  [7:0] exec_a,
    output  [7:0] exec_x,
    output  [7:0] exec_y,
    output        exec_c,
    output        exec_d,
    output        exec_n,
    output        exec_v,
    output        exec_z
);

reg   [7:0] r_pcl;
reg   [7:0] r_pch;
reg   [7:0] r_a;
reg   [7:0] r_x;
reg   [7:0] r_y;
reg   [7:0] r_sp;

wire        load_pc;
wire [15:0] next_pc;
wire  [7:0] w_psr;

wire        w_c;
wire        w_i;
wire        w_v;
wire        w_d;
wire        w_n;
wire        w_z;
wire        w_b;
wire        w_set_c;
wire        w_set_i;
wire        w_set_v;
wire        w_set_d;
wire        w_set_n;
wire        w_set_z;
wire        w_set_b;

assign intr_s   = r_sp;
assign intr_psr = w_psr;
assign intr_pc  = { r_pch, r_pcl };

assign mem_pc   = { r_pch, r_pcl };
assign mem_a    = r_a;
assign mem_x    = r_x;
assign mem_y    = r_y;
assign mem_s    = r_sp;
assign mem_psr  = w_psr;
assign exec_pcl = r_pcl;
assign exec_pch = r_pch;
assign exec_a   = r_a;
assign exec_x   = r_x;
assign exec_y   = r_y;
assign exec_c   = w_psr[0];
assign exec_d   = w_psr[3];
assign exec_n   = w_psr[7];
assign exec_v   = w_psr[6];
assign exec_z   = w_psr[1];

assign load_pc  = intr_set_pcl | intr_set_pch |
                  exec_set_pcl | exec_set_pch;
assign next_pc  = { r_pch, r_pcl } + 16'h0001;

assign w_c      = exec_set_c ? exec_c_in : mem_psr_in[0];
assign w_set_c  = exec_set_c | mem_set_psr;
assign w_i      = exec_set_i ? exec_i_in :
                  intr_set_i ? 1'b1 :
                  mem_psr_in[2];
assign w_set_i  = exec_set_i | mem_set_psr | intr_set_i;
assign w_v      = exec_set_v ? exec_v_in : mem_psr_in[6];
assign w_set_v  = exec_set_v | mem_set_psr;
assign w_d      = exec_set_d ? exec_d_in : mem_psr_in[3];
assign w_set_d  = exec_set_d | mem_set_psr;
assign w_n      = exec_set_n ? exec_n_in : mem_psr_in[7];
assign w_set_n  = exec_set_n | mem_set_psr;
assign w_z      = exec_set_z ? exec_z_in : mem_psr_in[1];
assign w_set_z  = exec_set_z | mem_set_psr;
assign w_b      = intr_set_b ? 1'b1 : mem_psr_in[4];
assign w_set_b  = mem_set_psr | intr_set_b;

always @ (posedge clk or negedge rst_x) begin
    if (!rst_x) begin
        r_pcl <= 8'h00;
        r_pch <= 8'h00;
        r_a   <= 8'h00;
        r_x   <= 8'h00;
        r_y   <= 8'h00;
        r_sp  <= 8'h00;
    end else begin
        if (load_pc) begin
            if (intr_set_pcl) begin
                r_pcl <= intr_data;
            end else if (exec_set_pcl) begin
                r_pcl <= exec_data;
            end
            if (intr_set_pch) begin
                r_pch <= intr_data;
            end else if (exec_set_pch) begin
                r_pch <= exec_data;
            end
        end else begin
            if (mem_fetched) begin
                r_pch <= next_pc[15:8];
                r_pcl <= next_pc[7:0];
            end else if (mem_set_pc) begin
                r_pch <= mem_pc_in[15:8];
                r_pcl <= mem_pc_in[7:0];
            end
        end

        if (exec_set_a) begin
            r_a   <= exec_data;
        end
        if (exec_set_x) begin
            r_x   <= exec_data;
        end
        if (exec_set_y) begin
            r_y   <= exec_data;
        end

        if (exec_set_s) begin
            r_sp  <= exec_data;
        end else if (mem_pushed | intr_pushed) begin
            r_sp  <= r_sp - 8'h01;
        end else if (mem_pull) begin
            r_sp  <= r_sp + 8'h01;
        end
    end
end

StatusRegister psr(
    .clk        (clk),
    .rst_x      (rst_x),
    .c_carry    (w_c),
    .i_intr     (w_i),
    .v_overflow (w_v),
    .d_bcd      (w_d),
    .n_negative (w_n),
    .z_zero     (w_z),
    .b_brk      (w_b),
    .set_c      (w_set_c),
    .set_i      (w_set_i),
    .set_v      (w_set_v),
    .set_d      (w_set_d),
    .set_n      (w_set_n),
    .set_z      (w_set_z),
    .set_b      (w_set_b),
    .o_psr      (w_psr)
);
endmodule
