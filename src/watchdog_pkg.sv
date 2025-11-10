// watchdog_pkg.sv
package watchdog_pkg;

    // Enumerationstyp
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_type;

    // Function Implementation
    function logic signed [31:0] saturate(input logic signed [31:0] input, integer target_width);
        logic signed [31:0] result;
        integer i;

        if (input'high < target_width - 1) begin
            result = input; // Sign-extend
        end else begin
            if (input[input'high] == 1'b0) begin
                // Positive number
                if (|input[input'high:target_width]) begin // or_reduce
                    result = {target_width{1'b1}};
                    result[target_width - 1] = 1'b0;
                end else begin
                    result = input; // Truncate
                end
            end else begin
                // Negative number
                if (~(|(~input[input'high:target_width]))) begin // and_reduce(not(...))
                    result = {target_width{1'b0}};
                    result[target_width - 1] = 1'b1;
                end else begin
                    result = input; // Truncate
                end
            end
        end

        return result;
    endfunction

    function logic or_reduce(logic [31:0] v);
        logic result = 1'b0;
        integer i;
        for (i = 0; i < 32; i++) begin
            if (v[i] == 1'b1) begin
                result = result | v[i];
            end
        end
        return result;
    endfunction

    function logic and_reduce(logic [31:0] v);
        logic result = 1'b1;
        integer i;
        for (i = 0; i < 32; i++) begin
            if (v[i] == 1'b0) begin
                result = result & v[i];
            end
        end
        return result;
    endfunction

    function integer even_up(integer x);
        if ((x % 2) == 0) begin
            return x;
        end else begin
            return x + 1;
        end
    endfunction

    function integer msb_pos(logic unsigned [31:0] x);
        integer result = -1;
        integer i;
        for (i = 31; i >= 0; i--) begin
            if (x[i] == 1'b1) begin
                result = i;
                return result;
            end
        end
        return result; // returns -1 if all bits are 0
    endfunction

    function logic [3:0] sel_nibble32(logic [31:0] word, integer idx);
        integer lo = (idx * 4);
        return word[31 - lo:28 - lo];
    endfunction

endpackage
