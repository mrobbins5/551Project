localparam DATA_WIDTH = 4'h8; 
localparam ADDR_WIDTH = 4'hF; 

module rom_hidden_weight (

 input [(ADDR_WIDTH-1):0] addr,
 input clk,
 output reg [(DATA_WIDTH-1):0] q);
 // Declare the ROM variable
 reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
 initial begin
 $readmemh("rom_hidden_weight_contents.txt", rom);
 end
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule 

