// #################################################################################################
// # << NEORV32 - Blinking LED Demo Program >>                                                     #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
// #                                                                                               #
// # Redistribution and use in source and binary forms, with or without modification, are          #
// # permitted provided that the following conditions are met:                                     #
// #                                                                                               #
// # 1. Redistributions of source code must retain the above copyright notice, this list of        #
// #    conditions and the following disclaimer.                                                   #
// #                                                                                               #
// # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
// #    conditions and the following disclaimer in the documentation and/or other materials        #
// #    provided with the distribution.                                                            #
// #                                                                                               #
// # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
// #    endorse or promote products derived from this software without specific prior written      #
// #    permission.                                                                                #
// #                                                                                               #
// # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
// # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
// # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
// # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
// # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
// # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
// # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
// # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
// # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
// # ********************************************************************************************* #
// # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
// #################################################################################################


/**********************************************************************//**
 * @file blink_led/main.c
 * @author Stephan Nolting
 * @brief Simple blinking LED demo program using the lowest 8 bits of the GPIO.output port.
 **************************************************************************/

#include <neorv32.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/** Use the custom ASM version for blinking the LEDs defined (= uncommented) */
//#define USE_ASM_VERSION
/**@}*/

/************************************************************************//**
 * Global variables:
 * *************************************************************************/
  uint64_t Button_value;


/**********************************************************************//**
 * C function to blink LEDs
 **************************************************************************/
void Selection_led_mode_c(void);


/**********************************************************************//**
 * Main function; shows an incrementing 8-bit counter on GPIO.output(7:0).
 *
 * @note This program requires the GPIO controller to be synthesized (the UART is optional).
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {

  // init UART (primary UART = UART0; if no id number is specified the primary UART is used) at default baud rate, no parity bits, ho hw flow control
  neorv32_uart0_setup(BAUD_RATE, PARITY_NONE, FLOW_CONTROL_NONE);

  // check if GPIO unit is implemented at all
  if (neorv32_gpio_available() == 0) {
    neorv32_uart0_print("Error! No GPIO unit synthesized!\n");
    return 1; // nope, no GPIO unit synthesized
  }

  // capture all exceptions and give debug info via UART
  // this is not required, but keeps us safe
  neorv32_rte_setup();

  // Indicate to the user that the program is running
  neorv32_uart0_print("Running Practica1_mod program\n\n");
  neorv32_uart0_print("Pulse un boton para reproducir una secuencia:\n");
  neorv32_uart0_print("\t1. Contador\n");
  neorv32_uart0_print("\t2. Intermitente 1\n");
  neorv32_uart0_print("\t3. Intermitente 2\n");

  Selection_led_mode_c();

  return 0;
}

/**********************************************************************//**
 * Led mode fuction
 **************************************************************************/
void Selection_led_mode_c(void) {
  uint8_t time = 0;

  neorv32_gpio_port_set(0x20); // Asynchronous Reset
  neorv32_cpu_delay_ms(10); // wait 500ms using busy wait
  neorv32_gpio_port_set(0); // clear gpio output
  
  while (1) {


   switch(Button_value){
    case 0:
    	// Read the values of the buttons
   	Button_value = neorv32_gpio_port_get();
    	time = 0;
    break;

    case 1://Mode 1: contador...
      neorv32_gpio_port_set(time & 0x1F); // increment counter and mask for lowest 8 bit
      time++;
    break;    
    ubiub
    case 2://Mode 2: Itermitente 1
      //Intermitente según si la variable time es par o impar
      if((time & 0x01)) neorv32_gpio_port_set(0x0F);
      else neorv32_gpio_port_set(0x10);
      time++;
    break;
    
    case 3://Mode 3: Intermitnte 2
      //Intermitente según si la variable time es par o impar
      if((time & 0x01)) neorv32_gpio_port_set(0x1C);
      else neorv32_gpio_port_set(0x13);
      time++;
    break;
  
   }
    neorv32_cpu_delay_ms(200); // wait 500ms using busy wait

    if (time > 30){ //After 6 seconds in a mode...
      neorv32_gpio_port_set(0x20); // Asynchronous Reset 
      neorv32_uart0_print("\nReset activado");
      neorv32_cpu_delay_ms(10); // wait 500ms using busy wait
      neorv32_gpio_port_set(0); // clear gpio output
      time = 0;
      Button_value = 0;
    }
  }
}
