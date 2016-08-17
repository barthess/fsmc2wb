
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
   output reg [DW-1:0] 	  bram_do,
   input [BRAMS*DW-1:0]   bram_di,
   output reg [BRAMS-1:0] bram_en,
   output reg [0:0] 	  bram_we
   );

  localparam s_idle=0, s_nop=1, s_w_lat=2, s_w_we=3, s_adr_inc=4;
  reg [2:0] 		  state = s_idle;
  reg 			  write; //read or write

  reg [BRAM_AW-1:0] 	  a_cnt;
  wire [$clog2(BRAMS)-1:0] bram_idx;
  reg [DW-1:0] 		   fmc_d_out_reg;

  assign bram_idx = fmc_a[FMC_AW-1 : FMC_AW-$clog2(BRAMS)];
  assign fmc_d = (!fmc_ne && !fmc_noe) ? fmc_d_out_reg : 'bz;
  assign bram_a = a_cnt;
  

  always @(posedge fmc_clk) begin // registers for read and write
    fmc_d_out_reg <= bram_di[DW*(bram_idx+1)-1 -: DW];
    bram_do <= fmc_d;
  end
  

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

	s_nop: state <= write ? s_w_lat : s_adr_inc;

	s_w_lat: state <= s_w_we; // compensate for fmc_d registering

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

	default: state <= s_idle;
	
      endcase
    end   
  end // always @ (posedge fmc_clk)
  
endmodule

