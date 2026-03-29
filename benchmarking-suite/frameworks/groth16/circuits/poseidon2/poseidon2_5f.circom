pragma circom 2.2.2;

include "../hash-circuits/circuits/poseidon2/poseidon2.circom";

template Poseidon2Bench(nInputs) {
    signal input in[nInputs];
    signal output out[1];

    component p = Poseidon2(8);
    for (var i = 0; i < 5; i++) {
        p.in[i] <== in[i];
    }
    for (var i = 5; i < 8; i++) {
        p.in[i] <== 0;
    }
    out[0] <== p.out[0];
}

component main {public[in]} = Poseidon2Bench(5);