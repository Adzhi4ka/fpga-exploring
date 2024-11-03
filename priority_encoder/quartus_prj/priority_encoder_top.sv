module priority_encoder_top #(
  parameter DATA_W = 16
)(
  input logic               clk_i,
  input logic               srst_i,

  input logic  [DATA_W-1:0] data_i,
  input logic               data_val_i,

  output logic [DATA_W-1:0] data_left_o,
  output logic [DATA_W-1:0] data_right_o,
  output logic              data_val_o
);

logic              srst;

logic [DATA_W-1:0] data;
logic              data_val_input;

logic [DATA_W-1:0] data_left;
logic [DATA_W-1:0] data_right;
logic              data_val_output;

always_ff @( posedge clk_i )
  begin
    srst           <= srst_i;
    data           <= data_i;
    data_val_input <= data_val_i;
  end

priority_encoder #(
  .DATA_W       ( DATA_W          )
) priority_encoder_top_ins (
  .clk_i        ( clk_i           ),
  .srst_i       ( srst            ),

  .data_i       ( data            ),
  .data_val_i   ( data_val_input  ),

  .data_left_o  ( data_left       ),
  .data_right_o ( data_right      ),
  .data_val_o   ( data_val_output )
);

always_ff @( posedge clk_i )
  begin
    data_left_o  <= data_left;
    data_right_o <= data_right;
    data_val_o   <= data_val_output;
  end

endmodule