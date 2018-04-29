localparam DATA_WIDTH = 1'b1; 
localparam ADDR_WIDTH = 4'hA; 

module ram_input_unit (
input [(DATA_WIDTH-1):0] data,
input [(ADDR_WIDTH-1):0] addr,
input we, clk,
output [(DATA_WIDTH-1):0] q);

// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
// Variable to hold the registered read address
reg [ADDR_WIDTH-1:0] addr_reg;

initial
$readmemh("ram_input_contents.txt", ram);

always @ (posedge clk) begin
if (we) // Write
	ram[addr] <= data;
	addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule