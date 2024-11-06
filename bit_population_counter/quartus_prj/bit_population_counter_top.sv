module bit_population_counter_top #(
  parameter DATA_W = 16
)(
  input  logic                      clk_i,
  input  logic                      srst_i,

  input  logic [DATA_W-1:0]         data_i,
  input  logic                      data_val_i,

  output logic [$clog2(DATA_W)+1:0] data_o,
  output logic                      data_val_o
);

logic                      srst;

logic [DATA_W-1:0]         data_input;
logic                      data_val_input;

logic [$clog2(DATA_W)+1:0] data_output;
logic                      data_val_output;

always_ff @( posedge clk_i )
  begin
    srst           <= srst_i;
    data_input     <= data_i;
    data_val_input <= data_val_i;
  end

bit_population_counter #(
  .DATA_W     ( DATA_W          )
) bit_population_counter_ins (
  .clk_i      ( clk_i           ),
  .srst_i     ( srst            ),

  .data_i     ( data_input      ),
  .data_val_i ( data_val_input  ),
  
  .data_o     ( data_output     ),
  .data_val_o ( data_val_output )
);

always_ff @( posedge clk_i )
  begin
    data_o     <= data_output;
    data_val_o <= data_val_output;
  end


endmodule