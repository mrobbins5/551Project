module snn_core(clk, rst_n, start, q_input, addr_input_unit, digit, done); 

//input and ouput snn logic
input logic start; 					 //Logic to start SNN_core
input logic q_input; 				 //Bit by bit transmissioin of the bitmap
input logic clk, rst_n; 
output logic [3:0] digit; 			 // The Z output Number with the highest score
output logic done; 

//The concatenated value (the real address) of Hidden weight address bits
//and input addres sbits. 5 Hidden bits is MSB followed by the 10 input address. 
output logic [9:0] addr_input_unit;  

//rom and ram addresses
logic [14:0] addr_hidden_weight;
logic [4:0] addr_hidden_unit;
logic [8:0] addr_output_weight;
logic [3:0] addr_output_unit;
logic [10:0] addr_act_func;

//FSM logic counters
logic [9:0] cnt_input; 					//The address of the X(input)
logic [4:0] cnt_hidden;					//The hidden bits portion of the address
logic [3:0] cnt_output; 				//The output bits address (0-9)
logic cnt_hidden_clr, cnt_input_clr, cnt_output_clr;	//counter clear flags
logic cnt_hidden_inc, cnt_input_inc, cnt_output_inc;	//counter increment flags

logic macIn1Sel, macIn2Sel, doneFlag;

//Mac
logic signed  [7:0] in1, in2; 		//Internal inputs for mac
logic signed [25:0] acc; 			//Internal output of mac
logic mac_clr; 						//Internal clear for mac

//Ram-Rom Address Clear/Inc
logic addr_output_weight_clr; 								//Rom output weight
logic addr_input_unit_inc, 		addr_input_unit_clr;		//Ram input unit
logic addr_hidden_weight_clr;								//Rom hidden weight
logic addr_hidden_unit_inc, 	addr_hidden_unit_clr;		//Ram hidden unit
logic addr_output_unit_inc, 	addr_output_unit_clr;		//Ram output unit

//FSM States
typedef enum logic [3:0] {IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE, 
					MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t; 
state_t cur_state, nxt_state; 

////////////////////
//// MAC module ////
////////////////////
mac MAC(.acc(acc), .in1(in1), .in2(in2), .clr(mac_clr), .clk(clk), .rst_n(rst_n)); //Instantiate mac

/////////////////////
//////// ROM ////////
/////////////////////

//weight of layers and the digit
logic [7:0] q_weight_hidden;
logic [7:0] q_weight_output;
logic [7:0] q_lut;

rom_hidden_weight RHW(addr_hidden_weight, clk, q_weight_hidden); 	//Instantiate rom_hidden_weight
rom_output_weight ROW(addr_output_weight, clk, q_weight_output); 	//Instantiate rom_output_weight 
rom_act_func_lut RAFL(addr_act_func, clk, q_lut); 					//Instantiate rom_act_func_lut

/////////////////////
//////// RAM ////////
/////////////////////

logic [7:0] d_hidden_unit, q_hidden_unit;
logic [7:0] d_output_unit;
logic signed [7:0] q_ext;
logic we_ram_hidden_unit; //When we write to ram 

ram_hidden_unit RHU(d_hidden_unit, addr_hidden_unit, we_ram_hidden_unit, clk, q_hidden_unit);	//Instantiate ram_hidden_unit

////////////////////////////////////////////
//////////// 784, 32, and 10 COUNTER ////////////
////////////////////////////////////////////

//FSM counters to assure correct logic flow
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cnt_input	<= 10'b0; 
		cnt_hidden	<= 5'b0; 
		cnt_output	<= 4'b0; 
	end
	else begin
		if (cnt_input_clr)
			cnt_input <= 10'b0; 
		else if (cnt_input_inc)
			cnt_input <= cnt_input + 1'b1;	
		if (cnt_hidden_clr)
			cnt_hidden <= 5'b0; 
		else if (cnt_hidden_inc)
			cnt_hidden <= cnt_hidden + 1'b1; 		
		if (cnt_output_clr)
			cnt_output <= 4'b0; 
		else if (cnt_output_inc)
			cnt_output <= cnt_output + 1'b1; 
	end
end

//////////////////////////////
////////// MAC RECT //////////
//////////////////////////////
logic [10:0] rect_addr;

//rectify address logic
assign rect_addr[10:0] = (!(acc[25]) && (|acc[24:17])) ? 11'h3FF :
		((acc[25]) && !(&acc[24:17])) ? 11'h400 : acc [17:7];
assign addr_act_func = rect_addr + 11'h400; 

/////////////////////////////////////////////////////
////////////////// ADDR ASSIGNMENT //////////////////
/////////////////////////////////////////////////////

always_ff @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		addr_input_unit 	<= 10'b0;
		addr_hidden_unit 	<= 5'b0;
		addr_output_unit 	<= 4'b0;
		end
	else begin
		if (addr_input_unit_clr)
			addr_input_unit <= 10'b0;
		else if (addr_input_unit_inc)
			addr_input_unit <= addr_input_unit + 1'b1;
		if (addr_hidden_unit_clr)
			addr_hidden_unit <= 10'b0;
		else if (addr_hidden_unit_inc)
			addr_hidden_unit <= addr_hidden_unit + 1'b1;		
		if (addr_output_unit_clr) 
			addr_output_unit <= 10'b0;
		else if (addr_output_unit_inc)
			addr_output_unit <= addr_output_unit + 1'b1;
	end
end

assign addr_hidden_weight[14:0] = (addr_hidden_weight_clr) ? 10'b0 : {cnt_hidden[4:0], cnt_input[9:0]};
assign addr_output_weight[8:0] = (addr_output_weight_clr) ? 10'b0 : {cnt_output[3:0], cnt_hidden[4:0]};

///////////////////////
/////// COMPARE ///////
///////////////////////

logic compare;
logic [7:0] maxVal;
logic [3:0] maxInd;
logic maxVal_MaxInd_clr; 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		maxInd <= 4'b0;
		maxVal <= 8'b0;
	end
	else if(maxVal_MaxInd_clr) begin
		maxInd <= 4'b0;
		maxVal <= 8'b0;
	end else if(compare) begin
		
		//START COMPARISON
		//logically compare msb to lsb to find which digit is larger
		if(maxVal[7] != d_output_unit[7]) begin
			if(d_output_unit[7]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[6] != d_output_unit[6]) begin
			if(d_output_unit[6]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[5] != d_output_unit[5]) begin
			if(d_output_unit[5]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[4] != d_output_unit[4]) begin
			if(d_output_unit[4]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[3] != d_output_unit[3]) begin
			if(d_output_unit[3]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[2] != d_output_unit[2]) begin
			if(d_output_unit[2]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[1] != d_output_unit[1]) begin
			if(d_output_unit[1]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end else if (maxVal[0] != d_output_unit[0]) begin
			if(d_output_unit[0]) begin
				maxVal <= d_output_unit;
				maxInd <= addr_output_unit; 
			end
		end
	end
	
end

//////////////////////////////////////
/////////// ASSIGN OUTPUTS ///////////
//////////////////////////////////////

assign digit = (doneFlag) ? maxInd : digit;

assign done = (doneFlag) ? 1'b1 : 1'b0; 

assign q_ext = (q_input) ? 8'h7F : 8'h0; 		//Extend 1-bit q_input to 8-bit to make it either 0 (8’b00000000) or 127 (8’b01111111)
assign d_hidden_unit = q_lut;
assign d_output_unit = q_lut;

assign in1 = (macIn1Sel) ? q_hidden_unit : q_ext; 				//(M1): ram_hidden_unit OR q_input(ext)
assign in2 = (macIn2Sel) ? q_weight_output : q_weight_hidden; 	//(M2): rom_output_weight OR rom_hidden_weight

always_ff @(posedge clk, negedge rst_n) begin //FSM sequential logic
	if (!rst_n)
		digit <= 4'b0;
	else if (doneFlag)
		digit <= maxInd
end

/////////////////////////////////////////////
//////////////// CONTROL FSM ////////////////
/////////////////////////////////////////////

always_ff @(posedge clk, negedge rst_n) begin //FSM sequential logic
	if (!rst_n)
		cur_state <= IDLE; 
	else
		cur_state <= nxt_state;
end

always_comb begin
	//default all output variables
	cnt_input_clr = 1'b0; 
	cnt_hidden_clr = 1'b0; 
	cnt_output_clr = 1'b0;
	cnt_output_inc = 1'b0;
	cnt_input_inc = 1'b0;
	cnt_hidden_inc = 1'b0;
	
	mac_clr = 1'b0; 
	doneFlag = 1'b0; 
	
	addr_input_unit_inc = 1'b0;
	addr_input_unit_clr = 1'b0;
	
	addr_hidden_weight_clr = 1'b0;
	
	addr_hidden_unit_inc = 1'b0;
	addr_hidden_unit_clr = 1'b0;
	
	addr_output_weight_clr = 1'b0;
	
	addr_output_unit_inc = 1'b0;
	addr_output_unit_clr = 1'b0;
	
	macIn1Sel = 1'b0; 
	macIn2Sel = 1'b0;
	
	we_ram_hidden_unit = 1'b0;
	
	compare = 1'b0;
	
	maxVal_MaxInd_clr = 1'b0; 
	
	case (cur_state) 
	IDLE : begin
		
		mac_clr = 1'b1; 
		cnt_input_clr = 1'b1;
		cnt_output_clr = 1'b1;
		cnt_hidden_clr = 1'b1;
		addr_input_unit_clr = 1'b1;
		addr_hidden_weight_clr = 1'b1;
		addr_hidden_unit_clr = 1'b1;
		addr_output_weight_clr = 1'b1;
		addr_output_unit_clr = 1'b1;
		maxVal_MaxInd_clr = 1'b1; 
		
		if (start) begin
			nxt_state = MAC_HIDDEN; 
		end else
			nxt_state = IDLE; 
	end
	
	MAC_HIDDEN : begin
		//Check for both inputs to be received	
		if (cnt_input != 12'h30F) begin //If we haven't counted to 784, stay here
			cnt_input_inc = 1'b1;
			addr_input_unit_inc = 1'b1;
			nxt_state = MAC_HIDDEN;
		end
		else begin
			nxt_state = MAC_HIDDEN_BP1; 
		end
	end
	
	MAC_HIDDEN_BP1 : begin //Take time to do the calculation
		nxt_state = MAC_HIDDEN_BP2; 
	end
	
	MAC_HIDDEN_BP2 : begin //Take time to do yield the output
		mac_clr = 1'b1; 
		nxt_state = MAC_HIDDEN_WRITE; 
	end
	
	MAC_HIDDEN_WRITE : begin
		//Set the inputs to the MAC 		
		we_ram_hidden_unit = 1'b1; //Write to ram_hidden_unit
		addr_input_unit_clr = 1'b1;
		cnt_hidden_inc = 1'b1;
		addr_hidden_unit_inc = 1'b1;
		if (cnt_hidden != 5'h1f) begin //Haven't finished all 32 nodes
			cnt_input_clr = 1'b1; 
			nxt_state = MAC_HIDDEN;
		end	
		else begin
			cnt_hidden_clr = 1'b1;
			macIn1Sel = 1'b1;
			macIn2Sel = 1'b1;
			addr_hidden_unit_clr = 1'b1;  // start at the begining of the ram
			cnt_output_clr = 1'b1;
			mac_clr = 1'b1;
			nxt_state = MAC_OUTPUT;
		end
	end
	
	MAC_OUTPUT : begin
		macIn1Sel = 1'b1;
		macIn2Sel = 1'b1;
		if (cnt_hidden != 5'h1f) begin
			addr_hidden_unit_inc = 1'b1;
			cnt_hidden_inc = 1'b1;
			nxt_state = MAC_OUTPUT;
		end
		else begin
			nxt_state = MAC_OUTPUT_BP1;
		end
	end
	
	MAC_OUTPUT_BP1 : begin
		macIn1Sel = 1'b1;
		macIn2Sel = 1'b1;
		nxt_state = MAC_OUTPUT_BP2; 
	end
	
	MAC_OUTPUT_BP2 : begin
		macIn1Sel = 1'b1;
		macIn2Sel = 1'b1;
		compare = 1'b1;
		addr_output_unit_inc = 1'b1;
		cnt_output_inc = 1'b1;
		nxt_state = MAC_OUTPUT_WRITE; 
	end
	
	MAC_OUTPUT_WRITE : begin
		macIn1Sel = 1'b1;
		macIn2Sel = 1'b1; 	
		if (cnt_output != 6'h09) begin
			cnt_hidden_clr = 1'b1;
			mac_clr = 1'b1;
			addr_hidden_unit_clr = 1'b1;		
			nxt_state = MAC_OUTPUT;
		end
		else begin 
			nxt_state = DONE; 
		end
	end
	
	DONE : begin
		doneFlag = 1'b1; 
		nxt_state = IDLE;  
	end

	default : begin //If we go out of bounds
		nxt_state = IDLE; 
	end
	
	endcase	
end

endmodule