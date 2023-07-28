`timescale 1ns / 1ps
module gemm_core
// Param
#(
	parameter CNT_BIT = 31,
// BRAM
	parameter DWIDTH = 32,
	parameter AWIDTH = 12,
	parameter MEM_SIZE = 4096,
	parameter IN_DATA_WITDH = 8
)

(
    input 				clk,
    input 				reset_n,
	input 				i_run,
	input  [CNT_BIT-1:0]	i_num_cnt,
	output   			o_idle,
	output   			o_read,
	output   			o_write,
	output  			o_done,

// Memory I/F (Read from bram0 input nodes)
	output[AWIDTH-1:0] 	addr_b0,
	output 				ce_b0,
	output 				we_b0,
	input [DWIDTH-1:0]  q_b0,
	output[DWIDTH-1:0] 	d_b0,

// Memory I/F (Read to bram1 weights)
	output[AWIDTH-1:0] 	addr_b1,
	output 				ce_b1,
	output 				we_b1,
	input [DWIDTH-1:0]  q_b1,
	output[DWIDTH-1:0] 	d_b1,

// result for 4 core
	output[DWIDTH-1:0]  result_0,
	output[DWIDTH-1:0]  result_1,
	output[DWIDTH-1:0]  result_2,
	output[DWIDTH-1:0]  result_3
    );

/////// Local Param. to define state ////////
localparam S_IDLE	= 2'b00;
localparam S_RUN	= 2'b01;
localparam S_DONE  	= 2'b10;

/////// Type ////////
reg [1:0] c_state_read; // Current state  (F/F)
reg [1:0] n_state_read; // Next state (Variable in Combinational Logic)
reg [1:0] c_state_write; // Current state  (F/F)
reg [1:0] n_state_write; // Next state (Variable in Combinational Logic)
wire	  is_write_done;
wire	  is_read_done;

/////// Main ////////

// Step 1. always block to update state 
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
		c_state_read <= S_IDLE;
    end else begin
		c_state_read <= n_state_read;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
		c_state_write <= S_IDLE;
    end else begin
		c_state_write <= n_state_write;
    end
end

// Step 2. always block to compute n_state_read
always @(*) 
begin
	n_state_read = c_state_read; // To prevent Latch.
	case(c_state_read)
	S_IDLE	: if(i_run)
				n_state_read = S_RUN;
	S_RUN   : if(is_read_done)
				n_state_read = S_DONE;
	S_DONE	: n_state_read 	 = S_IDLE;
	endcase
end 

always @(*) 
begin
	n_state_write = c_state_write; // To prevent Latch.
	case(c_state_write)
	S_IDLE	: if(i_run)
				n_state_write = S_RUN;
	S_RUN   : if(is_write_done)
				n_state_write = S_DONE;
	S_DONE	: n_state_write   = S_IDLE;
	endcase
end 

// Step 3.  always block to compute output
// Added to communicate with control signals.
assign o_idle 		= (c_state_read == S_IDLE) && (c_state_write == S_IDLE);
assign o_read 		= (c_state_read == S_RUN);
assign o_write 		= (c_state_write == S_RUN);
assign o_done 		= (c_state_write == S_DONE); // The write state is slower than the read state.

// Step 4. Registering (Capture) number of Count
reg [CNT_BIT-1:0] num_cnt;  
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        num_cnt <= 0;  
    end else if (i_run) begin
        num_cnt <= i_num_cnt;
	end else if (o_done) begin
		num_cnt <= 0;
	end
end

// Step 5. increased addr_cnt
reg [CNT_BIT-1:0] addr_cnt_read;  
reg [CNT_BIT-1:0] addr_cnt_write;
assign is_read_done  = o_read  && (addr_cnt_read == num_cnt-1);
assign is_write_done = o_write && (addr_cnt_write == num_cnt-1);

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt_read <= 0;  
    end else if (is_read_done) begin
        addr_cnt_read <= 0; 
    end else if (o_read) begin
        addr_cnt_read <= addr_cnt_read + 1;
	end
end

wire result_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt_write <= 0;  
    end else if (is_write_done) begin
        addr_cnt_write <= 0; 
    //end else if (o_write && we_b1) begin  // core delay
    end else if (o_write && result_valid) begin  // core delay
        addr_cnt_write <= addr_cnt_write + 1;
	end
end

// Step 6. Read Data from BRAM0
// Assign Memory I/F. Read from BRAM0
assign addr_b0 	= addr_cnt_read;
assign ce_b0 	= o_read;
assign we_b0 	= 1'b0; // read only
assign d_b0		= {DWIDTH{1'b0}}; // no use

reg 				r_valid;
wire [DWIDTH-1:0] 	mem_data_0;

// 1 cycle latency to sync mem output
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid <= {DWIDTH{1'b0}};  
    end else begin
		r_valid <= o_read; // read data
	end
end
assign mem_data_0 = q_b0;  


// Step 6.1  Read Data from BRAM1 weight
// Assign Memory I/F. Read from BRAM0
assign addr_b1 	= addr_cnt_read;
assign ce_b1 	= o_read;
assign we_b1 	= 1'b0; // read only
assign d_b1		= {DWIDTH{1'b0}}; // no use

wire [DWIDTH-1:0] 	mem_data_1;

assign mem_data_1 = q_b1;  


wire	[IN_DATA_WITDH-1:0]	    w_a_0	 	= mem_data_0[(4*IN_DATA_WITDH)-1:(3*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_0	 	= mem_data_1[(4*IN_DATA_WITDH)-1:(3*IN_DATA_WITDH)];
wire	[(4*IN_DATA_WITDH)-1:0] w_result_0	;
wire 							w_valid_0 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_1	 	= mem_data_0[(3*IN_DATA_WITDH)-1:(2*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_1	 	= mem_data_1[(3*IN_DATA_WITDH)-1:(2*IN_DATA_WITDH)];
wire	[(4*IN_DATA_WITDH)-1:0] w_result_1	;
wire 							w_valid_1 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_2	 	= mem_data_0[(2*IN_DATA_WITDH)-1:(1*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_2	 	= mem_data_1[(2*IN_DATA_WITDH)-1:(1*IN_DATA_WITDH)];
wire	[(4*IN_DATA_WITDH)-1:0] w_result_2	;
wire 							w_valid_2 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_3	 	= mem_data_0[(1*IN_DATA_WITDH)-1:(0*IN_DATA_WITDH)]; //only need this for input data.
wire	[IN_DATA_WITDH-1:0]	    w_b_3	 	= mem_data_1[(1*IN_DATA_WITDH)-1:(0*IN_DATA_WITDH)];
wire	[(4*IN_DATA_WITDH)-1:0] w_result_3	;
wire 							w_valid_3 	;

mul_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_mul_core_0(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_3	 	),
	.i_wegt		(w_b_0	 	),
	.o_result	(w_result_0	),
	.o_valid	(w_valid_0	)
);

mul_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_mul_core_1(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_3	 	),
	.i_wegt		(w_b_1	 	),
	.o_result	(w_result_1	),
	.o_valid	(w_valid_1	)
);

mul_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_mul_core_2(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_3	 	),
	.i_wegt		(w_b_2	 	),
	.o_result	(w_result_2	),
	.o_valid	(w_valid_2	)
);

mul_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_mul_core_3(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_3	 	),
	.i_wegt		(w_b_3	 	),
	.o_result	(w_result_3	),
	.o_valid	(w_valid_3	)
);

assign result_valid = w_valid_0 & w_valid_1 & w_valid_2 & w_valid_3;
assign result_0 	= w_result_0;
assign result_1 	= w_result_1;
assign result_2 	= w_result_2;
assign result_3 	= w_result_3;

endmodule
