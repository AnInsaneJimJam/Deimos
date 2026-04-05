pragma circom 2.0.0;

include "../circomlib/circuits/poseidon/poseidon.circom";

template PoseidonBench(nInputs) {
    signal input in[nInputs];
    signal output out;

    component p = Poseidon(2);
    for (var i = 0; i < 2; i++) {
        p.inputs[i] <== in[i];
    }
    out <== p.out;
}

component main {public[in]} = PoseidonBench(2);