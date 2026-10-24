module alu (
    input wire                i_clk, //zegar
    input wire                i_rstn, //reset 
    input wire signed [7:0]   i_arg0, //A
    input wire signed [7:0]   i_arg1, //B
    input wire        [3:0]   i_oper, //wybór operacji
    output reg signed [7:0]   o_result, //wynik
    output reg        [5:0]   o_flag, //flagi: O, C, Z, N, E, T
);