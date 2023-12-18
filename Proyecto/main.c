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
void Represent_Display(uint8_t Decenas, uint8_t Centenas, uint8_t Enable);


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
  uint8_t num = 0; 
  uint8_t q_key_value = 0xFF;
  uint32_t total_value = 0;
  int estado = 10;
  int decena = 0;
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET, 0x000B0B0B);
  
  

  while(1){
    //uint32_t registro0 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET);   
    uint32_t registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);   
    uint32_t registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);   
    //uint32_t registro3 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET);
    uint32_t registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
   
    

      switch(estado)
      {
        case 10:
          if(registro4 == 0xF)
          {
            Represent_Display(0,12,1);
            neorv32_gpio_port_set(0x0F);
            neorv32_cpu_delay_ms(3000);
            neorv32_gpio_port_set(0x00);
            Represent_Display(0,12,0);
          }
          else{
            Key_value = Lee_teclado();
            if(Key_value != 0xFF){
              if(Key_value != q_key_value){
              neorv32_uart0_print("Funciona 4\n");
                if(Key_value < 10){estado=0;}
                else{estado = Key_value;} 
                q_key_value = Key_value;
              }            
            }
            else{q_key_value = 0xFF;}
          }
        break;

        case 0:  //Number
          num = decena*10+Key_value;
          neorv32_uart0_print("Funciona 5\n");
          Represent_Display(decena,Key_value,1);
          total_value=(total_value<<4)+Key_value;
          total_value = total_value & 0xFF;
          neorv32_uart0_printf("Total_value: %u\n",total_value);
          neorv32_uart0_printf("num: %u\n",num);
          neorv32_uart0_printf("Decena: %d\n",decena);
          neorv32_uart0_printf("UNidad: %u\n",Key_value);
          decena = Key_value;
          estado = 10;
        break;

        case 65:  //A
          neorv32_uart0_print("Funciona 6\n");
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+total_value;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 2;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 1;
        break;

        case 66:  //B
          neorv32_uart0_print("Funciona 7\n");
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<8);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 2;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 2;
        break;

        case 67:  //C
        neorv32_uart0_print("Funciona 8\n");
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<16);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 4;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 3;
        break;

        case 68:  //D
        neorv32_uart0_print("Funciona 9\n");
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<24);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 8;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 4;
        break;

        case 1:  //Check A protocol
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 1) != 0)
          {
            neorv32_uart0_print("\nClave A correcta\n");
            neorv32_gpio_port_set(0x01);
            neorv32_cpu_delay_ms(2000);
            neorv32_gpio_port_set(0x00);
            total_value=0;
            estado = 10;
          }
          else
          {
            total_value=0;
            estado = 5;
          }
        break;

        case 2:  //Check B protocol
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 2) != 0)
          {
            neorv32_uart0_print("\nClave B correcta\n");
            neorv32_gpio_port_set(0x02);
            neorv32_cpu_delay_ms(2000);
            neorv32_gpio_port_set(0x00);
            total_value=0;
            estado = 10;
          }
          else
          {
            total_value=0;
            estado = 5;
          }
        break;

        case 3:  //Check C protocol
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 4) != 0)
          {
            neorv32_uart0_print("\nClave C correcta\n");
            neorv32_gpio_port_set(0x04);
            neorv32_cpu_delay_ms(2000);
            neorv32_gpio_port_set(0x00);
            total_value=0;
            estado = 10;
          }
          else
          {
            total_value=0;
            estado = 5;
          }
        break;

        case 4:  //Check D protocol
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 8) != 0)
          {
            neorv32_uart0_print("\nClave D correcta\n");
            neorv32_gpio_port_set(0x08);
            neorv32_cpu_delay_ms(2000);
            neorv32_gpio_port_set(0x00);
            total_value=0;
            estado = 10;
          }
          else
          {
            total_value=0;
            estado = 5;
          }
        break;

        case 5: //Fail
          neorv32_uart0_print("\nClave incorrecta->Claves reseteadas\n");  
          Represent_Display(10,11,1);        
          neorv32_gpio_port_set(0x10);
          neorv32_cpu_delay_ms(3000);
          neorv32_gpio_port_set(0x00);
          neorv32_gpio_port_set(0x20);
          estado = 10;

        break;
      } 
 
  
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

void Represent_Display(uint8_t Decenas, uint8_t Centenas, uint8_t Enable){

  uint16_t FPGA_display;
  uint16_t Mask;
  uint8_t i;

  for (i=3, Mask = 0x0004, FPGA_display = Decenas ; i<13 ; i++){
    FPGA_display = Decenas == i ? Mask : FPGA_display;
    Mask = (Mask << 1);
  }

  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG0_OFFSET,  FPGA_display); // Escribo Decenas
  
    for (i=3, Mask = 0x0004, FPGA_display = Centenas ; i<13 ; i++){
    FPGA_display = Centenas == i ? Mask : FPGA_display;
    Mask = (Mask << 1);
  }
  
  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG1_OFFSET,  FPGA_display); // Escribo Centenas

  if(Enable != 0){
      neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG2_OFFSET, 0x00000001); // Indico que escriba el valor en el display
  }
  else{
    neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG2_OFFSET, 0x00000000); // Indico que escriba el valor en el display    
  }
};
