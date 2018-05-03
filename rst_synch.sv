module rst_synch(rst_n,RST_n,clk);

input RST_n, clk;
output rst_n;
logic rst_n;

logic temp;
always_ff@(negedge clk, negedge RST_n) begin

if(!RST_n) begin
  temp <= 1'b0;
end else begin
  temp <= 1'b1;
end

end

always_ff@(negedge clk, negedge RST_n) begin

if(!RST_n) begin
  rst_n <= 1'b0;
end else begin
  rst_n <= temp;
end

end



endmodule
