module alu (
    input  logic [3:0] opcode,
    input  logic [7:0] a, b,
    output logic [15:0] result
);
    always_comb begin 

        result = '0;

        if (opcode == 4'b0001)
            result = a + b;

        if (opcode == 4'b0010)
            result = a - b;

        if (opcode == 4'b0011)
            result = a * b;

    end
endmodule


