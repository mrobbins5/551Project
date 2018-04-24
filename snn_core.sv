//snn_core

//MAC MODULE
//SOME MUXES CONNECTING THEM
//WEIGHTS and LUT ARE PROVIDED 

module snn_core(clk, rst_n, start, q_input, addr_input_unit, digit, done); 

input logic start; 
input logic d_input; 
input logic clk, rst_n; 

output logic [9:0] addr_input_unit; 
output logic [3:0] digit; 
output logic done; 

//Counting stuff
logic [9:0] count784; 
logic [5:0] count32; 
logic clear32Flag, clear784Flag;

//internal inputs for mac
signed logic [7:0] in1, in2;
//internal output of mac
logic signed [25:0] acc;
//internal clear for mac
logic clr; 


logic signed [7:0] q_ext; 
//FSM Design modeled by professor's diagram/// BP = "Back Porch"
typedef enum [3:0]{IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE, 
					MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t; 

state_t cur_state, nxt_state; 

 

//Instantiate MAC module 
mac mac1(acc, in1, in2, clr, clk, rst_n);

//rect // address TODO
assign rect_addr = (acc[25] == 0 && |acc[24:17] ) ? 11'h3FF :
		(acc[25] == 1 && &acc[24:17]) ? 11'h400 : acc [17:7];
assign addr = rect_addr + 11'h400; 



//************************************ROM***************************************//
//////////////////////////////////////////////////////////////////////////////////

//Instantiate rom_hidden_weight
rom_hidden_weight rhw1(addr, clk, q1);
 
//Instantiate rom_output_weight 
rom_output_weight row1(addr, clk, q2);

//Instantiate rom_act_func_lut
rom_act_func_lut rafl(addr, clk, q_lut); 

//*************************************RAM**************************************//
//////////////////////////////////////////////////////////////////////////////////

//Instantiate ram_hidden_unit
ram_hidden_unit rhu1(data, addr, we, clk, q_weight_hidden); 

//Instantiate ram_output_unit
ram_output_unit rou1(data, addr, we, clk, q_weight_output); 


//Extend 1-bit q_input to 8-bit to make it either 0 (8’b00000000) or 127 (8’b01111111).
assign q_ext = (q_input) ? 8'h7F : 8'h0 ;

// assign addr_hidden_weight = (some flag from FSM) addr_hidden_weight + 1 : addr_hidden_weight;

//SEQUENTIAL LOGIC/////////////////////////////////////////////////////////////////////////////

//FSM sequential logic
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) cur_state <= IDLE; 
	else cur_state <= nxt_state;
end

//784 and 32 Counter logic for FSM 
always_ff @(posedge clk, negedge rst_n) begin

	if(!rst_n) begin
		count784 <= 8'b0; 
		count32 <= 8'b0; 
	end
	
	else begin

		if(clear784Flag) count784 <= 8'b0; 
		else count784 <= count784 + 1'b1; 
		
		if(clear32Flag) count32 <= 8'b0; 
		else count32 <= count32 + 1'b1; 
		
	end
end

//COMBINATIONAL LOGIC//////////////////////////////////////////////////////////////////////////  
always_comb begin
	//Initialize all output variables
	done = 0; 
	digit = 4'b0000; 
	addr_input_unit = 10'b00_0000_0000;
	clear784Flag = 1'b0; 
	clear32Flag = 1'b0; 
	
	case(cur_state)
	IDLE : begin
		//Wait until "start"
		clear784Flag = 1'b1; //Set clear 784 flag
		if(start) nxt_state = MAC_HIDDEN; 
		else nxt_state = IDLE; 
	end
	
	MAC_HIDDEN : begin
		//Check for both inputs to be received
		if() nxt_state = MAC_HIDDEN; 
		else nxt_state = MAC_HIDDEN_BP1; 
	end
	
	MAC_HIDDEN_BP1 : begin
		//Take time to do the calculation
		nxt_state = MAC_HIDDEN_BP2;
		in1 = q_ext; 
		in2 = q1;
	end
	
	MAC_HIDDEN_BP2 : begin
		//Take time to do yield the output
		nxt_state = MAC_HIDDEN_WRITE; 
		
	end
	
	MAC_HIDDEN_WRITE : begin
		//Set the inputs to the MAC 
		
		
		//Haven't finished all 784 bits 
		if(!(count784 == 12'h310)) nxt_state = MAC_HIDDEN;		
		
		//Finished all 784 bits
		else nxt_state = MAC_OUTPUT; 

	end 
	
	MAC_OUTPUT : begin
		if() nxt_state = MAC_OUTPUT; 
		else nxt_state = MAC_OUTPUT_BP1; 
	end
	
	MAC_OUTPUT_BP1 : begin
		nxt_state = MAC_OUTPUT_BP2; 
	end
	
	MAC_OUTPUT_BP2 : begin
		nxt_state = MAC_OUTPUT_WRITE; 
	end
	
	MAC_OUTPUT_WRITE : begin
		if(!(count32 == 6'h20) nxt_state = MAC_OUTPUT; 
		else begin 
			nxt_state = DONE; 
			clear32Flag = 1'b1; //Set clear 32 flag
		end
	end
	
	DONE : begin
		nxt_state = IDLE; 
	end
	
	//If we go out of bounds
	default : begin
		nxt_state = IDLE; 
	end
	
		

end

endmodule

