library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Humificador is
    Port ( CLK    : in  STD_LOGIC;
           resetHm    : in  STD_LOGIC;
           Up     : in  STD_LOGIC;
           Down   : in  STD_LOGIC;
           HmOut  : out STD_LOGIC);
end Humificador;

architecture Behavioral of Humificador is
    signal counter        : integer := 0;
    signal state          : integer := 0;
    signal down_activated : STD_LOGIC := '0';
    signal down_prev      : STD_LOGIC := '0';
    constant HALF_SECOND  : integer := 25000000; -- 50MHz clock, half-second delay

begin
    process(CLK, resetHm)
    begin
        if rising_edge(CLK) then
            if resetHm = '1' then
                HmOut <= '1';
                counter <= 0;
                state <= 0;
                down_activated <= '0';
                down_prev <= '0';
            else
                if Up = '1' then
                    HmOut <= '0';
                elsif Down = '1' and down_prev = '0' then
                    -- Detect rising edge of Down
                    down_activated <= '1';
                    counter <= 0;
                    state <= 0;
                end if;

                if down_activated = '1' then
                    if counter < HALF_SECOND then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        case state is
                            when 0 =>
                                HmOut <= '0';
                                state <= 1;
                            when 1 =>
                                HmOut <= '1';
                                state <= 2;
                            when 2 =>
                                HmOut <= '0';
                                state <= 3;
                            when 3 =>
                                HmOut <= '1';
                                state <= 4;
                            when 4 =>
                                HmOut <= '0';
                                state <= 5;
                            when 5 =>
                                HmOut <= '1';
                                state <= 6;
                                down_activated <= '0'; -- Complete the cycle
                            when others =>
                                state <= 0;
                        end case;
                    end if;
                elsif Up /= '1' then
                    HmOut <= '1';
                end if;

                down_prev <= Down; -- Update the previous state of Down
            end if;
        end if;
    end process;
end Behavioral;
