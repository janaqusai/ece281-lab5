--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is  -- TODO
          port( 
                clk  : in std_logic;
                btnU : in std_logic;
                btnC : in std_logic;
                sw   : in std_logic_vector(15 downto 0);
                led  : out std_logic_vector(15 downto 0);
                an   : out std_logic_vector(3 downto 0);
                seg  : out std_logic_vector(6 downto 0)
                );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
        signal w_cycle  : std_logic;
        signal w_A      : std_logic_vector(7 downto 0);
        signal w_B      : std_logic_vector(7 downto 0);
        signal w_sel    : std_logic_vector(3 downto 0);
        signal w_result : std_logic_vector(7 downto 0);
        signal w_bin    : std_logic_vector(7 downto 0); -- MUX output
        signal w_sign   : std_logic_vector(3 downto 0);
        signal w_hund   : std_logic_vector(3 downto 0);
        signal w_tens   : std_logic_vector(3 downto 0);
        signal w_ones   : std_logic_vector(3 downto 0);
        signal w_TDM    : std_logic_vector(3 downto 0);
        signal w_flags  : std_logic_vector(2 downto 0);
        
        signal w_clk_fsm: std_logic;
        signal w_clk_tdm: std_logic;
        
        signal w_ssd_in : std_logic_vector(3 downto 0); -- input to seven seg decoder

        signal f_registerA : unsigned(7 downto 0) := "00000000";
        signal f_registerB : unsigned(7 downto 0) := "00000000";
        signal f_state : std_logic_vector(3 downto 0) := "1000";
        signal f_state_next : std_logic_vector(3 downto 0) := "1000";
        
        signal w_sign2 : std_logic;

component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component clock_divider;

component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component TDM4;

component twoscomp_decimal is
    port (
        i_binary: in std_logic_vector(7 downto 0);
        o_negative: out std_logic;
        o_hundreds: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component twoscomp_decimal;

component ALU is
    port ( -- TO DO
        i_A: in std_logic_vector(7 downto 0);
        i_B: in std_logic_vector(7 downto 0);
        i_op: in std_logic_vector(2 downto 0);
        o_result: out std_logic_vector(7 downto 0);
        o_flags: out std_logic_vector(2 downto 0)
        );
end component ALU;

component sevenSegDecoder is
    port ( 
           i_D : in STD_LOGIC_VECTOR (3 downto 0);
           o_S : out STD_LOGIC_VECTOR (6 downto 0)
          );
end component sevenSegDecoder;


begin
	-- PORT MAPS ----------------------------------------
ALU_inst : ALU port map(
    i_A => std_logic_vector(f_registerA),
    i_B => std_logic_vector(f_registerB),
    i_op => sw(2 downto 0),
    o_result => w_result,
    o_flags => w_flags
    );

clkdiv_fsm_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000000 ) -- 1 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => '0',
            o_clk   => w_clk_fsm
        );

clkdiv_tdm_inst : clock_divider
        generic map ( k_DIV => 100000 )
        port map (						  
            i_clk   => clk,
            i_reset => '0',
            o_clk   => w_clk_tdm
        );

TDM_inst : TDM4 port map (
           i_clk => w_clk_tdm,
           i_reset => '0',
           i_D3 => w_sign,
		   i_D2 => w_hund,
		   i_D1 => w_tens,
		   i_D0 => w_ones,
		   o_data => w_ssd_in,
		   o_sel => w_sel
	);

SSD_inst : sevenSegDecoder port map (
           i_D => w_ssd_in,
           o_S => seg
          );
          
twoscomp_inst : twoscomp_decimal port map (
                  i_binary => w_bin,
                  o_negative => w_sign2,
                  o_hundreds => w_hund,
                  o_tens => w_tens,
                  o_ones => w_ones
              );

	
	-- CONCURRENT STATEMENTS ----------------------------

f_state_next(3) <= f_state(0);
f_state_next(2) <= f_state(3);
f_state_next(1) <= f_state(2);
f_state_next(0) <= f_state(1);

FSM : process (w_clk_fsm)
	begin
		 if (btnU = '1') then
           f_state <= "1000";
       elsif (rising_edge(w_clk_fsm)) then
           if (btnC = '1') then
           f_state <= f_state_next;
       else
           f_state <= f_state;
       end if;
      end if;
	end process FSM;

load_registers : process (clk)
begin
    if f_state = "1000" then 
        f_registerA <= unsigned(sw(7 downto 0));
    elsif f_state = "0100" then
        f_registerB <= unsigned(sw(7 downto 0));
    end if;
end process load_registers;
    
	
an(3 downto 0) <= "1111" when (f_state = "1000") else
                   w_sel;

led(15 downto 13) <= w_flags when (f_state = "0001") else
                   "000";

led(3 downto 0) <= f_state;
  

-- for MUX
w_bin <= std_logic_vector(f_registerA) when (f_state(1 downto 0) = "00") else -- S0 and S1 (S0 is blank)
         std_logic_vector(f_registerB) when (f_state(1 downto 0) = "10") else -- S2
         w_result when (f_state(1 downto 0) = "01");

w_sign <= x"a" when (w_sign2 = '1') else
           x"b";

end top_basys3_arch;
