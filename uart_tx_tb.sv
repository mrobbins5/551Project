module uart_tx_tb();

logic clk, rst_n,tx_start;
logic [7:0] tx_data;

uart_tx iDUT(.clk(clk),.rst_n(rst_n),.tx_start(tx_start),.tx_data(tx_data),.tx(tx),.tx_rdy(tx_rdy));

initial begin
	clk = 0;
	rst_n = 0;
	#26040 tx_data = 8'hA5;
	#26040
	#200 rst_n = 0;
	#600 rst_n = 1;
	#100 tx_start = 1;
	#10 tx_start = 0;
end

initial
	$monitor("time: %t tx: %b ",$time,tx);

always
	#5 clk = ~clk;

endmodule