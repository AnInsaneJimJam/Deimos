// Initializes the shared UniFFI scaffolding and defines the `MoproError` enum.
mopro_ffi::app!();

/// You can also customize the bindings by #[uniffi::export]
/// Reference: https://mozilla.github.io/uniffi-rs/latest/proc_macro/index.html
#[uniffi::export]
fn mopro_uniffi_hello_world() -> String {
    "Hello, World!".to_string()
}

#[macro_use]
mod stubs;

mod error;
pub use error::MoproError;

// CIRCOM_TEMPLATE
// --- Circom Example of using groth16 proving and verifying circuits ---

// Module containing the Circom circuit logic (Multiplier2)
#[macro_use]
mod circom;

rust_witness::witness!(keccak);
rust_witness::witness!(sha256);

set_circom_circuits! {
    ("keccak.zkey", circom_prover::witness::WitnessFn::RustWitness(keccak_witness)),
    ("sha256.zkey", circom_prover::witness::WitnessFn::RustWitness(sha256_witness)),
}

#[cfg(test)]
mod circom_tests {
    use crate::circom::{generate_circom_proof, verify_circom_proof, ProofLib};

    const KECCAK_ZKEY_PATH: &str = "./test-vectors/circom/keccak.zkey";
    const SHA256_ZKEY_PATH: &str = "./test-vectors/circom/sha256.zkey";

    #[test]
    fn test_keccak() {
        let circuit_inputs = r#"{
    "in": [
        "72",
        "101",
        "108",
        "108",
        "111",
        "32",
        "87",
        "111",
        "114",
        "108",
        "100",
        "33",
        "32",
        "84",
        "104",
        "105",
        "115",
        "32",
        "105",
        "115",
        "32",
        "97",
        "32",
        "116",
        "101",
        "115",
        "116",
        "32",
        "109",
        "115",
        "103",
        "46"
    ]
    }"#.to_string();
        let result =
            generate_circom_proof(KECCAK_ZKEY_PATH.to_string(), circuit_inputs, ProofLib::Arkworks);
        assert!(result.is_ok());
        let proof = result.unwrap();
        assert!(verify_circom_proof(KECCAK_ZKEY_PATH.to_string(), proof, ProofLib::Arkworks).is_ok());
    }

    #[test]
    fn test_sha256() {
        let circuit_inputs = r#"{
    "in": [
        "40",
        "202",
        "21",
        "44",
        "148",
        "225",
        "219",
        "127",
        "125",
        "137",
        "45",
        "39",
        "181",
        "182",
        "116",
        "221",
        "65",
        "64",
        "40",
        "99",
        "92",
        "60",
        "3",
        "33",
        "40",
        "159",
        "154",
        "251",
        "14",
        "238",
        "144",
        "106"
    ]
}"#.to_string();
        let result =
            generate_circom_proof(SHA256_ZKEY_PATH.to_string(), circuit_inputs, ProofLib::Arkworks);
        assert!(result.is_ok());
        let proof = result.unwrap();
        assert!(verify_circom_proof(SHA256_ZKEY_PATH.to_string(), proof, ProofLib::Arkworks).is_ok());
    }
}


// HALO2_TEMPLATE
halo2_stub!();

// NOIR_TEMPLATE
noir_stub!();

#[cfg(test)]
mod uniffi_tests {
    #[test]
    fn test_mopro_uniffi_hello_world() {
        assert_eq!(super::mopro_uniffi_hello_world(), "Hello, World!");
    }
}
