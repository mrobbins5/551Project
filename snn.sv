module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
input clk;			      // 50MHz clock
input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
output logic [8:0] led;	// Drives LEDs of DE0 nano board
input uart_rx;
output uart_tx;
logic rst_n;				 	// Synchronized active low reset
logic uart_rx_ff, uart_rx_synch;

/******************************************************
Reset synchronizer
******************************************************/
rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));

/******************************************************
RAM
******************************************************/
logic q_input;
logic we;
logic [9:0] addr_input_unit;
ram_input_unit riu1(uart_data, addr_input_unit, we, clk, q_input); 

/******************************************************
SNN_CORE
******************************************************/
logic start;
logic [3:0] digit;
snn_core sc(clk, rst_n, start, q_input, addr_input_unit, digit, done); 

/******************************************************
UART_TX, UART_RX
******************************************************/

// Declare wires below
logic [7:0] uart_data;
logic tx_rdy;
logic rx_rdy;

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

uart_rx instance1(.clk(clk),.rst_n(rst_n),.rx(uart_rx_synch),.rx_rdy(rx_rdy),.rx_data(uart_data));
uart_tx instance2(.clk(clk),.rst_n(rst_n),.tx_start(done),.tx_data(led),.tx(uart_tx),.tx_rdy(tx_rdy));

/****************************
CONTROL FSM
****************************/

//start is an input to FSM
//done is an input to FSM

typedef enum logic [1:0] {RX, CORE, TX} state_t; 

state_t cur_state, nxt_state; 

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) cur_state <= IDLE; 
	else cur_state <= nxt_state;
end

always_comb begin
case(cur_state)
	start = 1'b0; // start SNN core
	clear_cycle = 1'b0;
we = 1'b0;
	RX : begin
		if (cycle_full) begin
			nxt_state = RAM;
			start = 1'b1;
			end
		else if (rx_rdy) begin
			we = 1b'1;
			nxt_state = RX;
			end
		else
			nxt_state = RX;
	end
	
	
	CORE : begin
	if (done)
		nxt_state = TX;
	else
		nxt_state = CORE;
	end
	
	TX: begin
		if (tx_rdy) begin
			nxt_state = RX;
			clear_cycle = 1'b1;
		end
		else
			nxt_state = TX;
	end
	default: begin
		nxt_state = RX;
	end
end

////////////////////////////////////
// 7-bit (98 cycles) byte counter //
////////////////////////////////////
logic [6:0] cycle;
logic clear_cycle, cycle_full;

always_ff @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cycle <= 1'b0;
	end 
	else if (clear_cycle) begin
		cycle <= 1'b0;
	end
	else if (rx_rdy)
		cycle <= cycle + 1'b1;
end

assign cycle_full = (cycle  == 7'h62) ? 1'b1 : 1'b0; // 98 cycles

		
/******************************************************
LED
******************************************************/
assign led = {4'b0, digit};

endmodule
