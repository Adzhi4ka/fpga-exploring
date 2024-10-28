module deserializer #(
  parameter DATA_O_W = 16
)(
  input logic                 clk_i,
  input logic                 srst_i,

  input logic                 data_i,
  input logic                 data_val_i,

  output logic [DATA_O_W-1:0] deser_data_o,
  output logic                deser_data_val_o
);

localparam COUNTER_W = $clog2(DATA_O_W);

logic [DATA_O_W-1:0]  deser_data_buff;
logic [COUNTER_W-1:0] counter;

assign deser_data_o = deser_data_buff;

// deser_data_buff
always_ff @( posedge clk_i )
  begin
    if ( data_val_i )
        deser_data_buff[counter] <= data_i;
  end

// counter
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      counter <= (COUNTER_W)'(DATA_O_W - 1);
    else
      if ( data_val_i )
        if ( !counter )
          counter <= (COUNTER_W)'(DATA_O_W - 1);
        else
          counter <= counter - 1'b1;
  end

// deser_data_val_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      deser_data_val_o <= '0;
    else
      if ( !counter && !deser_data_val_o && data_val_i )
        deser_data_val_o <= '1;
      else 
        deser_data_val_o <= '0;
  end

endmodule
