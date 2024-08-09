module testbench;

  parameter DSIZE = 8;
  parameter ASIZE = 4;
  
  wire [DSIZE-1:0] rdata;
  wire wfull;
  wire rempty;
  reg [DSIZE-1:0] wdata;
  reg winc, wclk, wrst_n;
  reg rinc, rclk, rrst_n;

  // FIFO instance
  fifo1 #(DSIZE, ASIZE) fifo1 (
    .rdata(rdata), 
    .wfull(wfull), 
    .rempty(rempty), 
    .wdata(wdata), 
    .winc(winc), 
    .wclk(wclk), 
    .wrst_n(wrst_n), 
    .rinc(rinc), 
    .rclk(rclk), 
    .rrst_n(rrst_n)
  );

  // Simple FIFO data storage for comparison
  reg [DSIZE-1:0] wdata_temp_q [0:29]; // Fixed-size array
  integer wdata_count, i, j; // Counters
  
  // Clock generation
  always #10 wclk = ~wclk;
  always #35 rclk = ~rclk;

  // Write process
  initial begin
    wclk = 1'b0; wrst_n = 1'b0;
    winc = 1'b0;
    wdata = 0;
    wdata_count = 0;
    
    // Reset wait
    repeat(10) @(posedge wclk);
    wrst_n = 1'b1;

    // Write data
    repeat(2) begin
      for (i = 0; i < 30; i = i + 1) begin
        @(posedge wclk);
        if (!wfull) begin
          winc = (i % 2 == 0) ? 1'b1 : 1'b0;
          if (winc) begin
            wdata = $random; // Use $random for random data generation
            wdata_temp_q[wdata_count] = wdata;
            wdata_count = wdata_count + 1;
          end
        end
      end
      #50;
    end
  end

  // Read process
  initial begin
    rclk = 1'b0; rrst_n = 1'b0;
    rinc = 1'b0;

    // Reset wait
    repeat(20) @(posedge rclk);
    rrst_n = 1'b1;

    // Read data
    repeat(2) begin
      for (i = 0; i < 30; i = i + 1) begin
        @(posedge rclk);
        if (!rempty) begin
          rinc = (i % 2 == 0) ? 1'b1 : 1'b0;
          if (rinc && wdata_count > 0) begin
            wdata_count = wdata_count - 1;
            if (rdata !== wdata_temp_q[0]) 
              $error("Time = %0t: Comparison Failed: expected wr_data = %h, rd_data = %h", $time, wdata_temp_q[0], rdata);
            else 
              $display("Time = %0t: Comparison Passed: wr_data = %h and rd_data = %h", $time, wdata_temp_q[0], rdata);
            // Shift data
            for (j = 0; j < wdata_count; j = j + 1) begin
              wdata_temp_q[j] = wdata_temp_q[j + 1];
            end
          end
        end
      end
      #50;
    end

    $stop;
  end
  
  // VCD dump
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end

endmodule
