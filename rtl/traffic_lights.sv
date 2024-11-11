module traffic_lights #(
  parameter BLINK_HALF_PERIOD_MS,
  parameter BLINK_GREEN_TIME_TICK,
  parameter RED_YELLOW_MS,
  parameter CLK_FREQ_HZ = 2000
)(
  input  logic        clk_0m002,
  input  logic        srst_i,

  input  logic [2:0]  cmd_type_i,
  input  logic        cmd_val_i,

  input  logic [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o 
);

localparam TOTAL_BLINK_CLK        = ((2 * BLINK_HALF_PERIOD_MS) * BLINK_GREEN_TIME_TICK * CLK_FREQ_HZ) / 1000;
localparam RED_YELLOW_CLK         = (CLK_FREQ_HZ * RED_YELLOW_MS) / 1000;
localparam BLINK_QUART_PERIOD_CLK = (BLINK_HALF_PERIOD_MS * CLK_FREQ_HZ) / 1000;

// Состояния КА для светофора
enum logic [2:0] {
  RED,          // Красный
  RED_YELLOW,   // Красный и желтый
  GREEN,        // Зеленый
  GREEN_BLINK,  // Зеленый мигает
  YELLOW,       // Желтый

  YELLOW_BLINK, // Неуправляемый переход
  OFF           // Выключен
} state, next_state;

logic [15:0] red_time;
logic [15:0] yellow_time;
logic [15:0] green_time;

logic [15:0] timer;
logic [15:0] blink_counter;

// state
always_ff @( posedge clk_0m002 )
  if ( srst_i )
    state <= OFF;
  else
    if ( cmd_val_i )
      case( cmd_type_i )
        3'b000:
          begin
            state <= RED;
          end
        3'b001:
          begin
            state <= OFF;
          end
        3'b010:
          begin
            state <= YELLOW_BLINK;
          end
        default
          begin
            state <= next_state;
          end
      endcase
    else
      state <= next_state;

// Реализация КА для светофора
always_comb
  begin
    next_state = state;

    case( state )
      RED:
        begin
          if ( timer >= (red_time - 1))
            next_state = RED_YELLOW;
        end
      RED_YELLOW:
        begin
          if ( timer >= (RED_YELLOW_CLK - 1) )
            next_state = GREEN;
        end
      GREEN:
        begin
          if ( timer >= (green_time - 1) )
            next_state = GREEN_BLINK;
        end
      GREEN_BLINK:
        begin
          if (timer >= (TOTAL_BLINK_CLK - 1)) 
            next_state = YELLOW;
        end
      YELLOW:
        begin
          if (timer >= (yellow_time - 1))
            next_state = RED;
        end
      YELLOW_BLINK:
        begin
          next_state = YELLOW_BLINK;
        end
      OFF:
        begin
          next_state = OFF;
        end
      
      default:
        begin
          next_state = OFF;
        end
   endcase
  end

// timer
always_ff @( posedge clk_0m002 )
  begin
    if ( srst_i )
      timer <= '0;
    else
      if (( state == next_state ) && ( state != OFF ) && ( state != YELLOW_BLINK ))
        timer <= timer + (15)'(1);
      else
        timer <= '0;
  end

// red_time
always_ff @( posedge clk_0m002 ) 
  begin
    if ( srst_i )
      red_time <= '0;
    else
      if (cmd_val_i == 1'b1)
        if ( ( cmd_type_i == (3)'(4) ) && ( state == YELLOW_BLINK ) )
          red_time <= (15)'(cmd_data_i * CLK_FREQ_HZ / 1000);
  end

// yellow_time
always_ff @( posedge clk_0m002 ) 
  begin
    if ( srst_i )
      yellow_time <= '0;
    else
      if (cmd_val_i == 1'b1)
        if ( ( cmd_type_i == (3)'(5) ) && ( state == YELLOW_BLINK ) )
          yellow_time <= (15)'(cmd_data_i * CLK_FREQ_HZ / 1000);
  end

// green_time
always_ff @( posedge clk_0m002 ) 
  begin
    if ( srst_i )
      green_time <= '0;
    else
      if (cmd_val_i == 1'b1)
        if ( ( cmd_type_i == (3)'(3) ) && ( state == YELLOW_BLINK ) )
          green_time <= (15)'(cmd_data_i * CLK_FREQ_HZ / 1000);
  end

// blink_counter
always_ff @( posedge clk_0m002 ) 
  begin
    if ( srst_i )
      blink_counter <= '0;
    else
      if ( ( state == YELLOW_BLINK ) || ( state == GREEN_BLINK ) )
        if ( blink_counter >= (2 * BLINK_QUART_PERIOD_CLK - 1))
          blink_counter <= '0;
        else
          blink_counter <= blink_counter + (15)'(1);
      else
        blink_counter <= '0;
  end

// Выходные сигналы
// red_o
// green_o
// yellow_o
always_comb
  begin
    red_o    = '0;
    yellow_o = '0;
    green_o  = '0;

    case ( state )
      RED:
        begin
          red_o    = '1;
          yellow_o = '0;
          green_o  = '0;
        end
      RED_YELLOW:
        begin
          red_o    = '1;
          yellow_o = '1;
          green_o  = '0;
        end
      GREEN:
        begin
          red_o    = '0;
          yellow_o = '0;
          green_o  = '1;
        end
      GREEN_BLINK:
        begin
          red_o    = '0;
          yellow_o = '0;

          if (blink_counter >= BLINK_QUART_PERIOD_CLK)
            green_o  = ~green_o;
        end
      YELLOW:
        begin
          red_o    = '0;
          yellow_o = '1;
          green_o  = '0;
        end
      YELLOW_BLINK:
        begin
          red_o = '0;

          if (blink_counter >= BLINK_QUART_PERIOD_CLK)
            yellow_o  = ~yellow_o;
          
          green_o = '0;
        end
      OFF:
        begin
          red_o    = '0;
          yellow_o = '0;
          green_o  = '0;
        end
    endcase
  end

endmodule