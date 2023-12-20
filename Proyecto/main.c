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
  uint8_t q_key_value = 0xFF;
  uint32_t total_value = 0;
  int estado = 10;
  int decena = 0;
  uint8_t led1 = 0x01;
  uint8_t led2 = 0x02;
  uint8_t led3 = 0x04;
  uint8_t led4 = 0x08;
  uint8_t v_gpio = 0x00;

  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET, 0x00000000);
  neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET, 0x75123456);
  
  

  while(1){
    //to know always whats happening on the registers
    //uint32_t registro0 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG0_OFFSET);   
    uint32_t registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);   
    uint32_t registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);   
    //uint32_t registro3 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET);
    uint32_t registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
   
    

      switch(estado)
      {
        case 10: //Initial case-->waiting for caracters
          if(registro4 == 0xF)
          {
            neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET,0x00000000);
            neorv32_uart0_printf("\nPuerta abierta, tiene 5s...\n");
            Represent_Display(0,12,1);
            neorv32_cpu_delay_ms(5000);
            v_gpio = 0x00;
            neorv32_gpio_port_set(0x20);
            neorv32_gpio_port_set(0x00);
            Represent_Display(0,12,0);
          }
          else{
            //New pulse on the keypad
            Key_value = Lee_teclado();
            if(Key_value != 0xFF){
              if(Key_value != q_key_value){
                if(Key_value < 10){estado=0;}
                else{estado = Key_value;} 
                q_key_value = Key_value;
              }            
            }
            else{q_key_value = 0xFF;}
          }
        break;

        case 0:  //Number
          Represent_Display(decena,Key_value,1);  //Displays the numbers
          total_value=(total_value<<4)+Key_value;   //Move units to tens
          total_value = total_value & 0xFF; //Take only last numbers and discard the rest
          neorv32_uart0_printf("Total_value: %x\n",total_value);
          decena = Key_value;
          estado = 10;

          //Show registers to see how it works easier
          //  neorv32_uart0_printf("Registro 1: %x\n",registro1);
          //  neorv32_uart0_printf("Registro 2: %x\n",registro2);
          //  neorv32_uart0_printf("Registro 3: %x\n",registro3);
          //  neorv32_uart0_printf("Registro 4: %x\n",registro4);


        break;

        //Case 65-69 only for letters
        case 65:  //A
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+total_value;  
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 1;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 1;
        break;

        case 66:  //B
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<8); //Writing on the correct position of the protocol specified
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 2;  //Signal to hardware to know we want to compare passwords
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 2;
        break;

        case 67:  //C
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<16);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 4;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 3;
        break;

        case 68:  //D
          registro1 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET);
          registro1 = registro1+(total_value<<24);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG1_OFFSET, registro1);

          registro2 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET);
          registro2 = registro2 + 8;
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG2_OFFSET, registro2);

          estado = 4;
        break;

        case 69:  //E-->Reset
          neorv32_gpio_port_set(0x20);  //General reset except to reg3
          neorv32_gpio_port_set(0x00);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET, 0x75123456);
          v_gpio = 0x00;
          estado = 10;
          neorv32_uart0_print("\nVariables y claves reseteadas\n");
        break;

        case 1:  //Check A protocol
          neorv32_cpu_delay_ms(500);
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 1) != 0) //Condition specified on hardware
          {
            neorv32_uart0_print("\nClave A correcta\n");
            v_gpio = v_gpio+ led1;  //To not disturb other leds
            neorv32_gpio_port_set(v_gpio);
            neorv32_cpu_delay_ms(1000);
            Represent_Display(10,11,0);
            decena = 0;
            Key_value = 0xFF;
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
          neorv32_cpu_delay_ms(500);
          registro4 = neorv32_cpu_load_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG4_OFFSET);
          if((registro4 & 2) != 0)
          {
            neorv32_uart0_print("\nClave B correcta\n");
            v_gpio = v_gpio+ led2;
            neorv32_gpio_port_set(v_gpio);
            neorv32_cpu_delay_ms(1000);
            Represent_Display(10,11,0); 
            decena = 0;
            Key_value = 0xFF;
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
            v_gpio = v_gpio+ led3;
            neorv32_gpio_port_set(v_gpio);
            neorv32_cpu_delay_ms(1000);
            Represent_Display(10,11,0); 
            decena = 0;
            Key_value = 0xFF;
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
            v_gpio = v_gpio+ led4;
            neorv32_gpio_port_set(v_gpio);
            neorv32_cpu_delay_ms(1000);
            Represent_Display(10,11,0); 
            decena = 0;
            Key_value = 0xFF;
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
          Represent_Display(10,11,1);  //-->CL   
          neorv32_gpio_port_set(0x10);  //Red led
          neorv32_cpu_delay_ms(3000);
          neorv32_gpio_port_set(0x20); //General reset except to reg3
          neorv32_gpio_port_set(0x00);
          neorv32_cpu_store_unsigned_word (WB_TECLADO_BASE_ADDRESS + WB_TECLADO_REG3_OFFSET, 0x75123456);
          Represent_Display(10,11,0); //-->--
          v_gpio = 0x00;
          decena = 0;
          Key_value = 0xFF;
          total_value=0;
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

  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG0_OFFSET,  FPGA_display); // Write tens
  
    for (i=3, Mask = 0x0004, FPGA_display = Centenas ; i<13 ; i++){
    FPGA_display = Centenas == i ? Mask : FPGA_display;
    Mask = (Mask << 1);
  }
  
  neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG1_OFFSET,  FPGA_display); // Write units

  if(Enable != 0){
      neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG2_OFFSET, 0x00000001); // Order to write on display
  }
  else{
    neorv32_cpu_store_unsigned_word (WB_DISPLAY_BASE_ADDRESS + WB_DISPLAY_REG2_OFFSET, 0x00000000); // Order to write on display    
  }
};
