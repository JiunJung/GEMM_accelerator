
`timescale 1 ns / 1 ps

	module myip_v1_0_S00_AXI #
	(

		parameter CNT_BIT = 31,

		parameter integer MEM0_DATA_WIDTH = 32,
		parameter integer MEM0_ADDR_WIDTH = 12,
		parameter integer MEM0_MEM_DEPTH  = 4096, 

		parameter integer MEM1_DATA_WIDTH = 32,
		parameter integer MEM1_ADDR_WIDTH = 12,	
		parameter integer MEM1_MEM_DEPTH  = 4096,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 6 
	)
	(
		output 					o_run,
		output  [CNT_BIT-1:0]	o_num_cnt, 
		input   				i_idle,
		input   				i_running,
		input					i_done,

		//Memory I/F
		output		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr1,
		output		 						mem0_ce1,
		output		 						mem0_we1,
		input 		[MEM0_DATA_WIDTH-1:0]  	mem0_q1,
		output		[MEM0_DATA_WIDTH-1:0] 	mem0_d1,

		//Memory I/F
		output		[MEM1_ADDR_WIDTH-1:0] 	mem1_addr1,
		output		 						mem1_ce1,
		output		 						mem1_we1,
		input 		[MEM1_DATA_WIDTH-1:0]  	mem1_q1,
		output		[MEM1_DATA_WIDTH-1:0] 	mem1_d1,

		//result for 4 core
		input		[MEM0_DATA_WIDTH-1:0]  	result_0,
		input		[MEM0_DATA_WIDTH-1:0]  	result_1,
		input		[MEM0_DATA_WIDTH-1:0]  	result_2,
		input		[MEM0_DATA_WIDTH-1:0]  	result_3,

		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY

	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;
	reg  	axi_rvalid_d; //delay 1 cycle from bram read

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3; 
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_rega;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regb;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regc;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regd;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_rege;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regf;

	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	//assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_RVALID	= axi_rvalid_d; //delay 1 cycle from bram read
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
//	      slv_reg1 <= 0; //Not use Write in 0x04 (STATUS, READ Only) 
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
		  slv_reg4 <= 0;
		  slv_reg5 <= 0;
		  slv_reg6 <= 0;
		  slv_reg7 <= 0;
		  slv_reg8 <= 0;
		  slv_reg9 <= 0;
		  slv_rega <= 0;
		  slv_regb <= 0;
		  slv_regc <= 0;
		  slv_regd <= 0;
		  slv_rege <= 0;
		  slv_regf <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
			  //Not use Write in 0x04 (STATUS, READ Only)
//	          4'h1:
//	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
//	                // Respective byte enables are asserted as per write strobes 
//	                // Slave register 1
//	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//	              end  
	          4'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h8:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h9:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'ha:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_rega[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hb:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_regb[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hc:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_regc[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hd:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_regd[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'he:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_rege[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hf:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_regf[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          default : begin
	                      slv_reg0 <= slv_reg0;
//	                      slv_reg1 <= slv_reg1; //Not use Write in 0x04 (STATUS, READ Only)
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
						  slv_reg4 <= slv_reg4;
						  slv_reg5 <= slv_reg5;
						  slv_reg6 <= slv_reg6;
						  slv_reg7 <= slv_reg7;
						  slv_reg8 <= slv_reg8;
						  slv_reg9 <= slv_reg9;
						  slv_rega <= slv_rega;
						  slv_regb <= slv_regb;
						  slv_regc <= slv_regc;
						  slv_regd <= slv_regd;
						  slv_rege <= slv_rege;
						  slv_regf <= slv_regf;
	                    end
	        endcase
	      end
	  end
	end    

	//AXI4-Lite Read / Write Condition 
	wire clk = S_AXI_ACLK;                       
	wire reset_n = S_AXI_ARESETN;

	wire [C_S_AXI_ADDR_WIDTH-1:0]   mem0_axi_addr = 'h8; 
	wire [C_S_AXI_ADDR_WIDTH-1:0]   mem0_axi_data = 'hc; 
	wire [C_S_AXI_DATA_WIDTH-1:0]	mem0_addr_reg = S_AXI_WDATA; 
	wire [C_S_AXI_DATA_WIDTH-1:0]	mem0_data_reg = S_AXI_WDATA;  
	wire mem0_addr_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem0_axi_addr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]); 
	wire mem0_data_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem0_axi_data[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]); 
	wire mem0_data_read_hit = slv_reg_rden && (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem0_axi_data[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);

	//Address conunter to BRAM
	reg	[MEM0_ADDR_WIDTH-1:0] mem0_addr_cnt;
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
	        mem0_addr_cnt <= 0;  
	    end else if (mem0_addr_write_hit) begin 
	        mem0_addr_cnt <= mem0_addr_reg; 
	    end else if (mem0_data_write_hit || mem0_data_read_hit) begin
	        mem0_addr_cnt <= mem0_addr_cnt + 1;
		end
	end

	//delay 1 cycle, read valid from memory
	reg slv_reg_rden_d;
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
			axi_rvalid_d	<= 'd0;
			slv_reg_rden_d	<= 'd0;
	    end else begin
			axi_rvalid_d	<= axi_rvalid;
			slv_reg_rden_d	<= slv_reg_rden;
	    end 
	end

	//Assgin Memory I/F
	assign mem0_addr1 	= mem0_addr_cnt[MEM0_ADDR_WIDTH-1:0]			; 
	assign mem0_ce1		= mem0_data_write_hit || mem0_data_read_hit		;
	assign mem0_we1		= mem0_data_write_hit 							;
	assign mem0_d1		= mem0_data_reg									;

	// AXI4-Lite Read / Write Condition 
	wire [C_S_AXI_ADDR_WIDTH-1:0]   mem1_axi_addr = 'h10; 
	wire [C_S_AXI_ADDR_WIDTH-1:0]   mem1_axi_data = 'h14; 
	wire [C_S_AXI_DATA_WIDTH-1:0]	mem1_addr_reg = S_AXI_WDATA;  
	wire [C_S_AXI_DATA_WIDTH-1:0]	mem1_data_reg = S_AXI_WDATA; 
	wire mem1_addr_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem1_axi_addr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire mem1_data_write_hit = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem1_axi_data[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);
	wire mem1_data_read_hit = slv_reg_rden && (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == mem1_axi_data[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]);

	//Address conunter to BRAM
	reg	[MEM1_ADDR_WIDTH-1:0] mem1_addr_cnt;
	always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
	        mem1_addr_cnt <= 0;  
	    end else if (mem1_addr_write_hit) begin
	        mem1_addr_cnt <= mem1_addr_reg; 
	    end else if (mem1_data_write_hit || mem1_data_read_hit) begin
	        mem1_addr_cnt <= mem1_addr_cnt + 1;
		end
	end

	//Assgin Memory I/F
	assign mem1_addr1 	= mem1_addr_cnt[MEM1_ADDR_WIDTH-1:0]			; 
	assign mem1_ce1		= mem1_data_write_hit || mem1_data_read_hit		;
	assign mem1_we1		= mem1_data_write_hit 							;
	assign mem1_d1		= mem1_data_reg									;

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        4'h0   : reg_data_out <= slv_reg0;
	        4'h1   : reg_data_out <= slv_reg1;
	        4'h2   : reg_data_out <= slv_reg2;
	        4'h3   : reg_data_out <= mem0_q1[C_S_AXI_DATA_WIDTH-1:0]; //from bram0 out
	        //4'h3   : reg_data_out <= slv_reg3;
	        4'h4   : reg_data_out <= slv_reg4;
	        4'h5   : reg_data_out <= mem1_q1[C_S_AXI_DATA_WIDTH-1:0]; //from bram1 out
	        //4'h5   : reg_data_out <= slv_reg5;
	        //4'h6   : reg_data_out <= slv_reg6;
	        //4'h7   : reg_data_out <= slv_reg7;
	        //4'h8   : reg_data_out <= slv_reg8;
	        //4'h9   : reg_data_out <= slv_reg9;
	        4'h6   : reg_data_out <= result_0;
	        4'h7   : reg_data_out <= result_1;
	        4'h8   : reg_data_out <= result_2;
	        4'h9   : reg_data_out <= result_3;
	        4'ha   : reg_data_out <= slv_rega;
	        4'hb   : reg_data_out <= slv_regb;
	        4'hc   : reg_data_out <= slv_regc;
	        4'hd   : reg_data_out <= slv_regd;
	        4'he   : reg_data_out <= slv_rege;
	        4'hf   : reg_data_out <= slv_regf;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      //if (slv_reg_rden)
	      if (slv_reg_rden_d) //1 cycle delay, read valid from memory
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	//Add user logic here
	
	// tick gen o_run
	reg r_run;
	always @(posedge clk) begin 
    	if(!reset_n) begin // sync reset_n
    	    r_run <= 1'b0;  
    	end else begin
            r_run <= slv_reg0[CNT_BIT];
		end 
	end
	
	assign o_run 		= (r_run == 1'b0) && (slv_reg0[CNT_BIT] == 1'b1) ; // Posedge 1 tick
	assign o_num_cnt 	= slv_reg0[CNT_BIT-1:0]; 	// 30:0

	//	wire reset_n = S_AXI_ARESETN;
	//	wire clk = S_AXI_ACLK;
	reg r_done; // to keep done status, i_done is a 1 tick.
	
	always @(posedge clk) begin
    	if(!reset_n) begin  // sync reset_n
    	    r_done <= 1'b0;  
    	end else if (i_done) begin
    	    r_done <= 1'b1;
		end else if (o_run) begin
			r_done <= 1'b0;
		end  
	// else. keep status
	end

	always @(posedge clk) begin 
    	if(!reset_n) begin // sync reset_n
    	    slv_reg1 <= 32'b0;  
    	end else begin
			slv_reg1[0] <= i_idle;
			slv_reg1[1] <= i_running;
			slv_reg1[2] <= r_done;
			// no use [31:3]
		end 
	end
	// User logic ends

	endmodule
