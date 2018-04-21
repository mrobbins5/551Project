//Signed 8-bit MAC module

module mac(acc, a, b, clr_n, clk, rst_n);  //Declare all inputs and outputs of the Multiply Accumulator module

//a and b are the 8bit inputs that will be accumulated with outputs previous value
input signed [7:0] a; 
input signed [7:0] b; 
input clr_n, clk, rst_n; 

output logic signed[25:0] acc; //The output is larger due to multiplication

logic [25:0] acc_nxt, add, mult, testACC, testMULT, testSUM;  //Internal wires used to combine and calculate into outputs

//Registers -> Behavioral


//asynchronous flipflop to implement the transition logic
always_ff @(posedge clk, negedge rst_n) begin

	//Bottom register
	if(!rst_n) begin
		acc <= 26'h0000000;
	
	end 
	else begin
		acc <= acc_nxt;	
	end
	
end

//Datapath -> Dataflow

//Sign extend the first bit of multiplier
assign testMULT = {mult[15], mult[15:0]};

//Sign extend the first bit of accumulator
assign testACC = {acc[25], acc[25:0]};

//Sum and compare
assign testSUM = testMULT + testACC; //
assign acc_nxt = (clr_n) ? (mult + acc) : 26'h0000000;   //Sets the next value of transition (If not reset) to be equalt to mult+acc 
assign mult = a*b; 
		

endmodule

