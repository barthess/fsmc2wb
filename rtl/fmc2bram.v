
module fmc2bram
  #(
    parameter FMC_AW = 20,
    parameter BRAM_AW = 12,
    parameter DW = 32,
    parameter BRAMS = 8+1, // one line for math control regs
    parameter CTL_REGS = 6
    )
  (
   input 		  rst,
   output reg 		  mmu_int,
  
   input 		  fmc_clk,
   input [FMC_AW-1:0] 	  fmc_a,
   inout [DW-1:0] 	  fmc_d,
   input 		  fmc_noe,
   input 		  fmc_nwe,
   input 		  fmc_ne,

   output [BRAM_AW-1:0]   bram_a,
   output [DW-1:0] 	  bram_do,
   input [BRAMS*DW-1:0]   bram_di,
   output reg [BRAMS-1:0] bram_en,
   output reg [0:0] 	  bram_we
   );

  localparam s_idle=0, s_nop=1, s_w_we=2, s_adr_inc=3;
  reg [1:0] 		  state;
  reg 			  write; //read or write

  reg [BRAM_AW-1:0] 	  a_cnt;
  wire [$clog2(BRAMS)-1:0] bram_idx;

  assign bram_idx = fmc_a[FMC_AW-1 : FMC_AW-$clog2(BRAMS)];
  assign fmc_d = (!fmc_ne && !fmc_noe) ? bram_di[DW*(bram_idx+1)-1 -: DW] : 'bz;
  assign bram_a = a_cnt;
  assign bram_do = fmc_d;


  always @(posedge fmc_clk) begin
    if (rst) begin
      state <= s_idle;
      a_cnt <= 0;
      bram_en <= 0;
      bram_we <= 0;
      mmu_int <= 0;
    end else begin
      case (state)
	
	s_idle:
	  if (!fmc_ne) begin
	    a_cnt <= fmc_a[BRAM_AW-1:0];
	    bram_en[bram_idx] <= 1;
	    write <= !fmc_nwe;
	    state <= s_nop;

	    mmu_int <= 0;
	    if (bram_idx >= BRAMS)
	      mmu_int <= 1;
	    if (bram_idx == BRAMS-1 && fmc_a[BRAM_AW-1:0] >= CTL_REGS)
	      mmu_int <= 1;
	  end

	s_nop: state <= write ? s_w_we : s_adr_inc;

	s_w_we: begin
	  bram_we <= 1;
	  state <= s_adr_inc;
	end

	s_adr_inc: begin
	  a_cnt <= a_cnt + 1;
	  if (fmc_ne) begin
	    state <= s_idle;
	    a_cnt <= 0;
	    bram_en <= 0;
	    bram_we <= 0;
	  end
	end
      endcase
    end   
  end // always @ (posedge fmc_clk)
  
endmodule

