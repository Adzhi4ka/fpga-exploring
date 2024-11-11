module priority_encoder_tb;

parameter DATA_W = 16;
parameter TEST_CNT = 1000;

typedef struct {
  logic [DATA_W-1:0] data;
  integer            right_index;
  integer            left_index;
} test_arg;

typedef struct {
  logic [DATA_W-1:0] left_data;
  logic [DATA_W-1:0] right_data;
} output_arg;

bit                clk;
bit                srst;
bit                rst_done;

logic [DATA_W-1:0] data;
logic              data_val_input;

logic [DATA_W-1:0] data_left;
logic [DATA_W-1:0] data_right;
logic              data_val_output;

initial
  forever
    #5 clk = !clk;

default clocking cb
  @ (posedge clk);
endclocking

priority_encoder #(
  .DATA_W      ( DATA_W           )
) priority_encoder_test (
  .clk_i        ( clk             ),
  .srst_i       ( srst            ),

  .data_i       ( data            ),
  .data_val_i   ( data_val_input  ),

  .data_left_o  ( data_left       ),
  .data_right_o ( data_right      ),
  .data_val_o   ( data_val_output )
);

mailbox #( test_arg   ) generated_data = new();
mailbox #( test_arg   ) sended_data    = new();
mailbox #( output_arg ) readed_data    = new();

task gen_data( input   int           cnt,
               mailbox #( test_arg ) data );
  for (int i = 0; i < cnt; ++i)
    begin
      test_arg data_to_send;

      if ( !$urandom_range(3, 0) )
        begin
          data_to_send.data        = '0;
          data_to_send.left_index  = -1;
          data_to_send.right_index = -1; 
        end
      else
        begin
          data_to_send.data = $urandom_range(2**DATA_W - 1, 0);
          data_to_send.left_index = $urandom_range(DATA_W-1, 0);
          data_to_send.right_index = $urandom_range(data_to_send.left_index, 0);

          data_to_send.data[data_to_send.left_index] = 1'b1;
          data_to_send.data[data_to_send.right_index] = 1'b1;
        end

      data_to_send.data = data_to_send.data & (((1 << (data_to_send.left_index-data_to_send.right_index+1)) - 1) << data_to_send.right_index);
    
      data.put( data_to_send );
    end
endtask

task priority_encoder_wr( mailbox #( test_arg ) generated_data,
                          mailbox #( test_arg ) sended_data    );
  test_arg           arg;
  logic [DATA_W-1:0] trash;

  while ( generated_data.num() )
    begin
      ##1
      generated_data.get(arg);
      sended_data.put(arg);

      data           <= arg.data;
      data_val_input <= 1'b1;

      ##1
      data           <= trash;
      data_val_input <= 1'b0;
    end

  ##1
  srst <= 1'b1;
  ##1
  srst <= 1'b0;
endtask

task priority_encoder_r( mailbox #( output_arg ) readed_data );
  output_arg out_args;

  forever
    begin
      if ( srst )
        return;

      ##1
      #2
      if ( data_val_output )
        begin
          out_args = '{left_data:data_left, right_data:data_right};
          readed_data.put( out_args );
        end
    end  
endtask

task compare_data (mailbox #( test_arg   ) sended_data,
                   mailbox #( output_arg ) readed_data);
  test_arg   sended;
  output_arg readed;

  if ( sended_data.num() != readed_data.num() )
    begin
      $display( "Size of ref data: %d", sended_data.num() );
      $display( "And sized of dut data: %d", readed_data.num() );
      $display( "Do not match" );
      $stop();
    end
  
  for (int i = 0; sended_data.num() ; ++i)
    begin
      sended_data.get(sended);
      readed_data.get(readed);

      if (readed.left_data !== (1 << sended.left_index))
        begin
          $display("ERROR! Data don`t match.");
          $display("Reference data: %b", sended.data);
          $display("Left bit index: %d", sended.left_index);
          $display("Readed left data:    %b", readed.left_data);

          $stop();
        end
      
      if (readed.right_data !== (1 << sended.right_index))
        begin
          $display("ERROR! Data don`t match.");
          $display("Reference data: %b", sended.data);
          $display("Right bit index: %d", sended.right_index);
          $display("Readed right data:    %b", readed.right_data);

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
    gen_data(TEST_CNT, generated_data);
    wait( rst_done );

    fork
      priority_encoder_wr(generated_data, sended_data);
      priority_encoder_r(readed_data);
    join
    
    compare_data(sended_data, readed_data);
    $display("TEST PASSED");
    $stop();
  end

endmodule