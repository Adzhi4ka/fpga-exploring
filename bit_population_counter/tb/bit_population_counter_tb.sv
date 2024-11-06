module bit_population_counter_tb;

parameter DATA_W      = 25;
parameter BIT_COUNT_W = $clog2(DATA_W)+1;

parameter TEST_CNT    = 1000;


typedef struct {
  logic [DATA_W-1:0]         data;
  logic [BIT_COUNT_W:0] bit_count;
} test_arg;

bit                        clk;
bit                        srst;
bit                        rst_done;

logic [DATA_W-1:0]         data_input;
logic                      data_val_input;

logic [BIT_COUNT_W:0] data_output;
logic                      data_val_output;

initial
  forever
    #5 clk = !clk;

default clocking cb
  @ (posedge clk);
endclocking

bit_population_counter #(
  .DATA_W     ( DATA_W          )
) test (
  .clk_i      ( clk             ),
  .srst_i     ( srst            ),

  .data_i     ( data_input      ),
  .data_val_i ( data_val_input  ),
  
  .data_o     ( data_output     ),
  .data_val_o ( data_val_output )
);

mailbox #( test_arg             ) generated_data = new();
mailbox #( test_arg             ) sended_data    = new();
mailbox #( logic[BIT_COUNT_W:0] ) readed_data    = new();

task gen_data( input   int           cnt,
               mailbox #( test_arg ) data );
  test_arg data_to_send;

  for ( int i = 0; i < cnt; ++i)
    begin
      data_to_send.bit_count = 0;

      if (!$urandom_range(5, 0))
        begin
          data_to_send.data      = 0;
        end
      else
        begin
          data_to_send.data      = $urandom_range(2**DATA_W - 1, 0);

          for (int i = 0; i < DATA_W; ++i)
            data_to_send.bit_count += data_to_send.data[i];
        end

      data.put( data_to_send );
    end
endtask

task bit_population_counter_wr( mailbox #( test_arg ) generated_data,
                                mailbox #( test_arg ) sended_data    );
  test_arg arg;

  while ( generated_data.num() )
    begin
      ##1
      generated_data.get(arg);
      sended_data.put(arg);

      data_input     <= arg.data;
      data_val_input <= 1'b1;

      ##1
      data_val_input <= 1'b0;
      ##1
      wait( data_val_output );
    end

  wait( data_val_output );  
  ##1
  srst <= 1'b1;
  ##1
  srst <= 1'b0;
endtask

task bit_population_counter_r(mailbox #( logic[BIT_COUNT_W:0] ) readed_data);
    forever
      begin
        ##1
        if ( srst )
          return;
        
        wait( data_val_output );

        readed_data.put(data_output);

        wait( !data_val_output );
      end
endtask

task compare_data (mailbox #( test_arg              ) sended_data,
                   mailbox #( logic [BIT_COUNT_W:0] ) readed_data);

  test_arg              sended;
  logic [BIT_COUNT_W:0] readed;  

  if ( sended_data.num() != readed_data.num() )
    begin
      $display( "Size of ref data: %d", sended_data.num() );
      $display( "And sized of dut data: %d", readed_data.num() );
      $display( "Do not match" );
      $stop();
    end
  
  for (int i = 0; sended_data.num(); ++i)
    begin
      sended_data.get(sended);
      readed_data.get(readed);
      
      if ( sended.bit_count !== readed )
        begin
          $display("ERROR! Data don`t match.");
          $display("Reference data: %b", sended.data);
          $display("Reference bit count: %b", sended.bit_count);
          $display("Readed data: %b", readed);
          $stop();
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
      bit_population_counter_wr(generated_data, sended_data);
      bit_population_counter_r(readed_data);
    join

    compare_data(sended_data, readed_data);

    $display("TEST PASSED");
    $stop();
  end

endmodule