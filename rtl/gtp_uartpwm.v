module gtp_uartpwm
  #(
    parameter COMMA = 8'hBC //K28.5
    )
  (
   input 	     rst,
   input 	     gtp_txusrclk,
   input 	     gtp_rxusrclk,
   output reg [7:0]  gtp_txdata,
   output reg 	     gtp_txcharisk,
   input [7:0] 	     gtp_rxdata,
   input 	     gtp_rxcharisk,
   input 	     gtp_resetdone,
   input 	     gtp_plllkdet,
   input 	     gtp_rxbyteisaligned,

   input [15:0]      uart_rx,
   input [15:0]      uart_cts,
   output reg [15:0] uart_tx,
   output reg [15:0] uart_rts,

   input [15:0]      pwm_in,
   output reg [15:0] pwm_out
   );

  //PWM x16, UART x16, UART flow control x16
  localparam s_comma=0, s_pwm_lsb=1, s_pwm_msb=2, s_uart_lsb=3, s_uart_msb=4,
    s_uartfc_lsb=5, s_uartfc_msb=6;
  
  reg [2:0] 	     tx_state, rx_state; //in terms of GTP
  reg [15:0] 	     uart_rx_i;
  reg [15:0] 	     uart_cts_i;
  reg [15:0] 	     pwm_in_i;

  always @(posedge gtp_txusrclk) begin //GTP TX
    if (rst) begin
      tx_state <= s_uartfc_msb;
    end
    else begin
      gtp_txcharisk <= 0; //default
      case (tx_state)
	s_comma: begin
	  if (gtp_resetdone && gtp_plllkdet) begin
	    tx_state <= s_pwm_lsb;
	    gtp_txdata <= pwm_in_i[7:0];
	  end
	end
	s_pwm_lsb: begin
	  tx_state <= s_pwm_msb;
	  gtp_txdata <= pwm_in_i[15:8];
	end
	s_pwm_msb: begin
	  tx_state <= s_uart_lsb;
	  gtp_txdata <= uart_rx_i[7:0];
	end
	s_uart_lsb: begin
	  tx_state <= s_uart_msb;
	  gtp_txdata <= uart_rx_i[15:8];	
	end
	s_uart_msb: begin
	  tx_state <= s_uartfc_lsb;
	  gtp_txdata <= uart_cts_i[7:0];	
	end
	s_uartfc_lsb: begin
	  tx_state <= s_uartfc_msb;
	  gtp_txdata <= uart_cts_i[15:8];	
	end
	s_uartfc_msb: begin
	  tx_state <= s_comma;
	  gtp_txdata <= COMMA;
	  gtp_txcharisk <= 1;
	  pwm_in_i <= pwm_in;
	  uart_rx_i <= uart_rx;
	  uart_cts_i <= uart_cts;	
	end
      endcase // case (tx_state)
    end     
  end

  always @(posedge gtp_rxusrclk) begin //GTP RX
    if (rst) begin
      rx_state <= s_comma;
    end
    else begin
      case (rx_state)
	s_comma: begin
	  if (gtp_rxbyteisaligned && gtp_rxcharisk && gtp_rxdata==COMMA)
	    rx_state <= s_pwm_lsb;
	end
	s_pwm_lsb: begin
	  rx_state <= s_pwm_msb;
	  pwm_out[7:0] <= gtp_rxdata;
	end
	s_pwm_msb: begin
	  rx_state <= s_uart_lsb;
	  pwm_out[15:8] <= gtp_rxdata;
	end
	s_uart_lsb: begin
	  rx_state <= s_uart_msb;
	  uart_tx[7:0] <= gtp_rxdata;
	end
	s_uart_msb: begin
	  rx_state <= s_uartfc_lsb;
	  uart_tx[15:8] <= gtp_rxdata;
	end
	s_uartfc_lsb: begin
	  rx_state <= s_uartfc_msb;
	  uart_rts[7:0] <= gtp_rxdata;
	end
	s_uartfc_msb: begin
	  rx_state <= s_comma;
	  uart_rts[15:8] <= gtp_rxdata;     
	end
      endcase // case (rx_state)
    end     
  end

endmodule // gtp_uartpwm
