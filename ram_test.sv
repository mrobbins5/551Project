module ram_test #(
parameter DATA_WIDTH = 4'h8 ,parameter ADDR_WIDTH = 3'h5)(
input  data,
input [9:0] addr,
input we, clk,
output  q);

// Declare the RAM variable
reg [DATA_WIDTH-1'b1:0] ram[2**ADDR_WIDTH-1'b1:0];

// Variable to hold the registered read address
reg [ADDR_WIDTH-1'b1:0] addr_reg;

initial
	$readmemh("ram_test.txt", ram);

always @ (posedge clk) begin
	if (we) ram[addr] <= data; // Write
	addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule