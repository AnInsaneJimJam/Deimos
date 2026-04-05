pragma circom 2.0.0;

include "../circomlib/circuits/poseidon/poseidon.circom";

template PoseidonBench(nInputs) {
    signal input in[nInputs];
    signal output out;

    component p1 = Poseidon(16);
    component p2 = Poseidon(16);
    component p3 = Poseidon(4);
    for (var i = 0; i < 16; i++) {
        p1.inputs[i] <== in[i];
        p2.inputs[i] <== in[i+16];
    }
    p3.inputs[0] <== p1.out;
    p3.inputs[1] <== p2.out;
    p3.inputs[2] <== in[32];
    p3.inputs[3] <== in[33];
    out <== p3.out;
}

component main {public[in]} = PoseidonBench(34);