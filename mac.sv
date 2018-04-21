//Signed 8-bit MAC module

module mac(acc, in1, in2, clr, clk, rst_n);  //Declare all inputs and outputs of the Multiply Accumulator module

//a and b are the 8bit inputs that will be accumulated with outputs previous value
input signed [7:0] in1; 
input signed [7:0] in2; 
input clr, clk, rst_n; 

output logic signed [25:0] acc; //The output is larger due to multiplication

logic signed [25:0] acc_nxt, add, mult_ext;  //Internal wires used to combine and calculate into outputs
logic signed [15:0] mult; 


//asynchronous flipflop to implement the transition logic
always_ff @(posedge clk, negedge rst_n) begin

	//Bottom register
	if(!rst_n)
		acc <= 26'h0;
	else
		acc <= acc_nxt;	
end

assign mult_ext = {{10{mult[15]}}, mult[15:0]};

assign acc_nxt = (clr) ? (mult_ext + acc) : 26'b0;   //Sets the next value of transition (If not reset) to be equalt to mult+acc 
assign mult = in1*in2; 
		

endmodule

