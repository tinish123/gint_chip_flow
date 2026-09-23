module prng_tb;

localparam [288:0] seed = 288'hb0d13043e49ea30ac56abacc9710ddabdade245bb60a8021947a86bc224153b7fa001443;

reg clk;
always #5 clk = ~clk;
reg rst;
reg seed_shift_in;
reg seed_shift_en;
reg rng_en;
wire [255:0] rands;

// used to loop through timesteps while seeding
integer i;

prng_top dut (
  .clk(clk), .rng_en(rng_en), .rands(rands), .rst(rst),
  .seed_shift_en(seed_shift_en),
  .seed_shift_in(seed_shift_in)
);

initial begin
  clk = 0;
  rst = 0;
  rng_en=0;
  seed_shift_en = 0;
  seed_shift_in = 0;
  #4;
  seed_shift_en = 1;
  for (i=0;i<288;i=i+1) begin
    seed_shift_in = seed[i];
    $display("Pushing seed bit %i.\n", i);
    #10;
  end
  seed_shift_en = 0;
  #6;
  $display("Begin RNG\n");
  @(negedge clk);
  rst = 1;
  rng_en = 1;
  @(negedge clk);
  rst = 0;
  #100_000;
  $display("RNG time completed sucessfully!\n\n");
  $finish;
end

initial begin
  $dumpfile("prng_tb.dump");
  $dumpvars(0, prng_tb);
end


endmodule
