//------------------------------------------------------------------------------
// Function: saturate
//------------------------------------------------------------------------------
function logic [31:0] saturate(input signed [31:0] input, int target_width); // Assuming maximum target_width of 32
    logic signed [31:0] result; // Assuming maximum target_width of 32
    
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

//------------------------------------------------------------------------------
// Function: or_reduce
//------------------------------------------------------------------------------
function logic or_reduce(logic [31:0] v); // Assuming maximum width of 32
    logic result = 1'b0;
    for (int i = 0; i < 32; i++) begin // Assuming maximum width of 32
        if (v[i] == 1'b1) begin
            result = result | v[i];
        end
    end
    return result;
endfunction

//------------------------------------------------------------------------------
// Function: and_reduce
//------------------------------------------------------------------------------
function logic and_reduce(logic [31:0] v); // Assuming maximum width of 32
    logic result = 1'b1;
    for (int i = 0; i < 32; i++) begin // Assuming maximum width of 32
        if (v[i] == 1'b0) begin
            result = result & v[i];
        end
    end
    return result;
endfunction

//------------------------------------------------------------------------------
// Function: even_up
//------------------------------------------------------------------------------
function int even_up(int x);
    if ((x % 2) == 0) begin
        return x;
    end else begin
        return x + 1;
    end
endfunction

//------------------------------------------------------------------------------
// Function: msb_pos
//------------------------------------------------------------------------------
function int msb_pos(logic unsigned [31:0] x); // Assuming maximum width of 32
    int result = -1;
    for (int i = 31; i >= 0; i--) begin // Assuming maximum width of 32
        if (x[i] == 1'b1) begin
            result = i;
            return result;
        end
    end
    return result; // returns -1 if all bits are 0
endfunction

//------------------------------------------------------------------------------
// Function: sel_nibble32
//------------------------------------------------------------------------------
function logic [3:0] sel_nibble32(logic [31:0] word, int idx);
    int lo = (idx * 4);
    return word[31 - lo:28 - lo];
endfunction
