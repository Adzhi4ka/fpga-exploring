module traffic_lights_top #(
  parameter           BLINK_HALF_PERIOD_MS = 10,
  parameter           BLINK_GREEN_TIME_TICK = 5,
  parameter           RED_YELLOW_MS = 10
)(
  input  logic        clk_i,
  input  logic        srst_i,

  input  logic [2:0]  cmd_type_i,
  input  logic        cmd_val_i,

  input  logic [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o 
);

logic        srst;

logic [2:0]  cmd_type;
logic        cmd_val;

logic [15:0] cmd_data;

logic        red;
logic        yellow;
logic        green;

always_ff @( posedge clk_i )
  begin
    srst     <= srst_i;
    cmd_type <= cmd_type_i;
    cmd_val  <= cmd_val_i;
    cmd_data <= cmd_data_i;
  end

traffic_lights #(
  .BLINK_HALF_PERIOD_MS  ( BLINK_HALF_PERIOD_MS  ),
  .BLINK_GREEN_TIME_TICK ( BLINK_GREEN_TIME_TICK ),
  .RED_YELLOW_MS         ( RED_YELLOW_MS         )
) traffic_lights_test (
  .clk_i             ( clk_i             ),
  .srst_i                ( srst                  ),

  .cmd_type_i            ( cmd_type              ),
  .cmd_val_i             ( cmd_val               ),

  .cmd_data_i            ( cmd_data              ),

  .red_o                 ( red                   ),
  .yellow_o              ( yellow                ),
  .green_o               ( green                 ) 
);

always_ff @( posedge clk_i )
  begin
    red_o    <= red;
    yellow_o <= yellow;
    green_o  <= green;
  end

endmodule