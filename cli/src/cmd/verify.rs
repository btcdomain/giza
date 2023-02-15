use std::fs::File;
use std::io::Read;
use std::path::PathBuf;

use super::ProofData;
use crate::utils::{Cmd, get_program_hash};
use air::{ProcessorAir, PublicInputs};
use clap::{Parser, ValueHint};
use winter_utils::{Deserializable, SliceReader};
use winter_verifier::StarkProof;

pub struct VerifyOutput {}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct VerifyArgs {
    #[clap(
        help = "Path to the STARK proof",
        long,
        value_hint = ValueHint::FilePath
    )]
    pub proof: PathBuf,

    #[clap(
    help = "specific cairo program hash",
    long,
    value_hint = ValueHint::CommandString
    )]
    pub program_hash: Option<String>,
}

#[derive(Debug)]
pub enum Error {}

impl Cmd for VerifyArgs {
    type Output = Result<VerifyOutput, Error>;

    fn run(self) -> Self::Output {
        // Load proof and public inputs from file
        let mut b = Vec::new();
        let mut f = File::open(self.proof).unwrap();
        f.read_to_end(&mut b).unwrap();
        let data: ProofData = bincode::deserialize(&b).unwrap();
        let mut pub_inputs =
            PublicInputs::read_from(&mut SliceReader::new(&data.input_bytes[..])).unwrap();
        pub_inputs.program_hash = get_program_hash(self.program_hash);
        let proof = StarkProof::from_bytes(&data.proof_bytes).unwrap();

        // Verify execution
        match winter_verifier::verify::<ProcessorAir>(proof, pub_inputs) {
            Ok(_) => println!("Execution verified"),
            Err(err) => println!("Failed to verify execution: {}", err),
        }

        Ok(VerifyOutput {})
    }
}
