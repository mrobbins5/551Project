module mac_tb();

logic signed [7:0] a; 
logic signed [7:0] b; 
logic clr, clk, rst_n; 

logic signed [25:0] acc; 


//Instantiate DUT
mac iDUT(acc, a, b, clr, clk, rst_n);


initial begin

//initialize values
rst_n = 0; 
clr = 0; 
a = 8'd0; 
b = 8'd0; 


#10;

rst_n = 1; 
clr = 1; 

//Test: 2*5 + (-2)*5 + (-3)*8

a = 8'd2; 
b = 8'd5;

#10;

a = 8'd2; 
b = -8'd5; 

#10;

a = -8'd3;
b = 8'd8; 

#10

//Example that generates overflow

a = 8'b01111111;
b = 8'b01111111;

end


initial clk = 0;
always clk = #5 ~clk; 

endmodule

