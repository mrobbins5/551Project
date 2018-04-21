//snn_core

//MAC MODULE
//SOME MUXES CONNECTING THEM
//WEIGHTS and LUT ARE PROVIDED 

module snn_core(clk, rst_n, start, d_input, addr_input_unit, digit, done); 

input logic start; 
input logic d_input; 
input logic clk, rst_n; 

output logic [9:0] addr_input_unit; 
output logic [3:0] digit; 
output logic done; 

//FSM Design modeled by professor's diagram/// BP = "Back Porch"
typedef enum [3:0]{IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE, 
					MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t; 

state_t cur_state, nxt_state; 



//Instantiate MAC module 

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
	
	end
	MAC_HIDDEN : begin
	
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
	
		

end

endmodule

