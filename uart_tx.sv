module uart_tx(clk,rst_n,tx_start,tx_data,tx,tx_rdy);

input clk,rst_n,tx_start;
input [7:0] tx_data;
output logic tx,tx_rdy;

typedef enum reg {IDLE,TX} state_t;
state_t state;
state_t nxt_state;

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
logic baud_full_tx;

//Increments the baudrate (2604 cycles)
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    baud_count <= 1'b0;
  else if(clear_baud)
	baud_count <= 1'b0;
  else if(baud_full_tx)
    baud_count <= 1'b0; 
  else if(baud_count != 12'hA2C) //2604
    baud_count <= baud_count + 1'b1;
  end

assign baud_full_tx = (baud_count == 12'hA2C) ? 1'b1 : 1'b0; 

/////////////////////////
// 4-bit index counter //
/////////////////////////
logic [3:0] index;
logic bit_full,clear_index;
always_ff @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		bit_full <= 1'b0;
		index <= 3'b0;
	end 
	else if (clear_index) begin
		bit_full <= 1'b0;
		index <= 3'b0;
	end
	else begin
		if (index == 4'b1001)
			bit_full <= 1'b1;
		else if (baud_full_tx)
			index <= index + 1'b1;
	end		
end

/////////////////////////
// 8-bit right shifter //
/////////////////////////
logic load;
logic shift;
logic [7:0] tx_data_shift;
always_ff @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		tx_data_shift <= 8'h0;
		tx <= 1'b1;
	end else
		if (load) begin
			tx_data_shift <= tx_data;
			tx <= 1'b0; // start bit
		end else if (shift && baud_full_tx) begin
			{tx_data_shift,tx} <= {1'b1,tx_data_shift[7:1],tx_data_shift[0]};
		end		
end

///////////////////////
// combi for outputs //
///////////////////////
always @ (*) begin
//default outputs
	load = 1'b0;
	shift = 1'b0;
	clear_baud = 1'b0;
	clear_index = 1'b1;
	tx_rdy = 1'b1;
	case (state)
		IDLE: begin
			if (tx_start) begin
				load = 1'b1;
				clear_baud = 1'b1;
				nxt_state = TX;
			end
			else begin 
				clear_baud = 1'b1;
				nxt_state = IDLE;
			end
		end		
		TX: begin
			tx_rdy = 1'b0;
			if (!bit_full && baud_full_tx) begin
				shift = 1'b1;
				nxt_state = TX;
			end
			else if (bit_full && baud_full_tx) begin
				shift = 1'b1;
				nxt_state = IDLE;
			end
			else begin
				nxt_state = TX;
			end
			clear_index = 1'b0;
		end
		default: nxt_state = IDLE;
	endcase		
end


endmodule