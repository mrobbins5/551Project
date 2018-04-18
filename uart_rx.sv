//DUT by Michael and Mark 

module uart_rx(rx, rx_rdy, rx_data, clk, rst_n, buffer_data); 

input logic rx, rx_rdy, clk, rst_n; 

output logic [0:7] rx_data; //Setup to have LSB to the left

output logic [0:9] buffer_data; //Setup to have LSB to the left

logic [11:0] baud_ctr; //baud rate counter

logic baud_full; 

logic shift; 

logic clr; 

logic rx_start;

typedef enum reg [1:0] {IDLE, RX} state_t; 

state_t state, nxt_state; 

//Counter for which bit we are at in the line
logic [3:0] counter; 

assign baud_full = (baud_ctr >= 12'hA2C) ? 1'b1 : 1'b0; 
//assign clr = (baud_full) ? 1'b1 : 1'b0; 

assign shift = (counter < 9) ? 1'b1 : 1'b0; 

assign rx_data[0:7] = (rx_rdy) ? buffer_data[1:8] : 8'h00;

//Transition to the next state 
always_ff @(posedge clk, negedge rst_n) begin
 if (!rst_n)
  state <= IDLE; 
 else
state <= nxt_state; 
end

//Increments the baudrate (2604 cycles)
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    baud_ctr <= 0;
  else if(baud_ctr<12'hA2C) //2604
    baud_ctr <= baud_ctr+1;
  else if(baud_full)
    baud_ctr <= 0; 
  end
  
  
//Increment through data until the stop bit is reached
always_ff @(posedge clk, negedge rst_n) begin

//Reset counter and set start bit
if (!rst_n) begin
counter <= 1'b1; 
buffer_data <= 10'b1000000000; 
end

//Increment counter and get data
else begin
buffer_data[0] <= 1'b0;
buffer_data[counter] <= rx;

if(baud_full)
counter <= counter + shift; 

end

end


always_comb begin
//rx_trans=1'b0;
clr = 1'b0;
rx_start=1'b0;
//rx_data = 8'b00000000; //Default values 

case (state)
IDLE : begin

if(rx==0) begin
  rx_start=1'b1;
 nxt_state = RX;  //rx_ready asserted only when all bits have been received
end

else nxt_state = IDLE;

end

RX : begin

//Data state. Exit when counter surpasses data size
if(counter >= 4'h9) begin
    nxt_state = IDLE; 
 	  clr=1'b1;   //clears buffer
 	 // if(buffer_data[0]== 0 && buffer_data[9]==1)rx_trans=1'b1;
  end else begin 
   nxt_state = RX;
    
 end

end

//default : begin // Default is back porch

//Check for the stop bit
//if (rx_rdy) begin
//if(buffer_data[0]== 0 && buffer_data[9]==1) begin //make sure the start and stop bits are correct
//Copy over data because stop bit was correctly recieved
//rx_data[0:7] = buffer_data[1:8]; //counter

//end 
//end
//Go to IDLE no matter what. If stop bit is not recieved frame is ignored
//nxt_state = IDLE; 
///end

endcase

end

endmodule


