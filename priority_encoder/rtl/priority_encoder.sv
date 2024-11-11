module priority_encoder #(
  parameter DATA_W = 16
)(
  input  logic             clk_i,
  input  logic             srst_i,

  input  logic[DATA_W-1:0] data_i,
  input  logic             data_val_i,

  output logic[DATA_W-1:0] data_left_o,
  output logic[DATA_W-1:0] data_right_o,
  output logic             data_val_o
);

function logic [DATA_W-1:0] ReverseBits(logic [DATA_W-1:0] data);
  logic [DATA_W-1:0] reversed_data;

  for (integer i = 0; i < DATA_W; i++) 
    reversed_data[i] = data[DATA_W-1-i];

  return reversed_data;
endfunction

logic [DATA_W-1:0] reversed_data;
logic [DATA_W-1:0] reversed_data_left;
logic [DATA_W-1:0] data_i_buff;

assign reversed_data      = ReverseBits(data_i_buff);
assign reversed_data_left = reversed_data & (-reversed_data);
assign data_left_o        = ReverseBits(reversed_data_left);
assign data_right_o       = data_i_buff & (-data_i_buff);

// data_val_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i ) 
      data_val_o <= '0;
    else
      data_val_o <= data_val_i;
  end

// data_i_buff
always_ff @( posedge clk_i )
  begin
    if ( data_val_i )
      data_i_buff <= data_i;
  end

endmodule