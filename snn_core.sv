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

//May need another sequential for back porches/counters

//COMBINATIONAL LOGIC//////////////////////////////////////////////////////////////////////////  
always_comb begin
	//Initialize all output variables
	done = 0; 
	digit = 4'b0000; 
	addr_input_unit = 10'b00_0000_0000;
	
	case(cur_state)
	IDLE : begin
		//Wait until "start"
		if(start) nxt_state = MAC_HIDDEN; 
		else nxt_state = IDLE; 
	end
	MAC_HIDDEN : begin
		//if(something<32) nxt_state = MAC_HIDDEN; 
	end
	MAC_HIDDEN_BP1 : begin
	
	end
	MAC_HIDDEN_BP2 : begin
	
	end
	MAC_HIDDEN_WRITE : begin
	
	end 
	MAC_OUTPUT : begin
	
	end
	MAC_OUTPUT_BP1 : begin
	
	end
	MAC_OUTPUT_BP2 : begin
	
	end
	MAC_OUTPUT_WRITE : begin
	
	end
	DONE : begin
	
	end
	//If we go out of bounds
	default : begin
		nxt_state = IDLE; 
	end
	
		

end

endmodule

