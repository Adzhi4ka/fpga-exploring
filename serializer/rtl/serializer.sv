parameter DATA_W = 16;
parameter DATA_MOD_W = 4;

module serializer(
  input  logic                      clk_i,
  input  logic                      srst_i,

  input  logic [DATA_W - 1:0]      data_i,
  input  logic [DATA_MOD_W - 1:0]  data_mod_i,
  input  logic                     data_val_i,

  output logic                     ser_data_o,
  output logic                     ser_data_val_o,

  output logic                     busy_o
);

logic [DATA_W - 1:0]     data_i_buff;
logic [DATA_MOD_W - 1:0] data_mod_i_buff;
logic [DATA_MOD_W:0] counter;

always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      begin
        data_i_buff     <= 0;
        data_mod_i_buff <= 0;
        ser_data_o      <= 0;
        ser_data_val_o  <= 0;
        busy_o          <= 0;
      end
    else 
      begin
        if ( data_val_i && !busy_o )
          begin
            if ( data_mod_i >= 1 && data_mod_i <= 2 )
              busy_o <= 0;
            else
              begin
                data_i_buff     <= data_i;
                data_mod_i_buff <= data_mod_i == 0 ? 3'b0 : data_mod_i - 1'b1;
                counter         <= 0;
                busy_o          <= 1;
              end
          end

        if (busy_o)
          begin
            if (( data_mod_i_buff == 0 && counter == ( DATA_W ) ) || 
                ( counter > data_mod_i_buff && data_mod_i_buff != 0 )
            )
              begin
                busy_o         <= 0;
                ser_data_val_o <= 0;
              end
            else
              begin
                ser_data_o      <= data_i_buff[DATA_W - 1 - counter];
                ser_data_val_o  <= 1;
                counter         <= counter + 1'b1;
              end
          end
      end
  end

endmodule