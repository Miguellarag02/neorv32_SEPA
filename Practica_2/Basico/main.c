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
uint8_t Lee_teclado(void);


/**********************************************************************//**
 * Main function; shows an incrementing 8-bit counter on GPIO.output(7:0).
 *
 * @note This program requires the GPIO controller to be synthesized (the UART is optional).
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {
  uint8_t Key_value = 0; 
  uint8_t q_key_value = 0;

  // init UART (primary UART = UART0; if no id number is specified the primary UART is used) at default baud rate, no parity bits, ho hw flow control
  neorv32_uart0_setup(BAUD_RATE, PARITY_NONE, FLOW_CONTROL_NONE);

  // check if GPIO unit is implemented at all
  if (neorv32_gpio_available() == 0) {
    neorv32_uart0_print("Error! No GPIO unit synthesized!\n");
    return 1; // nope, no GPIO unit synthesized
  }
  neorv32_rte_setup();

  while(1){
    Key_value = Lee_teclado();

    if(Key_value != 0xFF){
      if(Key_value != q_key_value){
        neorv32_uart0_print("\nSe ha pulsado la tecla: ");
        if(Key_value < 10) neorv32_uart0_printf("%u",Key_value);
        else neorv32_uart0_printf("%c",Key_value);
        q_key_value = Key_value;
      }
    }
  }
  return 0;
}

uint8_t Lee_teclado(void){
  uint32_t Key_value = 0;
  uint8_t Caracter = 0xFF;
  
  Key_value = neorv32_gpio_port_get();
  Key_value = (Key_value >> 4);

  if (Key_value & 0x0008) Caracter = 1;
  else if (Key_value & 0x8000) Caracter = 2;
  else if (Key_value & 0x0800) Caracter = 3;
  else if (Key_value & 0x0080) Caracter = 65;
  else if (Key_value & 0x0004) Caracter = 4;
  else if (Key_value & 0x4000) Caracter = 5;
  else if (Key_value & 0x0400) Caracter = 6;
  else if (Key_value & 0x0040) Caracter = 66;
  else if (Key_value & 0x0002) Caracter = 7;
  else if (Key_value & 0x2000) Caracter = 8;
  else if (Key_value & 0x0200) Caracter = 9;
  else if (Key_value & 0x0020) Caracter = 67;
  else if (Key_value & 0x0001) Caracter = 0;
  else if (Key_value & 0x1000) Caracter = 70;
  else if (Key_value & 0x0100) Caracter = 69;
  else if (Key_value & 0x0010) Caracter = 68;
  else Caracter = 0xFF;
  return Caracter;
};
