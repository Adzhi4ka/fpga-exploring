module deserializer_top #(
  parameter DATA_O_W = 16
)(
  input logic                 clk_i,
  input logic                 srst_i,

  input logic                 data_i,
  input logic                 data_val_i,

  output logic [DATA_O_W-1:0] deser_data_o,
  output logic                deser_data_val_o
);

logic                srst;

logic                data;
logic                data_val;

logic [DATA_O_W-1:0] deser_data;
logic                deser_data_val;

always_ff @( posedge clk_i )
  begin
    srst     <= srst_i;
    data     <= data_i;
    data_val <= data_val_i;
  end

deserializer #(
  .DATA_O_W         ( DATA_O_W       )
) deserializer_ins (
  .clk_i            ( clk_i            ),
  .srst_i           ( srst           ),

  .data_i           ( data           ),
  .data_val_i       ( data_val       ),

  .deser_data_o     ( deser_data     ),
  .deser_data_val_o ( deser_data_val )
);

always_ff @( posedge clk_i )
  begin
    deser_data_o     <= deser_data;
    deser_data_val_o <= deser_data_val;
  end

endmodule
