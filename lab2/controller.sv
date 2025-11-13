module controller 
#(
    parameter WIDTH = 16,
    parameter INSTR_LEN = 20,
    parameter ADDR = 5
)(
    input logic clk,
    input logic reset,
    input logic go,
    input logic [INSTR_LEN-1:0] instruction,
    input logic done,
    output logic enable,
    output logic [ADDR-1:0] pc,
    output logic [3:0] opcode,
    output logic [7:0] a, b,
    output logic invalid_opcode
);

    enum logic [1:0] {IDLE, FETCH, EXECUTE} state, next_state;
    logic [ADDR-1:0] pc_reg, next_pc_reg;

    assign pc = pc_reg;
    assign opcode = instruction[19:16];
    assign a = instruction[15:8];
    assign b = instruction[7:0];

    always_comb begin : fsm_logic
        // defaults
        enable = 1'b0;
        next_state = state;
        next_pc_reg = pc_reg;

        case (state)
            IDLE: begin
                if (go) next_state = FETCH;
            end

            FETCH: begin
                // Halt instruction
                if (opcode == 4'b0000) begin
                    next_pc_reg = pc_reg + 1;
                    next_state = IDLE;
                end
                else next_state = EXECUTE;
            end

            EXECUTE: begin
                enable = 1'b1;
                if (done) begin
                    next_pc_reg = pc_reg + 1;
                    next_state = FETCH;
                end
            end
        endcase
    end

    always_comb begin : set_invalid_opcode
        invalid_opcode = 1'b1;
        if (opcode == 4'b1011) invalid_opcode = 1'b0;
        if (opcode >= 1 && opcode <= 3) invalid_opcode = 1'b0;
    end

    always_ff @(posedge clk or posedge reset) begin : flipflop
        if (reset) begin
            state <= IDLE;
            pc_reg <= '0;
        end
        else begin // clock rising edge
            state <= next_state;
            pc_reg <= next_pc_reg;
        end
    end

endmodule










