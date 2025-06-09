#define __MAIN_C__

#include <stdint.h>
#include <stdbool.h>

// Define the raw base address values for the i/o devices

#define AHB_IPORT_BASE                          0x40000000
#define AHB_OPORT_BASE                          0x50000000
#define AHB_UART_BASE                           0x60000000

// Define pointers with correct type for access to 32-bit i/o devices
//
// The locations in the devices can then be accessed as:
//    IPORT_REGS[0]
//    OPORT_REGS[0]
//
volatile uint32_t* IPORT_REGS = (volatile uint32_t*) AHB_IPORT_BASE;
volatile uint32_t* OPORT_REGS = (volatile uint32_t*) AHB_OPORT_BASE;
volatile uint32_t* UART_REGS  = (volatile uint32_t*) AHB_UART_BASE;

//////////////////////////////////////////////////////////////////
// Functions provided to access i/o devices
//////////////////////////////////////////////////////////////////

void write_out(uint32_t value) {

  OPORT_REGS[0] = value;

}

uint32_t read_out(void) {

  return OPORT_REGS[0];

}

uint32_t read_switches(void) {

  return IPORT_REGS[0];

}

void uart_send(uint8_t c) {
  while ((UART_REGS[1] & 0x1) == 0) {}
  UART_REGS[0] = c;
}

//////////////////////////////////////////////////////////////////
// Other Functions
//////////////////////////////////////////////////////////////////

int factorial(int value) {

  if ( value == 0 ) return 1;
  else return ( value * factorial(value - 1) );

}

//////////////////////////////////////////////////////////////////
// Main Function
//////////////////////////////////////////////////////////////////

int main(void) {

  int switch_temp = -1;

  write_out( 0x55555555 );

  // wait for all the switches to go to zero
  while( read_switches() != 0x0000 ){}

  write_out( read_out() << 1 );

  // wait for the least significant switch to go to 1
  while( ( read_switches() & 0x0001 ) != 0x0001 ){}

  write_out( read_out() >> 1 );

  // repeat forever (embedded programs generally do not terminate)
  while(1){

    // wait for the switches to change
    while( read_switches() == (uint32_t) switch_temp  ){}

    switch_temp = read_switches();
    if ( switch_temp < 8 ) {
      // if the switch value < 8 return the factorial
      write_out( factorial(switch_temp) );
    } else {
      // otherwise flag an error
      write_out( -1 );
    }
  }

}
