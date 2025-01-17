library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Contador_4Hr is
    port (
        CLK: in STD_LOGIC;
        reset_4Hrs: in STD_LOGIC;
        hours4H: out INTEGER range 0 to 4;
        minutes4H: out INTEGER range 0 to 59;
        seconds4H: out INTEGER range 0 to 59;
        Pout: out STD_LOGIC
    );
end Contador_4Hr;

architecture rtl of Contador_4Hr is
    constant max_count: INTEGER := 30000;
    signal count: INTEGER range 0 to max_count := 0;
    signal one_hz_clk: STD_LOGIC := '0';

    signal sec_count: INTEGER range 0 to 59 := 0;
    signal min_count: INTEGER range 0 to 59 := 0;
    signal hour_count: INTEGER range 0 to 4 := 0;
    
    signal Pout_signal: STD_LOGIC := '0'; -- Señal interna para Pout

begin
    -- Generate 1 Hz clock from 50 MHz clock
    gen_clock: process(CLK)
    begin
        if rising_edge(CLK) then
            if count < max_count - 1 then 
                count <= count + 1;
            else
                count <= 0;
                one_hz_clk <= not one_hz_clk;
            end if;
        end if;
    end process;

    -- Counter process
    count_seconds: process(one_hz_clk, reset_4Hrs)
    begin
        if reset_4Hrs = '1' then
            sec_count <= 0;
            min_count <= 0;
            hour_count <= 0;
            Pout_signal <= '0'; -- Resetear Pout_signal
        elsif rising_edge(one_hz_clk) then
            if sec_count < 59 then
                sec_count <= sec_count + 1;
            else
                sec_count <= 0;
                if min_count < 59 then
                    min_count <= min_count + 1;
                else
                    min_count <= 0;
                    if hour_count < 4 then
                        hour_count <= hour_count + 1;
                    else
                        hour_count <= 0; -- Resetear contador de horas
                    end if;
                end if;
            end if;

            -- Activar Pout_signal cuando hour_count alcance 4
            if hour_count = 4 then
                Pout_signal <= '1';
            else
                Pout_signal <= '0';
            end if;
        end if;
    end process;

    -- Output assignments
    hours4H <= hour_count;
    minutes4H <= min_count;
    seconds4H <= sec_count;
    Pout <= Pout_signal; -- Asignar la señal interna a la salida

end rtl;
