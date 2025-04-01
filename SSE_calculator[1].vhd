library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SSE_calculator is
    Generic( 
        DATA_WIDTH: INTEGER := 8;
        SLOPE:      INTEGER := 2;
        INTERCEPT:  INTEGER := 7;
        RAM_WIDTH : integer;
        RAM_DEPTH : integer;
        RAM_ADD   : integer
        );
    Port (
        CLK: IN STD_LOGIC;
        RST: IN STD_LOGIC;
        START: IN STD_LOGIC;
        DATA_OUT: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);       -- The data outputed is the SSE
        READY: OUT STD_LOGIC;
        
        -- Ram communicatin
        SIGNAL ADDR: OUT STD_LOGIC_VECTOR(RAM_ADD-1 DOWNTO 0);
        SIGNAL WE, EN: OUT STD_LOGIC;
        SIGNAL DOUT: IN STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0)        
    );
end SSE_calculator;

architecture Behavioral of SSE_calculator is
    -- Data read from RAM
    SIGNAL regX, nextRegX: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regY, nextRegY: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    
    -- Data to be evaluated
    SIGNAL regEvalY, nextRegEvalY: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regSSE, nextRegSSE: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regSub, nextRegSub: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL regSquare, nextRegSquare: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    
    -- Data useful to iterate
    SIGNAL currCount, nextCount: INTEGER;                   -- it is used to iterate in a state
    SIGNAL fsmCurrCount, fsmNextCount: INTEGER;             -- it is used to iterate in the all fsm
    
    TYPE StateType IS (INIT, READ, EVALUATE_Y, EVALUATE_SUB, EVALUATE_SQUARE, SUM, DONE);
    SIGNAL CurrState, NextState: StateType;
    
begin
    regProc: PROCESS(CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF RST = '1' THEN
            
                regX <= (OTHERS => '0');
                regY <= (OTHERS => '0');
                
                regEvalY <= (OTHERS => '0');
                regSSE <= (OTHERS => '0');
                regSub <= (OTHERS => '0');
                regSquare <= (OTHERS => '0');
                
               currCount <= 0;
               fsmCurrCount <= 0;
               
               CurrState <= INIT;
            ELSE
                regX <= nextRegX;
                regY <= nextRegY;       
                
                regEvalY <= nextRegEvalY;
                regSSE <= nextRegSSE;
                regSub <= nextRegSub;
                regSquare <= nextRegSquare;
                
               currCount <= nextCount;
               fsmCurrCount <= fsmNextCount; 
                
               CurrState <= NextState;                   
            END IF;
        END IF;
    END PROCESS;
    
    CombLogic:PROCESS(CurrState, START, regX, regY, regEvalY, regSSE, regSub, regSquare, currCount, fsmCurrCount)
        VARIABLE tmp: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    BEGIN
        DATA_OUT <= (OTHERS => 'Z');
        READY <= '0';
        CASE CurrState IS
            WHEN INIT =>
                NextRegX <= (OTHERS => '0');
                NextRegY <= (OTHERS => '0');
                
                nextRegEvalY <= (OTHERS => '0');
                nextRegSSE <= (OTHERS => '0');
                nextRegSub <= (OTHERS => '0');
                nextRegSquare <= (OTHERS => '0');
                
                nextCount <= 2;
                fsmNextCount <= 0;
                nextState <= INIT;
                
                IF START = '1' THEN 
                    nextState <= READ;
                END IF;
            WHEN READ =>
                ADDR <= STD_LOGIC_VECTOR(to_unsigned(fsmCurrCount, RAM_ADD));
                EN <= '1';
                WE <= '0';
                nextCount <= currCount - 1;
                nextState <= READ;
                IF currCount = 0 THEN
                    nextRegX <= DOUT(15 DOWNTO 8);
                    nextRegY <= DOUT(7 DOWNTO 0);
                    nextRegEvalY <= (OTHERS => '0');
                    nextRegSquare <= (OTHERS => '0');   
                    fsmNextCount <= fsmCurrCount + 1;
                    nextState <= EVALUATE_Y;
                    nextCount <= SLOPE;
                END IF;
            WHEN EVALUATE_Y =>
                nextState <= EVALUATE_Y;
                nextCount <= currCount - 1;
                
                nextRegEvalY <= STD_LOGIC_VECTOR(unsigned(regEvalY) + unsigned(regX));
                
                IF currCount = 0 THEN
                    nextRegEvalY <= STD_LOGIC_VECTOR(unsigned(regEvalY) + to_unsigned(INTERCEPT, DATA_WIDTH));
                    nextState <= EVALUATE_SUB;
                END IF;
            WHEN EVALUATE_SUB =>
                nextState <= EVALUATE_SQUARE;
                nextRegSub <= STD_LOGIC_VECTOR(ABS(signed(regY) - signed(regEvalY)));
                nextCount <= to_integer((ABS(signed(regY) - signed(regEvalY))));
            WHEN EVALUATE_SQUARE =>
                nextCount <= currCount - 1;
                IF currCount > 0 THEN
                    nextRegSquare <= STD_LOGIC_VECTOR(unsigned(regSquare) + unsigned(regSub));
                END IF;
                IF currCount = 0 THEN
                    nextState <= SUM;
                END IF;
            WHEN SUM =>
                nextRegSSE <= STD_LOGIC_VECTOR(unsigned(regSSE) + unsigned(regSquare));
                nextCount <= 2;
                NextState <= READ;
                IF fsmCurrCount = RAM_DEPTH THEN
                    NextState <= DONE; 
                END IF;
            WHEN DONE =>
                DATA_OUT <= regSSE;
                NextState <= INIT;       
                READY <= '1';         
            WHEN OTHERS =>
                NextState <= INIT;
        END CASE;
    END PROCESS;
end Behavioral;
