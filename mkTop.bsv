// P10: Activation function - cfloat8_1_5_2 => input x

// Team: Rohit Kumar (EE20B111), Valipireddy Satya (EE20B145)

// The goal is to first compute exp(x) and then the activation functions can be computed easily

// Importing necessary modules
import Bits::*;
import Eq::*;
import Arithmetic::*;
import FloatingPoint::*;
import BitOps::*;
import FPGA::*;
import Real::*;
import FPU::*;
import Clocks::*;
import Real::*;

// Defining a struct for input x - cfloat_8_1_5_2 data type
typedef struct {
    F#(1,0) sign;
    F#(5,0) exponent;
    F#(2,0) mantissa;
} cfloat8_1_5_2 deriving (Bits, Eq);

// Get the floating point value (Cfloat to float value converter)
module mkCFloatConverter;
    
    function Real cfloatToFloat(cfloat8_1_5_2 x);
        Real result;

        // Extracting sign, exponent, and mantissa
        Bit#(1) sign = x.sign;
        Bit#(5) exponent = x.exponent;
        Bit#(2) mantissa = x.mantissa;

        // floating-point result
        result = $signed(sign) * $pow(2.0, exponent - 15) * (1.0 + $signed(mantissa) / $pow(2.0, 2));

        return result;
    endfunction
endmodule

// Get the cfloat back from real result
function cfloat8_1_5_2 floatToCFloat(Real x);
    cfloat8_1_5_2 result;

    // Handle special cases: zero and NaN
    if (x == 0.0) begin
        result.sign     = 0;
        result.exponent = 0;
        result.mantissa = 0;
    end else begin
        // Extract sign, exponent, and mantissa components
        result.sign = $sign(x);
        Real absX = $abs(x);
        Integer exp = $floor($log2(absX));
        result.exponent = exp + 15;  // Bias for cfloat8_1_5_2 format
        result.mantissa = $rshft($round(absX * $pow(2.0, 2 - exp)), 6);  
    end

    return result;
endfunction

/******************* Exponetial of X *********************/
module mkExpCalci;
    Reg#(Real) x <- mkReg(0.0);
    Reg#(Real) result <- mkReg(0.0);
    Reg#(Integer) n <- mkReg(0);

    // to calculate factorial
    function Integer factorial(Integer k);
        if (k == 0) return 1;
        else return k * factorial(k - 1);
    endfunction

    // Rule to calculate e^x using Maclaurin series
    rule computeExp;
        Real term = x ** n / $fromInteger(factorial(n));
        result <= result + term;
        n <= n + 1;
    endrule

    // Rule to reset
    rule reset;
        x <= 0.0;
        result <= 0.0;
        n <= 0;
    endrule

    // Interface method to set the input value x
    method Action setX(Real value);
        x <= value;
        n <= 0;
        result <= 1.0; // for (n=0)
    endmethod
endmodule


/******************* Tanh of X *********************/
module mkTanhCalci;
  
  mkExpCalci expCalci <- mkExpCalci;

  // Inputs and outputs
  Reg#(Real) x <- mkReg(0.0);
  Reg#(Real) tanhResult <- mkReg(0.0);

  // Rule to set x in expCalci and compute exp(x)
  rule computeExp;
    expCalci.setX(2.0 * x); // Compute e^(2x) using the expCalci module above
  endrule

  // Rule to compute tanh(x) = (exp(2x)-1)/(exp(2x)+1)
  rule computeTanh;
    tanhResult <= (expCalci.result - 1.0) / (expCalci.result + 1.0);
  endrule

  // Interface method to set the input value x
  method Action setX(Real value);
    x <= value;
    // Trigger the rule to compute exp(x) and then tanh(x)
    computeExp;
    computeTanh;
  endmethod
endmodule


/******************* Sigmoid of X *********************/
module mkSigmoidCalci;
  
  mkExpCalci expCalci <- mkExpCalci;

  // Inputs and outputs
  Reg#(Real) x <- mkReg(0.0);
  Reg#(Real) sigmoidResult <- mkReg(0.0);

  // Rule to set x in expCalci and compute exp(-x)
  rule computeExp;
    expCalci.setX(-1.0 * x); // Compute e^{-x} using the existing expCalci
  endrule

  // Rule to compute sigmoid(x) = 1/(1+exp(-x))
  rule computeSigmoid;
    sigmoidResult <= 1.0 / (1.0 + expCalci.result);
  endrule

  // Interface method to set the input value x
  method Action setX(Real value);
    x <= value;
    // Trigger the rule to compute exp(-x) and then sigmoid(x)
    computeExp;
    computeSigmoid;
  endmethod
endmodule


/******************* SeLU of X *********************/
module mkSeLUCalci;
  // Instantiate the mkExpCalci module
  mkExpCalci expCalci <- mkExpCalci;

  // Inputs and outputs
  Reg#(Real) x <- mkReg(0.0);
  Reg#(Real) seluResult <- mkReg(0.0);

  // SeLU parameters (can be adjuested as per the need)
  Real lambda <- 1.0507;
  Real alpha <- 1.6732;

  // Rule to set x in expCalci and compute exp(x)
  rule computeExp;
    expCalci.setX(x); // Compute e^x using the existing expCalci
  endrule

  // Rule to compute SeLU(x) using the result of exp(x)
  rule computeSeLU;
    if (x > 0.0) begin
      seluResult <= lambda * x;
    end else begin
      seluResult <= lambda * alpha * (expCalci.result - 1.0);
    end
  endrule

  // Interface method to set the input value x
  method Action setX(Real value);
    x <= value;
    // Trigger the rule to compute exp(x) and then SeLU(x)
    computeExp;
    computeSeLU;
  endmethod
endmodule


/******************* leaky_ReLU of X *********************/
module mkLeakyReLUCalci;
  // Instantiate the mkExpCalci module
  mkExpCalci expCalci <- mkExpCalci;

  // Inputs and outputs
  Reg#(Real) x <- mkReg(0.0);
  Reg#(Real) leakyReLUResult <- mkReg(0.0);

  // Leaky ReLU slope parameter (adjust as needed)
  Real alpha <- 0.01;

  // Rule to set x in expCalci and compute exp(x)
  rule computeExp;
    expCalci.setX(x); // Compute e^x using the existing expCalci
  endrule

  // Rule to compute Leaky ReLU(x) using the result of exp(x)
  rule computeLeakyReLU;
    if (x > 0.0) begin
      leakyReLUResult <= x;
    end else begin
      leakyReLUResult <= alpha * x;
    end
  endrule

  // Interface method to set the input value x
  method Action setX(Real value);
    x <= value;
    // Trigger the rule to compute exp(x) and then Leaky ReLU(x)
    computeExp;
    computeLeakyReLU;
  endmethod
endmodule


/***************** Top module *****************/
module mkTop;
    
    mkCFloatConverter cfloatConverter <- mkCFloatConverter;
    mkExpCalci expCalci <- mkExpCalci;
    mkTanhCalci tanhCalci <- mkTanhCalci;
    mkSigmoidCalci sigmoidCalci <- mkSigmoidCalci;
    mkSeLUCalci seluCalci <- mkSeLUCalci;
    mkLeakyReLUCalci leakyReLUCalci <- mkLeakyReLUCalci;

    // Inputs and outputs
    Reg#(cfloat8_1_5_2) inputX <- mkReg(cfloat8_1_5_2Zero);
    Reg#(Real) expResult <- mkReg(0.0);
    Reg#(Real) tanhResult <- mkReg(0.0);
    Reg#(Real) sigmoidResult <- mkReg(0.0);
    Reg#(Real) seluResult <- mkReg(0.0);
    Reg#(Real) leakyReLResult <- mkReg(0.0);
    Reg#(cfloat8_1_5_2) tanhOutput <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) sigmoidOutput <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) seluOutput <- mkReg(cfloat8_1_5_2Zero);
    Reg#(cfloat8_1_5_2) leakyReLOutput <- mkReg(cfloat8_1_5_2Zero);

    // Rule to convert cfloat to float and set x in expCalci
    rule convertAndSetExpCalci;
        expCalci.setX(cfloatConverter.cfloatToFloat(inputX));
    endrule

    // Rule to compute exp(x) and store the result
    rule computeExp;
        expResult <= expCalci.result;
    endrule

    
    // Rule to set x in tanhCalci and compute tanh(x)
    rule setAndComputeTanh;
        tanhCalci.setX(expResult);
    endrule
    // Rule to store the result of tanh(x)
    rule storeTanhResult;
        tanhResult <= tanhCalci.tanhResult;
    endrule
    // Rule to convert tanh result back to cfloat8_1_5_2
    rule convertTanhResult;
        tanhOutput <= cfloatConverter.floatToCFloat(tanhResult);
    endrule

    
    // Rule to set x in sigmoidCalci and compute sigmoid(x)
    rule setAndComputeSigmoid;
        sigmoidCalci.setX(expResult);
    endrule
    // Rule to store the result of sigmoid(x)
    rule storeSigmoidResult;
        sigmoidResult <= sigmoidCalci.sigmoidResult;
    endrule
    // Rule to convert sigmoid result back to cfloat8_1_5_2
    rule convertSigmoidResult;
        sigmoidOutput <= cfloatConverter.floatToCFloat(sigmoidResult);
    endrule
    
    
    // Rule to set x in seluCalci and compute selu(x)
    rule setAndComputeSeLU;
        seluCalci.setX(expResult);
    endrule
    // Rule to store the result of selu(x)
    rule storeSeLUResult;
        seluResult <= seluCalci.seluResult;
    endrule
    // Rule to convert selu result back to cfloat8_1_5_2
    rule convertSeLUResult;
        seluOutput <= cfloatConverter.floatToCFloat(seluResult);
    endrule

    
    // Rule to set x in leakyReLUCalci and compute leakyReLU(x)
    rule setAndComputeLeakyReLU;
        leakyReLUCalci.setX(expResult);
    endrule
    // Rule to store the result of leakyReLU(x)
    rule storeLeakyReLResult;
        leakyReLResult <= leakyReLUCalci.leakyReLUResult;
    endrule
    // Rule to convert leakyReLU result back to cfloat8_1_5_2
    rule convertLeakyReLResult;
        leakyReLOutput <= cfloatConverter.floatToCFloat(leakyReLResult);
    endrule
    

endmodule