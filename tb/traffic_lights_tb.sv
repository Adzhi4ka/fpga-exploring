module traffic_lights_tb;

parameter BLINK_HALF_PERIOD_MS  = 10;
parameter BLINK_GREEN_TIME_TICK = 2;
parameter RED_YELLOW_MS         = 15;

parameter RED_MS    = 10;
parameter GREEN_MS  = 10;
parameter YELLOW_MS = 10;



bit          clk_0m002;
bit          srst;
bit          rst_done;

logic [2:0]  cmd_type;
logic        cmd_val;

logic [15:0] cmd_data;

logic        red;
logic        yellow;
logic        green;

initial
  forever
    #250 clk_0m002 = !clk_0m002;

initial
  begin
    srst     <= 1'b0;
    ##1;
    srst     <= 1'b1;
    ##1;
    srst     <= 1'b0;
    rst_done <= 1'b1;
  end

default clocking cb
  @ (posedge clk_0m002);
endclocking

traffic_lights #(
  .BLINK_HALF_PERIOD_MS  ( BLINK_HALF_PERIOD_MS  ),
  .BLINK_GREEN_TIME_TICK ( BLINK_GREEN_TIME_TICK ),
  .RED_YELLOW_MS         ( RED_YELLOW_MS         )
) traffic_lights_test (
  .clk_0m002             ( clk_0m002             ),
  .srst_i                ( srst                  ),

  .cmd_type_i            ( cmd_type              ),
  .cmd_val_i             ( cmd_val               ),

  .cmd_data_i            ( cmd_data              ),

  .red_o                 ( red                   ),
  .yellow_o              ( yellow                ),
  .green_o               ( green                 ) 
);

task send_command(input logic [2:0] command, logic [15:0] data = 0);
  begin
    cmd_type <= command;
    cmd_data <= data;
    cmd_val  <= '1;

    ##1
    cmd_val  <= '0;
  end
endtask

task set_setting_mode();
  send_command((3)'(2));
endtask;

task add_setting();
  send_command((3)'(3), (15)'(GREEN_MS)); // время зеленого
  ##1
  send_command((3)'(4), (15)'(RED_MS)); // время красного
  ##1
  send_command((3)'(5), (15)'(YELLOW_MS)); // время желтого
endtask

task start_work();
  send_command((3)'(0));
endtask

task watching_stable_work();
  int red_clk_count;
  int red_yellow_clk_count;
  int green_clk_count;
  int green_blink_clk_off_count;
  int green_blink_clk_on_count;
  int yellow_clk_count;

  int blink;

  red_clk_count             <= 0;
  red_yellow_clk_count      <= 0;
  green_clk_count           <= 0;
  green_blink_clk_off_count <= 0;
  green_blink_clk_on_count  <= 0;
  yellow_clk_count          <= 0;
  
  while ( (red) && (!yellow) && (!green) )
    begin
      ##1
      red_clk_count <= red_clk_count + 1;
    end

  while ( red && yellow && !green )
    begin
      ##1
      red_yellow_clk_count <= red_yellow_clk_count + 1;
    end
  
  while ( !red && !yellow && green )
    begin
      ##1
      green_clk_count <= green_clk_count + 1;
    end

  for ( int i = 0; i < BLINK_GREEN_TIME_TICK; ++i )
    begin
      while ( !green && !yellow && !red )
        begin
          ##1
          green_blink_clk_off_count <= green_blink_clk_off_count + 1;
        end

      while ( green && !yellow && !red )
        begin
          ##1
          green_blink_clk_on_count <= green_blink_clk_on_count + 1;
        end
    end
  
  while ( !red && yellow && !green )
    begin
      ##1
      yellow_clk_count <= yellow_clk_count + 1;
    end
  
  ##1
  watching_stable_output( red_clk_count,
                          red_yellow_clk_count,
                          green_clk_count,
                          green_blink_clk_off_count,
                          green_blink_clk_on_count,
                          yellow_clk_count           );
endtask

task watching_stable_output( input
  int red_clk_count,
  int red_yellow_clk_count,
  int green_clk_count,
  int green_blink_clk_off_count,
  int green_blink_clk_on_count,
  int yellow_clk_count
);
  $display("Red ref time, ms               - %d", (red_clk_count * 500) / 1000);
  $display("Red time, ms                   - %d ", RED_MS);

  $display("==============================================================================");

  $display("RedYellow ref time, ms         - %d", (red_yellow_clk_count * 500) / 1000);
  $display("RedYellow time, ms             - %d", RED_YELLOW_MS);

  $display("==============================================================================");

  $display("Green ref time, ms             - %d", (green_clk_count * 500) / 1000);
  $display("Green time, ms                 - %d", GREEN_MS);

  $display("==============================================================================");

  $display("GreenOnBlinkTime ref time, ms  - %d", (green_blink_clk_off_count * 500) / 1000);
  $display("GreenOnBlinkTime time, ms      - %d", BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK);

  $display("==============================================================================");

  $display("GreenOffBlinkTime ref time, ms - %d", (green_blink_clk_on_count * 500) / 1000);
  $display("GreenOffBlinkTime time, ms     - %d", BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK);

  $display("==============================================================================");

  $display("Yellow ref time, ms            - %d", (yellow_clk_count * 500) / 1000);
  $display("Yellow time, ms                - %d", YELLOW_MS);

endtask

initial 
  begin
    wait( rst_done );

    set_setting_mode();
    add_setting();

    start_work();

    watching_stable_work();

    $stop();
  end

endmodule;