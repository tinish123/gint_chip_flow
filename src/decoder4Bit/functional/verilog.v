

///////////////////////////////////////////////////////////////////////////////////4-BIT INPUT DECODER FOR BP_MUX_SEL SELECTION DURING BP_MUX_TEST MODE/////////////////////////////////////////////////////////////////////////////////////////////////
module decoder4Bit(input wire mode,
  input wire [3:0] decIn,
  output reg [15:0] decOut);

  always @(*)
	begin
	if (mode==1'b1) begin
        case (decIn)
        4'b0000 : decOut <= 16'h0001;
        4'b0001 : decOut <= 16'h0002;
        4'b0010 : decOut <= 16'h0004;
        4'b0011 : decOut <= 16'h0008;
        4'b0100 : decOut <= 16'h0010;
        4'b0101 : decOut <= 16'h0020;
        4'b0110 : decOut <= 16'h0040;
        4'b0111 : decOut <= 16'h0080;
        4'b1000 : decOut <= 16'h0100;
        4'b1001 : decOut <= 16'h0200;
        4'b1010 : decOut <= 16'h0400;
        4'b1011 : decOut <= 16'h0800;
        4'b1100 : decOut <= 16'h1000;
        4'b1101 : decOut <= 16'h2000;
        4'b1110 : decOut <= 16'h4000;
        4'b1111 : decOut <= 16'h8000;
        default: decOut <= 0;
        endcase
    end else begin
        decOut <= 0;
    end
end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

