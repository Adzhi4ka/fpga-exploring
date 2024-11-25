module debouncer_tb;

parameter PULSE_LENGTH = 20; // в тактах
parameter TASKS_CNT    = 100;

parameter CLK_FREQ_MHZ = 100;
parameter GLITCH_TIME_NS = 100;
  
parameter CLEAR_TASK_CNT = TASKS_CNT / 10;
parameter NOISE_TASK_CNT = TASKS_CNT - CLEAR_TASK_CNT;

bit   clk;

logic key;
logic key_pressed_stb;

event start_stable;

typedef struct {
  int before_stable_duration;
  int stable_duration;
  int after_stable_duration;
  int pause_duration;
} task_t;

typedef struct {
  int key_pressed_stb_clk_count;
} pulse_stat_t;

enum logic {
  CLEAR_TASK = 1'b0,
  NOISE_TASK = 1'b1
} task_status;

task generate_tasks ( mailbox #( task_t ) gt,
                      int                 task_cnt,
                      int                 stable_duration,
                      bit                 task_status = NOISE_TASK
                    );
  for (int i = 0; i < task_cnt; i++ )
    begin
      task_t new_task;
      if( task_status == CLEAR_TASK )
        begin
          new_task.before_stable_duration = 0;
          new_task.after_stable_duration  = 0;
        end
      else
        begin
          new_task.before_stable_duration = $urandom_range(stable_duration/4,1);
          new_task.after_stable_duration  = $urandom_range(stable_duration/4,1);
        end
      new_task.stable_duration = stable_duration;
      new_task.pause_duration  = stable_duration;
      gt.put( new_task );
    end
endtask

task automatic glitch_time_receive( int press_count, ref int signal_stat[$] );
  int glitch_clk_count = 0;

  for (int i = 0; i < press_count; ++i)
    begin
      @(start_stable);
      ##1
      while ( key_pressed_stb == 0 )
        begin
          ##1
          glitch_clk_count += 1;
        end
        
      signal_stat.push_back(glitch_clk_count);
      glitch_clk_count = 0;
    end
endtask

task automatic key_pressed_stb_counter( int timeout, output int strobe_count );
  int tick_counter;

  tick_counter = 0;
  strobe_count = 0;

  while ( tick_counter < timeout )
    begin
      ##1
      if (key_pressed_stb == 1'b1)
        strobe_count += 1;
      
      tick_counter += 1;
    end
endtask

task send_tasks( mailbox #( task_t ) st );
  while ( st.num != 0 )
    begin
      task_t send_task;

      st.get( send_task );

      for ( int i = 0; i < send_task.pause_duration; i++ )
        begin
          ##1;
          key <= 1'b1;
        end

      for ( int i = 0; i < send_task.before_stable_duration - 1; i++ )
        begin
          ##1;
          key <= $urandom_range(1,0);
        end

      ##1;
      key <= '1;

      -> start_stable;
      for ( int i = 0; i < send_task.stable_duration; i++ )
        begin
          ##1;
          key <= 1'b0;
        end

      for ( int i = 0; i < send_task.after_stable_duration; i++ )
        begin
          ##1;
          key <= $urandom_range(1,0);
        end
    end
endtask

function automatic bit check_glitch_time(ref int signal_stat[$]);
  int clk_time;

  while ( signal_stat.size() )
    begin
      clk_time = signal_stat.pop_back();
      if ( clk_time < CLK_FREQ_MHZ * GLITCH_TIME_NS / 1000)
        begin
          $error("Glitch time less than expected: %d", clk_time);

          return 0;
        end
    end

  return 1;
endfunction

function automatic bit check_test(int task_count, int strobe_received_cnt, ref int signal_stat[$]);
  if( signal_stat.size() != task_count )
    begin
      $display( "Not all pulses were recieved in test! %d", signal_stat.size() );

      return 0;
    end

  if ( strobe_received_cnt != task_count)
    begin
      $display( "More than expected strobes! %d", strobe_received_cnt );

      return 0;
    end

  return check_glitch_time(signal_stat);
endfunction

initial
  forever
    #5 clk = !clk;

default clocking cb
  @ (posedge clk);
endclocking

debouncer #(
  .CLK_FREQ_MHZ      ( CLK_FREQ_MHZ    ),
  .GLITCH_TIME_NS    ( GLITCH_TIME_NS  )
) db_inst (
  .clk_i             ( clk             ),

  .key_i             ( key             ),
  .key_pressed_stb_o ( key_pressed_stb )
);

mailbox #( task_t ) gen_tasks = new();

int                 clear_signal_stat[$];
int                 noise_signal_stat[$];

int                 clear_strobe_cnt;
int                 noise_strobe_cnt;

initial
  begin
    $display( "Starint tests. Config:" );
    $display( "\t PULSE_LENGTH (stable time for each input pulse) = %d", PULSE_LENGTH );
    $display( "\t TASKS_CNT (count of task to send) = %d", TASKS_CNT );
    $display( "Starting with sending %d clear signals with no noise", CLEAR_TASK_CNT );

    generate_tasks( gen_tasks, CLEAR_TASK_CNT, PULSE_LENGTH, CLEAR_TASK );

    fork
      send_tasks( gen_tasks );
      glitch_time_receive( CLEAR_TASK_CNT, clear_signal_stat );
      key_pressed_stb_counter( 3 * PULSE_LENGTH * NOISE_TASK_CNT, clear_strobe_cnt );
    join

    if ( check_test(CLEAR_TASK_CNT, clear_strobe_cnt, clear_signal_stat) )
      $display( "### Test 1 with clear signal done ###" );
    else
      $display( "### Test 1 with clear signal FAILED ###" );


    $display( "\nStarting test #2: sending %d signals with noise", NOISE_TASK_CNT );

    generate_tasks( gen_tasks, NOISE_TASK_CNT, PULSE_LENGTH, NOISE_TASK );

    fork
      send_tasks( gen_tasks );
      glitch_time_receive( NOISE_TASK_CNT, noise_signal_stat );
      key_pressed_stb_counter( 3 * PULSE_LENGTH * NOISE_TASK_CNT, noise_strobe_cnt);
    join

    if ( check_test(NOISE_TASK_CNT, noise_strobe_cnt, noise_signal_stat) )
      $display( "### Test 2 with noise signal done ###" );
    else
      $display( "### Test 2 with noise signal FAILED ###" );

    $stop();
  end

endmodule