
module fmc2slaves
  #(
    parameter FMC_AW = 20,
    parameter BRAM_AW = 11,
    parameter DW = 32,
    parameter BRAMS = 16,
    parameter CTL_REGS = 6
    )
  (
   input 		    rst,
   output reg 		    mmu_int,
  
   input 		    fmc_clk,
   input [FMC_AW-1:0] 	    fmc_a,
   inout [DW-1:0] 	    fmc_d,
   input 		    fmc_noe,
   input 		    fmc_nwe,
   input 		    fmc_ne,

   // BRAMS, ctl_regs, memtest BRAM, LEDs
   output [BRAM_AW-1:0]     slave_a,
   output reg [DW-1:0] 	    slave_do,
   input [(BRAMS+3)*DW-1:0] slave_di,
   output reg [BRAMS+2:0]   slave_en,
   output reg [0:0] 	    slave_we
   );

  localparam s_idle=0, s_nop=1, s_w_lat=2, s_w_we=3, s_adr_inc=4;
  reg [2:0] 		    state = s_idle;
  reg 			    write; //read or write

  reg [BRAM_AW-1:0] 	    a_cnt;
  wire [$clog2(BRAMS+3)-1:0] slave_idx;
  reg [DW-1:0] 		     fmc_d_out_reg;

  assign slave_idx = fmc_a[FMC_AW-1 : FMC_AW-$clog2(BRAMS+3)];
  assign fmc_d = (!fmc_ne && !fmc_noe) ? fmc_d_out_reg : 'bz;
  assign slave_a = a_cnt;
  

  always @(posedge fmc_clk) begin // registers for read and write
    fmc_d_out_reg <= slave_di[DW*(slave_idx+1)-1 -: DW];
    slave_do <= fmc_d;
  end
  

  always @(posedge fmc_clk) begin
    if (rst) begin
      state <= s_idle;
      a_cnt <= 0;
      slave_en <= 0;
      slave_we <= 0;
      mmu_int <= 0;
    end else begin
      case (state)
	
	s_idle:
	  if (!fmc_ne) begin
	    a_cnt <= fmc_a[BRAM_AW-1:0];
	    slave_en[slave_idx] <= 1;
	    write <= !fmc_nwe;
	    state <= s_nop;

	    // address check
	    mmu_int <= 0;
	    if (slave_idx >= BRAMS+3)
	      mmu_int <= 1;
	    if (slave_idx == BRAMS && fmc_a[BRAM_AW-1:0] >= CTL_REGS) // ctl_regs
	      mmu_int <= 1;
	    if (slave_idx == BRAMS+2 && fmc_a[BRAM_AW-1:0] != 0) // LEDs
	      mmu_int <= 1;
	  end

	s_nop: state <= write ? s_w_lat : s_adr_inc;

	s_w_lat: state <= s_w_we; // compensate for fmc_d registering

	s_w_we: begin
	  slave_we <= 1;
	  state <= s_adr_inc;
	end

	s_adr_inc: begin
	  a_cnt <= a_cnt + 1;
	  if (fmc_ne) begin
	    state <= s_idle;
	    a_cnt <= 0;
	    slave_en <= 0;
	    slave_we <= 0;
	  end
	end

	default: state <= s_idle;
	
      endcase
    end   
  end // always @ (posedge fmc_clk)
  
endmodule

