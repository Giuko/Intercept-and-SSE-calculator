library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity intercept_part is
    Generic( 
        DATA_WIDTH: INTEGER := 8;
        SLOPE:      INTEGER := 2;
        INIT_FILE : string := "memory.mem"
        );
    Port (
        CLK: IN STD_LOGIC;
        RST: IN STD_LOGIC;
        START: IN STD_LOGIC;
        DATA_OUT: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);       -- The data outputed is the intercept
        READY: OUT STD_LOGIC
    );
end intercept_part;

architecture Behavioral of intercept_part is
    constant RAM_WIDTH : integer := 16;
    constant RAM_DEPTH : integer := 8;
    constant RAM_ADD   : integer := 3;
    COMPONENT RAM IS
        generic(
            RAM_WIDTH : integer;
            RAM_DEPTH : integer;
            RAM_ADD   : integer;
            INIT_FILE : string
        );
        port(
            ADDR : in std_logic_vector(RAM_ADD-1 downto 0);         -- Address bus, width determined from RAM_DEPTH
            DIN  : in std_logic_vector(RAM_WIDTH-1 downto 0);       -- RAM input data
            CLK  : in std_logic;                                    -- Clock
            WE   : in std_logic;                                    -- Write enable
            EN   : in std_logic;                                    -- RAM Enable, for additional power savings, disable port when not in use
            DOUT : out std_logic_vector(RAM_WIDTH-1 downto 0)       -- RAM output data
        );
    end COMPONENT;
    
    
    COMPONENT intercept_calculator is
        Generic( 
        DATA_WIDTH: INTEGER;
        SLOPE:      INTEGER;
        RAM_WIDTH : integer;
        RAM_DEPTH : integer;
        RAM_ADD   : integer
        );
        Port (
            CLK: IN STD_LOGIC;
            RST: IN STD_LOGIC;
            START: IN STD_LOGIC;
            DATA_OUT: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);       -- The data outputed is the intercept
            READY: OUT STD_LOGIC;
        
            -- Ram communicatin
            SIGNAL ADDR: OUT STD_LOGIC_VECTOR(RAM_ADD-1 DOWNTO 0);
            SIGNAL WE, EN: OUT STD_LOGIC;
            SIGNAL DOUT: IN STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0)
        );
    end COMPONENT;

    SIGNAL ADDR: STD_LOGIC_VECTOR(RAM_ADD-1 DOWNTO 0);
    SIGNAL DIN: STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);
    SIGNAL WE, EN: STD_LOGIC;
    SIGNAL DOUT: STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);

begin
    intercept: intercept_calculator GENERIC MAP (DATA_WIDTH, SLOPE, RAM_WIDTH, RAM_DEPTH, RAM_ADD) PORT MAP(CLK, RST, START, DATA_OUT, READY, ADDR, WE, EN, DOUT);
    RAM_MEM: RAM GENERIC MAP(RAM_WIDTH, RAM_DEPTH, RAM_ADD, INIT_FILE) PORT MAP(ADDR, DIN, CLK, WE, EN, DOUT);
end Behavioral;
