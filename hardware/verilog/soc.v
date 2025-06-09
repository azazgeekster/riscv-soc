// Example code for a PicoRV32 AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
//
// This version supports 3 AHBLite slaves:
//
//  ahb_ram           RAM
//  ahb_input_port    Non-specific Input Port
//  ahb_output_port   Non-specific Output Port
//

`timescale 1ns / 100ps

module soc(

  input HCLK, HRESETn,
  
  input [31:0] iPort, 

  output [31:0] oPort,
  output LOCKUP

);
 

  // Global & Master AHB Signals
  wire [31:0] HADDR, HWDATA, HRDATA;
  wire [1:0] HTRANS;
  wire [2:0] HSIZE, HBURST;
  wire [3:0] HPROT;
  wire HWRITE, HMASTLOCK, HRESP, HREADY;

  // Per-Slave AHB Signals
  wire HSEL_RAM, HSEL_IPORT, HSEL_OPORT;
  wire [31:0] HRDATA_RAM, HRDATA_IPORT, HRDATA_OPORT;
  wire HREADYOUT_RAM, HREADYOUT_IPORT, HREADYOUT_OPORT;

  // Set this to zero because PicoRV32 does not support LOCKUP
  assign LOCKUP = 1'b0;

  // Set this to zero because simple slaves do not generate errors
  assign HRESP = 1'b0;

  // PicoRV32 is AHB Master
  picorv32_ahb riscv_1 (

    // AHB Signals
    .HCLK, .HRESETn,
    .HADDR, .HBURST, .HMASTLOCK, .HPROT, .HSIZE, .HTRANS, .HWDATA, .HWRITE,
    .HRDATA, .HREADY, .HRESP

  );


  // AHB interconnect including address decoder, register and multiplexer
  ahb_interconnect interconnect_1 (

    .HCLK, .HRESETn, .HADDR, .HRDATA, .HREADY,

    .HSEL_SIGNALS({HSEL_OPORT,HSEL_IPORT,HSEL_RAM}),
    .HRDATA_SIGNALS({HRDATA_OPORT,HRDATA_IPORT,HRDATA_RAM}),
    .HREADYOUT_SIGNALS({HREADYOUT_OPORT,HREADYOUT_IPORT,HREADYOUT_RAM})

  );


  // AHBLite Slaves
        
  ahb_ram ram_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_RAM),
    .HRDATA(HRDATA_RAM), .HREADYOUT(HREADYOUT_RAM)

  );

  ahb_input_port in_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_IPORT),
    .HRDATA(HRDATA_IPORT), .HREADYOUT(HREADYOUT_IPORT),

    .iPort(iPort)

  );

  ahb_output_port out_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_OPORT),
    .HRDATA(HRDATA_OPORT), .HREADYOUT(HREADYOUT_OPORT),

    .oPort(oPort)

  );

  //-------------------------
  // Assertions which should be valid for all systems:
  //

  // Assertions removed for Verilog-2001 compatibility


endmodule
