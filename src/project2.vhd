----------------------------------------------------------------------------------
-- Company: 
-- Engineers: Sanjay Sivapragasam and Raymond Vo
-- Create Date:    14:25:52 11/04/2025 
-- Module Name:    project2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project2 is
Port (
    CLK : in std_logic;
	 -- sync pulses for horizontal and vertical
    H : out std_logic; -- horizontal sync from .ucf
    V : out std_logic;  -- vertical sync from .ucf
	 -- RGB vectors based on given .ucf file
	 Rout : out std_logic_vector (7 downto 0);
	 Gout : out std_logic_vector (7 downto 0);
	 Bout : out std_logic_vector (7 downto 0);
	 -- switches used for paddle movement
	 SW0 : in std_logic;                          -- paddle1 up
    SW1 : in std_logic;                          -- paddle1 down
    SW2 : in std_logic;                          -- paddle2 up
    SW3 : in std_logic;                          -- paddle2 down
	 DAC_CLK : out std_logic                    -- pixel clock output
);
end project2;


architecture Behavioral of project2 is

-- setting up the VGA monitor display

-- horizontal VGA
constant total_horizontal : integer := 800; -- 800 clock cycles wide
constant active_horizontal : integer := 639; -- 640 clock cycles (count from 0)
constant front_porch_horizontal : integer := 16; -- 16 clock cycles
constant Hsync_pulse : integer := 96; -- 96 clock cycles
constant back_porch_horizontal : integer := 48; -- 48 clock cycles

-- vertical VGA
constant total_vertical : integer := 525; -- 525 clock cycles long
constant active_vertical : integer := 479; -- 480 clock cycles (count from 0)
constant front_porch_vertical : integer := 10; -- 10 clock cycles
constant Vsync_pulse : integer := 2; -- 2 clock cycles
constant back_porch_vertical : integer := 33; -- 33 clock cycles

-- signals for the sync pulses
signal Hsync, Vsync : std_logic := '0';


-- setting up the boundaries for the game
constant top_boundary : integer := 5; -- near top of the active region starting position of boundary
constant bottom_boundary : integer := 475; -- near the bottom of the active region
constant left_boundary : integer := 5; -- left of the active region
constant right_boundary : integer := 635; -- right of the active region
constant boundary_width : integer := 20; -- giving all boundaries an equal width of 20 pixels
constant halfline : integer := 309; -- setting up the line at the halfway point
constant gate_top : integer := 140; -- the top of the gate for goals
constant gate_height : integer := 200; -- height of the gate


-- counting variables for the horizontal position
signal h_count : integer range 0 to total_horizontal := 0;

-- counting variables for the vertical position
signal v_count : integer range 0 to total_vertical := 0;

-- variables for the ping-pong ball
-- ping pong ball starts at the center of the game
signal ball_x : integer := 320; -- 640/2
signal ball_y : integer := 240; -- 480/2
signal ball_x_velocity : integer := 2; -- horizontal velocity of the ball
signal ball_y_velocity : integer := 2; -- vertical velocity of the ball
constant ball : integer := 12; -- setting the size of the ball
signal ball_colour: std_logic := '0'; -- initializing the ball colour

-- setup of the ping-pong rackets
constant paddle_width : integer := 10; -- width of the paddle
constant paddle_length : integer := 100; -- length of the paddle

-- player 1 paddle located on the left side
signal paddle1_horizontal : integer := 40;
signal paddle1_vertical : integer := 300;

-- player 2 paddle located on the right side
signal paddle2_horizontal : integer := 600;
signal paddle2_vertical : integer := 300;

-- flagging variables to indicate changes
signal frame_check : std_logic := '0'; -- status variable for if it is a new frame or not
signal vga_enable : std_logic := '0'; -- status variable for if the VGA display visible or not (active region)

-- a variable for the new clock that will be used since VGA runs at 25MHz
signal new_clk : std_logic := '0'; 

-- setting up the RGB colour system
signal R, G, B : std_logic_vector(7 downto 0);


-- setting up the state machine for the states of play
signal pong_gameplay : integer := 0; -- 0 is gameplay, 1 is scoring, 2 is resetting the game
signal game_delay : integer := 0; -- used to delay between goal scored and resetting the game



-- ChipScope Components
component proj2_icon
  port (
    CONTROL0 : inout std_logic_vector(35 downto 0)
  );
end component;

component proj2_ila
  port (
    CONTROL : inout std_logic_vector(35 downto 0);
    CLK     : in  std_logic;
    DATA    : in  std_logic_vector(63 downto 0);
    TRIG0   : in  std_logic_vector(7 downto 0)
  );
end component;

signal CONTROL0 : std_logic_vector(35 downto 0);
signal ILA_DATA : std_logic_vector(63 downto 0);
signal ILA_TRIG : std_logic_vector(7 downto 0);



----------------- beginning of the project------------------------
begin

-- changing the 50 MHz frequency clock to 25 MHz clock
correct_clock : process (CLK)
begin
    if (rising_edge(CLK)) then
	 -- inverting the rising edge can divide frequency by 2
	 -- if the value itself is divided, then the amplitude would change
	 -- which is why the NOT command is used
        new_clk <= not new_clk; 
    end if;
end process correct_clock;

-- this is the output of the newly divided clock for DAC pixel clock
DAC_CLK <= new_clk;


-- the frame is filled in horizontally first from the beginning to the end of the line
-- then this repeats for all the lines in the display
-- once the last pixel of the full frame is filled in (on the last line -  line 525)
-- the process needs to repeat again at index (0,0)
vga_display : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (h_count = total_horizontal - 1) then -- at the end of the line, clock cycle 799
            h_count <= 0; -- reset back to beginning of a line, clock cycle 0
            if (v_count = total_vertical - 1) then -- at the last line, bottom of the display
                v_count <= 0; -- go back to first line, at the top of the display
                frame_check <= '1'; -- now requires a new frame since there are no more lines below this current line
            else
                v_count <= v_count + 1; -- go to next line (move down vertically by 1)
                frame_check <= '0'; -- still on the same frame, not a new frame
            end if;
        else
            h_count <= h_count + 1; -- not at the end of the line, increment to next clock cycle to the right
            frame_check <= '0'; -- still on current frame
        end if;
    end if;
end process vga_display;

-- for the sync pulses, VGA convention uses active-low. This means that when the voltage
-- drops to 0 (low pulse) to signal the end of a line or frame, it would be high (1) anytime else
-- this is because based on CRT standards, when the electron beam finished scanning a line
-- it would turn off, move to the left, and resume. So the pulse needs to be low between the porches,
-- and high in the active region and the porches itself

-- setup of the horizontal sync
horizontal_sync : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (h_count <= (active_horizontal + front_porch_horizontal)) or
           (h_count > (active_horizontal + front_porch_horizontal + Hsync_pulse)) then
            Hsync <= '1'; -- not in the pulse window
        else
            Hsync <= '0'; -- in the pulse window of 656 to 752 clock cycles
        end if;
    end if;
end process horizontal_sync;


-- setup of the vertical sync
vertical_sync : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (v_count <= (active_vertical + front_porch_vertical)) or
           (v_count > (active_vertical + front_porch_vertical + Vsync_pulse)) then
            Vsync <= '1'; -- not in the pulse window
        else
            Vsync <= '0'; -- in the pulse window
        end if;
    end if;
end process vertical_sync;


-- the trajectory of the ball needs to change by 90 degrees when it hits a boundary
hit_boundary : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (frame_check = '1') then
		  
		  
		  -- setting up a state machine to differentiate different stages of the game
		  -- there is the regular game play, when a player scores, and when the game resets
		  case pong_gameplay is
		  
		  -- regular play
		  when 0 => 
		  -- if the ball hits the top or bottom boundaries
            if (ball_y <= top_boundary + boundary_width) then
                ball_y_velocity <= abs(ball_y_velocity); -- travel downwards
            elsif (ball_y + ball >= bottom_boundary - boundary_width) then
                ball_y_velocity <= (-1)* abs(ball_y_velocity); -- travel upwards
            end if;


            -- if the ball hits the left boundary
            if (ball_x <= left_boundary + boundary_width and not(ball_y > gate_top and ball_y <= gate_top + gate_height)) then
                ball_x_velocity <= abs(ball_x_velocity);
				-- if the ball hits the right boundary
            elsif (ball_x + ball >= right_boundary - boundary_width and not(ball_y > gate_top and ball_y <= gate_top + gate_height)) then
                ball_x_velocity <= (-1)* abs(ball_x_velocity);
            end if;
				

            -- when the ball hits paddle1
            if (ball_x <= paddle1_horizontal + paddle_width and ball_x >= paddle1_horizontal and
                ball_y + ball >= paddle1_vertical and ball_y <= paddle1_vertical + paddle_length) then
                ball_x_velocity <= abs (ball_x_velocity);
            end if;
				
				-- when the ball hits paddle2
            if (ball_x + ball >= paddle2_horizontal and ball_x <= paddle2_horizontal + paddle_width and
                ball_y + ball >= paddle2_vertical and ball_y <= paddle2_vertical + paddle_length) then
                ball_x_velocity <= (-1)* abs(ball_x_velocity);
            end if;

            -- provide the ball velocity so it can move
            ball_x <= ball_x + ball_x_velocity;
            ball_y <= ball_y + ball_y_velocity;
				
				
				
				-- if the ball hits the left or right boundaries
            if (((ball_x <= left_boundary + boundary_width) and 
				(ball_y > gate_top and ball_y <= gate_top + gate_height)) or
				((ball_x + ball >= right_boundary - boundary_width) and 
				(ball_y > gate_top and ball_y <= gate_top + gate_height))) then
                ball_colour <= '1';
					 pong_gameplay <= 1;
					 game_delay <= 0;
            end if;

		  
		  -- when they score a goal
		  when 1 =>
		  game_delay <= game_delay +1;
		  
		  ball_x <= ball_x + ball_x_velocity;
		  ball_y <= ball_y + ball_y_velocity;
		  
		  
		  --ball_x <= 650;
		  --ball_y <= 530;
		  
		  if game_delay >= 180 then
			pong_gameplay <= 2;
		  end if;
		  
		  
		  -- to reset the game
		  when 2 =>
		  ball_x <= 320;
		  ball_y <= 240;
		  ball_x_velocity <= 2;
		  ball_y_velocity <= 2;
		  ball_colour <= '0';
		  pong_gameplay <= 0;
		  
		  -- player 1 paddle located on the left side
			--paddle1_horizontal <= 40;
			--paddle1_vertical <= 300;

			-- player 2 paddle located on the right side
			--paddle2_horizontal <= 600;
			--paddle2_vertical <= 300;
			when others =>
					pong_gameplay <= 0;
			end case;
        end if;
    end if;
end process hit_boundary;


-- enabling the display of the content on the monitor
display : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (h_count <= active_horizontal and v_count <= active_vertical) then
            vga_enable <= '1'; -- flag variable set to 1 to indicate it is in the active region
        else
            vga_enable <= '0';
        end if;
    end if;
end process display;


-- moving the paddles (using switches)
moving_paddle : process (new_clk)
begin
    if (rising_edge(new_clk)) then
        if (frame_check = '1') then
            -- player 1 paddle movement
            if (SW0 = '1' and SW1 = '1') then
					 paddle1_vertical <= paddle1_vertical;
				elsif (SW0 = '1' and paddle1_vertical > top_boundary + boundary_width) then
                paddle1_vertical <= paddle1_vertical - 2; -- move up
            elsif (SW1 = '1' and paddle1_vertical + paddle_length < bottom_boundary - boundary_width) then
                paddle1_vertical <= paddle1_vertical + 2; -- move down
            end if;

            -- player 2 paddle movement
				if (SW2 = '1' and SW3 = '1') then
					 paddle2_vertical <= paddle2_vertical;
            elsif (SW2 = '1' and paddle2_vertical > top_boundary + boundary_width) then
                paddle2_vertical <= paddle2_vertical - 2; -- move up
            elsif (SW3 = '1' and paddle2_vertical + paddle_length < bottom_boundary - boundary_width) then
                paddle2_vertical <= paddle2_vertical + 2; -- move down
            end if;
        end if;
    end if;
end process moving_paddle;


-- the final portion of this project is to draw everything with the correct colour schemes
draw_process : process(new_clk)
begin
  if rising_edge(new_clk) then
    if (vga_enable = '1') then -- if the vga is ready to display
      
     
 -- colour of ball
      if (h_count >= ball_x and h_count < ball_x + ball and
             v_count >= ball_y and v_count < ball_y + ball) then
        if (ball_colour = '1') then
          R <= (others => '1'); G <= (others => '0'); B <= (others => '0'); -- red (goal)
        else
          R <= (others => '1'); G <= (others => '1'); B <= (others => '0'); -- yellow (normal)
        end if;


	  -- making the gates green (drawn before borders so they are visible)
      elsif ((h_count < left_boundary + boundary_width and
            v_count > gate_top and v_count < gate_top + gate_height) or
          (h_count > right_boundary - boundary_width and
            v_count > gate_top and v_count < gate_top + gate_height)) then
        R <= (others => '0'); G <= (others => '1'); B <= (others => '0');

      -- making all the boundaries white as RGB [111] white
      elsif (v_count < top_boundary + boundary_width and v_count > top_boundary and h_count > left_boundary and h_count < right_boundary) or
            (v_count > bottom_boundary - boundary_width and v_count < bottom_boundary and h_count > left_boundary and h_count < right_boundary) or
            (h_count < left_boundary + boundary_width and h_count > left_boundary and v_count > top_boundary and v_count < bottom_boundary) or
            (h_count > right_boundary - boundary_width and h_count < right_boundary and v_count > top_boundary and v_count < bottom_boundary) then
        R <= (others => '1'); G <= (others => '1'); B <= (others => '1');
		elsif (v_count < top_boundary + 2) then
		  R <= (others => '0'); G <= (others => '1'); B <= (others => '0');
--		elsif (v_count < top_boundary or
--			    v_count > bottom_boundary or
--				 h_count < left_boundary or
--				 h_count > right_boundary) then
--		  R <= (others => '0'); G <= (others => '1'); B <= (others => '0');

      -- colouring the paddles
		-- player 1's paddle
      elsif (h_count >= paddle1_horizontal and
             h_count < paddle1_horizontal + paddle_width and
             v_count >= paddle1_vertical and
             v_count < paddle1_vertical + paddle_length) then
        R <= (others => '0'); G <= (others => '0'); B <= (others => '1'); -- blue
		
		-- player 2's paddle
      elsif (h_count >= paddle2_horizontal and
             h_count < paddle2_horizontal + paddle_width and
             v_count >= paddle2_vertical and
             v_count < paddle2_vertical + paddle_length) then
        R <= (others => '1'); G <= (others => '0'); B <= (others => '1'); -- purple

--      -- colour of ball
--      elsif (h_count >= ball_x and h_count < ball_x + ball and
--             v_count >= ball_y and v_count < ball_y + ball) then
--        if (ball_colour = '1') then
--          R <= (others => '1'); G <= (others => '0'); B <= (others => '0'); -- red (goal)
--        else
--          R <= (others => '1'); G <= (others => '1'); B <= (others => '0'); -- yellow (normal)
--        end if;

      -- center line
      elsif (h_count >= halfline and h_count < halfline + 3) then
			if ((v_count mod 32) < 16) then
        R <= (others => '0'); G <= (others => '0'); B <= (others => '0'); -- black
		  else
		  R <= (others => '0'); G <= (others => '1'); B <= (others => '0'); -- black
		  end if;

      -- background (green field)
      else
        R <= (others => '0'); G <= (others => '1'); B <= (others => '0');
      end if;
    else
      R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
    end if;
  end if;
end process draw_process;

-- Map the RGB outputs to match .ucf pins
Rout <= R;
Gout <= G;
Bout <= B;
-- Map the sync and clock signals to the ports based on .ucf
H <= Hsync;
V <= Vsync;
DAC_CLK <= new_clk;


-- chipscope waveform setup
u_icon : proj2_icon
  port map (
    CONTROL0 => CONTROL0
  );

u_ila : proj2_ila
  port map (
    CONTROL => CONTROL0,
    CLK     => new_clk,   -- pixel clock sampling
    DATA    => ILA_DATA,
    TRIG0   => ILA_TRIG
  );

-- map internal signals to ILA DATA inputs
ILA_DATA(51 downto 42) <= std_logic_vector(to_unsigned(h_count, 10));
ILA_DATA(41 downto 33) <= std_logic_vector(to_unsigned(v_count, 9));
ILA_DATA(32) <= Vsync;
ILA_DATA(31) <= Hsync;
ILA_DATA(30) <= frame_check;
ILA_DATA(29) <= vga_enable;
ILA_DATA(28) <= new_clk;
ILA_DATA(27) <= SW0;
ILA_DATA(26) <= SW1;
ILA_DATA(25) <= SW2;
ILA_DATA(24) <= SW3;
ILA_DATA(23 downto 16) <= R(7 downto 0);
ILA_DATA(15 downto 8) <= G(7 downto 0);
ILA_DATA(7 downto 0) <= B(7 downto 0);

end Behavioral;
