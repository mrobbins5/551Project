module rom_output_weight #(
parameter DATA_WIDTH = 4'h8, parameter ADDR_WIDTH = 4'h9)(
input [(ADDR_WIDTH-1'b1):0] addr,
input clk,
output reg [(DATA_WIDTH-1'b1):0] q);

// Declare the ROM variable
reg [DATA_WIDTH-1'b1:0] rom[2**ADDR_WIDTH-1'b1:0];

initial
	$readmemh("rom_output_weight_contents.txt", rom);
 
always @ (posedge clk) begin
	q <= rom[addr];
end

endmodule 