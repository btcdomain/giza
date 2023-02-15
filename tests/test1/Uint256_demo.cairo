%builtins output range_check

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.uint256 import Uint256, split_64, uint256_mul, uint256_eq, assert_uint256_le, uint256_add, uint256_mul_div_mod
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le

func main{output_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    const steps_felt = 2 ** 13;
    let steps_uint256 = split_64(steps_felt);

    let (felt_array) = alloc();

    %{
        round_c = []
        for i in range(64): 
            memory[ids.felt_array + i] = i ** 7 ^ 42
    %}
    local low: felt;
    local high: felt;

    %{
        modulus = 115792089237316195423570985008687907853269984665640564039457584006405596119041
        ids.low = modulus & ((1<<128) - 1)
        ids.high = modulus >> 128
    %}

    let mudulus = Uint256(low, high);
    let result = compute_mimc(inp=Uint256(3, 0), felt_array=felt_array, index=0, mudulus=mudulus);
    serialize_word(result.low);
    serialize_word(result.high);

    local x = result.low;
    local y = result.high;
    %{
        v = (ids.y << 128) + ids.x
        print('result: ', v)
    %}
    return ();
}

func compute_mimc{range_check_ptr}(inp: Uint256, felt_array: felt*, index, mudulus: Uint256) -> Uint256{
    alloc_locals;
    if (index == 2 ** 13 - 1) {
        return inp;
    }else {
        local inp_next: Uint256;
        local arr_index;
        %{
            ids.arr_index = ids.index % 64
        %}
        let arr_value = felt_array[arr_index];
        
        local a;
        local b;

        local inp_low = inp.low;
        local inp_high = inp.high;
        %{
            modulus = 2**256 - 2**32 * 351 + 1
            x = ids.inp_high << 128
            y = x + ids.inp_low
            inp_value = (ids.inp_high << 128) + ids.inp_low
            inp3_value = inp_value ** 3
            inp_new = (inp3_value + ids.arr_value) % modulus
            ids.a = inp_new & ((1 << 128) - 1)
            ids.b = inp_new >> 128
        %}

        local inp_next: Uint256 = Uint256(low=a, high=b);
        return compute_mimc(inp=inp_next, felt_array=felt_array, index=index+1, mudulus=mudulus);
    }
}

