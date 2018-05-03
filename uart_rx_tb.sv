module uart_rx_tb();

logic clk,rst_n,rx,rx_rdy;
logic [7:0] rx_data;

uart_rx iDUT(.clk(clk),.rst_n(rst_n),.rx(rx),.rx_rdy(rx_rdy),.rx_data(rx_data)); //instantiation

initial begin

	//A5
	clk = 0;
	rst_n = 0;
	rx = 1;
	#10 rst_n = 1;
	#200 //should not make difference
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 1;
	#26040
	#26040
	
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 1;
	#26040
	#26040
	
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 0;
	#26040
	rx = 1;
	#26040
	rx = 1;
	
	
	
	
	
	
	
	
	
	
	
end

always
	#5 clk = ~clk;

endmodule