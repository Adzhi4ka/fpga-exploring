module bit_population_counter #(
  parameter DATA_W = 16
)(
  input  logic                      clk_i,
  input  logic                      srst_i,

  input  logic [DATA_W-1:0]         data_i,
  input  logic                      data_val_i,

  output logic [$clog2(DATA_W)+1:0] data_o,
  output logic                      data_val_o
);

logic [DATA_W-1:0]         data_input_buff;
logic [$clog2(DATA_W)+1:0] counter;

// data_val_o
assign data_o = counter;

// data_input_buff
always_ff @( posedge clk_i ) 
  begin
    if ( srst_i )
      data_input_buff <= '0;
    else
      if ( data_val_i )
        data_input_buff <= data_i;
      else 
        data_input_buff <= data_input_buff & (data_input_buff - 1'b1);
  end

// counter
always_ff @( posedge clk_i ) 
  begin
    if ( srst_i )
      counter <= '0;
    else
      if ( data_val_i )
        counter <= '0;
      else
        if ( data_input_buff != 0 )
          counter <= counter + 1'b1;
  end

// data_val_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      data_val_o <= '0;
    else
      if ( data_input_buff == '0 && !data_val_o && !data_val_i )
        data_val_o <= '1;
      else
        data_val_o <= '0;
  end

  
endmodule