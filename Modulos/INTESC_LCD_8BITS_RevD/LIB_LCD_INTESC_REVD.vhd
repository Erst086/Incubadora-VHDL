library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE WORK.COMANDOS_LCD_REVD.ALL;

entity LIB_LCD_INTESC_REVD is

GENERIC(
			FPGA_CLK : INTEGER := 50_000_000
);


PORT(CLK: IN STD_LOGIC;

-----------------------------------------------------
------------------PUERTOS DE LA LCD------------------
	  RS 		  : OUT STD_LOGIC;							--
	  RW		  : OUT STD_LOGIC;							--
	  ENA 	  : OUT STD_LOGIC;							--
	  DATA_LCD : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  --
-----------------------------------------------------
----Entradas u salidas de los modulos----------------
	  Start		  : in STD_LOGIC;		
	  DATA 	 	  : INOUT STD_LOGIC;
     Salida_PWM : out STD_LOGIC;
	  mtr2 		  : out STD_LOGIC;
	  HmOut 		  : out STD_LOGIC;
	  HmOutTemp  : out STD_LOGIC
-----------------------------------------------------
	  
	  
-----------------------------------------------------------
--------------ABAJO ESCRIBE TUS PUERTOS--------------------	
	 	
-----------------------------------------------------------
-----------------------------------------------------------

	  );

end LIB_LCD_INTESC_REVD;

architecture Behavioral of LIB_LCD_INTESC_REVD is


CONSTANT NUM_INSTRUCCIONES : INTEGER := 40; 	--INDICAR EL N�MERO DE INSTRUCCIONES PARA LA LCD
constant ACTIVATION_TIME_SEC : integer := 30;

--------------------------------------------------------------------------------
-------------------------SE�ALES DE LA LCD (NO BORRAR)--------------------------
																										--
component PROCESADOR_LCD_REVD is																--
																										--
GENERIC(																								--
			FPGA_CLK : INTEGER := 50_000_000;												--
			NUM_INST : INTEGER := 1																--
);																										--
																										--
PORT( CLK 				 : IN  STD_LOGIC;														--
	   VECTOR_MEM 		 : IN  STD_LOGIC_VECTOR(8  DOWNTO 0);							--
	   C1A,C2A,C3A,C4A : IN  STD_LOGIC_VECTOR(39 DOWNTO 0);							--
	   C5A,C6A,C7A,C8A : IN  STD_LOGIC_VECTOR(39 DOWNTO 0);							--
	   RS 				 : OUT STD_LOGIC;														--
	   RW 				 : OUT STD_LOGIC;														--
	   ENA 				 : OUT STD_LOGIC;														--
	   BD_LCD 			 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);			         	--
	   DATA 				 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);							--
	   DIR_MEM 			 : OUT INTEGER RANGE 0 TO NUM_INSTRUCCIONES					--
	);																									--
																										--
end component PROCESADOR_LCD_REVD;															--
																										--
COMPONENT CARACTERES_ESPECIALES_REVD is													--
																										--
PORT( C1,C2,C3,C4 : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);								--
		C5,C6,C7,C8 : OUT STD_LOGIC_VECTOR(39 DOWNTO 0)									--
	 );																								--
																										--
end COMPONENT CARACTERES_ESPECIALES_REVD;													--
																										--
CONSTANT CHAR1 : INTEGER := 1;																--
CONSTANT CHAR2 : INTEGER := 2;																--
CONSTANT CHAR3 : INTEGER := 3;																--
CONSTANT CHAR4 : INTEGER := 4;																--
CONSTANT CHAR5 : INTEGER := 5;																--
CONSTANT CHAR6 : INTEGER := 6;																--
CONSTANT CHAR7 : INTEGER := 7;																--
CONSTANT CHAR8 : INTEGER := 8;																--
																										--
type ram is array (0 to  NUM_INSTRUCCIONES) of std_logic_vector(8 downto 0); 	--
signal INST : ram := (others => (others => '0'));										--
																										--
signal blcd 			  : std_logic_vector(7 downto 0):= (others => '0');		--																										
signal vector_mem 	  : STD_LOGIC_VECTOR(8  DOWNTO 0) := (others => '0');		--
signal c1s,c2s,c3s,c4s : std_logic_vector(39 downto 0) := (others => '0');		--
signal c5s,c6s,c7s,c8s : std_logic_vector(39 downto 0) := (others => '0'); 	--
signal dir_mem 		  : integer range 0 to NUM_INSTRUCCIONES := 0;				--
																										--
--------------------------------------------------------------------------------

-------------------------Componentes de los modulos-----------------------------
--------------------------------------------------------------------------------
--  Contador de dias 
component dias_contador
        Port (
            CLK      : in STD_LOGIC;
            resetDYS : in STD_LOGIC;
            days     : out INTEGER range 0 to 25;
            hours    : out INTEGER range 0 to 23;
            minutes  : out INTEGER range 0 to 59;
            seconds  : out INTEGER range 0 to 59
        );
end component;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  DHT11
component DHT11 is

generic ( CLK_FPGA : INTEGER := 50_000_000 ); -- Valor de la frecuencia de reloj en Hertz.

port( CLK 		  : IN  	 STD_LOGIC;							-- Reloj del FPGA
	   DATA 	 	  : INOUT STD_LOGIC;							-- Puerto bidireccional de datos.
		ResetDHT11 : IN    STD_LOGIC;
	   RH 		  : OUT 	 STD_LOGIC_VECTOR(7 DOWNTO 0);	-- Valor de la humedad relativa.
	   TEMP 	 	  : OUT 	 STD_LOGIC_VECTOR(7 DOWNTO 0) -- Valor de la temperatura
	 );
end component DHT11;
--------------------------------------------------------------------------------
component Contador_4Hr is
        port (
            CLK: in STD_LOGIC;
            reset_4Hrs: in STD_LOGIC;
            hours4H: out INTEGER range 0 to 4;
            minutes4H: out INTEGER range 0 to 59;
            seconds4H: out INTEGER range 0 to 59;
            Pout: out STD_LOGIC
        );
end component Contador_4Hr;
--------------------------------------------------------------------------------
component TimerMR is
        generic (
            ACTIVATION_TIME_SEC : integer := 30
        );
        Port (
            CLK : in STD_LOGIC;
            reset_Mtr : IN 	STD_LOGIC;
            pulso : in STD_LOGIC;
            mtr2 : out STD_LOGIC
        );
end component;
--------------------------------------------------------------------------------
component PWM_C is
        Port (
            CLK : in STD_LOGIC;
			ResetPwm : in STD_LOGIC;
			Velocidad : in INTEGER range 0 to 700; -- Ajustado para una frecuencia de 14Hz
			Salida_PWM : out STD_LOGIC
		);
end component;
--------------------------------------------------------------------------------
component Humificador is
    Port (
        CLK    : in  STD_LOGIC;
        resetHm    : in  STD_LOGIC;
        Up     : in  STD_LOGIC;
        Down   : in  STD_LOGIC;
        HmOut  : out STD_LOGIC
    );
end component;

------------------Señales del modulo--------------------------------------------
--------------------------------------------------------------------------------

-------Contador dias-----------------------------------
signal days : INTEGER range 0 to 25;
signal hours : INTEGER range 0 to 23;
signal minutes : INTEGER range 0 to 59;
signal seconds : INTEGER range 0 to 59;
    -- Señales para la conversion
signal DiasD, DiasU: INTEGER range 0 to 9;
signal HorasD, HorasU: INTEGER range 0 to 9;
signal MinutosD, MinutosU: INTEGER range 0 to 9;
signal SegundosD, SegundosU: INTEGER range 0 to 9;

--------------------------------------------------------------------------------

	 -- Señales DHT1
signal RH : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal TEMP : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal HumD,HumU :INTEGER RANGE 0 TO 9 :=0; 
signal TempD,TempU :INTEGER RANGE 0 TO 9 :=0;   

signal RH_int 	 : INTEGER RANGE 0 TO 999;
signal TEMP_int : INTEGER RANGE 0 TO 999;

--------------------------------------------------------------------------------
	-- Señales contador 4 horas
signal hours4H: INTEGER range 0 to 4;
signal minutes4H: INTEGER range 0 to 59;
signal seconds4H: INTEGER range 0 to 59;
signal pulso : STD_LOGIC;
--------------------------------------------------------------------------------
signal pwm : STD_LOGIC;
signal Velocidad : INTEGER range 0 to 700 := 100;
------------------------------------------------------------------------------
signal UP : STD_LOGIC;
signal Down : STD_LOGIC;
------------------------------------------------------------------------------
------------------------------------------------------------------------------
signal resetDYS 	: STD_LOGIC;
signal ResetDHT11 : STD_LOGIC;
signal reset_4Hrs : STD_LOGIC;
signal ResetPwm   : STD_LOGIC;
signal reset_Mtr	: STD_LOGIC;
signal resetHm 	: STD_LOGIC;
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
begin
----------Procesos de los modulos-----------------------------------------------
--------------------------------------------------------------------------------

	 -- Contador dias 
    process(days, hours, minutes, seconds)-- Calcula decenas unidades
    begin
        DiasD <= days / 10;
        DiasU <= days mod 10;

        HorasD <= hours / 10;
        HorasU <= hours mod 10;

        MinutosD <= minutes / 10;
        MinutosU <= minutes mod 10;

        SegundosD <= seconds / 10;
        SegundosU <= seconds mod 10;
    end process;
	 
--------------------------------------------------------------------------------
	 process(RH, TEMP) -- proceso tranforma el vector a enteros
		 begin
			RH_int	<= to_integer(unsigned(RH));
			TEMP_int <= to_integer(unsigned(TEMP));
	 end process;
	 -----------------------------------------------
    process(RH_int, TEMP_int)-- Calcula decenas unidades
    begin
        TempD  <= TEMP_int / 10;
        TempU  <= TEMP_int mod 10;
        HumD   <= RH_int / 10;
        HumU   <= RH_int mod 10;
    end process;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	 
process(Start, days)
begin
    if Start = '1' then
        resetDYS <= '0';
        ResetDHT11 <= '0';
        reset_4Hrs <= '0';
        ResetPwm <= '0';
        reset_Mtr <= '0';
        resetHm <= '0';
    elsif days = 26 then
        resetDYS <= '1';
        ResetDHT11 <= '1';
        reset_4Hrs <= '1';
        ResetPwm <= '1';
        reset_Mtr <= '1';
        resetHm <= '1';
    else
        resetDYS <= '1';
        ResetDHT11 <= '1';
        reset_4Hrs <= '1';
        ResetPwm <= '1';
        reset_Mtr <= '1';
        resetHm <= '1';
    end if;

    if days >= 18 then
        reset_4Hrs <= '1';
        reset_Mtr <= '1';
    end if;
end process;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

---------------------------------------------------------------
-------------------COMPONENTES PARA LCD------------------------
																				 --
u1: PROCESADOR_LCD_REVD													 --
GENERIC map( FPGA_CLK => FPGA_CLK,									 --
				 NUM_INST => NUM_INSTRUCCIONES )						 --
																				 --
PORT map( CLK,VECTOR_MEM,C1S,C2S,C3S,C4S,C5S,C6S,C7S,C8S,RS, --
			 RW,ENA,BLCD,DATA_LCD, DIR_MEM );						 --
																				 --
U2 : CARACTERES_ESPECIALES_REVD 										 --
PORT MAP( C1S,C2S,C3S,C4S,C5S,C6S,C7S,C8S );				 		 --
																				 --
VECTOR_MEM <= INST(DIR_MEM);											 --
																				 --
---------------------------------------------------------------
---------------------------------------------------------------
-------------------------Componentes de los modulos-----------------------------
--------------------------------------------------------------------------------
u3: dias_contador
        Port map(
           CLK 			=> CLK,
           resetDYS 		=> resetDYS,
           days 			=> days,
           hours			=> hours,
           minutes 		=> minutes,
           seconds 		=> seconds
        );
--------------------------------------------------------------------------------
U4 : DHT11 
		  port map(
			  CLK 			=> CLK,
			  DATA 			=> DATA,
			  ResetDHT11 	=> ResetDHT11,
			  RH 				=> RH,
			  TEMP 			=> TEMP
		  );
--------------------------------------------------------------------------------
U5: Contador_4Hr 
		   port map (
				CLK => CLK,
				reset_4Hrs => reset_4Hrs,
				hours4H => hours4H,
				minutes4H => minutes4H,
				seconds4H => seconds4H,
				Pout => Pulso
		  );
--------------------------------------------------------------------------------
U6: TimerMR generic map (ACTIVATION_TIME_SEC => ACTIVATION_TIME_SEC) 
			port map (
				CLK 			=> CLK,
				reset_Mtr 	=> reset_Mtr, 
				pulso 		=> pulso,
				mtr2 			=> mtr2
        );
--------------------------------------------------------------------------------
u7: PWM_C
        port map (
            CLK => CLK,
            ResetPwm => ResetPwm,
            Velocidad => Velocidad,
            Salida_PWM => pwm
        );	Salida_PWM <= pwm;
--------------------------------------------------------------------------------
-- Instancia Humificador
U8: Humificador
		  port map (
				CLK   		=> CLK,
				resetHm   => resetHm,
				Up    		=> Up,
				Down  		=> Down,
				HmOut 		=> HmOut
		  );

--------------------------------------------------------------------------------
---------------ESCRIBE TU C�DIGO PARA LA LCD-----------------------
INST(0) <= LCD_INI("10");

INST(1) <= CHAR(MH);
INST(2) <= CHAR(o);
INST(3) <= CHAR(r);
INST(4) <= CHAR(a);
INST(5) <= CHAR_ASCII(X"3A");

INST(6) <= BUCLE_INI(1);
---------------
INST(7) <= POS(1,6);
INST(8) <= INT_NUM(DiasD);
INST(9) <= INT_NUM(DiasU);      
INST(10) <= CHAR_ASCII(X"3A");
INST(11) <= INT_NUM(HorasD);  
INST(12) <= INT_NUM(HorasU);
INST(13) <= CHAR_ASCII(X"3A");
INST(14) <= INT_NUM(MinutosD);  
INST(15) <= INT_NUM(MinutosU);
INST(16) <= CHAR_ASCII(X"3A");
INST(17) <= INT_NUM(SegundosD);  
INST(18) <= INT_NUM(SegundosU);   
-------------
INST(19) <= POS(2,1); 
INST(20) <= CHAR(MH);
INST(21) <= CHAR(m);
INST(22) <= CHAR(r);
-------------
INST(23) <= INT_NUM(HumD);           
INST(24) <= INT_NUM(Humu);   
INST(25) <= CHAR_ASCII(X"25");
-------------         
INST(26) <= CHAR(Mt);
INST(27) <= CHAR(m);
INST(28) <= CHAR(p);
----------  
INST(29) <= INT_NUM(TempD);    
INST(30) <= INT_NUM(TempU);   
INST(31) <= CHAR_ASCII(X"DF");
INST(32) <= CHAR(C);

----------------
INST(33) <= BUCLE_FIN(1);
INST(34) <= CODIGO_FIN(1);

-------------------------------------------------------------------
-------------------------------------------------------------------
--------------------ESCRIBE TU C�DIGO DE VHDL----------------------
-------------------------------------------------------------------
-- Proceso para controlar la velocidad del ventilador según la temperatura
process(CLK, days, TEMP_int)
begin
    if rising_edge(CLK) then
        if days < 18 then
            if TEMP_int = 37 or TEMP_int <= 38 then
                Velocidad <= 100; -- Velocidad del PWM a 100 si la temperatura está entre 37 y 38 grados
            elsif TEMP_int < 37 then
                Velocidad <= 60; -- Velocidad del PWM a 60 si la temperatura es inferior a 37 grados
            elsif TEMP_int > 38 then
                Velocidad <= 140; -- Velocidad del PWM a 140 si la temperatura supera los 38 grados
            end if;
        elsif days >= 18 then
            if TEMP_int >= 28 and TEMP_int <= 30 then
                Velocidad <= 105; -- Velocidad del PWM a 105 si la temperatura está entre 28 y 30 grados
            elsif TEMP_int > 30 then
                Velocidad <= 120; -- Velocidad del PWM a 120 si la temperatura supera los 30 grados
            end if;
        end if;
    end if;
end process;

-------------------------------------------------------------------
-- Proceso para controlar la activación de señales Up y Down del Humificador
--process(CLK, days, RH_int)
--    -- Declarar variables internas para la generación de pulsos
--    variable Up_pulse : std_logic := '0';
--    variable Down_pulse : std_logic := '0';
--begin
--    if rising_edge(CLK) then
--        if days < 18 then
--            -- Control de la humedad y activación independiente de señales Up y Down del Humificador
--            if RH_int < 58 or RH_int > 60 then
--                Up_pulse := '1'; -- Genera un pulso en Up
--                Down_pulse := '0'; -- Asegura que Down esté en bajo
--            elsif RH_int > 60 then
--                Down_pulse := '1'; -- Genera un pulso en Down
--                Up_pulse := '0'; -- Asegura que Up esté en bajo
--            end if;
--        elsif days >= 18 then
--            -- Control de la humedad y activación independiente de señales Up y Down del Humificador
--            if RH_int < 68 then
--                Up_pulse := '1'; -- Genera un pulso en Up
--                Down_pulse := '0'; -- Asegura que Down esté en bajo
--            elsif RH_int > 68 then
--                Down_pulse := '1'; -- Genera un pulso en Down
--                Up_pulse := '0'; -- Asegura que Up esté en bajo
--            end if;
--        end if;
--
--        -- Generar los pulsos para Up y Down
--        if Up_pulse = '1' then
--            Up <= '0';
--            Up <= '1';
--        end if;
--
--        if Down_pulse = '1' then
--            Down <= '0';
--            Down <= '1';
--        end if;
--    end if;
--end process;

-------------------------------------------------------------------
-- Proceso para controlar la activación de señales Up y Down del Humificador
process(CLK, days, RH_int)
begin
    if rising_edge(CLK) then
        if days < 18 then
            -- Control de la humedad y activación 
            if RH_int <= 58 and RH_int <= 60 then
                HmOutTemp <= '0'; -- Activa la señal
            elsif RH_int > 60 then
                HmOutTemp <= '1'; -- Desactiva la señal
            end if;
        elsif days >= 18 then
            -- Control de la humedad y activación 
            if RH_int < 68 then
                HmOutTemp <= '0'; -- Activa la señal 
            elsif RH_int >= 68 then
                HmOutTemp <= '1'; -- Desactiva la señal 
            end if;
        end if;
    end if;
end process;


end Behavioral;

