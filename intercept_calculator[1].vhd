library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity intercept_calculator is
    Generic( 
        DATA_WIDTH: INTEGER := 8;
        SLOPE:      INTEGER := 2;
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
end intercept_calculator;

architecture Behavioral of intercept_calculator is
    SIGNAL regX, nextRegX: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regMulX, nextRegMulX: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regY, nextRegY: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regAddr, nextRegAddr: INTEGER;
    SIGNAL CurrCount, NextCount: INTEGER;
    signal QR : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) ;
    
    TYPE StateType IS (INIT, SUM, MUL, DIV, DONE);
    SIGNAL CurrState, NextState: StateType;
    
begin 
    regProc: PROCESS(CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF RST = '1' THEN
                regX <= (OTHERS => '0');
                regMulX <= (OTHERS => '0');
                regY <= (OTHERS => '0');
                regAddr <= 0;
                CurrState <= INIT;
                CurrCount <= RAM_DEPTH;
            ELSE
                regX <= nextRegX;
                regMulX <= nextRegMulX;
                regY <= nextRegY;
                regAddr <= nextRegAddr;
                CurrState <= NextState;
                CurrCount <= NextCount;
            END IF;
        END IF;
    END PROCESS;
    
    CombLogic:PROCESS(CurrState, regX, regY, regAddr, CurrCount, START)
        VARIABLE x_tmp, y_tmp: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    BEGIN
        QR <= (OTHERS => 'Z');
        READY <= '0';
        CASE CurrState IS
            WHEN INIT =>
                ADDR <= (OTHERS => '0');
                WE <= '0';
                EN <= '0';
                nextRegX <= (OTHERS => '0');
                nextRegMulX <= (OTHERS => '0');
                nextRegY <= (OTHERS => '0');
                nextRegAddr <= 0;
                NextCount <= RAM_DEPTH;
                NextState <= INIT;
                IF START='1' THEN
                    NextState <= SUM;
                END IF;
            WHEN SUM =>     -- calculate sum(x) and sum(y)
                NextCount <= CurrCount-1;
                NextState <= SUM;
                EN <= '1';
                ADDR <= STD_LOGIC_VECTOR(to_unsigned(regAddr, RAM_ADD));
                nextRegAddr <= regAddr + 1;
                IF CurrCount < RAM_DEPTH-1 THEN       -- The RAM has 1 clock delay to return data
                    nextRegX <= std_logic_vector(unsigned(DOUT(RAM_WIDTH-1 DOWNTO 8)) + unsigned(regX));
                    nextRegY <= std_logic_vector(unsigned(DOUT(7 DOWNTO 0)) + unsigned(regY));
                END IF;
                
                IF CurrCount = -1 THEN
                    NextState <= MUL;
                    NextCount <= SLOPE;
                    -- Next Value of regX
                END IF;
            WHEN MUL =>
                IF CurrCount > 0 THEN 
                    nextRegMulX <= std_logic_vector(unsigned(regMulX) + unsigned(regX));
                    NextCount <= CurrCount - 1;
                    NextState <= MUL;
                ELSIF CurrCount = 0 THEN
                    NextState <= DIV;
                    NextCount <= RAM_ADD;
                END IF;
            WHEN DIV =>     -- calculate avg(x) and avg(y)
                nextState <= DIV;
                nextRegMulX <= '0' & regMulX(DATA_WIDTH-1 DOWNTO 1);  -- divide by 2
                nextRegY <= '0' & regY(DATA_WIDTH-1 DOWNTO 1);  -- divide by 2
                NextCount <= CurrCount - 1;
                IF CurrCount = 1 THEN
                    NextState <= DONE;
                END IF;
            WHEN DONE =>
                QR <= STD_LOGIC_VECTOR(unsigned(regY) - unsigned(regMulX));
                NextState <= INIT;
                READY <= '1';
            WHEN OTHERS =>
                NextState <= INIT;
        END CASE;
    END PROCESS;
    
    DATA_OUT <= QR;
end Behavioral;
