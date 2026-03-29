pragma circom 2.0.0;

include "../circomlib/circuits/poseidon/poseidon.circom";

template PoseidonBench(nInputs) {
    signal input in[nInputs];
    signal output out;

    component p1 = Poseidon(16);
    component p2 = Poseidon(2);
    for (var i = 0; i < 16; i++) {
        p1.inputs[i] <== in[i];
    }
    p2.inputs[0] <== p1.out;
    p2.inputs[1] <== in[16];
    out <== p2.out;
}

component main {public[in]} = PoseidonBench(17);