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
reg signed [7:0] temporary_result;
reg O, C, Z, N, E, T;

wire [7:0]  i_arg0_u = i_arg0; // zmienna bez znaku do przesuniecia logicznego
wire [15:0] ba = {i_arg1, i_arg0}; //polaczenie A i B w jeden 16 bitowy wektor

reg [8:0] temporary_variable;
reg [7:0] shift_val;

integer i;
integer zeros;
reg seen_zero;
integer loop_end;

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
    loop_end = 0;

    // wartosc bezwzgledna z B do przesuniec
    if (i_arg1 < 0)
        shift_val = -i_arg1;
    else
        shift_val = i_arg1;
    
    // liczenie zer dla flagi E (zero-hot)
    zeros = 0;
    for (i = 0; i < 16; i = i + 1) begin
        if (ba[i] == 1'b0)
            zeros = zeros + 1;
    end
    if (zeros != 1)
        E = 1'b1;
    else
        E = 1'b0;

    // sprawdzanie kodu termometrowego dla flagi T
    // od LSB ciag jedynek, po pierwszym zerze juz tylko zera
    T = 1'b1;
    seen_zero = 1'b0;
    for (i = 0; i < 16; i = i + 1) begin
        if (ba[i] == 1'b0)
            seen_zero = 1'b1;
        else if (seen_zero)
            T = 1'b0;
    end

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
                temporary_result = i_arg0_u << shift_val;
            else if (i_arg1 < 0)
                temporary_result = i_arg0_u >> shift_val;
            else
                temporary_result = i_arg0;
        end

        4'd6: begin //signed arithmetic shift
            if (i_arg1 > 0)
                temporary_result = i_arg0 <<< shift_val;
            else if (i_arg1 < 0)
                temporary_result = i_arg0 >>> shift_val;
            else
                temporary_result = i_arg0;
        end

        4'd7: begin //count trailing ones
            loop_end = 0;

            for (i = 0; i < 16; i = i + 1) begin //liczymy ilosc kolejnych jedynek od LSB do MSB w polaczonych argumentach
                if (ba[i] == 1'b1 && loop_end == 0)
                    temporary_result = temporary_result + 1;
                else
                    loop_end = 1;
            end
        end

        4'd8: begin //zero hot decoder
            if (E == 1'b0) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (ba[i] == 1'b0)
                        temporary_result = i;
                end
            end
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
