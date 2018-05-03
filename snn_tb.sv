module snn_tb();

logic clk, sys_rst_n;
logic [7:0] led;
logic uart_data;
logic [9:0] addr_input_unit;

logic rx, rx_rdy, tx, tx_start, tx_rdy;
logic [7:0] tx_data, rx_data; 

logic weINPUT;

uart_input_unit instance1(.data(uart_data), .addr(addr_input_unit), .we(weINPUT), .clk(clk), .q(uart_rx)); 
snn iDUT(.clk(clk),.sys_rst_n(sys_rst_n),.led(led),.uart_tx(uart_tx),.uart_rx(uart_rx),.addr_input_unit(addr_input_unit));
uart_rx iDUT(.clk(clk), .rst_n(sys_rst_n), .rx(rx),.rx_rdy(rx_rdy), .rx_data(rx_data));
uart_tx iDUT(.clk(clk), .rst_n(sys_rst_n), .tx_start(tx_start), .tx_data(tx_data),.tx(tx),.tx_rdy(tx_rdy));


initial begin
	clk = 0;
	#5 sys_rst_n = 1;
	weINPUT = 0;
	uart_data = 0;
	#5 sys_rst_n = 0;
	#5 sys_rst_n = 1;
end

always
	#5 clk = ~ clk;

endmodule