module serializer_tb;

parameter DATA_W     = 16;
parameter DATA_MOD_W = 4;

parameter TEST_CNT = 1000;

typedef struct {
  logic [DATA_W-1:0]     data;
  logic [DATA_MOD_W-1:0] data_mod;
} test_arg;

bit                    clk;
bit                    srst;
bit                    rst_done;

logic [DATA_W-1:0]     data;
logic [DATA_MOD_W-1:0] data_mod;
bit                    is_data_val;

bit                    ser_bit_data;
bit                    is_ser_data_val;

bit                    is_serializer_busy;

initial
  forever
    #5 clk = !clk;

default clocking cb
  @ (posedge clk);
endclocking

serializer #(
  .DATA_W         ( DATA_W             ),
  .DATA_MOD_W     ( DATA_MOD_W         )
) serializer_test (
  .clk_i          ( clk                ),
  .srst_i         ( srst               ),

  .data_i         ( data               ),
  .data_mod_i     ( data_mod           ),
  .data_val_i     ( is_data_val        ),

  .ser_data_o     ( ser_bit_data       ),
  .ser_data_val_o ( is_ser_data_val    ),

  .busy_o         ( is_serializer_busy )
);

mailbox #( test_arg ) generated_data = new();
mailbox #( test_arg ) sended_data    = new();
mailbox #( test_arg ) readed_data    = new();

task gen_data( input   int           cnt,
               mailbox #( test_arg ) data );
  test_arg data_to_send;

  for ( int i = 0; i < cnt; ++i)
    begin
      data_to_send.data     = $urandom_range(2**DATA_W - 1, 0);
      data_to_send.data_mod = $urandom_range(2**DATA_MOD_W - 1, 0);
      data.put( data_to_send );
    end

endtask

task serializer_wr( mailbox #( test_arg ) generated_data,
                    mailbox #( test_arg ) sended_data    );
  test_arg arg;

  while ( generated_data.num() )
    begin
      ##1
      if ( !is_serializer_busy )
        begin
          generated_data.get(arg);
          sended_data.put(arg);

          data        <= arg.data;
          data_mod    <= arg.data_mod;
          is_data_val <= 1'b1;

          ##1
          is_data_val <= 1'b0;
        end
    end

  wait( !is_serializer_busy );  
  srst <= 1'b1;
  ##1
  srst <= 1'b0;
endtask

task serializer_r( mailbox #( test_arg ) readed_data );
  test_arg readed;

  readed.data       <= '0;
  readed.data_mod   <= '0;

  forever
    begin
      if ( srst )
        begin
          readed_data.put(readed);
          return;
        end

      @( posedge is_ser_data_val ) 
      while ( is_ser_data_val )
        begin
          ##1
          readed.data[readed.data_mod] <= ser_bit_data;
          readed.data_mod              <= readed.data_mod + 1'b1;
        end


      readed_data.put(readed);
      readed.data       <= '0;
      readed.data_mod   <= '0;
    end  
endtask

task compare_data (mailbox #( test_arg ) sended_data,
                   mailbox #( test_arg ) readed_data);
  test_arg sended;
  test_arg readed;

  if ( sended_data.num() < readed_data.num() )
    begin
      $display( "Error! Serializer output more than need" );
      $stop();
    end
  
  for (int i = 0; i < sended_data.num(); ++i)
    begin
      if ( !readed_data.num() )
        begin
          $display( "Error! Serializer output less than need" );
          $stop();
        end
      
      sended_data.get(sended);
      if ( ( sended.data_mod == 1 ) || ( sended.data_mod == 2 ) )
        continue;

      readed_data.get(readed);
    
      if ( sended.data_mod != readed.data_mod )
        begin
          $display("ERROR! Data mod don`t match, %d", i);
          $display("Reference data mod: %d", sended.data_mod);
          $display("Readed data mod: %d", readed.data_mod);
          $stop();
        end
      
      for (int j = 0; j < sended.data_mod; ++j)
        begin
          if (sended.data[2**DATA_W - 1 - j] != readed.data[j])
            begin
              $display("ERROR! Data don`t match. (Readed data is reversed)");
              $display("Reference data: %d", sended.data);
              $display("Readed data: %d", readed.data);
              $stop();
            end
        end
    end
endtask

initial
  begin
    srst     <= 1'b0;
    ##1;
    srst     <= 1'b1;
    ##1;
    srst     <= 1'b0;
    rst_done <= 1'b1;
  end

initial 
  begin
    gen_data( TEST_CNT, generated_data );

    wait( rst_done );

    fork
      serializer_wr(generated_data, sended_data);
      serializer_r(readed_data);
    join

    compare_data(sended_data, readed_data);
    $display("TEST PASSED!");
    $stop();
  end

endmodule