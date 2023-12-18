
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;


entity wb_7segmentDisplay is
  generic(
    WB_ADDR_BASE        : std_ulogic_vector(31 downto 0) := x"90000020";
    WB_ADDR_SIZE        : integer := 16
  );
      -- Top-level ports. Board pins are defined in setups/osflow/constraints/iCEBreaker.pcf
  port (
    -- 12MHz Clock input
    clk_i                : in std_ulogic;
    reset_i              : in std_ulogic;

    -- Wishbone Comunication
    wb_tag_i             : in   std_ulogic_vector(02 downto 0);
    wb_adr_i             : in   std_ulogic_vector(31 downto 0); 
    wb_dat_i             : in   std_ulogic_vector(31 downto 0);
    wb_dat_o             : out  std_ulogic_vector(31 downto 0);
    wb_we_i              : in   std_ulogic;
    wb_sel_i             : in   std_ulogic_vector(03 downto 0);
    wb_stb_i             : in   std_ulogic;
    wb_cyc_i             : in   std_ulogic; 
    wb_lock_i            : in   std_ulogic;
    wb_ack_o             : out  std_ulogic;
    wb_err_o             : out  std_ulogic;

    -- 7 Segment Dislay
    aa_o                 : out  std_logic;
    ab_o                 : out  std_logic;
    ac_o                 : out  std_logic;
    ad_o                 : out  std_logic;
    ae_o                 : out  std_logic;
    af_o                 : out  std_logic;
    ag_o                 : out  std_logic;
    ds_o                 : out  std_logic


    );
end entity;

architecture wb_7segmentDisplay_rtl of wb_7segmentDisplay is


    type state_t is(
		IDLE,
		WB_WRITE_REG,
		END_TX
		);

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

    signal c_ds             : std_ulogic;
    signal n_ds             : std_ulogic;

    signal c_counter        : unsigned (16 downto 0);
    signal n_counter        : unsigned (16 downto 0);

    signal s_decod_num     : std_logic_vector(6 downto 0);
    signal s_num           : std_logic_vector(11 downto 0);

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
    
    ds_o    <= c_ds;

    -------------------------------------------------------
    -- Sinc processs                                    ---
    -------------------------------------------------------
    peripheral_teclado_sinc: process(clk_i, reset_i)
    begin
        if (reset_i = '1') then
            c_counter   <= (others => '0');
            c_reg0      <= (others => '0');
            c_reg1      <= (others => '0');
            c_reg2      <= (others => '0');
            c_ds        <= '0';

        elsif ( rising_edge(clk_i)) then
            c_counter   <= n_counter;
            c_reg0      <= n_reg0; -- Storage the tens
            c_reg1      <= n_reg1; -- Storage the hundreds
            c_reg2      <= n_reg2; -- Storage the controls signals
            c_ds        <= n_ds;

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
        c_reg0, -- Storage the tens
        c_reg1, -- Storage the hundreds
        c_reg2  -- Storage the Control signal
        )
    begin
        -- Keep values
        n_reg0 <= c_reg0;
        n_reg1 <= c_reg1;
        n_reg2 <= c_reg2;

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
                    when others =>
                        null;
                end case;
                wb_ack_o <= '1';
            end if;

        end if;

    end process;

    -------------------------------------------------------
    -- 7 segment display                                ---
    -------------------------------------------------------

    wb_7segmentDisplay_comb: process(c_counter)
    begin
        -- Counter
        n_counter   <= c_counter + 1;

        -- Digit Select
        n_ds        <= c_ds;
        if (c_counter = x"10000") then
            n_ds        <= not(c_ds); -- 183 Hz 
            n_counter   <= (others => '0'); 
            -- 12 MHz / 0x10000 = 12MHz / 65.536 = 183 Hz
        end if;

        -- Display
        aa_o        <= '0';
        ab_o        <= '0';
        ac_o        <= '0';
        ad_o        <= '0';
        ae_o        <= '0';
        af_o        <= '0';
        ag_o        <= '0';


        case(to_integer(unsigned(c_reg2(1 downto 0)))) is
            when 0 => -- Represent:  --
                ag_o    <= '1';

            when others => -- Represent the number

                aa_o        <= s_decod_num(6);
                ab_o        <= s_decod_num(5);
                ac_o        <= s_decod_num(4);
                ad_o        <= s_decod_num(3);
                ae_o        <= s_decod_num(2);
                af_o        <= s_decod_num(1);
                ag_o        <= s_decod_num(0);

        end case;

    end process;
 
    -------------------------------------------------------
    -- Decode number                                    ---
    -------------------------------------------------------

    WITH (c_ds) SELECT
    s_num           <= std_logic_vector(c_reg0(11 downto 0)) when '0',
                       std_logic_vector(c_reg1(11 downto 0)) when others;


    WITH (s_num) SELECT
    s_decod_num    <=   "1111110" when x"000", -- 0
                        "0000110" when x"001", -- 1
                        "1101101" when x"002", -- 2
                        "1001111" when x"004", -- 3
                        "0010111" when x"008", -- 4
                        "1011011" when x"010", -- 5
                        "1111011" when x"020", -- 6
                        "0001110" when x"040", -- 7
                        "1111111" when x"080", -- 8
                        "0011111" when x"100", -- 9
                        "0111110" when x"200", -- N
                        "0111101" when others; -- P



  -------------------------------------------------------
  -- Errors can not happen in this module             ---
  -------------------------------------------------------
  wb_err_o <= '0';

end architecture;