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
--|     ADD             000
--|     AND             001
--|     OR              010
--|     LEFT SHIFT      011
--|     SUBTRACT        100
--|     NAND            101
--|     NOR             110 
--|     RIGHT SHIFT     111
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


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
signal w_add_res : std_logic_vector(8 downto 0);
signal w_and_res : std_logic_vector(8 downto 0);
signal w_or_res : std_logic_vector(8 downto 0);
signal w_shift_res : std_logic_vector(8 downto 0);
signal w_result : std_logic_vector(8 downto 0);

signal w_A : std_logic_vector(8 downto 0);
signal w_B : std_logic_vector(8 downto 0);

  
begin
	
	-- CONCURRENT STATEMENTS ----------------------------

w_A(8) <= '0';
w_B(8) <= '0';
w_A(7 downto 0) <= i_A;
w_B(7 downto 0) <= i_B;

w_add_res <= std_logic_vector(unsigned(w_A) + unsigned(w_B)) when (i_op = "000") else
             std_logic_vector(unsigned(w_A) - unsigned(w_B)) when (i_op = "100");

w_and_res <= w_A and w_B when (i_op = "001") else
             w_A nand w_B when (i_op = "101");

w_or_res <= w_A or w_B when (i_op = "010") else
            w_A nor w_B when (i_op = "110");

w_shift_res <= std_logic_vector(shift_left(unsigned(w_A), to_integer(unsigned(w_B(2 downto 0))))) when (i_op = "011") else
               std_logic_vector(shift_right(unsigned(w_A), to_integer(unsigned(w_B(2 downto 0))))) when (i_op = "111");

w_result <= w_add_res when (i_op = "000") else
            w_add_res when (i_op = "100") else
            w_and_res when (i_op = "001") else
            w_and_res when (i_op = "101") else
            w_or_res when (i_op = "010") else
            w_or_res when (i_op = "110") else
            w_shift_res when (i_op = "011") else
            w_shift_res when (i_op = "111") else
            b"000000000";

o_result <= w_result(7 downto 0);

o_flags(2) <= '1' when (w_result(7) = '1') else
              '0';

o_flags(1) <= '1' when (w_result = b"000000000") else
              '0';

o_flags(0) <= '1' when (w_result(8) = '1') else
              '0';
	
end behavioral;
