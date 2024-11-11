module traffic_lights_tb;

parameter BLINK_HALF_PERIOD_MS  = 10;
parameter BLINK_GREEN_TIME_TICK = 2;
parameter RED_YELLOW_MS         = 15;


bit                        clk_0m002;
bit                        srst;
bit                        rst_done;

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

initial 
  begin
    wait( rst_done );

    // Запуск модуля
    ##3
    cmd_type  <= (3)'(2);
    cmd_val   <= '1;

    ##1
    cmd_val   <= '0;

    // Время зеленого
    ##3
    cmd_type  <= (3)'(3);
    cmd_val   <= '1;
    cmd_data  <= (15)'(10);

    ##1
    cmd_val   <= '0;

    // Время красного
    ##3
    cmd_type  <= (3)'(4);
    cmd_val   <= '1;
    cmd_data  <= (15)'(10);

    ##1
    cmd_val   <= '0;

    // Время желтого
    ##3
    cmd_type  <= (3)'(5);
    cmd_val   <= '1;
    cmd_data  <= (15)'(10);

    ##1
    cmd_val   <= '0;

    // Запуск светофора
    ##3
    cmd_type  <= (3)'(0);
    cmd_val   <= '1;

    ##1
    cmd_val   <= '0;

    ##10000

    $display("%d", (2000 * RED_YELLOW_MS) / 1000);
    $stop();
  end

endmodule;