module pc_uart_rx(clk,rst_n,rx,rx_rdy,rx_data);

input clk,rx,rst_n;
output logic rx_rdy;
output logic [7:0] rx_data;
logic baud_full,half_baud;

typedef enum reg [1:0] {IDLE,FRONT_POUCH,RX,BACK_POUCH} state_t;
state_t state,nxt_state;
///////////////////////////
// next state assignment //
///////////////////////////
always_ff @ (posedge clk or negedge rst_n) 
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

/////////////////////////////////////
// 12-bit baud counter (2604) //
/////////////////////////////////////
logic [11:0] baud_count;
logic clear_baud;
//logic baud_full,half_baud;

//Increments the baudrate (2604 cycles)
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    baud_count <= 1'b0;
  else if (clear_baud)
	baud_count <= 1'b0;
  else if(baud_count != 12'hA2C) //2603
    baud_count <= baud_count + 1'b1;
  else if(baud_full)
    baud_count <= 1'b0; 
  end

assign baud_full = (baud_count == 12'hA2C) ? 1'b1 : 1'b0; 
assign half_baud = (baud_count == 12'h516 || baud_count == 12'hA2C) ? 1'b1 : 1'b0;

/////////////////////////
// 4-bit index counter //
/////////////////////////
logic [4:0] index;
logic full_rx,clear_index;
always_ff @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		full_rx <= 1'b0;
		index <= 3'b0;
	end 
	else if (clear_index) begin
		full_rx <= 1'b0;
		index <= 3'b0;
	end
	else begin
		if (index == 4'b1000)
			full_rx <= 1'b1;
		else if (baud_full)
			index <= index + 1'b1;
	end		
end

/////////////////////////
// 8-bit right shifter //
/////////////////////////
logic clear_shift;
logic shift;
always_ff @ (posedge clk or negedge rst_n) begin
	if(!rst_n)
		rx_data <= 8'h0;
	else if (clear_shift)
		rx_data <= 8'h0;
	else if (shift)
			rx_data <= {rx,rx_data[7:1]};
end

///////////////////////
// combi for outputs //
///////////////////////
always @ (*) begin
//default output
clear_baud = 1'b0;
clear_shift = 1'b0;
clear_index = 1'b0;
shift = 1'b0;
rx_rdy = 1'b0;
	case (state)
		IDLE: begin
			if (rx) begin
				clear_baud = 1'b1;
				clear_index = 1'b1;
				nxt_state = IDLE;
			end
			else begin
				nxt_state = FRONT_POUCH;	
			end
		end
		FRONT_POUCH: begin
			if (half_baud) begin
				clear_baud = 1'b1;
				nxt_state = RX;
			end
			else begin
				nxt_state = FRONT_POUCH;	
			end
			clear_index = 1'b1;
			clear_shift = 1'b1;
		end
		RX: begin
			if (baud_full && full_rx) begin
				nxt_state = BACK_POUCH;	
				clear_baud = 1'b1;				
			end
			else if (baud_full && !full_rx) begin
				clear_baud = 1'b1;
				shift = 1'b1;
				nxt_state = RX;
			end

			else begin
				nxt_state = RX;	
			end
		end
		BACK_POUCH: begin
			if (half_baud) begin
				if(rx) begin
					rx_rdy = 1'b1;
				end
				nxt_state = IDLE;
			end
			else
				nxt_state = BACK_POUCH;	
		end
		default: nxt_state = IDLE;
	endcase
end

endmodule