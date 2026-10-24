module alu (
    input wire                i_clk, //zegar
    input wire                i_rstn, //reset 
    input wire signed [7:0]   i_arg0, //A
    input wire signed [7:0]   i_arg1, //B
    input wire        [3:0]   i_oper, //wybór operacji
    output reg signed [7:0]   o_result, //wynik
    output reg        [5:0]   o_flag, //flagi: O, C, Z, N, E, T
);

always @(*) begin //logika kombinacyjna
    O = 0;
    C = 0;
    Z = 0;
    N = 0;
    E = 0;
    T = 0; //ustawienie wartosci domyslnych na 0

    temporary_result = 0;
    temporary_variable = 0;

    //operacje alu
    case (i_oper)
        4'd0: begin //dodawanie A + B
            temporary_result = i_arg0 + i_arg1;
            
            if ((i_arg0[7] == i_arg1[7]) && (temporary_result[7] != i_arg0[7]))
            //overflow wystepuje jesli MSB obu argumentow jest ten sam, a MSB wyniku jest inny
                O = 1'b1; //overflow
            
            temporary_variable = {1'b0, i_arg0} + {1'b0, i_arg1}; //zmienna 9 bitowa do sprawdzenia przeniesienia
                C = temp[8];
        end
        
        4'd1: begin //odejmowanie A - B
            temporary_result = i_arg0 - i_arg1;

            if ((i_arg0[7] != i_arg1[7]) && (temporary_result[7] != i_arg0[7]))
            //overflow wystepuje jesli MSB argumentow jest rozny, a MSB wyniku jest inny niz MSB pierwszego argumentu
                O = 1'b1; //overflow
            
            temporary_variable = {1'b0, i_arg0} - {1'b0, i_arg1}; //zmienna 9 bitowa do sprawdzenia przeniesienia
                C = temp[8];
        end

        4'd2: begin //AND
            temporary_result = i_arg0 & i_arg1;
        end

        4'd3: begin //OR
            temporary_result = i_arg0 | i_arg1;
        end

        4'd4: begin //XOR
            temporary_result = i_arg0 ^ i_arg1;
        end

        4'd5: begin //signed logical shift
            if (i_arg1 > 0)
                temporary_result = i_arg0 << i_arg1;
            else if (i_arg1 < 0)
                temporary_result = i_arg0 >> -i_arg1;
            else
                temporary_result = i_arg0;
        end

        4'd6: begin //signed arithmetic shift
            if (i_arg1 > 0)
                temporary_result = i_arg0 <<< i_arg1;
            else if (i_arg1 < 0)
                temporary_result = i_arg0 >>> -i_arg1;
            else
                temporary_result = i_arg0;
        end

        4'd7: begin //count leading zeros
            temporary_result = count_leading_zeros(i_arg0);
        end

        4'd8: begin //one hot decoder
            temporary_result = one_hot_decoder(i_arg0);
        end

        default: begin
            temporary_result = 0;
        end
    
    if (temporary_result == 0) //flaga Z, sprawdzamy czy wynik jest rowny 0
        Z = 1'b1;
    
    if (temporary_result[7] == 1'b1) //flaga N, sprawdzamy czy MSB wyniku jest 1
        N = 1'b1;
    
    endcase
end
