pragma circom 2.2.2;

include "../hash-circuits/circuits/poseidon2/poseidon2.circom";

template Poseidon2Bench(nInputs) {
    signal input in[nInputs];
    signal output out[1];

    component p1 = Poseidon2(16);
    component p2 = Poseidon2(16);
    component p3 = Poseidon2(4);
    for (var i = 0; i < 16; i++) {
        p1.in[i] <== in[i];
        p2.in[i] <== in[i+16];
    }
    p3.in[0] <== p1.out[0];
    p3.in[1] <== p2.out[0];
    p3.in[2] <== in[32];
    p3.in[3] <== in[33];
    out[0] <== p3.out[0];
}

component main {public[in]} = Poseidon2Bench(34);