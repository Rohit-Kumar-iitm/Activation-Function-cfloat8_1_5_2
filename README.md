# Activation-Function-cfloat8_1_5_2

- We designed a module to support unary operators, such as activation functions used in deep learning, Eg: tanh(x), sigmoid(x) etc.
- To do so we did the following:
  - Taking the cfloat8_1_5_2 input as x, converting it to floating point value (using the respective bits)
  - From the floating point value of x, exp(x) is calculated using Maclaurin series expansion of exp(x)
  - The number of terms taken (in the series expansion) will be determined by the number of cycles or rules executed during the time of simulation, i.e., simulation will run for a specific time. So it will completely be on us (in the testbench), to decide how many terms we can take.
  - Once exp(x) is found out, computing the activation function -> Tanh(x), sigmoid(x),  will be easier to compute.
    - Tanh(x) = (exp(2x)-1)/(exp(2x)+1)
    - sigmoid(x) = 1/(1+exp(-x))
    - SeLU(x) = &lambda;x if x>=0 and SeLU(x) = &lambda;&alpha;(exp(x)-1) if x<0
    - leaky_ReLU(x) = x if x>=0 and leaky_ReLU(x) = &alpha;x otherwise
  - Once values are obtained, they are converted back into the cfloat8_1_5_2 format.
