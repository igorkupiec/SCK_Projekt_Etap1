module alu (
    input wire                i_clk, //zegar
    input wire                i_rstn, //reset 
    input wire signed [7:0]   i_arg0, //A
    input wire signed [7:0]   i_arg1, //B
    input wire        [3:0]   i_oper, //wybór operacji
    output reg signed [7:0]   o_result, //wynik
    output reg        [5:0]   o_flag //flagi: O, C, Z, N, E, T
);

//deklaracja zmiennych pomocniczych
reg O, C, Z, N, E, T;
reg signed [7:0] temporary_result;
reg [15:0] temporary_variable;

integer i;
reg loop_end;
reg [4:0] counter;

always @(*) begin //logika kombinacyjna

    //ustawienie początkowych wartości zmiennych pomocniczych
    O = 0;
    C = 0;
    Z = 0;
    N = 0;
    E = 0;
    T = 0;

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
                C = temporary_variable[8];
        end
        
        4'd1: begin //odejmowanie A - B
            temporary_result = i_arg0 - i_arg1;

            if ((i_arg0[7] != i_arg1[7]) && (temporary_result[7] != i_arg0[7]))
            //overflow wystepuje jesli MSB argumentow jest rozny, a MSB wyniku jest inny niz MSB pierwszego argumentu
                O = 1'b1; //overflow
            
            temporary_variable = {1'b0, i_arg0} - {1'b0, i_arg1}; //zmienna 9 bitowa do sprawdzenia przeniesienia
                C = temporary_variable[8];
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
            temporary_variable = {i_arg1, i_arg0}; //polaczenie A i B w jeden 16 bitowy wektor
            loop_end = 0;

            for (i = 0; i < 16; i = i + 1) begin //liczymy ilosc kolejnych zer od MSB do LSB w polaczonych argumentach
                if (temporary_variable[15-i] == 1'b0 && loop_end == 0)
                    temporary_result = temporary_result + 1;
                else
                    loop_end = 1;
            end

            //sprawdzamy kod temperaturowy
            T = 1'b1;
            for (i = temporary_result; i < 15; i = i + 1) begin
                if (temporary_variable[15-i] != 1'b1)
                    T = 1'b0;
            end
        end

        4'd8: begin //one hot decoder
            temporary_variable = {i_arg1, i_arg0}; //polaczenie A i B w jeden 16 bitowy wektor
            counter = 0;

            for (i = 0; i < 16; i = i + 1) begin //sprawdzamy czy w polaczonych argumentach jest tylko jeden bit ustawiony na 1
                if (temporary_variable[i] == 1'b1) begin
                    counter = counter + 1;
                    temporary_result = i; //zapisujemy indeks bitu ustawionego na 1
                end
            end

            if (counter == 1) //jesli jest tylko jeden bit ustawiony na 1, to flaga E = 1
                E = 1'b1;
        end

        default: begin
            temporary_result = 0;
        end
    endcase

    if (temporary_result == 0) //flaga Z, sprawdzamy czy wynik jest rowny 0
        Z = 1'b1;
    
    if (temporary_result[7] == 1'b1) //flaga N, sprawdzamy czy MSB wyniku jest 1
        N = 1'b1;

end

always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
        o_result <= 8'd0;
        o_flag   <= 6'd0;
    end
    
    else begin
        o_result <= temporary_result;
        o_flag   <= {O, C, Z, N, E, T};
    end
end

endmodule