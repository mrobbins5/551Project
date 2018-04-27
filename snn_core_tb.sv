module snn_core_tb();

logic we,rst_n,start,q_input,done;
logic [9:0] addr_input_unit;
logic [3:0] digit;
logic clk;
logic uart_data;

ram_input_unit instance1(uart_data, addr_input_unit, we, clk, q_input); 
//snn_core instance2(clk, rst_n, start, q_input, addr_input_unit, digit, done);

initial begin
	clk = 0;
	rst_n = 0;
	we = 0;
	uart_data = 1'bx;
	#5 rst_n = 1;
	start = 1;
	#5000 addr_input_unit = 10'h001;
	#5000 addr_input_unit = 10'h002;
	#5000 addr_input_unit = 10'h003;
	#5000 addr_input_unit = 10'h004;
	
end
	
always
	#5 clk = ~ clk;

endmodule