-- #################################################################################################
-- # << NEORV32 - Example setup including the bootloader, for the iCEBreaker (c) Board >>          #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

-- Created by Hipolito Guzman-Miranda based on Unai Martinez-Corral's adaptation to the iCESugar board

-- Allow use of std_logic, signed, unsigned
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Library where the processor is located
library neorv32;

entity neorv32_iCEBreaker_BoardTop_MinimalBoot is
  -- Top-level ports. Board pins are defined in setups/osflow/constraints/iCEBreaker.pcf
  port (
    -- 12MHz Clock input
    iCEBreakerv10_CLK                : in std_logic;
    -- UART0
    iCEBreakerv10_RX                 : in  std_logic;
    iCEBreakerv10_TX                 : out std_logic;
    -- Button inputs
    iCEBreakerv10_BTN_N              : in std_logic;
    iCEBreakerv10_PMOD2_9_Button_1   : in std_logic;
    iCEBreakerv10_PMOD2_4_Button_2   : in std_logic;
    iCEBreakerv10_PMOD2_10_Button_3  : in std_logic;
    -- LED outputs
    iCEBreakerv10_LED_R_N            : out std_logic;
    iCEBreakerv10_LED_G_N            : out std_logic;
    iCEBreakerv10_PMOD2_1_LED_left   : out std_logic;
    iCEBreakerv10_PMOD2_2_LED_right  : out std_logic;
    iCEBreakerv10_PMOD2_8_LED_up     : out std_logic;
    iCEBreakerv10_PMOD2_3_LED_down   : out std_logic;
    iCEBreakerv10_PMOD2_7_LED_center : out std_logic;
    -- Teclado
    iCEBreakerv10_PMOD1B_1           : out std_logic;
    iCEBreakerv10_PMOD1B_2           : out std_logic;
    iCEBreakerv10_PMOD1B_3           : out std_logic;
    iCEBreakerv10_PMOD1B_4           : out std_logic;
    iCEBreakerv10_PMOD1B_7           : in std_logic;
    iCEBreakerv10_PMOD1B_8           : in std_logic;
    iCEBreakerv10_PMOD1B_9           : in std_logic;
    iCEBreakerv10_PMOD1B_10          : in std_logic;
    -- Display 7 segmentos
    iCEBreakerv10_PMOD1A_1           : out std_logic;
    iCEBreakerv10_PMOD1A_2           : out std_logic;
    iCEBreakerv10_PMOD1A_3           : out std_logic;
    iCEBreakerv10_PMOD1A_4           : out std_logic;
    iCEBreakerv10_PMOD1A_7           : out std_logic;
    iCEBreakerv10_PMOD1A_8           : out std_logic;
    iCEBreakerv10_PMOD1A_9           : out std_logic;
    iCEBreakerv10_PMOD1A_10          : out std_logic
  );
end entity;

architecture neorv32_iCEBreaker_BoardTop_MinimalBoot_rtl of neorv32_iCEBreaker_BoardTop_MinimalBoot is

  -- -------------------------------------------------------------------------------------------
  -- Constants for microprocessor configuration
  -- -------------------------------------------------------------------------------------------

  -- General config --
  constant CLOCK_FREQUENCY              : natural := 12_000_000;  -- Microprocessor clock frequency (Hz)
  constant INT_BOOTLOADER_EN            : boolean := true;        -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
  constant HW_THREAD_ID                 : natural := 0;           -- hardware thread id (32-bit)

  -- RISC-V CPU Extensions --
  constant CPU_EXTENSION_RISCV_A        : boolean := true;        -- implement atomic extension?
  constant CPU_EXTENSION_RISCV_C        : boolean := true;        -- implement compressed extension?
  constant CPU_EXTENSION_RISCV_E        : boolean := false;       -- implement embedded RF extension?
  constant CPU_EXTENSION_RISCV_M        : boolean := true;        -- implement mul/div extension?
  constant CPU_EXTENSION_RISCV_U        : boolean := false;       -- implement user mode extension?
  constant CPU_EXTENSION_RISCV_Zfinx    : boolean := false;       -- implement 32-bit floating-point extension (using INT regs!)
  constant CPU_EXTENSION_RISCV_Zicsr    : boolean := true;        -- implement CSR system?
  constant CPU_EXTENSION_RISCV_Zifencei : boolean := false;       -- implement instruction stream sync.?

  -- Extension Options --
  constant FAST_MUL_EN                  : boolean := false;       -- use DSPs for M extension's multiplier
  constant FAST_SHIFT_EN                : boolean := false;       -- use barrel shifter for shift operations
  constant CPU_CNT_WIDTH                : natural := 34;          -- total width of CPU cycle and instret counters (0..64)

  -- Physical Memory Protection (PMP) --
  constant PMP_NUM_REGIONS              : natural := 0;            -- number of regions (0..64)
  constant PMP_MIN_GRANULARITY          : natural := 64*1024;      -- minimal region granularity in bytes, has to be a power of 2, min 8 bytes

  -- Hardware Performance Monitors (HPM) --
  constant HPM_NUM_CNTS                 : natural := 0;            -- number of implemented HPM counters (0..29)
  constant HPM_CNT_WIDTH                : natural := 40;           -- total size of HPM counters (0..64)

  -- Internal Instruction memory --
  constant MEM_INT_IMEM_EN              : boolean := true;         -- implement processor-internal instruction memory
  constant MEM_INT_IMEM_SIZE            : natural := 64*1024;      -- size of processor-internal instruction memory in bytes

  -- Internal Data memory --
  constant MEM_INT_DMEM_EN              : boolean := true;         -- implement processor-internal data memory
  constant MEM_INT_DMEM_SIZE            : natural := 8*1024;      -- size of processor-internal data memory in bytes

  -- Internal Cache memory --
  constant ICACHE_EN                    : boolean := false;       -- implement instruction cache
  constant ICACHE_NUM_BLOCKS            : natural := 4;           -- i-cache: number of blocks (min 1), has to be a power of 2
  constant ICACHE_BLOCK_SIZE            : natural := 64;          -- i-cache: block size in bytes (min 4), has to be a power of 2
  constant ICACHE_ASSOCIATIVITY         : natural := 1;           -- i-cache: associativity / number of sets (1=direct_mapped), has to be a power of 2

  -- Processor peripherals --
  constant IO_GPIO_EN                   : boolean := true;        -- implement general purpose input/output port unit (GPIO)?
  constant IO_MTIME_EN                  : boolean := true;        -- implement machine system timer (MTIME)?
  constant IO_UART0_EN                  : boolean := true;        -- implement primary universal asynchronous receiver/transmitter (UART0)?
  constant IO_PWM_NUM_CH                : natural := 3;           -- number of PWM channels to implement (0..60); 0 = disabled
  constant IO_WDT_EN                    : boolean := true;        -- implement watch dog timer (WDT)?


  -- -------------------------------------------------------------------------------------------
  -- Signals for internal IO connections
  -- -------------------------------------------------------------------------------------------
  signal gpio_o : std_ulogic_vector(63 downto 0);
  signal gpio_i : std_logic_vector(63 downto 0);

  signal n_button_val : std_logic_vector(3 downto 0):="0000";
  signal c_button_val : std_logic_vector(3 downto 0):="0000";
  
  signal c_counter : unsigned (1 downto 0):="00";
  signal n_counter : unsigned (1 downto 0):="00";

  -- Signals for Wishbone --
  signal wb_tag_m2s   : std_ulogic_vector(2 downto 0);          -- Request tag
  signal wb_adr_m2s   : std_ulogic_vector(31 downto 0);         -- Address
  signal wb_dat_keypad_s2m   : std_ulogic_vector(31 downto 0); -- Read Data from teclado
  signal wb_dat_display_s2m   : std_ulogic_vector(31 downto 0); -- Read Data from display
  signal wb_dat_m2s   : std_ulogic_vector(31 downto 0);         -- Write Data
  signal wb_we_m2s    : std_ulogic;                             -- Read/Write
  signal wb_sel_m2s   : std_ulogic_vector(3 downto 0);          -- Byte enable
  signal wb_stb_m2s   : std_ulogic;                             -- Strobe
  signal wb_cyc_m2s   : std_ulogic;                             -- Valid Cycle
  signal wb_lock_m2s  : std_ulogic;                             -- Exclusive Acces
  signal wb_ack_keypad_s2m   : std_ulogic;                     -- Transfer Ack from teclado 
  signal wb_err_keypad_s2m   : std_ulogic;                     -- Transfer error from display
  signal wb_ack_display_s2m   : std_ulogic;                    -- Transfer Ack from display 
  signal wb_err_display_s2m   : std_ulogic;                    -- Transfer error from display


  signal s_reset      : std_logic := '0';
begin

  -- -------------------------------------------------------------------------------------------
  -- Instance the microprocessor
  -- -------------------------------------------------------------------------------------------

  neorv32_inst: entity neorv32.neorv32_top
  generic map (
    -- General --
    CLOCK_FREQUENCY              => CLOCK_FREQUENCY,               -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN            => INT_BOOTLOADER_EN,             -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    HW_THREAD_ID                 => HW_THREAD_ID,                  -- hardware thread id (32-bit)

    -- On-Chip Debugger (OCD) --
    ON_CHIP_DEBUGGER_EN          => false,                         -- implement on-chip debugger?

    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_A        => CPU_EXTENSION_RISCV_A,         -- implement atomic extension?
    CPU_EXTENSION_RISCV_C        => CPU_EXTENSION_RISCV_C,         -- implement compressed extension?
    CPU_EXTENSION_RISCV_E        => CPU_EXTENSION_RISCV_E,         -- implement embedded RF extension?
    CPU_EXTENSION_RISCV_M        => CPU_EXTENSION_RISCV_M,         -- implement mul/div extension?
    CPU_EXTENSION_RISCV_U        => CPU_EXTENSION_RISCV_U,         -- implement user mode extension?
    CPU_EXTENSION_RISCV_Zfinx    => CPU_EXTENSION_RISCV_Zfinx,     -- implement 32-bit floating-point extension (using INT regs!)
    CPU_EXTENSION_RISCV_Zicsr    => CPU_EXTENSION_RISCV_Zicsr,     -- implement CSR system?
    CPU_EXTENSION_RISCV_Zicntr   => true,                          -- implement base counters?
    CPU_EXTENSION_RISCV_Zifencei => CPU_EXTENSION_RISCV_Zifencei,  -- implement instruction stream sync.?

    -- Extension Options --
    FAST_MUL_EN                  => FAST_MUL_EN,                   -- use DSPs for M extension's multiplier
    FAST_SHIFT_EN                => FAST_SHIFT_EN,                 -- use barrel shifter for shift operations
    CPU_CNT_WIDTH                => CPU_CNT_WIDTH,                 -- total width of CPU cycle and instret counters (0..64)

    -- Physical Memory Protection (PMP) --
    PMP_NUM_REGIONS              => PMP_NUM_REGIONS,       -- number of regions (0..64)
    PMP_MIN_GRANULARITY          => PMP_MIN_GRANULARITY,   -- minimal region granularity in bytes, has to be a power of 2, min 8 bytes

    -- Hardware Performance Monitors (HPM) --
    HPM_NUM_CNTS                 => HPM_NUM_CNTS,          -- number of implemented HPM counters (0..29)
    HPM_CNT_WIDTH                => HPM_CNT_WIDTH,         -- total size of HPM counters (1..64)

    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => MEM_INT_IMEM_EN,       -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => MEM_INT_IMEM_SIZE,     -- size of processor-internal instruction memory in bytes

    -- Internal Data memory --
    MEM_INT_DMEM_EN              => MEM_INT_DMEM_EN,       -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => MEM_INT_DMEM_SIZE,     -- size of processor-internal data memory in bytes

    -- Internal Cache memory --
    ICACHE_EN                    => ICACHE_EN,             -- implement instruction cache
    ICACHE_NUM_BLOCKS            => ICACHE_NUM_BLOCKS,     -- i-cache: number of blocks (min 1), has to be a power of 2
    ICACHE_BLOCK_SIZE            => ICACHE_BLOCK_SIZE,     -- i-cache: block size in bytes (min 4), has to be a power of 2
    ICACHE_ASSOCIATIVITY         => ICACHE_ASSOCIATIVITY,  -- i-cache: associativity / number of sets (1=direct_mapped), has to be a power of 2

    -- External memory interface --
    MEM_EXT_EN                   => true,                 -- implement external memory bus interface?
    MEM_EXT_TIMEOUT              => 0,                     -- cycles after a pending bus access auto-terminates (0 = disabled)

    -- Processor peripherals --
    IO_GPIO_EN                   => IO_GPIO_EN,    -- implement general purpose input/output port unit (GPIO)?
    IO_MTIME_EN                  => IO_MTIME_EN,   -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => IO_UART0_EN,   -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_UART1_EN                  => false,         -- implement secondary universal asynchronous receiver/transmitter (UART1)?
    IO_SPI_EN                    => false,         -- implement serial peripheral interface (SPI)?
    IO_TWI_EN                    => false,         -- implement two-wire interface (TWI)?
    IO_PWM_NUM_CH                => IO_PWM_NUM_CH, -- number of PWM channels to implement (0..60); 0 = disabled
    IO_WDT_EN                    => IO_WDT_EN,     -- implement watch dog timer (WDT)?
    IO_TRNG_EN                   => false,         -- implement true random number generator (TRNG)?
    IO_CFS_EN                    => false,         -- implement custom functions subsystem (CFS)?
    IO_CFS_CONFIG                => x"00000000",   -- custom CFS configuration generic
    IO_CFS_IN_SIZE               => 32,            -- size of CFS input conduit in bits
    IO_CFS_OUT_SIZE              => 32,            -- size of CFS output conduit in bits
    IO_NEOLED_EN                 => false          -- implement NeoPixel-compatible smart LED interface (NEOLED)?
  )
  port map (
    -- Global control --
    clk_i       => std_ulogic(iCEBreakerv10_CLK),   -- global clock, rising edge
    rstn_i      => std_ulogic(iCEBreakerv10_BTN_N), -- global reset, low-active, async

    -- JTAG on-chip debugger interface (available if ON_CHIP_DEBUGGER_EN = true) --
    jtag_trst_i => '0',                          -- low-active TAP reset (optional)
    jtag_tck_i  => '0',                          -- serial clock
    jtag_tdi_i  => '0',                          -- serial data input
    jtag_tdo_o  => open,                         -- serial data output
    jtag_tms_i  => '0',                          -- mode select

    -- Wishbone bus interface (available if MEM_EXT_EN = true) --
    wb_tag_o    => wb_tag_m2s,     -- request tag
    wb_adr_o    => wb_adr_m2s,     -- address
    wb_dat_i    => wb_dat_keypad_s2m or wb_ack_display_s2m,     -- read data
    wb_dat_o    => wb_dat_m2s,     -- write data
    wb_we_o     => wb_we_m2s,      -- read/write
    wb_sel_o    => wb_sel_m2s,     -- byte enable
    wb_stb_o    => wb_stb_m2s,     -- strobe
    wb_cyc_o    => wb_cyc_m2s,     -- valid cycle
    wb_lock_o   => wb_lock_m2s,    -- exclusive access request
    wb_ack_i    => wb_ack_display_s2m or wb_ack_keypad_s2m,     -- transfer acknowledge
    wb_err_i    => wb_err_display_s2m or wb_err_keypad_s2m,     -- transfer error

    -- Advanced memory control signals (available if MEM_EXT_EN = true) --
    fence_o     => open,                         -- indicates an executed FENCE operation
    fencei_o    => open,                         -- indicates an executed FENCEI operation

    -- GPIO (available if IO_GPIO_EN = true) --
    gpio_o      => gpio_o,                       -- parallel output
    gpio_i      => gpio_i,              	 -- parallel input

    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o => iCEBreakerv10_TX,             -- UART0 send data
    uart0_rxd_i => iCEBreakerv10_RX,             -- UART0 receive data
    uart0_rts_o => open,                         -- hw flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i => '0',                          -- hw flow control: UART0.TX allowed to transmit, low-active, optional

    -- secondary UART1 (available if IO_UART1_EN = true) --
    uart1_txd_o => open,                         -- UART1 send data
    uart1_rxd_i => '0',                          -- UART1 receive data
    uart1_rts_o => open,                         -- hw flow control: UART1.RX ready to receive ("RTR"), low-active, optional
    uart1_cts_i => '0',                          -- hw flow control: UART1.TX allowed to transmit, low-active, optional

    -- SPI (available if IO_SPI_EN = true) --
    spi_sck_o   => open,                         -- SPI serial clock
    spi_sdo_o   => open,                         -- controller data out, peripheral data in
    spi_sdi_i   => '0',                          -- controller data in, peripheral data out
    spi_csn_o   => open,                         -- SPI CS

    -- TWI (available if IO_TWI_EN = true) --
    twi_sda_io  => open,                         -- twi serial data line
    twi_scl_io  => open,                         -- twi serial clock line

    -- PWM (available if IO_PWM_NUM_CH > 0) --
    pwm_o       => open,                         -- pwm channels

    -- Custom Functions Subsystem IO --
    cfs_in_i    => (others => '0'),              -- custom CFS inputs conduit
    cfs_out_o   => open,                         -- custom CFS outputs conduit

    -- NeoPixel-compatible smart LED interface (available if IO_NEOLED_EN = true) --
    neoled_o    => open,                         -- async serial data line

    -- System time --
    mtime_i     => (others => '0'),              -- current system time from ext. MTIME (if IO_MTIME_EN = false)
    mtime_o     => open,                         -- current system time from int. MTIME (if IO_MTIME_EN = true)

    -- Interrupts --
    mtime_irq_i => '0',                          -- machine timer interrupt, available if IO_MTIME_EN = false
    msw_irq_i   => '0',                          -- machine software interrupt
    mext_irq_i  => '0'                           -- machine external interrupt
  );


  peripheral_teclado_0: entity neorv32.wb_peripheral_teclado
  generic map(WB_ADDR_BASE   => x"90000000",
              WB_ADDR_SIZE   => 32 )    
  port map(
    clk_i     => std_ulogic(iCEBreakerv10_CLK),
    reset_i   => s_reset,
    en_i      => '1',

    wb_tag_i  => wb_tag_m2s,     -- request tag
    wb_adr_i  => wb_adr_m2s,     -- address
    wb_dat_i  => wb_dat_m2s,     -- read data
    wb_dat_o  => wb_dat_keypad_s2m,     -- write data
    wb_we_i   => wb_we_m2s,      -- read/write
    wb_sel_i  => wb_sel_m2s,     -- byte enable
    wb_stb_i  => wb_stb_m2s,     -- strobe
    wb_cyc_i  => wb_cyc_m2s,     -- valid cycle
    wb_lock_i => wb_lock_m2s,    -- exclusive access request
    wb_ack_o  => wb_ack_keypad_s2m,     -- transfer acknowledge
    wb_err_o  => wb_err_keypad_s2m,     -- transfer error

    Row_1_i   => std_ulogic(iCEBreakerv10_PMOD1B_7),
    Row_2_i   => std_ulogic(iCEBreakerv10_PMOD1B_8), 
    Row_3_i   => std_ulogic(iCEBreakerv10_PMOD1B_9),     
    Row_4_i   => std_ulogic(iCEBreakerv10_PMOD1B_10), 
    Col_1_o   => iCEBreakerv10_PMOD1B_1,
    Col_2_o   => iCEBreakerv10_PMOD1B_2,
    Col_3_o   => iCEBreakerv10_PMOD1B_3,
    Col_4_o   => iCEBreakerv10_PMOD1B_4     
    );

    peripheral_7segmentDisplay: entity neorv32.wb_7segmentDisplay
    generic map(WB_ADDR_BASE   => x"90000020",
                WB_ADDR_SIZE   => 16 )    
    port map(
      clk_i     => std_ulogic(iCEBreakerv10_CLK),
      reset_i   => s_reset,
  
      wb_tag_i  => wb_tag_m2s,     -- request tag
      wb_adr_i  => wb_adr_m2s,     -- address
      wb_dat_i  => wb_dat_m2s,     -- read data
      wb_dat_o  => wb_dat_display_s2m,     -- write data
      wb_we_i   => wb_we_m2s,      -- read/write
      wb_sel_i  => wb_sel_m2s,     -- byte enable
      wb_stb_i  => wb_stb_m2s,     -- strobe
      wb_cyc_i  => wb_cyc_m2s,     -- valid cycle
      wb_lock_i => wb_lock_m2s,    -- exclusive access request
      wb_ack_o  => wb_ack_display_s2m,     -- transfer acknowledge
      wb_err_o  => wb_err_display_s2m,     -- transfer error

            -- 7 Segment Dislay
      aa_o      => iCEBreakerv10_PMOD1A_1,
      ab_o      => iCEBreakerv10_PMOD1A_2,
      ac_o      => iCEBreakerv10_PMOD1A_3,
      ad_o      => iCEBreakerv10_PMOD1A_4,
      ae_o      => iCEBreakerv10_PMOD1A_7,
      af_o      => iCEBreakerv10_PMOD1A_8,
      ag_o      => iCEBreakerv10_PMOD1A_9,
      ds_o      => iCEBreakerv10_PMOD1A_10
      );
    

  -- -------------------------------------------------------------------------------------------
  -- IO Connections
  -- -------------------------------------------------------------------------------------------
  iCEBreakerv10_PMOD2_1_LED_left   <= gpio_o(0);
  iCEBreakerv10_PMOD2_2_LED_right  <= gpio_o(1);
  iCEBreakerv10_PMOD2_8_LED_up     <= gpio_o(2);
  iCEBreakerv10_PMOD2_3_LED_down   <= gpio_o(3);
  iCEBreakerv10_PMOD2_7_LED_center <= gpio_o(4);  
  s_reset  <= gpio_o(5);

  gpio_i <= x"000000000000000"  &
            c_button_val;

  -- -------------------------------------------------------------------------------------------
  -- Buttom process
  -- -------------------------------------------------------------------------------------------
  State_buttom_sinc: process(iCEBreakerv10_CLK,iCEBreakerv10_PMOD2_10_Button_3)
  begin
    if (iCEBreakerv10_PMOD2_10_Button_3) then --Reset
      c_button_val <= (others => '0'); 
  
    elsif (rising_edge(iCEBreakerv10_CLK)) then
      c_button_val <= n_button_val;

    end if;

  end process;

  State_Buttom_comb: process(iCEBreakerv10_PMOD2_9_Button_1,iCEBreakerv10_PMOD2_4_Button_2,iCEBreakerv10_PMOD2_10_Button_3,c_button_val)
  begin
 	-- Keep the state
  	n_button_val <= c_button_val; 
  	-- We are sending which buttom has been pushed
  	if (iCEBreakerv10_PMOD2_9_Button_1 = '1') then
		n_button_val <= x"1";
	elsif (iCEBreakerv10_PMOD2_4_Button_2 = '1') then
		n_button_val <= x"2";
	elsif (iCEBreakerv10_PMOD2_10_Button_3 = '1') then 
		n_button_val <= x"3";

	end if;  
  end process;
  

end architecture;
