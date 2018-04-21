module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output logic [7:0] led;	// Drives LEDs of DE0 nano board
	
	input uart_rx;
	output uart_tx;

	logic rst_n;				 	// Synchronized active low reset
	
	logic uart_rx_ff, uart_rx_synch;
	
	logic rx_rdy; //leave unconnected

	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	/******************************************************
	UART
	******************************************************/
	
	// Declare wires below
	
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	uart_rx instance1(clk,rst_n,uart_rx,rx_rdy,uart_rx); 
	//module uart_rx(clk,rst_n,rx,rx_rdy,rx_data);
	
	uart_tx instance2(clk,rst_n,rx_rdy,rx_data,uart_tx,tx_rdy); 
	//module uart_tx(clk,rst_n,tx_start,tx_data,tx,tx_rdy);
			
	/******************************************************
	LED
	******************************************************/
	assign led = rx_data;

endmodule


