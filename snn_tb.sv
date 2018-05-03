module snn_tb();

logic clk, sys_rst_n;
logic uart_tx, uart_rx;
logic [7:0] led;
logic uart_data;
logic [9:0] addr_input_unit;

logic weINPUT;

uart_input_unit instance1(.data(uart_data), .addr(addr_input_unit), .we(weINPUT), .clk(clk), .q(uart_rx)); 
SNN iDUT(.clk(clk),.sys_rst_n(sys_rst_n),.led(led),.uart_tx(uart_tx),.uart_rx(uart_rx),.addr_input_unit(addr_input_unit));

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