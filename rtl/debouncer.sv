module debouncer #(
  parameter CLK_FREQ_MHZ,
  parameter GLITCH_TIME_NS
)(
  input  logic clk_i,

  input  logic key_i,
  output logic key_pressed_stb_o
);

// Сам модуль дает задержку в 3 такта
localparam DB_LATENCY = 5;

// + 999 -- Округление вверх
localparam DB_CNT_MAX = ((CLK_FREQ_MHZ * GLITCH_TIME_NS / 1000) - DB_LATENCY) > 0 ?
                        ((CLK_FREQ_MHZ * GLITCH_TIME_NS / 1000) - DB_LATENCY) : 0;

localparam DB_CNT_W   = $clog2(DB_CNT_MAX);

logic [3:0]        key_d;
logic              key_differ;

logic [DB_CNT_W:0] db_counter;
logic              db_counter_max;

logic              was_pressed;

// db_counter_max
assign db_counter_max = ( db_counter >= DB_CNT_MAX );

// db_counter
always_ff @( posedge clk_i )
  begin
    if (key_differ)
      db_counter <= '0;
    else
      if ( !db_counter_max )
        db_counter <= db_counter + (DB_CNT_W)'(1);
  end

// key_d
always_ff @( posedge clk_i)
  begin
    key_d[0] <= key_i;
    key_d[1] <= key_d[0];
    key_d[2] <= key_d[1];
    key_d[3] <= key_d[2];
  end

// key_differ
assign key_differ = key_d[3] ^ key_d[2];

// key_pressed_stb_o
always_ff @( posedge clk_i )
  begin
    if ( db_counter_max && ( was_pressed == 0) )
      key_pressed_stb_o <= !key_d[3];
    else 
      key_pressed_stb_o <= '0;
  end

// was_pressed
always_ff @( posedge clk_i )
  begin
    if ( db_counter_max )
      was_pressed = !key_d[3];
    else
      was_pressed = 0;
  end

endmodule