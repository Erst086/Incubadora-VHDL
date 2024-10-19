library IEEE; -- Biblioteca estándar IEEE para el diseño de hardware.
use IEEE.STD_LOGIC_1164.ALL; -- Paquete para la lógica estándar en VHDL.
use IEEE.STD_LOGIC_ARITH.ALL; -- Paquete para operaciones aritméticas con lógica estándar.
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- Paquete para operaciones sin signo con lógica estándar.

entity dias_contador is
    port (
        CLK: in STD_LOGIC; -- Señal de reloj de entrada.
        resetDYS: in STD_LOGIC; -- Señal de reinicio.
        days: out INTEGER range 0 to 25; -- Salida de días con rango de 0 a 26.
        hours: out INTEGER range 0 to 23; -- Salida de horas con rango de 0 a 23.
        minutes: out INTEGER range 0 to 59; -- Salida de minutos con rango de 0 a 59.
        seconds: out INTEGER range 0 to 59 -- Salida de segundos con rango de 0 a 59.
    );
end dias_contador;

architecture rtl of dias_contador is
    constant max_count: INTEGER := 1000; -- Contador máximo.
    signal count: INTEGER range 0 to max_count := 0; -- Señal de conteo con rango de 0 a max_count.
    signal clk_state: STD_LOGIC := '0'; -- Estado del reloj.
    signal one_hz_clk: STD_LOGIC := '0'; -- Reloj ya que ocupa para contar en Hz.

    signal sec_count: INTEGER range 0 to 59 := 0; -- Contador de segundos.
    signal min_count: INTEGER range 0 to 59 := 0; -- Contador de minutos.
    signal hour_count: INTEGER range 0 to 23 := 0; -- Contador de horas.
    signal day_count: INTEGER range 0 to 25 := 0; -- Contador de días.

begin
    -- Generar un reloj de 1 Hz desde el reloj de 50 MHz.
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
-- Proceso de contador.
count_seconds: process(one_hz_clk, resetDYS)
begin
    if resetDYS = '1' then
        sec_count <= 0;
        min_count <= 0;
        hour_count <= 0;
        day_count <= 0; -- Reiniciar también el contador de días
    elsif rising_edge(one_hz_clk) then
        if day_count < 26 then
            if sec_count < 59 then
                sec_count <= sec_count + 1;
            else
                sec_count <= 0;
                if min_count < 59 then
                    min_count <= min_count + 1;
                else
                    min_count <= 0;
                    if hour_count < 23 then
                        hour_count <= hour_count + 1;
                    else
                        hour_count <= 0;
                        day_count <= day_count + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;
    -- Asignaciones de salida.
    days <= day_count;
    hours <= hour_count;
    minutes <= min_count;
    seconds <= sec_count;

end rtl;

