module snn_core_tb();

logic we,rst_n,start,q_input,done;
logic [9:0] addr_input_unit;
logic [3:0] digit;
logic clk;
logic uart_data;

ram_input_unit instance1(.data(uart_data), .addr(addr_input_unit), .we(we), .clk(clk), .q(q_input)); 
snn_core instance2(clk, rst_n, start, q_input, addr_input_unit, digit, done);

initial begin
	clk = 0;
	#5 rst_n = 0;
	we = 0;
	uart_data = 1'b1;
	#5 rst_n = 1;
	start = 1;
	#50 start = 0;
end

/*initial $monitor("IN#%d %d %d#%d, acc:%d@%d", snn_core_tb.instance2.addr_input_unit,snn_core_tb.instance2.in1,
snn_core_tb.instance2.in2,snn_core_tb.instance2.addr_hidden_weight,
snn_core_tb.instance2.acc,snn_core_tb.instance2.addr_hidden_unit);*/
	
always
	#5 clk = ~ clk;

endmodule