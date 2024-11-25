module debouncer_top #(
  parameter CLK_FREQ_MHZ = 150,
  parameter GLITCH_TIME_NS = 100
)(
  input  logic clk_i,

  input  logic key_i,
  output logic key_pressed_stb_o
);

logic key;
logic key_pressed_stb;

always_ff @( posedge clk_i )
  begin
    key  <= key_i;
  end

debouncer #(
  .CLK_FREQ_MHZ   ( CLK_FREQ_MHZ   ),
  .GLITCH_TIME_NS ( GLITCH_TIME_NS )
) debouncer_ins (
  .clk_i             ( clk_i           ),

  .key_i             ( key             ),
  .key_pressed_stb_o ( key_pressed_stb )
);

always_ff @( posedge clk_i )
  begin
    key_pressed_stb_o <= key_pressed_stb;
  end

endmodule