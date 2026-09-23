module prng_top(
  input wire clk,
  input wire rst,
  input wire seed_shift_in,
  input wire seed_shift_en,
  input wire rng_en,
  output wire [255:0] rands
);
reg [31:0] seed_x;
reg [255:0] seed_y;

always @(posedge clk) begin
  if (seed_shift_en) begin
    seed_x <= {seed_shift_in, seed_x[31:1]};
    seed_y <= {seed_x[0], seed_y[255:1]};
  end else begin
    seed_x <= seed_x;
    seed_y <= seed_y;
  end
end

xormix32 #(.streams(8)) prng_core (
  .clk(clk), .rst(rst), .seed_x(seed_x),
  .seed_y(seed_y), .enable(rng_en),
  .result(rands)
);

endmodule
