--Codigo de proyecto final 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity LCD is 
port (
	CLOCK			: in STD_LOGIC;
	btn_in,btn_in1	: in std_logic;
	btn_out,btn1_out	: inout std_logic;

	--Entradas para LCD
--	direccion1,E_direccion		: IN STD_LOGIC; --sw que indica la direccion//sw que habilita el movimiento del display(texto completo)
	REINI 							: IN STD_LOGIC; --boton de reinicio (limpia LCD y muestra mensaje bienvenida)
	LCD_RS 			   			: OUT STD_LOGIC;							--	Comando, escritura
	LCD_RW				    		: OUT STD_LOGIC:='0';							-- LECTURA/ESCRITURA
	LCD_E 				   		: OUT STD_LOGIC;							-- ENABLE
	DATA 				   			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000";  -- PINES DATOS
---------
	Rest	: IN std_logic
--	ld0: OUT std_logic
	
);
end LCD;


architecture Behavioral of LCD is 
-----SIGNALS FOR LCD---------------
	--signal FSM
	type STATE_TYPE is (
		RST,ST0,ST1,ST2,SET_DEFI,SHOW1,SHOW2,CLEAR,ENTRY,B,i,e,n,v,d,o,vacio,M,R,uno,F,NN,FF,N_N,Espera,T,Espacio,Estados,
		CambioFila,dos--desplazamiento,CambioFila,decen,unid,limpiarlCD,espacio,dos_puntos,D,Z
        );
		signal State,Next_State : STATE_TYPE;

		signal CONT1 : STD_LOGIC_VECTOR(23 downto 0) := X"000000"; -- 16,777,216 = 0.33554432 s MAX
		signal CONT2 : STD_LOGIC_VECTOR(4 downto 0) :="00000"; -- 32 = 0.64us
		signal RESET : STD_LOGIC :='0';
		signal READY : STD_LOGIC :='0';

		signal unidades, decenas: integer range 0 to 9  :=0;
		--signal LCD_numeros_Encoder
		signal numeroD,numeroU: std_logic_vector(7 downto 0);
		signal I_s,Es,N_S,Os,Espacios,f_s,esperas,fila,ciclo	 	  : integer range 0 to 20:=0;

------------------------------------------------
		signal BTN0_REG1,BTN0_REG2,PULSO_BTN0,Q_T,BTN1_REG1,BTN1_REG2,PULSO_BTN1,Q_T1: std_logic;
		constant CNT_SIZE : integer := 19;
		signal btn_prev,btn_prev1   : std_logic := '0';
		signal counter,counter1    : std_logic_vector(CNT_SIZE downto 0) := (others => '0');
		signal btn0,btn1 :std_logic;
		signal listo:std_logic:='0';

		signal conta_1250us:integer range 0 to 50000000:=0;
begin


-----------------LCD-----------------------
-------------------------------------------------------------------
--Contador de Retardos CONT1--
process(CLOCK,RESET)
begin
	if RESET='1' then CONT1 <= (others => '0');
	elsif CLOCK'event and CLOCK='1' then CONT1 <= CONT1 + 1;
	end if;
end process;
-------------------------------------------------------------------
--Contador para Secuencias CONT2--
process(CLOCK,READY)
begin
	if CLOCK='1' and CLOCK'event then
		if READY='1' then CONT2 <= CONT2 + 1;
		else CONT2 <= "00000";
		end if;
	end if;
end process;
-------------------------------------------------------------------
--Actualizaci?n de estados--
act_Estados: process (CLOCK, Next_State)
begin
	if CLOCK='1' and CLOCK'event then State <= Next_State;
end if;
end process;
------------------------------------------------------------------
lcd_estados: process(CONT1,CONT2,State,CLOCK,Rest)
begin

if Rest = '1' THEN Next_State <= RST;
elsif CLOCK='0' and CLOCK'event then
	case State is

		when RST => -- Estado de reset
			if CONT1=X"000000"then --0s
				LCD_RS<='0';
				--LCD_RW<='0';
				LCD_E<='0';
				--DATA<=x"00";
				Next_State<=clear;
				listo <='0';
				Os<=0; F_s<=0; Espacios<=0; I_s<=0; Es<=0; N_s<=0; fila<=1; Esperas<=0;
			else
				Next_State<=clear;
				listo <='0';
				Os<=0; F_s<=0; Espacios<=0; I_s<=0; Es<=0; N_s<=0; fila<=1; Esperas<=0;
			end if;
			
		when ST0 => --Primer estado de espera por 25ms (20ms=0F4240=1000000)(15ms=0B71B0=750000)
		---SET 1
			if CONT1=X"2625A0" then -- 2,500,000=50ms
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET 8BITS, 2 LINE, 5X7
				Next_State<=ST0;
			elsif CONT2>"00001" and CONT2<"01110" then--rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=ST1;
			else
				Next_State<=ST0;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when ST1 => --Segundo estado de espera por 5ms --SET2
			if CONT1=X"03D090" then -- 250,000 = 5ms
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET
				Next_State<=ST1;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=ST2;
			else
				Next_State<=ST1;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when ST2 => --Tercer estado de espera por 100us  SET 3
			if CONT1=X"0035E8" then -- 5000 = 100us  = x35E8)
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET
				Next_State<=ST2;
				--BTN_OUT<='1';
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SET_DEFI;
			else
				Next_State<=ST2;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when SET_DEFI => --Cuarto paso, se asignan lineas logicas, modo de bits (8) y #caracteres(5x8)
			--SET DEFINITIVO
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00111000"; -- FUNCTION SET(lineas,caracteres,bits)
				Next_State<=SET_DEFI;
				
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SHOW1;
				LCD_RS<='0';
				--BTN_OUT<='1';
				
			else
				Next_State<=SET_DEFI;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when SHOW1 => --Quinto paso, se apaga el display por unica ocasion
		--SHOW _ APAGAR DISPLAY
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00001000"; -- SHOW, APAGAR DISPLAY POR UNICA OCASION 
				Next_State<=SHOW1;
				
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				-----CLEAR, LIMPIAR DISPLAY
				Next_State<=CLEAR;
			else
				Next_State<=SHOW1;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when CLEAR => --SEXTO PASO, SE LIMPIA EL DISPLAY 
	
			if CONT1=X"FFFFFF" then  --  E4E1C0    original 4C4B40
				READY<='1';
				LCD_RS<='0';
				DATA<="00000001"; -- CLEAR
				Next_State<=CLEAR;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=ENTRY;
			else
				Next_State<=CLEAR;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when ENTRY => --SEPTIMO PASO, CONFIGURAR MODO DE ENTRADA
			--ENTRY MODE
			if CONT1=X"3D090" then --espera por 5ms 250,000  3D090   E4E1C0
				READY<='1';
				DATA<="00000110"; -- ENTRY MODE, se mueve a la derecha(escritura), no se desplaza(barrido)
				Next_State<=ENTRY;
				
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SHOW2;
			else
				Next_State<=ENTRY;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when SHOW2 => --OCTAVO PASO, ENCENDER LA LCD Y CONFIGURAR CURSOR, PARPADEO
		---SHOW DEFINITIVO
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00001111"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=SHOW2;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='1';	
					if listo ='1' then 	
						Next_State<=M;
						Os<=1; Espacios<=0; F_s<=0;
						Fila<=1;
					else  Next_State<=B;  
					end if;
					Esperas<=0;
			else
				Next_State<=SHOW2;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when B => --LETRA B MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01000010"; -- B
				Next_State<=B;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
		         Next_State<=I;
			else
				Next_State<=B;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
				
		when I => --I Minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01101001"; -- I minuscula
				Next_State<=I;
				
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				
                    if I_s = 0 then 
						Next_State<=E; --Bi E nvenido
                    elsif I_s = 1 then 
                        Next_State<=D; --Bienveni d o 
                    end if;
                    I_s<=I_s+1;
			else
				Next_State<=I;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when E => --E Minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01100101"; -- E Minuscula
				Next_State<=E;
				
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=N;	--Bie N venido
			else
				Next_State<=E;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when N => --N Minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01101110"; -- N Minuscula
				Next_State<=N;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
                if N_s = 0 then 
				    Next_State<=v;	
                elsif N_s = 1 then 
                    Next_State<=I;
                end if;	
                N_s<=N_s+1;
			else
				Next_State<=N;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when V => --V Minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01110110"; -- V Minuscula
				Next_State<=V;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0'; 
				Next_State<=E;
			else
				Next_State<=V;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

				
		when D => --d minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01100100"; -- D Minuscula
				Next_State<=D;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='1';
				Next_State<=O; -- Bienvenid o
			else
				Next_State<=D;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when O => --O Minuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01101111"; -- O minuscula
				Next_State<=O;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';			
				if Os = 0 then 	
					listo<='1';
					Next_State<=Espera; --tiempo de espera un par de segundos
				elsif Os = 1 then 
					Next_State<=T; --M o tor 
				elsif Os = 2 then 
					Next_State<=r; --Mot o r 
				elsif Os = 3 then 
					if fila=1 then
						if BTN_OUT = '1' then Next_state <=NN;
						elsif BTN_OUT ='0' then  Next_state <=F;
						end if;
					elsif fila=2 then 
						if BTN1_OUT = '1' then Next_state <=N_N;
						elsif BTN1_OUT ='0' then  Next_state <=FF;
						end if;
					end if;
				end if;
				Os<=Os+1;
			else
				Next_State<=O;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

-----------------------ON/OFF
		when NN => --N mayuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01001110"; -- N de ON
				Next_State<=NN;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=CambioFila; 
			else
				Next_State<=NN;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
		
		when F => --N mayuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01000110"; -- F de OFF
				Next_State<=F;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
					if F_s=0 then 
						Next_State<=F; 
					elsif F_s=1 then  
						Next_State<=CambioFila; 
					end if;
					F_s<=F_s+1;
			else
				Next_State<=F;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

			when N_N => --N mayuscula
				if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
					READY<='1';
					DATA<="01001110"; -- N de ON
					Next_State<=N_N;
				elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
					LCD_E<='1';
				elsif CONT2="1111" then
					READY<='0';
					LCD_E<='0';				
					Next_State<=Clear; 
					 Os<=1;
				else
					Next_State<=N_N;
				end if;
					RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
			
			when FF => --N mayuscula
				if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
					READY<='1';
					DATA<="01000110"; -- F de OFF
					Next_State<=FF;
				elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
					LCD_E<='1';
				elsif CONT2="1111" then
					READY<='0';
					LCD_E<='0';
						if F_s=0 then 
							Next_State<=FF; 
						elsif F_s=1 then  
							Next_State<=clear; 
							Os<=1; F_s<=0;
						end if;
						F_s<=F_s+1;
				else
					Next_State<=FF;
				end if;
					RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

--------------MOTOR
		when M => --M Mayuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01001101"; -- M mayuscula
				Next_State<=M;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=O;
			else
				Next_State<=M;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when T => --M Mayuscula
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01110100"; -- M mayuscula
				Next_State<=T;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=O; 
			else
				Next_State<=T;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when R => --R MINUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01110010"; -- R minuscula
				Next_State<=R;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<= Espacio; 
			else
				Next_State<=R;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

--------------------------------------------------------------------------------

		when Espera => --contador tiempo espera
		if rising_edge(CLOCK) then
			if (conta_1250us = 50000000) then --cuenta 1250us (50MHz=62500)
					conta_1250us <= 1;
					if ciclo<1 then 
						ciclo<=ciclo+1;
					else ciclo<=0; Next_state<=clear;
					end if;
			else
					conta_1250us <= conta_1250us + 1;
					
			end if;
		end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when Espacio => --Espacio
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				LCD_RS<='0';
				DATA<="00010100"; 
				Next_State<=Espacio;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='1'; ---enviar datos
					if Espacios=0 then 
						Next_State<=uno;------ Motor_uno
					elsif Espacios=1 then 
						Next_State<=O;---Motor O_N/O_FF-- 
						fila<=1;
					elsif Espacios=2 then 
						Next_State<=dos;
					elsif Espacios=3 then 
						Next_State<=O;---Motor O_N/O_FF-- 
						fila<=2;
					end if; 
					Espacios<=Espacios+1;
			else
				Next_State<=Espacio;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when CambioFila => --Cambio Fila
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				LCD_RS<='0';
				DATA<="11000000"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=CambioFila;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='1';
				Next_State<=M;
				Os<=1;  F_s<=0;
			else
				Next_State<=CambioFila;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
---------------------------------------------		----------------------------
		when uno => --NUMERO 1
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00110001"; -- uno
				Next_State<=uno;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=Espacio;
			else
				Next_State<=uno;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
			
		when dos => --NUMERO 2
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00110010"; -- dos
				Next_State<=dos;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';				
				Next_State<=Espacio; 
			else
				Next_State<=dos;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

---------------------------------------------------------------------------
	
		when Vacio => --Sin ordenes
			if CONT1=X"E4E1C0" then --espera por 500ms 20ns*25,000,000=50ms 2500=9C4
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns

			elsif CONT2="1111" then
			else
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0	
		when others => READY<='0';
				LCD_E<='0';
				LCD_RS<='0';			
		end case;
end if;
end process;


-----------------------------------
-------------DEBOUNCER
deboun: process(clock)
begin
if (clock'event and clock='1') then
	--Boton1
	if (btn_prev xor btn_in) = '1' then
		counter <= (others => '0');
		btn_prev <= btn_in;
	elsif (counter(CNT_SIZE) = '0') then
		counter <= counter + 1;
		else
		btn0 <= btn_prev;
	end if;
	--Boton2
	if (btn_prev1 xor btn_in1) = '1' then
		counter1 <= (others => '0');
		btn_prev1 <= btn_in1;
	elsif (counter1(CNT_SIZE) = '0') then
		counter1 <= counter1 + 1;
		else
		BTN1 <= btn_prev1;
	end if;

end if;
end process;


--------------toggle
biest_D1: Process (Rest, Clock)
begin
	if Rest = '1' then
	BTN0_REG1 <= '0'; --boton 1
	BTN1_REG1 <= '0';--Boton 2
	elsif Clock'event and Clock='1' then
	BTN0_REG1 <= BTN0;    --boton1
	BTN1_REG1 <= BTN1;  --boton2
	end if;
end process;

biest_D2: Process (Rest, Clock)
begin
	if Rest = '1' then
	BTN0_REG2 <= '0';
	BTN1_REG2 <= '0';
	elsif Clock'event and Clock='1' then
	BTN0_REG2 <= BTN0_REG1;
	BTN1_REG2 <= BTN1_REG1;
	end if;
end process;

PULSO_BTN0 <= '1' when (BTN0_REG1 = '1' and BTN0_REG2='0') else '0';
PULSO_BTN1 <= '1' when (BTN1_REG1 = '1' and BTN1_REG2='0') else '0';

biest_T: Process (Rest, Clock,Q_T,Q_T1)
begin
	if Rest = '1' then
	Q_T <= '0';
	Q_T1 <= '0';
	elsif Clock'event and Clock='1' then
		if PULSO_BTN0 = '1' then
			Q_T <= NOT Q_T;
		elsif PULSO_BTN1 ='1' then 
			Q_T1 <= NOT Q_T1;
		end if;
	end if;
BTN_OUT <= Q_T;
BTN1_OUT <= Q_T1;
end process;

-------------END LCD----------------------
end Behavioral;

