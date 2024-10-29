module serializer #(
  parameter DATA_W     = 16,
  parameter DATA_MOD_W = 4
)(
  input  logic                     clk_i,
  input  logic                     srst_i,

  input  logic [DATA_W-1:0]        data_i,
  input  logic [DATA_MOD_W-1:0]    data_mod_i,
  input  logic                     data_val_i,

  output logic                     ser_data_o,
  output logic                     ser_data_val_o,

  output logic                     busy_o
);

localparam COUNTER_W = DATA_MOD_W + 1;

logic [DATA_W-1:0]     data_i_buff;
logic [DATA_MOD_W-1:0] data_mod_i_buff;
logic [COUNTER_W-1:0]  counter;

assign is_input_val = ( data_val_i         ) && 
                      ( data_mod_i != 'b1  ) && 
                      ( data_mod_i != 'b10 );

assign is_serializing_finished = ( ( ( data_mod_i_buff == (DATA_MOD_W)'(0) ) && ( counter == ( DATA_W )     ) ) || 
                                   ( ( data_mod_i_buff != (DATA_MOD_W)'(0) ) && ( counter > data_mod_i_buff ) ) );

// data_i_buff, data_mod_i_buff
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      begin
        data_i_buff     <= '0;
        data_mod_i_buff <= '0;
      end
    else
      if ( is_input_val )
        begin
          data_i_buff     <= data_i;
          data_mod_i_buff <= !data_mod_i ? (DATA_MOD_W)'(0) : data_mod_i - 1'b1;
        end
  end

// counter
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      counter <= '0;
    else
      if ( is_input_val )
        counter <= '0;
      else
        if ( busy_o )
          counter <= counter + 1'b1;
  end

// busy_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
        busy_o <= 1'b0;
    else
      if ( is_input_val )
        busy_o <= 1'b1;
      else if ( is_serializing_finished )
        busy_o <= 1'b0;
  end

// ser_data_val_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      ser_data_val_o <= 1'b0;
    else
      if ( busy_o )
        if ( is_serializing_finished )
          ser_data_val_o <= 1'b0;
        else
          ser_data_val_o <= 1'b1;
  end

// ser_data_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      ser_data_o <= 1'b0;
    else
      ser_data_o <= data_i_buff[(DATA_W - 1 - counter) & {DATA_MOD_W{1'b1}}];
  end

endmodule