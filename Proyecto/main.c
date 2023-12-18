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


/************************************************************************//**
 * DEFINES :
 * *************************************************************************/
#define WB_TECLADO_BASE_ADDRESS 0x90000000
#define WB_TECLADO_REG0_OFFSET 0x00
#define WB_TECLADO_REG1_OFFSET 0x04
#define WB_TECLADO_REG2_OFFSET 0x08
#define WB_TECLADO_REG3_OFFSET 0x0C
#define WB_TECLADO_REG4_OFFSET 0x10

#define WB_DISPLAY_BASE_ADDRESS 0x90000020 
#define WB_DISPLAY_REG0_OFFSET 0x00
#define WB_DISPLAY_REG1_OFFSET 0x04
#define WB_DISPLAY_REG2_OFFSET 0x08


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
  uint8_t KeyValue[16] = {  0 ,  7 ,  4 ,  1,
                           68 , 67 , 66 , 65,
                           69 ,  9 ,  6 ,  3,
                           70 ,  8 ,  5 ,  2 };



/**********************************************************************//**
 * ASM function to blink LEDs
 **************************************************************************/
extern void blink_led_asm(uint32_t gpio_out_addr);

/**********************************************************************//**
 * C function to read the Keypad
 **************************************************************************/
uint8_t Lee_teclado(void);


int main() {

  // init UART (primary UART = UART0; if no id number is specified the primary UART is used) at default baud rate, no parity bits, ho hw flow control
  neorv32_uart0_setup(BAUD_RATE, PARITY_NONE, FLOW_CONTROL_NONE);


  // check if GPIO unit is implemented at all
  if (neorv32_gpio_available() == 0) {
    neorv32_uart0_print("Error! No GPIO unit synthesized!\n");
    return 1; // nope, no GPIO unit synthesized
  }

  neorv32_rte_setup();

  neorv32_uart0_print("Program iniciated\n");

  uint8_t Key_value = 0xFF; 
  uint8_t q_key_value = 0xFF;

  while(1){
    Key_value = Lee_teclado();
    if(Key_value != 0xFF){
      if(Key_value != q_key_value){
        neorv32_uart0_print("\nSe ha pulsado la tecla: ");
        if(Key_value < 10){
           neorv32_uart0_printf("%u",Key_value);
        }
        else if(Key_value > 64 && Key_value < 71){
           neorv32_uart0_printf("%c",Key_value);
        }
        q_key_value = Key_value;
      }
    }
    else{
      q_key_value = 0xFF;
    }
  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG0_OFFSET, 0x1); // Escribo 1 en los decimales
  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG1_OFFSET, Key_value+1); // Escribo Key_value en las centenas
  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG2_OFFSET, 0x00000001); // Indico que escriba el valor en el display

  }
  return 0;
}




uint8_t Lee_teclado(void){
  uint32_t Key_value = 0;
  uint8_t Caracter = 0xFF;
  uint16_t Mask_Char;
  uint8_t i = 0;

  //Read register 0
  Key_value = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET) & 0x0000FFFF; 

  // If the user push a key:
  if (Key_value != 0x00000000){
    // Read the key value:
    for (i=0, Mask_Char = 0x0001 ; i<16 ; i++){
      Caracter = (Key_value & Mask_Char) != 0 ? KeyValue[i] : Caracter;
      Mask_Char = (Mask_Char << 1);
    }
    // Reset the register 0
      neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET, 0x00000000); 
  }

  return Caracter;
};
