`timescale 1 ns / 1 ps
module true_sync_dpbram (
	clk, 
	addr0, 
	ce0, 
	we0, 
	q0, 
	d0, 
	addr1, 
	ce1, 
	we1,
	q1, 
	d1
);

parameter DWIDTH = 16;
parameter AWIDTH = 12;
parameter MEM_SIZE = 3840;

input clk;

input[AWIDTH-1:0] addr0;
input ce0;
input we0;
output reg[DWIDTH-1:0] q0;
input[DWIDTH-1:0] d0;

input[AWIDTH-1:0] addr1;
input ce1;
input we1;
output reg[DWIDTH-1:0] q1;
input[DWIDTH-1:0] d1;

(* ram_style = "block" *)reg [DWIDTH-1:0] ram[0:MEM_SIZE-1];

always @(posedge clk)  
begin 
    if (ce0) begin
        if (we0) 
            ram[addr0] <= d0;
		else
        	q0 <= ram[addr0];
    end
end

always @(posedge clk)  
begin 
    if (ce1) begin
        if (we1) 
            ram[addr1] <= d1;
		else
        	q1 <= ram[addr1];
    end
end

endmodule
