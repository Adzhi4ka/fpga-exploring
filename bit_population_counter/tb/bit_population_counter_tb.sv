module bit_population_counter_tb;

parameter DATA_W   = 25;
parameter TEST_CNT = 10;


typedef struct {
  logic [DATA_W-1:0] data;
  integer            bit_count;
} test_arg;

bit                        clk;
bit                        srst;
bit                        rst_done;

logic [DATA_W-1:0]         data_input;
logic                      data_val_input;

logic [$clog2(DATA_W)+1:0] data_output;
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

mailbox #( test_arg          ) generated_data = new();
mailbox #( test_arg          ) sended_data    = new();
mailbox #( logic[DATA_W-1:0] ) readed_data    = new();

task gen_data( input   int           cnt,
               mailbox #( test_arg ) data );
  test_arg data_to_send;

  for ( int i = 0; i < cnt; ++i)
    begin
      data_to_send.data      = $urandom_range(2**DATA_W - 1, 0);
      data_to_send.bit_count = 0;

      for (int i = 0; i < DATA_W; ++i)
        data_to_send.bit_count += data_to_send.data[i];

      data.put( data_to_send );
    end
endtask

task bit_population_counter_wr( mailbox #( test_arg ) generated_data,
                                mailbox #( test_arg ) sended_data    );
  test_arg arg;

  generated_data.get(arg);
  sended_data.put(arg);

  data_input     <= arg.data;
  data_val_input <= 1'b1;

  ##1
  data_val_input <= 1'b0;

  while ( generated_data.num() )
    begin
      ##1
      wait( data_val_output );
      $display("%d %d", generated_data.num(), $stime());
      generated_data.get(arg);
      sended_data.put(arg);

      data_input     <= arg.data;
      data_val_input <= 1'b1;

      ##1
      data_val_input <= 1'b0;
    end

  ##1
  wait( !data_val_output );  
  srst <= 1'b1;
  ##1
  srst <= 1'b0;
endtask

task bit_population_counter_r(mailbox #( logic[DATA_W-1:0] ) readed_data);
    forever
      begin
        if ( srst )
          return;
        
        wait( data_val_output );
        readed_data.put(data_output);
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
      // bit_population_counter_r(readed_data);
    join

    $stop();
  end

endmodule