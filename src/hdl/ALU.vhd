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
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;


entity ALU is
-- TODO
port( i_A: in std_logic_vector(7 downto 0);
      i_B: in std_logic_vector(7 downto 0);
      i_op: in std_logic_vector(2 downto 0);
      o_result: out std_logic_vector(7 downto 0);
      o_flags: out std_logic_vector(2 downto 0)
      );
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
signal w_add_res : std_logic_vector(7 downto 0);
signal w_in1 : std_logic_vector(7 downto 0);

  
begin
	-- PORT MAPS ----------------------------------------

	
	-- CONCURRENT STATEMENTS ----------------------------
w_add_res <= std_logic_vector(unsigned(i_A) + unsigned(i_B)) when (i_op = "000") else
             std_logic_vector(unsigned(i_A) - unsigned(i_B)) when (i_op = "100");

o_result <= w_add_res when (i_op = "000") else
            w_add_res when (i_op = "100") else
            b"00000000";

o_flags(2) <= '0';

o_flags(1) <= '1' when (w_add_res = b"00000000") else
              '0';

o_flags(0) <= '1' when ((i_A(7) and i_B(7)) = '1') else
              '0';
	
end behavioral;
