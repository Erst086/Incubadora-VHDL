library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_C is
    Port (
        CLK : in STD_LOGIC;
        ResetPwm : in STD_LOGIC;
        Velocidad : in INTEGER range 0 to 700; -- Ajustado para una frecuencia de 14Hz
        Salida_PWM : out STD_LOGIC
    );
end PWM_C;

architecture Behavioral of PWM_C is
    signal counter : integer range 0 to 700 := 0; -- Ajustado para una frecuencia de 14Hz
    signal pwm : STD_LOGIC := '0';
begin
    process(CLK, ResetPwm)
    begin
        if ResetPwm = '1' then
            counter <= 0;
            pwm <= '0';
        elsif rising_edge(CLK) then
            if counter < Velocidad  then
                pwm <= '1';
            else
                pwm <= '0';
            end if;
            if counter = 700 then -- Ajustado para una frecuencia de 14Hz
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    Salida_PWM <= pwm;
end Behavioral;

