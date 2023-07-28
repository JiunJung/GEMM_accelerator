module fc_layer #
(
	parameter CNT_BIT = 31,

	parameter integer MEM0_DATA_WIDTH = 32,
	parameter integer MEM0_ADDR_WIDTH = 12,
	parameter integer MEM0_MEM_DEPTH  = 4096,

	parameter integer MEM1_DATA_WIDTH = 32,
	parameter integer MEM1_ADDR_WIDTH = 12,
	parameter integer MEM1_MEM_DEPTH  = 4096,
	// Do not modify the parameters beyond this line
	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 6 
)
(

	// Do not modify the ports beyond this line
	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
);

	wire  				w_run;
	wire [CNT_BIT-1:0]	w_num_cnt;
	wire   				w_idle;
	wire   				w_running;
	wire    			w_done;

	wire				w_read;
	wire				w_write;

	//Memory I/F
	// Ctrl Side
	wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr1	;
	wire		 						mem0_ce1	;
	wire		 						mem0_we1	;
	wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q1		;
	wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d1		;

	wire		[MEM1_ADDR_WIDTH-1:0] 	mem1_addr1	;
	wire		 						mem1_ce1	;
	wire		 						mem1_we1	;
	wire		[MEM1_DATA_WIDTH-1:0]  	mem1_q1		;
	wire		[MEM1_DATA_WIDTH-1:0] 	mem1_d1		;

	// Core Side
	wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr0	;
	wire		 						mem0_ce0	;
	wire		 						mem0_we0	;
	wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q0		;
	wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d0		;

	wire		[MEM1_ADDR_WIDTH-1:0] 	mem1_addr0	;
	wire		 						mem1_ce0	;
	wire		 						mem1_we0	;
	wire		[MEM1_DATA_WIDTH-1:0]  	mem1_q0		;
	wire		[MEM1_DATA_WIDTH-1:0] 	mem1_d0		;

	wire		[MEM0_DATA_WIDTH-1:0]  	result_0	;
	wire		[MEM0_DATA_WIDTH-1:0]  	result_1	;
	wire		[MEM0_DATA_WIDTH-1:0]  	result_2	;
	wire		[MEM0_DATA_WIDTH-1:0]  	result_3	;

// Instantiation of Axi Bus Interface S00_AXI
	myip_v1_0 # ( 
		.CNT_BIT(CNT_BIT),
		.MEM0_DATA_WIDTH (MEM0_DATA_WIDTH),
		.MEM0_ADDR_WIDTH (MEM0_ADDR_WIDTH),
		.MEM0_MEM_DEPTH  (MEM0_MEM_DEPTH ),
		.MEM1_DATA_WIDTH (MEM1_DATA_WIDTH),
		.MEM1_ADDR_WIDTH (MEM1_ADDR_WIDTH),
		.MEM1_MEM_DEPTH  (MEM1_MEM_DEPTH ),
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_inst (
		.o_run		(w_run),
		.o_num_cnt	(w_num_cnt),
		.i_idle		(w_idle),
		.i_running	(w_running),
		.i_done		(w_done),

		.mem0_addr1			(mem0_addr1	),
		.mem0_ce1			(mem0_ce1	),
		.mem0_we1			(mem0_we1	),
		.mem0_q1			(mem0_q1	),
		.mem0_d1			(mem0_d1	),

		.mem1_addr1			(mem1_addr1	),
		.mem1_ce1			(mem1_ce1	),
		.mem1_we1			(mem1_we1	),
		.mem1_q1			(mem1_q1	),
		.mem1_d1			(mem1_d1	),

		.result_0			(result_0	),
		.result_1			(result_1	),
		.result_2			(result_2	),
		.result_3			(result_3	),

		.s00_axi_aclk	(s00_axi_aclk	),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr	(s00_axi_awaddr	),
		.s00_axi_awprot	(s00_axi_awprot	),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata	(s00_axi_wdata	),
		.s00_axi_wstrb	(s00_axi_wstrb	),
		.s00_axi_wvalid	(s00_axi_wvalid	),
		.s00_axi_wready	(s00_axi_wready	),
		.s00_axi_bresp	(s00_axi_bresp	),
		.s00_axi_bvalid	(s00_axi_bvalid	),
		.s00_axi_bready	(s00_axi_bready	),
		.s00_axi_araddr	(s00_axi_araddr	),
		.s00_axi_arprot	(s00_axi_arprot	),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata	(s00_axi_rdata	),
		.s00_axi_rresp	(s00_axi_rresp	),
		.s00_axi_rvalid	(s00_axi_rvalid	),
		.s00_axi_rready	(s00_axi_rready	)
	);

	true_sync_dpbram 
	#(	.DWIDTH   (MEM0_DATA_WIDTH), 
		.AWIDTH   (MEM0_ADDR_WIDTH), 
		.MEM_SIZE (MEM0_MEM_DEPTH)) 
	u_bram0(
		.clk		(s00_axi_aclk	), 
	
	// Bram0 <-> Core 
		.addr0		(mem0_addr0		), 
		.ce0		(mem0_ce0		), 
		.we0		(mem0_we0		), 
		.q0			(mem0_q0		), 
		.d0			(mem0_d0		), 
	
	// Bram0 <-> AXI4LITE
		.addr1 		(mem0_addr1 	), 
		.ce1		(mem0_ce1		), 
		.we1		(mem0_we1		),
		.q1			(mem0_q1		), 
		.d1			(mem0_d1		)
	);

assign w_running = w_read | w_write;

	gemm_core # (
		.CNT_BIT(CNT_BIT),
		.DWIDTH 	(MEM0_DATA_WIDTH),
		.AWIDTH    	(MEM0_ADDR_WIDTH),
		.MEM_SIZE  	(MEM0_MEM_DEPTH ),
        .IN_DATA_WITDH (8) 
	) u_gemm_core(
	    .clk		(s00_axi_aclk	),
	    .reset_n	(s00_axi_aresetn),
		.i_run		(w_run			),
		.i_num_cnt	(w_num_cnt		),
		.o_idle		(w_idle			),
		.o_read		(w_read			),
		.o_write	(w_write		),
		.o_done		(w_done			),
	
		.addr_b0	(mem0_addr0		),
		.ce_b0		(mem0_ce0		),
		.we_b0		(mem0_we0		),
		.q_b0		(mem0_q0		),
		.d_b0		(mem0_d0		),
	
		.addr_b1	(mem1_addr0		),
		.ce_b1		(mem1_ce0		),
		.we_b1		(mem1_we0		),
		.q_b1		(mem1_q0		),
		.d_b1		(mem1_d0		),

		.result_0	(result_0		),
		.result_1	(result_1		),
		.result_2	(result_2		),
		.result_3	(result_3		)
	);

	true_sync_dpbram 
	#(	.DWIDTH   (MEM1_DATA_WIDTH), 
		.AWIDTH   (MEM1_ADDR_WIDTH), 
		.MEM_SIZE (MEM1_MEM_DEPTH)) 
	u_bram1(
		.clk		(s00_axi_aclk), 

		//Bram1 <-> Core
		.addr0		(mem1_addr0		), 
		.ce0		(mem1_ce0  		), 
		.we0		(mem1_we0  		), 
		.q0			(mem1_q0   		), 
		.d0			(mem1_d0   		), 
	
		// Bram1 <-> AXI4LITE
		.addr1 		(mem1_addr1 	), 
		.ce1		(mem1_ce1		), 
		.we1		(mem1_we1		),
		.q1			(mem1_q1		), 
		.d1			(mem1_d1		)
	);


endmodule

