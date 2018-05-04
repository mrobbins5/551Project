module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
input clk;			    // 50MHz clock
input sys_rst_n;		// Unsynched reset from push button. Needs to be synchronized.
output logic [7:0] led;	// Drives LEDs of DE0 nano board
input uart_rx;
output uart_tx;
logic rst_n;			// Synchronized active low reset
logic uart_rx_ff, uart_rx_synch;

//////////////////////////////
///// RESET SYNCHRONIZER /////
//////////////////////////////

rst_synch i_rst_synch(.clk(clk), .RST_n(sys_rst_n), .rst_n(rst_n));

/////////////////////////////////
//////// ADDR ASSIGNMENT ////////
/////////////////////////////////

logic [9:0] Addr_FSM;
logic Addr_FSM_clr, Addr_FSM_inc;

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		Addr_FSM <= 10'b0;
	end
	else if (Addr_FSM_clr) begin
		Addr_FSM <= 10'b0;
	end
	else if (Addr_FSM_inc) begin
		Addr_FSM <= Addr_FSM + 1'b1;
	end
end

///////////////
///// RAM /////
///////////////

logic q_input;
logic we;
logic [9:0] addr_input_unit;
logic [7:0] uart_data;
logic [9:0] Addr_SNN_CORE;
logic ram_input_data;

ram_input_unit RHU(ram_input_data, addr_input_unit, we, clk, q_input); //where addr is coming from

assign addr_input_unit = (we) ? Addr_FSM : Addr_SNN_CORE;

////////////////////
///// SNN_CORE /////
////////////////////

logic start;
logic [3:0] digit;
snn_core sc(clk, rst_n, start, q_input, Addr_SNN_CORE, digit, done); 

//////////////////////////////
////// UART_TX, UART_RX //////
//////////////////////////////

logic tx_rdy;
logic rx_rdy;

logic shift;
logic [7:0] tempData; 

logic led_done; 
logic [3:0] digit_led_setup;
/////////////////////
//////// LED ////////
/////////////////////
assign digit = (led_done) ? digit : 1'b0; 
assign led = {4'b00, digit};

// Double flop RX for meta-stability reasons
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		uart_rx_ff		<= 1'b1;
		uart_rx_synch	<= 1'b1;
		
		//Shifting logic
		tempData <= 1'b0; 
	end
	else begin
		uart_rx_ff 		<= uart_rx;
		uart_rx_synch 	<= uart_rx_ff;
		
		//Shifting logic
		if(rx_rdy) tempData <= uart_data; 
		else if(shift) tempData <= (tempData >> 1); 
		else tempData <= tempData; 
	end
end

// Instantiate UART_RX and UART_TX and connect them below
// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".

uart_rx instance1(.clk(clk),.rst_n(rst_n),.rx(uart_rx_synch),.rx_rdy(rx_rdy),.rx_data(uart_data));
uart_tx instance2(.clk(clk),.rst_n(rst_n),.tx_start(done),.tx_data(led),.tx(uart_tx),.tx_rdy(tx_rdy));


assign ram_input_data = tempData[0];

////////////////////////////////////
/////  98 and 8 cycles counter /////
////////////////////////////////////

logic cycle98_clr, cycle98_inc, cycle8_clr, cycle8_inc, cycle8_full, cycle98_full;
logic [6:0] cycle98;
logic [2:0] cycle8;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cycle98 <= 1'b0;
		cycle8 	<= 1'b0;
	end 
	else begin
		if (cycle98_clr) begin
			cycle98 <= 1'b0;
		end
		if (cycle8_clr) begin
			cycle8 <= 1'b0;
		end
		
		if (cycle8_inc) begin
			cycle8 <= cycle8 + 1'b1;
		end
		if (cycle98_inc) begin
			cycle98 <= cycle98 + 1'b1;
		end
	end
end

assign cycle98_full = (cycle98  == 7'h61) ? 1'b1 : 1'b0; // 98 cycles
assign cycle8_full = (cycle8  == 3'h7) ? 1'b1 : 1'b0; // 8 cycles

/////////////////////////
////// CONTROL FSM //////
/////////////////////////

typedef enum logic [1:0] {RX, RAM, CORE, TX} state_t; 

state_t cur_state, nxt_state; 

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cur_state <= RX; 
	else
		cur_state <= nxt_state;
end

always_comb begin
	shift = 1'b0;
	start = 1'b0;
	we = 1'b0;
	
	Addr_FSM_clr = 1'b0;
	Addr_FSM_inc = 1'b0;
	
	cycle98_clr = 1'b0;
	cycle8_clr = 1'b0;
	
	cycle98_inc = 1'b0;
	cycle8_inc = 1'b0;
	led_done = 1'b1; 
	case(cur_state)
	
	RX: begin
	led_done = 0;   
		if (rx_rdy) begin
			cycle98_inc = 1'b1;
	//		Addr_FSM_inc = 1'b1;
			//we = 1'b1;//////////////////
			nxt_state = RAM;
		end
		else begin
			nxt_state = RX;
		end
	end
	RAM: begin
		Addr_FSM_inc = 1'b1;
		we = 1'b1;
		if (!cycle8_full) begin
			cycle8_inc = 1'b1;
			shift = 1'b1;		
			nxt_state = RAM;
		end
		else if (cycle98_full) begin
			start = 1'b1;
			nxt_state = CORE;
		end
		else begin
			cycle8_clr = 1'b1;
			nxt_state = RX;
		end
	end
	
	CORE: begin
		if (done) begin
			nxt_state = TX;
		end
		else begin
			nxt_state = CORE;
		end
	end
	
	TX: begin
		if (tx_rdy) begin
			Addr_FSM_clr = 1'b1;
			nxt_state = RX;
			//clear everything because done. 
			cycle98_clr = 1'b1;
			cycle8_clr = 1'b1;
		end
		else begin
			nxt_state = TX;
		end
	end
	
	default: begin
		nxt_state = RX;
	end	
endcase
end



endmodule