// Example code for an AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing one read-only locations
//
// Number of addressable locations : 1
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Read Input Port (iPort)
//


`timescale 1ns / 100ps

module ahb_input_port(

  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // AHB Signals from Master to Slave
  input [31:0] HADDR, // With this interface HADDR is ignored
  input [31:0] HWDATA,
  input [2:0] HSIZE,
  input [1:0] HTRANS,
  input HWRITE,
  input HREADY,
  input HSEL,

  // AHB Signals from Slave to Master
  output reg [31:0] HRDATA,
  output HREADYOUT,

  //Non-AHB Signals
  input [31:0] iPort

);


  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  //control signals are stored in registers
  reg read_enable;
 
  //Generate the control signals in the address phase
  always @(posedge HCLK or negedge HRESETn)
    if ( ! HRESETn )
      begin
        read_enable <= 1'b0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        read_enable <= ! HWRITE;
     end
    else
      begin
        read_enable <= 1'b0;
     end

  //Act on control signals in the data phase

  // read
  always @*
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = 32'b0;
    else
      HRDATA = iPort;

  //Transfer Response
  assign HREADYOUT = 1'b1; //Single cycle Write & Read. Zero Wait state operations



endmodule

