class transaction;
  rand bit din;    // Random data input
  bit dout;        // Data output

  // Copy function
  function transaction copy();
    copy = new();
    copy.din = this.din;
    copy.dout = this.dout;
  endfunction

  // Display function
  function void display(input string tag);
    $display("[%0s] : DIN : %0b DOUT : %0b", tag, din, dout);
  endfunction
endclass

// Generator
class generator;
  transaction tr;
  mailbox #(transaction) mbx;      // Mailbox to driver
  mailbox #(transaction) mbxref;   // Mailbox to scoreboard
  event sconext; // Event to synchronize with scoreboard
  event done;    // Event to signal completion
  int count;     // Number of transactions to generate

  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;
    this.mbxref = mbxref;
    tr = new();
  endfunction

  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("[GEN] : RANDOMIZATION FAILED");
      mbx.put(tr.copy); // Send to driver
      mbxref.put(tr.copy); // Send to scoreboard
      tr.display("GEN");
      @(sconext); // Wait for scoreboard to complete
    end
    ->done; // Signal completion
  endtask
endclass

// Driver
class driver;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task reset();
    vif.rst <= 1'b1; // Assert reset
    repeat(5) @(posedge vif.clk); // Wait for 5 clock cycles
    vif.rst <= 1'b0; // Deassert reset
    $display("[DRV] : RESET DONE");
  endtask

  task run();
    forever begin
      mbx.get(tr); // Get transaction from generator
      vif.din <= tr.din; // Drive DUT input
      @(posedge vif.clk); // Wait for clock edge
      tr.display("DRV");
    end
  endtask
endclass

// Monitor
class monitor;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    tr = new();
    forever begin
      repeat(2) @(posedge vif.clk); // Wait for 2 clock cycles
      tr.dout = vif.dout; // Capture DUT output
      mbx.put(tr); // Send to scoreboard
      tr.display("MON");
    end
  endtask
endclass

// Scoreboard
class scoreboard;
  transaction tr;
  transaction trref;
  mailbox #(transaction) mbx;
  mailbox #(transaction) mbxref;
  event sconext;

  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;
    this.mbxref = mbxref;
  endfunction

  task run();
    forever begin
      mbx.get(tr); // Get from monitor
      mbxref.get(trref); // Get from generator
      tr.display("SCO");
      trref.display("REF");
      if (tr.dout == trref.din)
        $display("[SCO] : DATA MATCHED");
      else
        $display("[SCO] : DATA MISMATCHED");
      $display("-------------------------------------------------");
      ->sconext; // Signal generator to continue
    end
  endtask
endclass

// Environment
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  event next;

  mailbox #(transaction) gdmbx; // Generator -> Driver
  mailbox #(transaction) msmbx; // Monitor -> Scoreboard
  mailbox #(transaction) mbxref; // Generator -> Scoreboard

  virtual dff_if vif;

  function new(virtual dff_if vif);
    gdmbx = new();
    mbxref = new();
    gen = new(gdmbx, mbxref);
    drv = new(gdmbx);
    msmbx = new();
    mon = new(msmbx);
    sco = new(msmbx, mbxref);
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    gen.sconext = next;
    sco.sconext = next;
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask

  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass

// Testbench
module tb;
  dff_if vif();

  dff dut(vif);

  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk;

  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 30; // Number of transactions
    env.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
