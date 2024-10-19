library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TimerMR is
    generic (
        ACTIVATION_TIME_SEC : integer := 10 -- Tiempo de activación predeterminado en segundos
    );
    Port (
        CLK : in STD_LOGIC;
        reset_Mtr : IN 	STD_LOGIC;
        pulso : in STD_LOGIC;
        mtr2 : out STD_LOGIC
    );
end TimerMR;

architecture Behavioral of TimerMR is
    constant CLOCK_FREQ : integer := 50000000; -- Frecuencia del reloj (50 MHz en este ejemplo)
    constant COUNT_MAX : integer := CLOCK_FREQ * ACTIVATION_TIME_SEC; -- Valor máximo de counter
    
    signal counter : integer range 0 to COUNT_MAX := 0;
    signal active : STD_LOGIC := '0';---------------------
    signal pulso_last : STD_LOGIC := '0';
	 --signal reset_Mtr : STD_LOGIC := '0';
begin
    process(CLK, reset_Mtr)
    begin
        if reset_Mtr = '1' then
            counter <= 0;
            active <= '1';---------------------
        elsif rising_edge(CLK) then
            if (pulso = '1' and pulso_last = '0') or (pulso = '0' and pulso_last = '1') then -- Detecta flanco de subida en pulso
                active <= '0';-------------------
                counter <= 0;
            end if;
            
            if active = '0' then
                if counter = COUNT_MAX then
                    active <= '1';---------------  -- nota la logica en los active es inversa por el modulo de relevador se activa con un 0
                else
                    counter <= counter + 1;
                end if;
            end if;
            
            pulso_last <= pulso; -- Almacena el estado anterior de pulso
        end if;
    end process;

    mtr2 <= active;
end Behavioral;
