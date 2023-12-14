import mkTop::*;

module mkTopTestbench;
    // Instantiate the design under test (DUT)
    mkTop dut <- mkTop;

    // Inputs
    Reg#(cfloat8_1_5_2) inputX <- mkReg(cfloat8_1_5_2Zero);

    // Observables
    Reg#(cfloat8_1_5_2) tanhOutput_obs <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) sigmoidOutput_obs <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) seluOutput_obs <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) leakyReLOutput_obs <- mkReg(cfloat8_1_5_2Zero);

    // Simulation loop
    rule simulate;
        // Set input value
        inputX <= cfloat8_1_5_2'((0, 16, 2)); // Modify as needed

        // Wait for a few cycles
        $display("Waiting for a few cycles...");
        wait(100);

        // Set input value in DUT
        dut.inputX <= inputX;

        // Wait for a few more cycles
        $display("Waiting for a few more cycles...");
        wait(100);

        // Observe output results
        tanhOutput_obs <= dut.tanhOutput;
        sigmoidOutput_obs <= dut.sigmoidOutput;
        seluOutput_obs <= dut.seluOutput;
        leakyReLOutput_obs <= dut.leakyReLOutput;

        // Display results
        $display("Input: %f, tanhOutput: %f, sigmoidOutput: %f, seluOutput: %f, leakyReLOutput: %f",
                 cfloatConverter.cfloatToFloat(inputX),
                 cfloatConverter.cfloatToFloat(tanhOutput_obs),
                 cfloatConverter.cfloatToFloat(sigmoidOutput_obs),
                 cfloatConverter.cfloatToFloat(seluOutput_obs),
                 cfloatConverter.cfloatToFloat(leakyReLOutput_obs));

        // Finish simulation after observing results
        $finish;
    endrule
endmodule