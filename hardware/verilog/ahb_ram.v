// Example code for an AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing a RAM
// Since this loads a program it is for FPGA use only
//
// Number of addressable locations : 2**MEMWIDTH
// Size of each addressable location : 8 bits
// Supported transfer sizes : Word, Halfword, Byte
// Alignment of base address : Word aligned
//

// Memory is synchronous which should suit block memory types
// Read and Write addresses are separate
//   (this supported by many FPGA block memories)
//

// This model is for Altera (Intel) FPGAs only
//   The RAM model has three dimensions
//   * This is the advised technique for byte access in Altera FPGAs
//   * This is not currently supported for block RAM in Xilinx FPGAs
//

`ifdef PROG_FILE
  // already defined - do nothing
`else
  `define PROG_FILE  "code.hex"
`endif

`timescale 1ns / 100ps

module ahb_ram #(
  parameter MEMWIDTH = 14
)(
  //AHBLITE INTERFACE

    //Slave Select Signal
    input HSEL,
    //Global Signals
    input HCLK,
    input HRESETn,
    //Address, Control & Write Data
    input HREADY,
    input [31:0] HADDR,
    input [1:0] HTRANS,
    input HWRITE,
    input [2:0] HSIZE,
    input [31:0] HWDATA,
    // Transfer Response & Read Data
    output HREADYOUT,
    output [31:0] HRDATA

);


  localparam No_Transfer = 2'b0;

// Memory Array  
  reg [3:0][7:0] memory[0:(2**(MEMWIDTH-2)-1)];
  reg [31:0] data_from_memory;

//control signals are stored in registers
  reg write_enable, read_enable;
  reg [MEMWIDTH-3:0] write_address, read_address, saved_read_address;
  reg [3:0] byte_select;
  

// read program into ram
  initial
    $readmemh( `PROG_FILE, memory, 0, (2**(MEMWIDTH-2)-1));
 
//Generate the control signals and write_address in the address phase
  always @(posedge HCLK or negedge HRESETn)
    if (! HRESETn )
      begin
        write_enable <= 1'b0;
        read_enable <= 1'b0;
        write_address <= {MEMWIDTH-2{1'b0}};
        byte_select <= 4'b0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        read_enable <= ! HWRITE;
        if ( HWRITE ) write_address <= HADDR[MEMWIDTH-1:2];
        byte_select <= generate_byte_select( HSIZE, HADDR[1:0] );
      end
    else
      begin
        write_enable <= 1'b0;
        read_enable <= 1'b0;
        byte_select <= 4'b0;
      end

// read address is calculated a cycle earlier than write address
  always @*
    if ( HREADY && HSEL && (HTRANS != No_Transfer) && ! HWRITE )
      read_address = HADDR[MEMWIDTH-1:2];
    else
      read_address = saved_read_address;

  always @(posedge HCLK or negedge HRESETn)
    if (! HRESETn )
      saved_read_address <= {MEMWIDTH-2{1'b0}};
    else
      saved_read_address <= read_address;
      
//Act on control signals in the data phase

  // This block models the RAM timing
  // Read and write are both synchronous
  // The code uses a standard format to ensure easy synthesis
  //
  // "New Data" Read-During-Write Behaviour:
  //  In this case we use blocking assignments in order to return new data
  //    if read and write addresses match
  //  This avoids a potential read-after-write data hazard
  //
  always @(posedge HCLK)
    begin
      if ( write_enable )
        begin
          if( byte_select[0]) memory[write_address][0] = HWDATA[ 7: 0];
          if( byte_select[1]) memory[write_address][1] = HWDATA[15: 8];
          if( byte_select[2]) memory[write_address][2] = HWDATA[23:16];
          if( byte_select[3]) memory[write_address][3] = HWDATA[31:24];
        end
      data_from_memory = memory[read_address];
    end
    
  //read
  // (output of zero when not enabled for read is not necessary but may help with debugging)
  assign HRDATA[ 7: 0] = ( read_enable && byte_select[0] ) ? data_from_memory[ 7: 0] : 8'b0;
  assign HRDATA[15: 8] = ( read_enable && byte_select[1] ) ? data_from_memory[15: 8] : 8'b0;
  assign HRDATA[23:16] = ( read_enable && byte_select[2] ) ? data_from_memory[23:16] : 8'b0;
  assign HRDATA[31:24] = ( read_enable && byte_select[3] ) ? data_from_memory[31:24] : 8'b0;

//Transfer Response
  assign HREADYOUT = 1'b1; //Single cycle Write & Read. Zero Wait state operations


// decode byte select signals from the size and the lowest two address bits
  function [3:0] generate_byte_select( input [2:0] size, input [1:0] byte_adress );
    reg byte3, byte2, byte1, byte0;
    byte0 = size[1] || ( byte_adress == 0 );
    byte1 = size[1] || ( size[0] && ( byte_adress == 0 ) ) || ( byte_adress == 1 );
    byte2 = size[1] || ( byte_adress == 2 );
    byte3 = size[1] || ( size[0] && ( byte_adress == 2 ) ) || ( byte_adress == 3 );
    return { byte3, byte2, byte1, byte0 };
  endfunction

endmodule
