`timescale 1ns / 100ps

module ahb_uart #(
  parameter CLOCK_FREQ = 50000000,
  parameter BAUD_RATE  = 115200
)(
  // AHB Lite Interface
  input        HCLK,
  input        HRESETn,
  input [31:0] HADDR,
  input [31:0] HWDATA,
  input [2:0]  HSIZE,
  input [1:0]  HTRANS,
  input        HWRITE,
  input        HREADY,
  input        HSEL,
  output reg [31:0] HRDATA,
  output       HREADYOUT,

  // UART pins
  input  uart_rx,
  output uart_tx
);

  localparam No_Transfer = 2'b0;

  // registers are word aligned so just use HADDR[3:2]
  reg write_enable, read_enable;
  reg [1:0] addr_reg;

  always @(posedge HCLK or negedge HRESETn)
    if (!HRESETn) begin
      write_enable <= 0;
      read_enable  <= 0;
      addr_reg     <= 0;
    end else if (HREADY && HSEL && (HTRANS != No_Transfer)) begin
      write_enable <= HWRITE;
      read_enable  <= ~HWRITE;
      addr_reg     <= HADDR[3:2];
    end else begin
      write_enable <= 0;
      read_enable  <= 0;
    end

  // addresses
  localparam ADDR_DATA   = 2'b00; // offset 0
  localparam ADDR_STATUS = 2'b01; // offset 4

  // uart instance
  reg        tx_valid;
  reg [7:0]  tx_data;
  wire       tx_ready;

  wire [7:0] rx_data;
  wire       rx_valid;
  reg        rx_ready;

  uart #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_i (
    .clk(HCLK),
    .resetn(HRESETn),
    .rx(uart_rx),
    .tx(uart_tx),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready)
  );

  // drive UART control signals
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      tx_valid <= 0;
      tx_data  <= 0;
      rx_ready <= 0;
    end else begin
      tx_valid <= 0;
      rx_ready <= 0;
      if (write_enable && addr_reg == ADDR_DATA) begin
        tx_data  <= HWDATA[7:0];
        tx_valid <= 1;
      end
      if (read_enable && addr_reg == ADDR_DATA)
        rx_ready <= 1; // acknowledge read of rx byte
    end
  end

  // return read data
  always @* begin
    case (addr_reg)
      ADDR_DATA:   HRDATA = {24'b0, rx_data};
      ADDR_STATUS: HRDATA = {30'b0, rx_valid, tx_ready};
      default:     HRDATA = 32'b0;
    endcase
  end

  // this simple slave is always ready in a single cycle
  assign HREADYOUT = 1'b1;

endmodule

