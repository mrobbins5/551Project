module snn_tb();

logic clk, sys_rst_n;
logic snn_tx, snn_rx;
logic [7:0] led;

logic rx_rdy;
logic tx_rdy, tx_start; 

logic [7:0] rx_data;
logic [7:0] tx_data;

logic [9:0] addr;
logic [7:0] Byte;

pc_ram instance4(1'bx, addr, 1'b0, clk, q);

//Chunks of 8 go into tx_data
pc_uart_tx instance2(.clk(clk),.rst_n(sys_rst_n),.tx_start(tx_start),.tx_data(Byte),.tx(snn_rx),.tx_rdy(tx_rdy));

SNN iDUT(.clk(clk),.sys_rst_n(sys_rst_n),.led(led),.uart_tx(snn_tx),.uart_rx(snn_rx));

pc_uart_rx instance3(.clk(clk),.rst_n(sys_rst_n),.rx(snn_tx),.rx_rdy(rx_rdy),.rx_data(rx_data));

//Now we want to read from pc_ram and move the data into pc_uart_tx
//8 Bits at a time
//98 times


initial begin
	clk = 0;
	#5 sys_rst_n = 1;
	#5 sys_rst_n = 0;
	#5 sys_rst_n = 1;
	Byte = 0;
	tx_start = 0; 
	
	for(int i = 0 ; i < 98; i++) begin
		
		
		for(int j = 0; j < 8; j++) begin
			Byte[j] = q; 
			addr = 8*i + j; 
			#26040;
		end
		
		tx_start = 1;
		#10;
		tx_start = 0; 
		#26040;
		#26040;
		#26040;
		
	end	
end

always
	#5 clk = ~ clk;

endmodule