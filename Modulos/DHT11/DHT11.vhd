library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DHT11 is

GENERIC ( CLK_FPGA : INTEGER := 50_000_000 ); -- Valor de la frecuencia de reloj en Hertz.

PORT( CLK 	 		: IN  	STD_LOGIC;							-- Reloj del FPGA.
	   ResetDHT11  : IN  	STD_LOGIC;							-- Resetea el proceso de adquisicion, el reset es asincrono y activo en alto.
	   ENABLE 		: IN 	STD_LOGIC:= '1';-- Habilitador, inicia el proceso de adquisicion cuando se pone a '1'.
	   DATA 	 		: INOUT STD_LOGIC;							-- Puerto bidireccional de datos.
	   ERROR  		: OUT 	STD_LOGIC;							-- Bit que indica si hubo algun error al verificar el Checksum.
	   RH 	 		: OUT 	STD_LOGIC_VECTOR(7 DOWNTO 0);	-- Valor de la humedad relativa.
	   TEMP 	 		: OUT 	STD_LOGIC_VECTOR(7 DOWNTO 0); -- Valor de la temperatura.
	   FIN 	 		: OUT 	STD_LOGIC							-- Bit que indica fin de adquisicion.
	 );
	  
end DHT11;

architecture Behavioral of DHT11 is

CONSTANT MAX_CONTA	: INTEGER := CLK_FPGA*2;	  -- Define el valor maximo de "cont" para un retardo de 2 segundos.
CONSTANT MAX_RANGO	: INTEGER := CLK_FPGA - 1;   -- Define el valor maximo de "cont2".
CONSTANT MAX_18MS		: INTEGER := CLK_FPGA/55; 	  -- Constante para retardo de 18ms.
CONSTANT RANGO_1		: INTEGER := CLK_FPGA/13888; -- Constante para definir el rango minimo para determinar si se registro un '0' o '1' logico.
CONSTANT RANGO_2		: INTEGER := CLK_FPGA/12500; -- Constante para definir el rango maximo para determinar si se registro un '0' o '1' logico.

signal enable_cont	: std_logic := '0';											 -- Bandera que habilita el proceso del contador "cont".
signal flanco_bajada : std_logic := '0';											 -- Bandera que indica cuando se ha detectado un flanco de bajada.
signal reg			   : std_logic_vector(3  downto 0) := (others => '0'); -- Registro para la deteccion de flancos.
signal reg_total 		: std_logic_vector(39 downto 0) := (others => '0'); -- Registro donde se almacenan los 40 bits de informacion que manda el sensor DHT11.
signal sum 				: std_logic_vector(7  downto 0) := (others => '0'); -- Señal que almacena el resultado de la sumatoria para el Checksum.
signal cont	 			: integer range 0 to MAX_CONTA := 0;					 -- Contador para diferentes retardos.
signal cont2 			: integer range 0 to MAX_RANGO := 0;					 -- Señal que guarda el tiempo de duracion en '0' para determinar si se recibio un '0' o '1'.
signal estados			: integer range 0 to 15 := 0;								 -- Señal para maquina de estados.
signal i 				: integer range 0 to 40 := 40;							 -- Señal que indica el bit que se almacenara en "reg_total".

begin


-- Proceso que inicia el conteo cuando se active "enable_cont" --
process(CLK)
begin
	if rising_edge(CLK) then
		if(enable_cont = '1') then
			cont <= cont + 1;
		else 
			cont <= 0;
		end if;
	end if;
end process;		


-- Proceso que se encarga de la adquisicion de datos --
process(CLK, ResetDHT11)
begin

if ResetDHT11 = '1' then -- Resetea la maquina de estados.
	estados <= 0;
		
elsif rising_edge(clk) then	
	
	case estados is
		when 0 => -- Espera a que este activo "enable" para iniciar el proceso de adquisicion.
			DATA <= 'Z';
			fin <= '0';
			ERROR <= '0';
			if ENABLE = '1' then
				estados <= 1;
			else
				estados <= 0;
			end if;
			fin <= '0';
			
		when 1 => -- Tiempo de espera de 18 milisegundos necesarios segun las especificaciones de la tarjeta con un '0' en "DATA".
			DATA <= '0';
			enable_cont <= '1';
			if(cont = MAX_18MS) then 
				enable_cont <= '0';
				estados <= 2;
			else
				estados <= 1;
			end if;
		
		
		when 2 => -- Se pone el puerto "DATA" en alta impedancia.
			DATA <= 'Z';
			if DATA = '0' then
				estados <= 3;
			else
				estados <= 2;
			end if;
			
		when 3 => -- Espera a que el sensor responda con un flanco de bajada y despuus vuelve a mandar un '1'.
			if flanco_bajada = '1' then
				estados <= 4;
			else
				estados <= 3;
			end if;
				
		when 4 => -- Espera los flancos de bacada de cada uno de los bits a reconocer.
			enable_cont <= '1';
			if flanco_bajada = '1' then
				cont2 <= cont;
				estados <= 5;
				enable_cont <= '0';
			else
				estados <= 4;
			end if;
		when 5 => -- Compara los tiempos de adquisicion para definir si es un '0' o '1' logico y se almacenan en "reg_total".
			if cont2 > RANGO_1 and cont2 < RANGO_2 then
				reg_total(i) <= '0';
					i <= i-1;
				if i = 0 then
					estados <= 6;
					i <= 40;
				else
					estados <= 4;
				end if;
			else
				reg_total(i) <= '1';
				i <= i-1;
				if i = 0 then
					estados <= 6;
					i <= 40;
				else
					estados <= 4;
				end if;
			end if;
			
		when 6 => -- Realiza la sumatoria de los datos para verificar el Checksum segun las especificaciones del sensor.
			sum <= reg_total(39 downto 32) + reg_total(31 downto 24) + reg_total(23 downto 16) +  reg_total(15 downto 8);
			estados <= 7;
			
		when 7 => -- Se compara el Checksum con el valor de "sum", si es igual la trasnferencia fue exitosa y se mandan los valores por "RH" y "TEMP" sino se manda error y se debera resetear el proceso.
			if sum = reg_total(7 downto 0) then
				rh <= reg_total(39 downto 32);
				temp <= reg_total(23 downto 16);
				estados <= 8;
			else
				estados <= 12; 
			end if;
		
		when 8 => -- Tiempo de espera de 2 segundos para la proxima adquisicion.
			enable_cont <= '1';
			if(cont = MAX_CONTA) then
				enable_cont <= '0';
				estados <= 9;
			else	
				estados <= 8;
			end if;
			
		when 9 => -- Se activa la bandera "FIN".
			FIN <= '1';
			estados <= 10;

		when 10 => -- Se desactiva la bandera "FIN".
			fin <= '0';
			estados <= 11;
		
		when 11 => -- Estado dummy.
			estados <= 0;

		when OTHERS => -- Se manda el error en caso de que el Checksum no coincida.
			ERROR <= '1';
			
	end case;
end if;
end process;
			

--Proceso que hace la deteccion de flancos mediante un registro de corrimiento.
process(CLK)
begin
	if rising_edge(CLK) then
		reg <= reg(2 downto 0)&DATA;
		if reg = "1100" then
			flanco_bajada <= '1';
		else
			flanco_bajada <= '0';
		end if;
	end if;
end process;
			
end Behavioral;
