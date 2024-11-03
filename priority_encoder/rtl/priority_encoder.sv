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

// data_val_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i ) 
      data_val_o <= '0;
    else
      if ( data_val_i )
        data_val_o <= '1;
      else
        data_val_o <= '0;
  end

// data_right_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i ) 
      data_right_o <= '0;
    else 
      if ( data_val_i )
        data_right_o <= data_i & (~data_i + 1'b1);
  end

// data_left_o
always_ff @( posedge clk_i )
  begin
    if ( srst_i ) 
      data_left_o <= '0;
    else 
      if ( data_val_i )
        for (int i = DATA_W-1; i >= 0; --i)
          if ( data_i[i] )
            begin
              data_left_o <= ((DATA_W)'(0) | ((DATA_W)'(1) << i));
              break;
            end
          else
            data_left_o <= (DATA_W)'(0);
  end
    
endmodule