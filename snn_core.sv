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

//FSM Design modeled by professor's diagram/// BP = "Back Porch"
typedef enum [3:0]{IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE, 
					MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t; 

state_t cur_state, nxt_state; 



//Instantiate MAC module 
mac mac1(acc, in1, in2, clr, clk, rst_n);

//Instantiate rom_hidden_weight
rom_hidden_weight rhw1(addr, clk, q);
 
//Instantiate rom_output_weight 
rom_output_weight row1(addr, clk, q);

//Instantiate ram_hidden_unit
ram_hidden_unit rhu1(data, addr, we, clk, q); 

//Instantiate ram_output_unit
ram_output_unit rou1(data, addr, we, clk, q); 

//Instantiate rom_act_func_lut
rom_act_func_lut rafl(addr, clk, q); 

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

