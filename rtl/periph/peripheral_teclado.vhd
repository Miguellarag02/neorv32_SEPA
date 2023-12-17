
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peripheral_teclado is
  port (
    -- 12MHz Clock input
    clk_i                : in std_logic;
    reset_i              : in std_logic;

    -- Rows
    en_i                 : in std_logic;
    Row_1_i              : in std_logic;
    Row_2_i              : in std_logic;
    Row_3_i              : in std_logic;
    Row_4_i              : in std_logic;
    
    -- Cols
    Col_1_o              : out std_logic;
    Col_2_o              : out std_logic;
    Col_3_o              : out std_logic;
    Col_4_o              : out std_logic;

    -- Key codificated in One Hot
    Key_o     : out std_logic_vector(15 downto 0)

    );
end entity;

architecture peripheral_rtl of peripheral_teclado is

    -- SIGNALS

    signal c_counter : unsigned (1 downto 0);
    signal n_counter : unsigned (1 downto 0);

    signal c_key_value    : std_logic_vector(15 downto 0);
    signal n_key_value    : std_logic_vector(15 downto 0);

    signal c_key     : std_logic_vector(15 downto 0);
    signal n_key     : std_logic_vector(15 downto 0);

    signal c_col     : std_logic_vector(3 downto 0);
    signal n_col     : std_logic_vector(3 downto 0);

    signal s_row     : std_logic_vector(3 downto 0);

    begin

    -------------------------------------------------------
    -- Concurrents Outputs                              ---
    -------------------------------------------------------
    Col_1_o <= c_col(0);
    Col_2_o <= c_col(1);
    Col_3_o <= c_col(2);
    Col_4_o <= c_col(3);
    
    s_row   <= Row_4_i &
               Row_3_i &
               Row_2_i &
               Row_1_i;

    Key_o   <= c_key_value;   

    peripheral_teclado_sinc: process(clk_i, reset_i)
    begin
        if (reset_i = '1') then
            c_counter   <=  (others => '0');
            c_col       <= (others => '0');   
            c_key       <= (others => '0');
            c_key_value <= (others => '0'); 

        elsif ( rising_edge(clk_i)) then
            c_counter   <= n_counter;
            c_col       <= n_col;
            c_key       <= n_key;
            c_key_value <= n_key_value;

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

end architecture;