module traffic_lights_tb;

parameter BLINK_HALF_PERIOD_MS  = 10;
parameter BLINK_GREEN_TIME_TICK = 4;
parameter RED_YELLOW_MS         = 15;

parameter CYCLE_COUNT = 4;

typedef struct {
  int red_ms;
  int green_ms;
  int yellow_ms;
} color_times;

typedef struct {
  int red_clk_count             = 0;
  int red_yellow_clk_count      = 0;
  int green_clk_count           = 0;
  int green_blink_clk_off_count = 0;
  int green_blink_clk_on_count  = 0;
  int yellow_clk_count          = 1;
} lights_clk_count;

bit          clk_i;
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
    #5 clk_i = !clk_i;

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
  @ (posedge clk_i);
endclocking

traffic_lights #(
  .BLINK_HALF_PERIOD_MS  ( BLINK_HALF_PERIOD_MS  ),
  .BLINK_GREEN_TIME_TICK ( BLINK_GREEN_TIME_TICK ),
  .RED_YELLOW_MS         ( RED_YELLOW_MS         )
) traffic_lights_test (
  .clk_i                 ( clk_i                 ),
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

task add_setting(input color_times times);
  send_command((3)'(3), (15)'(times.green_ms));  // время зеленого
  ##1
  send_command((3)'(4), (15)'(times.red_ms));    // время красного
  ##1
  send_command((3)'(5), (15)'(times.yellow_ms)); // время желтого
endtask

task start_work();
  send_command((3)'(0));
endtask

event red_end;
event red_yellow_end;
event green_end;
event green_blink_end;
event yellow_end;

mailbox #( int ) readed_clk_cnt = new();

task watching_work( int cycle_count, mailbox #( int ) readed_clk_cnt);
  lights_clk_count counter;
  for (int i = 0; i < cycle_count; ++i)
    begin
      while ( red && !yellow && !green )
        begin
          ##1
          counter.red_clk_count <= counter.red_clk_count + 1;
        end

      readed_clk_cnt.put(counter.red_clk_count + 1);
      -> red_end;

      while ( red && yellow && !green )
        begin
          ##1
          counter.red_yellow_clk_count <= counter.red_yellow_clk_count + 1;
        end
      
      readed_clk_cnt.put(counter.red_yellow_clk_count + 1);
      -> red_yellow_end;

      while ( !red && !yellow && green )
        begin
          ##1
          counter.green_clk_count <= counter.green_clk_count + 1;
        end

      readed_clk_cnt.put(counter.green_clk_count + 1);
      -> green_end;

      for ( int i = 0; i < BLINK_GREEN_TIME_TICK; ++i )
        begin
          while ( !green && !yellow && !red )
            begin
              ##1
              counter.green_blink_clk_off_count <= counter.green_blink_clk_off_count + 1;
            end

          while ( green && !yellow && !red )
            begin
              ##1
              counter.green_blink_clk_on_count <= counter.green_blink_clk_on_count + 1;
            end
        end

      readed_clk_cnt.put(counter.green_blink_clk_off_count + 1);
      readed_clk_cnt.put(counter.green_blink_clk_on_count + 1);
      -> green_blink_end;
      
      while ( !red && yellow && !green )
        begin
          ##1
          counter.yellow_clk_count <= counter.yellow_clk_count + 1;
        end

      readed_clk_cnt.put(counter.yellow_clk_count + 1);
      -> yellow_end;
    end
endtask

task check_output( color_times times, int cycle_count, mailbox #( int ) readed_clk_cnt );
  lights_clk_count counter;
  for (int i = 1; i <= cycle_count; ++i)
    begin
      @(red_end)
      readed_clk_cnt.get(counter.red_clk_count);

      if (times.red_ms * i != counter.red_clk_count / 2)
        begin
          $display("Red ref time, ms - %d", counter.red_clk_count / 2);
          $display("Red time, ms     - %d ", times.red_ms * i);

          $stop();
        end

      @(red_yellow_end)
      readed_clk_cnt.get(counter.red_yellow_clk_count);

      if (RED_YELLOW_MS * i != counter.red_yellow_clk_count / 2)
        begin
          $display("RedYellow ref time, ms - %d", (counter.red_yellow_clk_count) / 2);
          $display("RedYellow time, ms     - %d", RED_YELLOW_MS * i);
          
          $stop();
        end

      @(green_end)
      readed_clk_cnt.get(counter.green_clk_count);

      if (times.green_ms * i != counter.green_clk_count / 2)
        begin
          $display("Green ref time, ms - %d", counter.green_clk_count / 2);
          $display("Green time, ms     - %d", times.green_ms * i);

          $stop();
        end

      @(green_blink_end)
      readed_clk_cnt.get(counter.green_blink_clk_off_count);
      readed_clk_cnt.get(counter.green_blink_clk_on_count);

      if (BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK * i != counter.green_blink_clk_off_count / 2)
        begin
          $display("GreenOffBlinkTime ref time, ms - %d", 
            counter.green_blink_clk_off_count / 2);
          $display("GreenOffBlinkTime time, ms     - %d", 
            BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK * i);
            
          $stop();
        end

      if (BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK * i != counter.green_blink_clk_on_count / 2)
        begin
          $display("GreenOnBlinkTime ref time, ms - %d", 
            counter.green_blink_clk_on_count / 2);
          $display("GreenOnBlinkTime time, ms     - %d", 
            BLINK_HALF_PERIOD_MS * BLINK_GREEN_TIME_TICK * i);

          $stop();
        end

      @(yellow_end)
      readed_clk_cnt.get(counter.yellow_clk_count);

      if (times.yellow_ms * i != counter.yellow_clk_count / 2)
        begin
          $display("Yellow ref time, ms - %d", counter.yellow_clk_count / 2);
          $display("Yellow time, ms     - %d", times.yellow_ms * i);

          $stop();
        end
    end
endtask

task noise_creator(int cycle_count);
  for (int i = 0; i < cycle_count; ++i)
    begin
      @(red_end)
      cmd_type <= $urandom_range(5, 3);
      cmd_data <= $urandom_range(2**15, 0);

      @(red_yellow_end)
      cmd_type <= $urandom_range(5, 3);
      cmd_data <= $urandom_range(2**15, 0);

      @(green_end)
      cmd_type <= $urandom_range(5, 3);
      cmd_data <= $urandom_range(2**15, 0);

      @(green_blink_end)
      cmd_type <= $urandom_range(5, 3);
      cmd_data <= $urandom_range(2**15, 0);

      @(yellow_end)
      cmd_type <= $urandom_range(5, 3);
      cmd_data <= $urandom_range(2**15, 0);
    end
endtask

initial 
  begin
    color_times times = '{red_ms: 10, green_ms: 10, yellow_ms: 10};
    lights_clk_count counter;

    wait( rst_done );

    set_setting_mode();
    add_setting(times);

    start_work();    

    fork
      watching_work(CYCLE_COUNT, readed_clk_cnt);
      check_output(times, CYCLE_COUNT, readed_clk_cnt);      
    join

    $display("TEST PASSED!");

    $stop();
  end

endmodule