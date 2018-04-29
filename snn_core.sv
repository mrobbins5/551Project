//snn_core

//MAC MODULE
//SOME MUXES CONNECTING THEM
//WEIGHTS and LUT ARE PROVIDED 

module snn_core(clk, rst_n, start, q_input, addr_input_unit, digit, done); 

input logic start; 
input logic q_input; 
input logic clk, rst_n; 

output logic [9:0] addr_input_unit; 
output logic [3:0] digit; 
output logic done; 

//Counting 
logic [9:0] count784; 
logic [5:0] count32; 
logic clear32Flag, clear784Flag, macIn1Sel, macIn2Sel, doneFlag;


logic signed  [7:0] in1, in2; 		//internal inputs for mac
logic signed [25:0] acc; 			//internal output of mac
logic mac_clr; 							//internal clear for mac

//Address
logic [10:0] addr; 

logic addr_input_unit_inc,addr_hidden_weight_inc,addr_hidden_unit_inc,addr_output_weight_inc;


logic signed [7:0] q_ext; 
//FSM Design modeled by professor's diagram/// BP = "Back Porch"
typedef enum logic [3:0] {IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE, 
					MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t; 

state_t cur_state, nxt_state; 
 

//////////////////////////////Instantiate MAC module////////////////////////////// 
mac mac1(acc, in1, in2, mac_clr, clk, rst_n);

//************************************ROM***************************************//
//////////////////////////////////////////////////////////////////////////////////

//Instantiate rom_hidden_weight
rom_hidden_weight rhw1(addr_hidden_weight, clk, q_weight_hidden);
 
//Instantiate rom_output_weight 
rom_output_weight row1(addr_output_weight, clk, q_weight_output);

//Instantiate rom_act_func_lut
rom_act_func_lut rafl(addr, clk, q_lut); 

//*************************************RAM**************************************//
//////////////////////////////////////////////////////////////////////////////////

//Instantiate ram_hidden_unit
ram_hidden_unit rhu1(d_hidden_unit, addr_hidden_unit, we, clk, q_hidden_unit); 

//Instantiate ram_output_unit
ram_output_unit rou1(d_output_unit, addr, we, clk, q_weight_output); 

//Extend 1-bit q_input to 8-bit to make it either 0 (8’b00000000) or 127 (8’b01111111).
assign q_ext = (q_input) ? 8'h7F : 8'h0 ;
assign d_hidden_unit = q_lut;
assign d_output_unit = (doneFlag) ? q_lut : 1'b0;
assign in1 = (macIn1Sel) ? q_hidden_unit : q_ext; // First 2:1 mux (M1) // q_input (extended) vs ram_hidden_unit
assign in2 = (macIn2Sel) ? q_weight_output : q_weight_hidden; // Second 2:1 mux (M2) // rom_hidden_weight vs rom_output weight

//////////////////////////////////////////////SEQUENTIAL LOGIC////////////////////////////////

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
		else if (cur_state == MAC_HIDDEN || cur_state == MAC_OUTPUT_WRITE)count784 <= count784 + 1'b1; 	
		if(clear32Flag) count32 <= 8'b0; 
		else if(cur_state == MAC_HIDDEN_WRITE||cur_state==MAC_OUTPUT) count32 <= count32 + 1'b1; 
	end
end

//////////////////////////////////Rectify address/////////////////////////////////
assign rect_addr = (acc[25] == 0 && |acc[24:17] ) ? 11'h3FF :
		(acc[25] == 1 && &acc[24:17]) ? 11'h400 : acc [17:7];
assign addr = rect_addr + 11'h400; 

/////////////////////////////////ASSIGN OUTPUTS///////////////////////////////////
assign digit = q_weight_output; 
assign done = (doneFlag) ? 1'b1 : 1'b0; 

assign addr_input_unit = (addr_input_unit_inc) ? addr_input_unit + 1'b1 : addr_input_unit;
assign addr_hidden_weight = (addr_hidden_weight_inc) ? addr_hidden_weight + 1'b1 : addr_hidden_weight;
assign addr_hidden_unit = (addr_hidden_unit_inc) ? addr_hidden_unit + 1'b1 : addr_hidden_unit;
assign addr_output_weight = (addr_output_weight_inc) ? addr_output_weight + 1'b1 : addr_output_weight;
// addr_input_unit control RAM_INPUT_UNIT_Address
// and increment every time it gets a bit

////////////////////////////////////////COMBINATIONAL LOGIC////////////////////////////////////
always_comb begin
	//Initialize all output variables
	clear784Flag = 1'b0; 
	clear32Flag = 1'b0; 
	mac_clr = 1'b0; 
	doneFlag = 1'b0; 
	addr_input_unit_inc = 1'b0;
	addr_hidden_weight_inc = 1'b0;
	addr_hidden_unit_inc = 1'b0;
	addr_output_weight_inc = 1'b0;
	macIn1Sel = 1'b0; 
	macIn2Sel = 1'b0; 
	
	case(cur_state) 
	IDLE : begin
		//Wait until "start"
		clear784Flag = 1'b1; //Set clear 784 flag
		macIn1Sel = 1'b0; 
		macIn2Sel = 1'b0; 
		if(start) nxt_state = MAC_HIDDEN; 
		else nxt_state = IDLE; 
	end
	
	MAC_HIDDEN : begin
		//Check for both inputs to be received
		//If we haven't counted to 784, stay here
		if(count784 != 12'h310) begin
			nxt_state = MAC_HIDDEN; 
			addr_input_unit_inc = 1'b1;		//Start incrementing input address
			addr_hidden_weight_inc = 1'b1;	//Start incrementing hidden address
		end
		
		//Continue to next state
		else begin
			nxt_state = MAC_HIDDEN_BP1; 
			addr_hidden_weight_inc = 1'b0; 	//Stop incrementing hidden address for porches
		end
	end
	
	MAC_HIDDEN_BP1 : begin
		//Take time to do the calculation
		nxt_state = MAC_HIDDEN_BP2;

	end
	
	MAC_HIDDEN_BP2 : begin
		//Take time to do yield the output
		nxt_state = MAC_HIDDEN_WRITE; 
		
	end
	
	MAC_HIDDEN_WRITE : begin
		//Set the inputs to the MAC 
		
		
		//Haven't finished all 784 bits 
		if(count32 != 6'h20) begin
			nxt_state = MAC_HIDDEN;
			addr_hidden_weight_inc = 1'b1; //Start incrementing hidden address after porches
			clear784Flag = 1'b1; 
			mac_clr = 1'b1; 
		end
		//Finished all 32 bits
		else begin
			nxt_state = MAC_OUTPUT;
			addr_output_weight_inc = 1'b1; //Start incrementing ouput address
			clear32Flag = 1'b1; 
			macIn2Sel = 1'b1; 
			macIn1Sel = 1'b1; 

		end
	end 
	
	MAC_OUTPUT : begin
		if(count32 != 6'h20) nxt_state = MAC_OUTPUT; 
		else begin
			nxt_state = MAC_OUTPUT_BP1; 
			addr_output_weight_inc = 1'b0; //Stop incrementing output address
		end
	end
	
	MAC_OUTPUT_BP1 : begin
		nxt_state = MAC_OUTPUT_BP2; 
	end
	
	MAC_OUTPUT_BP2 : begin
		nxt_state = MAC_OUTPUT_WRITE; 
		clear32Flag = 1'b1; 
	end
	
	MAC_OUTPUT_WRITE : begin
		if(count784 != 6'h0A) begin
			nxt_state = MAC_OUTPUT; //We reuse 784 counter to count to 10
			addr_output_weight_inc = 1'b1; //Start incrementing ouput address again
			clear32Flag = 1'b1; 
			mac_clr = 1'b1; 
		end
		else begin 
			nxt_state = DONE; 
		end
	end
	
	DONE : begin
		nxt_state = IDLE; 
		doneFlag = 1'b1; 
	end
	
	//If we go out of bounds
	default : begin
		nxt_state = IDLE; 
	end
	
	endcase
	
end

endmodule


