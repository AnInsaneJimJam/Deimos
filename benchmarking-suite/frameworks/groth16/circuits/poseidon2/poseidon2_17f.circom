pragma circom 2.2.2;

include "../hash-circuits/circuits/poseidon2/poseidon2.circom";

template Poseidon2Bench(nInputs) {
    signal input in[nInputs];
    signal output out[1];

    component p1 = Poseidon2(16);
    component p2 = Poseidon2(2);
    for (var i = 0; i < 16; i++) {
        p1.in[i] <== in[i];
    }
    p2.in[0] <== p1.out[0];
    p2.in[1] <== in[16];
    out[0] <== p2.out[0];
}

component main {public[in]} = Poseidon2Bench(17);