use winter_prover::ProverError;

#[derive(Debug)]
pub enum ExecutionError {
    ProverError(ProverError),
}
