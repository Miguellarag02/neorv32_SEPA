
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_peripheral_teclado is
  generic(
    WB_BASE_ADDRESS     : std_ulogic_vector(31 downto 0) := x"90000000";
    WB_NUM_REGS         : integer  := 2 --Two registers
  );
      -- Top-level ports. Board pins are defined in setups/osflow/constraints/iCEBreaker.pcf
  port (
    -- 12MHz Clock input
    clk_i                : in std_ulogic;
    reset_i              : in std_ulogic;

    -- Wishbone Comunication
    wb_tag_i             : in std_ulogic_vector(02 downto 0);
    wb_adr_i             : in std_ulogic_vector(31 downto 0); 
    wb_dat_i             : in  std_ulogic_vector(31 downto 0);
    wb_dat_o             : out std_ulogic_vector(31 downto 0);
    wb_we_i              : in std_ulogic;
    wb_sel_i             : in std_ulogic_vector(03 downto 0);
    wb_stb_i             : in std_ulogic;
    wb_cyc_i             : in std_ulogic; 
    wb_lock_i            : in std_ulogic;
    wb_ack_o             : out  std_ulogic;
    wb_err_o             : out  std_ulogic;

    -- Rows
    en_i                 : in std_ulogic;
    Row_1_i              : in std_ulogic;
    Row_2_i              : in std_ulogic;
    Row_3_i              : in std_ulogic;
    Row_4_i              : in std_ulogic;
    
    -- Cols
    Col_1_o              : out std_logic;
    Col_2_o              : out std_logic;
    Col_3_o              : out std_logic;
    Col_4_o              : out std_logic;

    -- Key codificated in One Hot
    Key_o     : out std_ulogic_vector(15 downto 0)

    );
end entity;

architecture wb_peripheral_rtl of wb_peripheral_teclado is


    type state_t is(
		IDLE,
		WB_WRITE_REG,
		END_TX
		);

    -- internal constants --
    constant addr_mask_c : std_ulogic_vector(31 downto 0) := std_ulogic_vector(to_unsigned((WB_NUM_REGS*4)-1, 32));
    constant all_zero_c  : std_ulogic_vector(31 downto 0) := (others => '0');

    -----------------------------------------------------------    
    -- SIGNALS                                              ---
    -----------------------------------------------------------

    -- address match --
    signal access_req       : std_ulogic;

    -- registers --
    signal c_reg0, n_reg0   : std_ulogic_vector(31 downto 0);
    signal c_reg1, n_reg1   : std_ulogic_vector(31 downto 0);
    --signal c_reg2, n_reg2   : std_ulogic_vector(31 downto 0);
    --signal c_reg3, n_reg3   : std_ulogic_vector(31 downto 0);


    signal c_counter        : unsigned (1 downto 0);
    signal n_counter        : unsigned (1 downto 0);

    signal c_key            : std_ulogic_vector(15 downto 0);
    signal n_key            : std_ulogic_vector(15 downto 0);

    signal c_state_tx       : state_t;
    signal n_state_tx       : state_t;

    signal c_col            : std_ulogic_vector(3 downto 0);
    signal n_col            : std_ulogic_vector(3 downto 0);

    signal s_row            : std_ulogic_vector(3 downto 0);

    begin

    -------------------------------------------------------
    -- Sanity Checks                                    ---
    -------------------------------------------------------
    -- Address space will always be a power of two, so I don't check it.
    assert not ((std_ulogic_vector(to_unsigned((WB_NUM_REGS*4), 32)) and addr_mask_c) /= all_zero_c) report "wb_regs config ERROR: Module base address <WB_ADDR_BASE> has to be aligned to its address space <WB_ADDR_SIZE>." severity error;

    -------------------------------------------------------
    -- Device Access?                                   ---
    -------------------------------------------------------
    access_req <= '1' when ((wb_adr_i and (not addr_mask_c)) = ((std_ulogic_vector(to_unsigned((WB_NUM_REGS*4), 32))) and (not addr_mask_c))) 
                        else '0';

    -------------------------------------------------------
    -- Concurrents Outputs                              ---
    -------------------------------------------------------
    Col_1_o <= std_logic(c_col(0));
    Col_2_o <= std_logic(c_col(1));
    Col_3_o <= std_logic(c_col(2));
    Col_4_o <= std_logic(c_col(3));
    
    s_row   <= Row_4_i &
               Row_3_i &
               Row_2_i &
               Row_1_i;

    Key_o   <= c_key;

    -------------------------------------------------------
    -- Read key processs                                ---
    -------------------------------------------------------
              
    peripheral_teclado_sinc: process(clk_i, reset_i)
    begin
        if (reset_i = '1') then
            c_counter   <=  (others => '0');
            c_col       <= (others => '0');   
            c_key       <= (others => '0');

        elsif ( rising_edge(clk_i)) then
            c_counter   <= n_counter;
            c_col       <= n_col;
            c_key       <= n_key;

        end if;
    end process;

    peripheral_teclado_decode: process(c_counter,s_row,c_col,c_key)
    begin
    n_key       <= (others => '0');
    n_col       <= (others => '0');
    n_counter   <= (others => '0');

    if (en_i = '1') then
        n_counter   <= c_counter + 1;

        case (c_counter) is
            when "00" =>
                n_col   <=  "1110";
                if (s_row /= "1111") then
                    n_key <= x"000" & not(s_row);
                end if;
                
            when "01" =>
                n_col   <=  "1101";
                if (s_row /= "1111") then
                    n_key <= x"00" & not(s_row) & x"0";
                end if;

            when "10" =>
                n_col   <=  "1011";
                if (s_row /= "1111") then
                    n_key <= x"0" & not(s_row) & x"00";
                end if;

            when others =>
                n_col   <=  "0111";
                if (s_row /= "1111") then
                    n_key <= not(s_row) & x"000";
                end if;
        end case;
    end if;

end process;


    -------------------------------------------------------
    -- WISHBONE PROCESS                                 ---
    -------------------------------------------------------


    wb_peripheral_teclado_tx_sinc: process(clk_i, reset_i)
    begin
        if (reset_i = '1') then
            c_reg0 <= x"ACCEDE00"; --(others => '0');
            c_reg1 <= x"DEC0DE01"; --(others => '0');
            --reg2 <= x"C0FFEE02"; --(others => '0');
            --reg3 <= x"BA0BAB03"; --(others => '0');


        elsif (rising_edge(clk_i)) then
            c_reg0 <= n_reg0;
            c_reg1 <= n_reg1;
            --c_reg2 <= n_reg2;
            --c_reg3 <= n_reg3;


        end if;
    end process;

    wb_peripheral_teclado_tx_comb: process(
        wb_cyc_i, 
        wb_stb_i, 
        wb_sel_i, 
        access_req, 
        wb_we_i,
        c_reg0, 
        c_reg1 
        --c_reg2, 
        --c_reg3
        )
    begin
        -- Keep values
        n_reg0 <= c_reg0; -- x"0000" & c_key; -- Key value
        n_reg1 <= c_reg1;
        --n_reg2 <= reg2;
        --n_reg3 <= reg3;
        wb_dat_o <= c_reg0;
        -- Default ack is inactive
        wb_ack_o <= '0';

        -- Is the peripheral selected?
        if (wb_cyc_i = '1') and (wb_stb_i = '1') and (access_req = '1') then

        -- Write access, only full-word accesses
        if (wb_we_i = '1' and wb_sel_i = "1111") then
            case to_integer(unsigned(wb_adr_i(((WB_NUM_REGS/2)*2)+2 downto 2))) is
            when 0 =>
                -- n_reg0 <= wb_dat_i; Forbidden write here!!
            when 1 =>
                n_reg1 <= wb_dat_i;
                
            --when 2 =>
                --n_reg2 <= wb_dat_i;
            --when 3 =>
                --n_reg3 <= wb_dat_i;
            when others =>
                null;
            end case;
            wb_ack_o <= '1';
        else
        -- Read access
            case to_integer(unsigned(wb_adr_i(((WB_NUM_REGS/2)*2)+2 downto 2))) is
            when 0 =>
                wb_dat_o <= c_reg0;
            when 1 =>
                wb_dat_o <= c_reg1;
            --when 2 =>
                --wb_dat_o <= c_reg2;
            --when 3 =>
                --wb_dat_o <= c_reg3;
            when others =>
                null;
            end case;
            wb_ack_o <= '1';
        end if;

        end if;

    end process;

  -------------------------------------------------------
  -- Errors can not happen in this module             ---
  -------------------------------------------------------
  wb_err_o <= '0';

end architecture;