`timescale 1ns/1ns

module fmc2bram_tb;

  parameter FMC_AW = 20;
  parameter BRAM_AW = 12;
  parameter DW = 32;
  parameter BRAMS = 8+1;
  parameter FMC_AW_UNUSED_BITS = FMC_AW-BRAM_AW-$clog2(BRAMS);
  parameter FMC_READ_LAT = 1;

  /*AUTOREGINPUT*/
  // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
  reg [BRAMS*DW-1:0]	bram_di;		// To uut of fmc2bram.v
  reg [FMC_AW-1:0] 	fmc_a;			// To uut of fmc2bram.v
  reg			fmc_clk;		// To uut of fmc2bram.v
  reg			fmc_ne;			// To uut of fmc2bram.v
  reg			fmc_noe;		// To uut of fmc2bram.v
  reg			fmc_nwe;		// To uut of fmc2bram.v
  reg			rst;			// To uut of fmc2bram.v
  // End of automatics
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [BRAM_AW-1:0] 	bram_a;			// From uut of fmc2bram.v
  wire [DW-1:0] 	bram_do;		// From uut of fmc2bram.v
  wire [BRAMS-1:0] 	bram_en;		// From uut of fmc2bram.v
  wire [0:0] 		bram_we;		// From uut of fmc2bram.v
  wire [DW-1:0] 	fmc_d;			// To/From uut of fmc2bram.v
  wire			mmu_int;		// From uut of fmc2bram.v
  // End of automatics
  
  wire [BRAMS*DW-1:0] 	bram_di_dly; // race avoidance

  fmc2bram
    #(/*AUTOINSTPARAM*/
      // Parameters
      .FMC_AW				(FMC_AW),
      .BRAM_AW				(BRAM_AW),
      .DW				(DW),
      .BRAMS				(BRAMS))
  uut
    (/*AUTOINST*/
     // Outputs
     .mmu_int				(mmu_int),
     .bram_a				(bram_a[BRAM_AW-1:0]),
     .bram_do				(bram_do[DW-1:0]),
     .bram_en				(bram_en[BRAMS-1:0]),
     .bram_we				(bram_we[0:0]),
     // Inouts
     .fmc_d				(fmc_d[DW-1:0]),
     // Inputs
     .rst				(rst),
     .fmc_clk				(fmc_clk),
     .fmc_a				(fmc_a[FMC_AW-1:0]),
     .fmc_noe				(fmc_noe),
     .fmc_nwe				(fmc_nwe),
     .fmc_ne				(fmc_ne),
     .bram_di				(bram_di_dly));

  
  // Data
  
class TxType;
  rand bit [$clog2(BRAMS)-1:0] bram_idx;
  rand bit [BRAM_AW-1:0] addr;
  int 			len;
  rand bit [DW-1:0] data[];

  constraint data_size {data.size() == len;}
  constraint c_idx {bram_idx < BRAMS;}

  function new(input int l);
    len = l;
  endfunction
endclass // TxType

  bit [DW-1:0] 		bram_array [BRAMS][bit [BRAM_AW-1:0]];
  logic [DW-1:0] 	fmc_d_int;
  bit [7:0] 		bram_en_sum;
  
  
  // Tasks
  
  function void init();
    rst = 0;
    fmc_clk = 0;
    fmc_ne = 1;
    fmc_noe = 1;
    fmc_nwe = 1;  
  endfunction // init

  
  task reset();
    @(negedge fmc_clk) rst = 1;
    @(negedge fmc_clk) rst = 0;
    rst_check: assert (bram_en == 0 && bram_we == 0);
  endtask
  
  
  task tx_read(input TxType tx);
    @(negedge fmc_clk);
    fmc_ne = 0;
    fmc_a = {tx.bram_idx, FMC_AW_UNUSED_BITS'(0), tx.addr};
    
    repeat(2) @(negedge fmc_clk);
    fmc_noe = 0;
    
    repeat(1 + FMC_READ_LAT) @(posedge fmc_clk);
    for (int i=0; i<tx.len; i++) begin
      @(posedge fmc_clk);
      $display("READ: A:%d,%h D:%h", tx.bram_idx, tx.addr+i, fmc_d);
      read_check: assert (fmc_d == bram_array[tx.bram_idx][tx.addr+i]);
    end
    
    @(posedge fmc_clk); #1;
    fmc_ne = 1;
    fmc_noe = 1;
  endtask // tx_read

  
  task tx_write(input TxType tx);
    @(negedge fmc_clk);
    fmc_ne = 0;
    fmc_nwe = 0;
    fmc_a = {tx.bram_idx, FMC_AW_UNUSED_BITS'(0), tx.addr};
    
    repeat(2) @(negedge fmc_clk);
    for (int i=0; i<tx.len; i++) begin
      @(negedge fmc_clk);
      fmc_d_int = tx.data[i];
      $display("WRITE: A:%d,%h D:%h", tx.bram_idx, tx.addr+i, tx.data[i]);
    end

    @(posedge fmc_clk); #1;
    fmc_ne = 1;
    fmc_nwe = 1;
  endtask // tx_write

  
  
  // Env model

  always #5 fmc_clk = ~fmc_clk;

  always_ff @(posedge fmc_clk) // bram model
    foreach (bram_en[i])
      if (bram_en[i])
	if (bram_we)
	  bram_array[i][bram_a] = bram_do;
	else
	  bram_di[DW*(i+1)-1 -: DW] = bram_array[i][bram_a];
  
  assign #1 bram_di_dly = bram_di;

  assign fmc_d = (!fmc_ne && !fmc_nwe) ? fmc_d_int : 'bz;

  always_comb begin
    bram_en_sum = 0;
    foreach (bram_en[i]) bram_en_sum += bram_en[i];
  end

  
  // Assertions

  assert property (@(posedge fmc_clk) bram_en_sum <= 1);

  
  
  // Main
  
  initial begin
    TxType tx;
    
    $dumpfile("dump.vcd");
    $dumpvars;
    
    tx = new(4);
    
    init();
    reset();
    
    repeat(5) begin
      tx.randomize();
      tx_write(tx);
      repeat(2) @(posedge fmc_clk);
      tx_read(tx);
      repeat(2) @(posedge fmc_clk);
    end
    
    #10 $finish;
  end // initial begin

  
endmodule
