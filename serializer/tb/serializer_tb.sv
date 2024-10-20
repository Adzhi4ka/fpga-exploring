module serializer_tb;

bit clk;
initial
  forever
    #5 clk = !clk;

bit sync_reset;
logic [15:0] input_data;
logic [4:0] input_data_mod;
bit is_data_valid;

bit serialized_bit_data;
bit is_valid_serialized_bit_data;

bit is_serializer_busy;

serializer serializer_test (
  .clk_i          ( clk                          ),
  .srst_i         ( sync_reset                   ),

  .data_i         ( input_data                   ),
  .data_mod_i     ( input_data_mod               ),
  .data_val_i     ( is_data_valid                ),

  .ser_data_o     ( serialized_bit_data          ),
  .ser_data_val_o ( is_valid_serialized_bit_data ),

  .busy_o         ( is_serializer_busy           )
);

int test_file;
int file_data;
int file_data_mod;

initial
  begin
    test_file = $fopen("/home/adzhi4ka/fpga-exploring/serializer/tb/test.txt", "r");

    if( !test_file )
      begin
        $display("File test.txt was NOT found!");
        $stop();
      end

    @( posedge clk );
    sync_reset <= 1'b1;
    @( posedge clk );
    sync_reset <= 1'b0;

    while( !$feof(test_file) )
      begin
        $fscanf(test_file, "%d", file_data);
        $fscanf(test_file, "%d", file_data_mod);

        $display("%b, %b \n", input_data, input_data_mod);

        @( posedge clk );
        input_data     <= file_data;
        input_data_mod <= file_data_mod;
        is_data_valid  <= 1;

        @( posedge clk );
        is_data_valid  <= 0;

        @( posedge clk );
        for (int i = 0; i < file_data_mod; i++)
          begin
            @( posedge clk );
            if (( is_serializer_busy )                         &&
                ( !is_valid_serialized_bit_data )              && 
                ( serialized_bit_data != input_data[15 - i] ))
              begin
                $display("Test failed\n");
                $stop();
              end
          end      
      end

    $display("Test passed\n");  
    $stop();
  end

endmodule