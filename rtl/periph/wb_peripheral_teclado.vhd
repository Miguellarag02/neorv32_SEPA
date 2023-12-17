
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;


entity wb_peripheral_teclado is
  generic(
    WB_ADDR_BASE        : std_ulogic_vector(31 downto 0) := x"90000000";
    WB_ADDR_SIZE        : integer := x"10"
  );
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
    Col_4_o              : out std_logic

    );
end entity;

architecture wb_peripheral_rtl of wb_peripheral_teclado is


    -- internal constants --
    constant addr_mask_c : std_ulogic_vector(31 downto 0) := std_ulogic_vector(to_unsigned(WB_ADDR_SIZE-1, 32));
    constant all_zero_c  : std_ulogic_vector(31 downto 0) := (others => '0');

    -----------------------------------------------------------    
    -- SIGNALS                                              ---
    -----------------------------------------------------------

    -- address match --
    signal access_req       : std_ulogic;

    -- registers --
    signal c_reg0, n_reg0   : std_ulogic_vector(31 downto 0);
    signal c_reg1, n_reg1   : std_ulogic_vector(31 downto 0);
    signal c_reg2, n_reg2   : std_ulogic_vector(31 downto 0);
    signal c_reg3, n_reg3   : std_ulogic_vector(31 downto 0);
    signal c_reg4, n_reg4   : std_ulogic_vector(31 downto 0);


    signal c_counter        : unsigned (1 downto 0);
    signal n_counter        : unsigned (1 downto 0);

    signal c_key            : std_ulogic_vector(15 downto 0); -- Update each cycle
    signal n_key            : std_ulogic_vector(15 downto 0);

    signal c_state_tx       : state_t;
    signal n_state_tx       : state_t;

    signal c_col            : std_ulogic_vector(3 downto 0);
    signal n_col            : std_ulogic_vector(3 downto 0);

    signal s_row            : std_ulogic_vector(3 downto 0);

    signal c_key_value      : std_ulogic_vector(15 downto 0); -- Update each four cycles
    signal n_key_value      : std_ulogic_vector(15 downto 0);

    signal c_Password_result  : std_logic_vector(3 downto 0);
    signal n_Password_result  : std_logic_vector(3 downto 0);

    begin

    -- Sanity Checks --------------------------------------------------------------------------
    -- ----------------------------------------------------------------------------------------
    assert not (WB_ADDR_SIZE < 4) report "wb_regs config ERROR: Address space <WB_ADDR_SIZE> has to be at least 4 bytes." severity error;
    assert not (is_power_of_two_f(WB_ADDR_SIZE) = false) report "wb_regs config ERROR: Address space <WB_ADDR_SIZE> has to be a power of two." severity error;
    assert not ((WB_ADDR_BASE and addr_mask_c) /= all_zero_c) report "wb_regs config ERROR: Module base address <WB_ADDR_BASE> has to be aligned to its address space <WB_ADDR_SIZE>." severity error;

    -- Device Access? -------------------------------------------------------------------------
    -- ----------------------------------------------------------------------------------------
    access_req <= '1' when ((wb_adr_i and (not addr_mask_c)) = (WB_ADDR_BASE and (not addr_mask_c))) else '0';


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
           
    -------------------------------------------------------
    -- Sinc processs                                    ---
    -------------------------------------------------------
    peripheral_teclado_sinc: process(clk_i, reset_i)
    begin
        if (reset_i = '1') then
            c_counter   <= (others => '0');
            c_col       <= (others => '0');   
            c_key       <= (others => '0');
            c_key_value <= (others => '0');
            c_reg0      <= (others => '0');
            c_reg1      <= (others => '0');
            c_reg2      <= (others => '0');
            c_reg3      <= (others => '0');
            c_reg4      <= (others => '0');

        elsif ( rising_edge(clk_i)) then
            c_counter   <= n_counter;
            c_col       <= n_col;
            c_key       <= n_key;
            c_key_value <= n_key_value;
            c_reg0      <= n_reg0; -- Storage the Key_value
            c_reg1      <= n_reg1; -- Storage the user password
            c_reg2      <= n_reg2; -- Storage the controls signals
            c_reg3      <= n_reg3; -- Storage the real password
            c_reg4      <= n_reg4; -- Storage the AND result between the user and the real password

        end if;
    end process;

    -------------------------------------------------------
    -- Read key processs                                ---
    -------------------------------------------------------

    peripheral_teclado_decode: process(c_counter, s_row, c_col, c_key, c_key_value)
    begin
        n_key       <= c_key;
        n_col       <= (others => '0');
        n_counter   <= (others => '0');
        n_key_value <= c_key_value;

        -- Sampling the value each four cycles.
        if(c_counter = "00" and c_key /= "00000000" ) then
            n_key_value <= c_key;     
            n_key <= (others => '0'); -- Reset de value
        end if;

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

    wb_peripheral_teclado_tx_comb: process(
        wb_cyc_i, 
        wb_stb_i, 
        wb_sel_i, 
        access_req, 
        wb_we_i,
        c_key_value,
        c_reg0, -- Storage the Key_value
        c_reg1, -- Storage the User password
        c_reg2, -- Storage the Control signal
        c_reg3, -- Storage the Real Password
        c_reg4  -- Storage the Comparation result
        )
    begin
        -- Keep values
        n_reg0 <=  x"0000" & c_key_value;
        n_reg1 <= c_reg1;
        n_reg2 <= c_reg2;
        n_reg3 <= c_reg3;
        n_reg4 <= c_reg4;

        if (c_reg2(7 downto 0) = x"10") then -- New Password
            n_reg2 <= (others => '0');
            n_reg3 <= c_reg1; 
        end if;

        wb_dat_o <= c_reg0;
        -- Default ack is inactive
        wb_ack_o <= '0';

        -- Is the peripheral selected?
        if (wb_cyc_i = '1') and (wb_stb_i = '1') and (access_req = '1') then

            -- Write access, only full-word accesses
            if (wb_we_i = '1' and wb_sel_i = "1111") then
                case to_integer(unsigned(wb_adr_i(index_size_f(WB_ADDR_SIZE)-1 downto 2))) is
                    when 0 =>
                        n_reg0 <= wb_dat_i; 
                    when 1 =>
                        n_reg1 <= wb_dat_i;
                    when 2 =>
                        n_reg2 <= wb_dat_i;
                    when 3 =>
                        n_reg3 <= wb_dat_i;
                    when 4 =>
                        n_reg4 <= wb_dat_i;
                    when others =>
                        null;
                end case;
                wb_ack_o <= '1';
            else
            -- Read access
                case to_integer(unsigned(wb_adr_i(index_size_f(WB_ADDR_SIZE)-1 downto 2))) is
                    when 0 =>
                        wb_dat_o <= c_reg0;
                    when 1 =>
                        wb_dat_o <= c_reg1;
                    when 2 =>
                        wb_dat_o <= c_reg2;
                    when 3 =>
                        wb_dat_o <= c_reg3;
                    when 4 =>
                        wb_dat_o <= c_reg4;
                    when others =>
                        null;
                end case;
                wb_ack_o <= '1';
            end if;

        end if;

    end process;

    
    -------------------------------------------------------
    -- COMPARE THE PASSWORD                             ---
    -------------------------------------------------------
    wb_peripheral_teclado_Compare_password_comb: process(
        c_reg1, 
        c_reg2,
        c_reg3, 
        c_Password_result
        )
    begin   

        n_Password_result <= c_Password_result;
                        
            if (c_reg2(0) = '1') then  -- Command "A"
                if ((c_reg1(7 downto 0) xnor c_reg3(7 downto 0)) = "11111111") then
                    n_Password_result <= c_Password_result(3 downto 1) & "1";
                end if;
            end if;

            if (c_reg2(1) = '1') then -- Command "B"
                if ((c_reg1(15 downto 8) xnor c_reg3(15 downto 8)) = "11111111") then
                    n_Password_result <= c_Password_result(3 downto 2) & "1" & c_Password_result(0);
                end if;
            end if;

            if (c_reg2(2) = '1') then  -- Command "C"
                if ((c_reg1(23 downto 16) xnor c_reg3(23 downto 16)) = "11111111") then
                    n_Password_result <= c_Password_result(3) & "1" & c_Password_result(1 downto 0);
                end if;
            end if;

           if (c_reg2(3) = '1') then -- Command "D"
                if ((c_reg1(31 downto 24) xnor c_reg3(31 downto 24)) = "11111111") then
                    n_Password_result <= "1" & c_Password_result(2 downto 0);
                end if;
            end if;


    end process;

  -------------------------------------------------------
  -- Errors can not happen in this module             ---
  -------------------------------------------------------
  wb_err_o <= '0';

end architecture;