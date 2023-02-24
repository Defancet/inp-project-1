-- cpu.vhd: Simple 8-bit CPU (BrainFuck interpreter)
-- Copyright (C) 2022 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Maksim Kalutski <xkalut00@stud.fit.vutbr.cz>
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(12 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_RDWR  : out std_logic;                    -- cteni (0) / zapis (1)
   DATA_EN    : out std_logic;                    -- povoleni cinnosti
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna
   IN_REQ    : out std_logic;                     -- pozadavek na vstup data
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- LCD je zaneprazdnen (1), nelze zapisovat
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is
  -- cnt
  signal cnt_reg: std_logic_vector(12 downto 0) := "0000000000000";
  signal cnt_inc: std_logic;
  signal cnt_dec: std_logic;
  signal cnt_clr: std_logic;

  --pc
  signal pc_reg: std_logic_vector(12 downto 0) := "0000000000000";
  signal pc_inc: std_logic;
  signal pc_dec: std_logic;
  signal pc_clr: std_logic;

  --ptr
  signal ptr_reg: std_logic_vector(12 downto 0) := "0000000000000";
  signal ptr_inc: std_logic;
  signal ptr_dec: std_logic;
  signal ptr_clr: std_logic;

  -- mx1
  signal mx1_sel: std_logic;

  -- mx2
  signal mx2_sel: std_logic_vector(1 downto 0) := "00";
  
type fsm_state is (
		state_idle,
		state_fetch,
		state_decode,
		state_inc_help,
		state_inc_ptr,
		state_dec_ptr,
		state_inc_cell_0, state_inc_cell_1, state_inc_cell_2,
		state_dec_cell_0, state_dec_cell_1, state_dec_cell_2,
		state_while_0, state_while_help, state_while_1,
		state_while_end_0, state_while_end_1, state_while_end_2, state_while_end_3,
		state_do,
		state_do_end_0, state_do_end_1, state_do_end_2, state_do_end_3,
		state_putchar,
		state_getchar_0, state_getchar_1,
		state_null,
		state_others,
		state_wait
	);
	signal fsm_current_state : fsm_state := state_idle;
	signal fsm_next_state : fsm_state;

begin
  pc: process (CLK, RESET)
	begin
		if (RESET = '1') then
			pc_reg <= (others => '0');
		elsif (rising_edge(CLK)) then
			if (pc_clr = '1') then
				pc_reg <= (others => '0');
			elsif (pc_inc = '1') then
				pc_reg <= pc_reg + 1;
			elsif (pc_dec = '1') then
				pc_reg <= pc_reg - 1;
			end if;
		end if;
	end process;

  ptr: process (CLK, RESET)
	begin
		if (RESET = '1') then
			ptr_reg <= (12 => '1', others => '0');
		elsif (rising_edge(CLK)) then
			if (ptr_clr = '1') then
				ptr_reg <= (12 => '1', others => '0');
			elsif (ptr_inc = '1') then
				ptr_reg <= ptr_reg + 1;
			elsif (ptr_dec = '1') then
				ptr_reg <= ptr_reg - 1;
			end if;
		end if;
	end process;

  cnt_cntr: process (CLK, RESET)
	begin
		if (RESET = '1') then
			cnt_reg <= (others => '0');
		elsif (rising_edge(CLK)) then
			if (cnt_clr = '1') then
				cnt_reg <= (others => '0');
			elsif (cnt_inc = '1') then
				cnt_reg <= cnt_reg + 1;
			elsif (cnt_dec = '1') then
				cnt_reg <= cnt_reg - 1;
			end if;
		end if;
	end process;

  mx1: process (CLK, RESET)
	begin
		if (RESET = '1') then
			DATA_ADDR <= (others => '0');
		elsif (rising_edge(CLK)) then
			case mx1_sel is
				when '0' => DATA_ADDR <= pc_reg;
				when '1' => DATA_ADDR <= ptr_reg;
				when others => 
				DATA_ADDR <= (others => '0');
			end case;
		end if;
	end process;

  mx2: process (CLK, RESET)
	begin
		if (RESET = '1') then
			DATA_WDATA <= (others => '0');
		elsif (rising_edge(CLK)) then
			case mx2_sel is
				when "00" => DATA_WDATA  <= IN_DATA;
				when "01" => DATA_WDATA  <= DATA_RDATA - 1;
				when "10" => DATA_WDATA  <= DATA_RDATA + 1;
				when others => DATA_WDATA  <= (others => '0');
			end case;
		end if;
	end process;

  OUT_DATA <= DATA_RDATA;

  fsm_curr_state: process (CLK, RESET)
	begin
		if (RESET = '1') then
			fsm_current_state <= state_idle;
		elsif (rising_edge(CLK) and (EN = '1')) then
			fsm_current_state <= fsm_next_state;
		end if;
	end process;

    fsm_nex_state: process (fsm_current_state, cnt_reg, OUT_BUSY, IN_VLD, DATA_RDATA)
	begin

		cnt_inc <= '0';
		cnt_dec <= '0';
		cnt_clr <= '0';

		pc_inc <= '0';
		pc_dec <= '0';
		pc_clr <= '0';

		ptr_inc <= '0';
		ptr_dec <= '0';
		ptr_clr <= '0';

		mx1_sel <= '0';
		mx2_sel <= "00";


		DATA_RDWR <= '0';
		DATA_EN <= '1';
		IN_REQ <= '0';
		OUT_WE <= '0';

		case (fsm_current_state) is

			when state_idle =>
				fsm_next_state <= state_wait;

			when state_fetch =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '1';
				fsm_next_state <= state_decode;

			when state_decode =>
				case DATA_RDATA is
					when X"3E"  => fsm_next_state <= state_inc_ptr;
					when X"3C"  => fsm_next_state <= state_dec_ptr;
					when X"2B"  => fsm_next_state <= state_inc_cell_0;
					when X"2D"  => fsm_next_state <= state_dec_cell_0;
					when X"5B"  => fsm_next_state <= state_while_0;
					when X"5D"  => fsm_next_state <= state_while_end_0;
					when X"28"  => fsm_next_state <= state_do;
					when X"29"  => fsm_next_state <= state_do_end_0;
					when X"2E"  => fsm_next_state <= state_putchar;
					when X"2C"  => fsm_next_state <= state_getchar_0;
					when X"00"  => fsm_next_state <= state_null;
					when others => fsm_next_state <= state_others;
				end case;
		
			when state_inc_ptr =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '1';
				mx2_sel <= "10";
				ptr_inc <= '1';
				pc_inc <= '1';
				fsm_next_state <= state_wait;
				
------------------------------------------------------------------------------
				
			when state_dec_ptr =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '1';
				mx2_sel <= "01";
				ptr_dec <= '1';
				pc_inc <= '1';
				fsm_next_state <= state_wait;

------------------------------------------------------------------------------

			when state_inc_cell_0 =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '1';
				mx2_sel <= "10";
				fsm_next_state <= state_inc_cell_1;
				pc_inc <= '1';

			when state_inc_cell_1 =>
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
			
			when state_inc_cell_2 =>
				mx1_sel <= '0';
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				fsm_next_state <= state_wait;

------------------------------------------------------------------------------
				
			when state_dec_cell_0 =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '1';
				mx2_sel <= "01";
				fsm_next_state <= state_dec_cell_1;
				pc_inc <= '1';

			when state_dec_cell_1 =>
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
			
			when state_dec_cell_2 =>
				mx1_sel <= '0';
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				fsm_next_state <= state_wait;

------------------------------------------------------------------------------

			when state_while_0 =>
				if DATA_RDATA = "00000000" then
					cnt_inc <= '1';
					mx1_sel <= '0';
					fsm_next_state <= state_while_help;
				else
					fsm_next_state <= state_wait;
				end if;
				pc_inc <= '1';

			when state_while_help =>
				fsm_next_state <= state_while_1;

			when state_while_1 =>
				if cnt_reg = "0000000000000" then
					fsm_next_state <= state_wait;
				else
					if DATA_RDATA = X"5B" then
						cnt_inc <= '1';
					elsif DATA_RDATA = X"5D" then
						cnt_dec <= '1';
					end if;
					fsm_next_state <= state_while_help;
				end if;
				pc_inc <= '1';

			when state_while_end_0 =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
				if DATA_RDATA = "00000000" then
					pc_inc <= '1';
				else
					fsm_next_state <= state_while_end_1;
				end if;

			when state_while_end_1 =>
				mx1_sel <= '0';
				if DATA_RDATA = X"5B" then
					cnt_dec <= '1';
					pc_inc <= '1';
				elsif DATA_RDATA = X"5D" then
					cnt_inc <= '1';
					pc_dec <= '1';
				end if;
				fsm_next_state <= state_while_end_2;
				
			when state_while_end_2 =>
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
				if cnt_reg = "0000000000000" then
					pc_inc <= '1';
				else
					pc_dec <= '1';
					fsm_next_state <= state_while_end_3;
				end if;

			when state_while_end_3 =>
				mx1_sel <= '0';
				fsm_next_state <= state_while_end_1;

------------------------------------------------------------------------------

			when state_do =>
				if DATA_RDATA = "00000000" then
					cnt_inc <= '1';
					mx1_sel <= '0';
				else
					fsm_next_state <= state_wait;
				end if;
				pc_inc <= '1';

			when state_do_end_0 =>
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
				if DATA_RDATA = "00000000" then
					pc_inc <= '1';
				else
					fsm_next_state <= state_do_end_1;
				end if;

			when state_do_end_1 =>
				mx1_sel <= '0';
				if DATA_RDATA = X"28" then
					cnt_dec <= '1';
					pc_inc <= '1';
				elsif DATA_RDATA = X"29" then
					cnt_inc <= '1';
					pc_dec <= '1';
				end if;
				fsm_next_state <= state_do_end_2;
				
			when state_do_end_2 =>
				mx1_sel <= '0';
				fsm_next_state <= state_wait;
				if cnt_reg = "0000000000000" then
					pc_inc <= '1';
				else
					pc_dec <= '1';
					fsm_next_state <= state_do_end_3;
				end if;

			when state_do_end_3 =>
				mx1_sel <= '0';
				fsm_next_state <= state_do_end_1;

------------------------------------------------------------------------------

			when state_putchar =>
				if OUT_BUSY = '0' then
					OUT_WE <= '1';
					pc_inc <= '1';
					fsm_next_state <= state_wait;
				elsif OUT_BUSY = '1' then
					DATA_EN <= '1';
					DATA_RDWR <= '0';
					mx1_sel <= '1';
					fsm_next_state <= state_putchar;
				end if;

------------------------------------------------------------------------------

			when state_getchar_0 =>
				mx1_sel <= '1';
				if IN_VLD /= '1' then
					IN_REQ <= '1';
					fsm_next_state <= state_getchar_0;
				else
					mx2_sel <= "00";
					DATA_EN <= '1';
					DATA_RDWR <= '0';
					fsm_next_state <= state_getchar_1;
				end if;

			when state_getchar_1 =>
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				mx1_sel <= '1';	
				pc_inc <= '1';
				fsm_next_state <= state_wait;

------------------------------------------------------------------------------
								
			when state_others =>
				pc_inc <= '1';
				fsm_next_state <= state_wait;

			when state_wait =>
				fsm_next_state <= state_fetch;
			
			when others =>
		 		fsm_next_state <= state_fetch;
		end case;
	end process;
end behavioral;
