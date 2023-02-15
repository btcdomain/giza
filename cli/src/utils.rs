/// Common trait for all cli commands
pub trait Cmd: clap::Parser + Sized {
    type Output;

    fn run(self) -> Self::Output;
}

pub fn get_program_hash(hex_str: Option<String>) -> Vec<u8>{
    if hex_str.is_some() {
        hex::decode(hex_str.unwrap()).unwrap()
    }else {
        vec![]
    }

}