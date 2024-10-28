module deserializer_tb;

parameter DATA_O_W = 20;
parameter TEST_CNT = 100;

typedef struct {
  logic                data[$];
  logic                data_val[$];
  logic [DATA_O_W-1:0] expected_data;
} test_arg;

bit                   clk;
bit                   srst;
bit                   rst_done;

logic                 data;
logic                 data_val;

logic [DATA_O_W-1:0] deser_data;
logic                deser_data_val;

initial
  forever
    #5 clk = !clk;

default clocking cb
  @ (posedge clk);
endclocking

deserializer #(
  .DATA_O_W         ( DATA_O_W       )
) deserializer_test (
  .clk_i            ( clk            ),
  .srst_i           ( srst           ),

  .data_i           ( data           ),
  .data_val_i       ( data_val       ),

  .deser_data_o     ( deser_data     ),
  .deser_data_val_o ( deser_data_val )
);

mailbox #( test_arg             ) generated_data = new();
mailbox #( logic [DATA_O_W-1:0] ) sended_data    = new();
mailbox #( logic [DATA_O_W-1:0] ) readed_data    = new();

task gen_data( input   int           cnt,
               mailbox #( test_arg ) data );

  int count_puted_bits;

  for ( int i = 0; i < cnt; ++i)
    begin
      test_arg data_to_send;

      data_to_send.expected_data = $urandom_range(2**DATA_O_W - 1, 0);
      
      count_puted_bits = 0;

      while ( count_puted_bits < DATA_O_W )
        begin
          if ( $urandom_range(1, 0) )
            begin
              data_to_send.data.push_back(data_to_send.expected_data[count_puted_bits]);
              data_to_send.data_val.push_back(1'b1);
              ++count_puted_bits;
            end
          else
            begin
              data_to_send.data.push_back($urandom_range(1, 0));
              data_to_send.data_val.push_back(1'b0);
            end
        end
    
      data.put( data_to_send );
      data_to_send.data.delete();
      data_to_send.data_val.delete();
    end

endtask

task deserializer_wr( mailbox #( test_arg )             generated_data,
                      mailbox #( logic [DATA_O_W-1:0] ) sended_data    );
  test_arg arg;

  while ( generated_data.num() )
    begin

      generated_data.get(arg);
      sended_data.put(arg.expected_data);

      while ( arg.data.size() )
        begin
          ##1
          data     <= arg.data.pop_front();
          data_val <= arg.data_val.pop_front();
        end

        ##1
        data_val <= 1'b0;
    end
    
  
  ##1
  srst <= 1'b1;
  ##1
  srst <= 1'b0;
endtask

task deserializer_r( mailbox #( logic [DATA_O_W-1:0] ) readed_data );
  forever
    begin
      if ( srst )
          return;

      ##1
      if ( deser_data_val )
          readed_data.put( deser_data );
    end  
endtask

task compare_data (mailbox #( logic [DATA_O_W-1:0] ) sended_data,
                   mailbox #( logic [DATA_O_W-1:0] ) readed_data);
  logic [DATA_O_W-1:0] sended;
  logic [DATA_O_W-1:0] readed;

  if ( sended_data.num() != readed_data.num() )
    begin
      $display( "Size of ref data: %d", sended_data.num() );
      $display( "And sized of dut data: %d", readed_data.num() );
      $display( "Do not match" );
      $stop();
    end
  
  for (int i = 0; i < sended_data.num(); ++i)
    begin
      sended_data.get(sended);
      readed_data.get(readed);
      
      for (int j = 0; j < DATA_O_W; ++j)
        begin
          if (sended[DATA_O_W - 1 - j] != readed[j])
            begin
              $display("ERROR! Data don`t match. (Readed data is reversed)");
              $display("Reference data: %b", sended);
              $display("Readed data:    %b", readed);
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
      deserializer_wr(generated_data, sended_data);
      deserializer_r(readed_data);
    join

    compare_data(sended_data, readed_data);
    $display("TEST PASSED!");
    
    $stop();
  end

endmodule
