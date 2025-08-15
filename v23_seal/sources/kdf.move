// Copyright (c), Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module v23_seal::kdf;

use std::hash::sha3_256;
use sui::{bls12381::{Self, G1, G2, GT}, group_ops::Element};

const DST_KDF: vector<u8> = b"SUI-SEAL-IBE-BLS12381-H2-00";
const DST_ID: vector<u8> = b"SUI-SEAL-IBE-BLS12381-00";

public(package) fun kdf(
    input: &Element<GT>,
    nonce: &Element<G2>,
    gid: &Element<G1>,
    object_id: address,
    index: u8,
): vector<u8> {
    let mut bytes = DST_KDF;
    bytes.append(*input.bytes());
    bytes.append(*nonce.bytes());
    bytes.append(*gid.bytes());
    bytes.append(object_id.to_bytes());
    bytes.push_back(index);
    sha3_256(bytes)
}

public(package) fun hash_to_g1_with_dst(id: &vector<u8>): Element<G1> {
    let mut bytes = DST_ID;
    bytes.append(*id);
    bls12381::hash_to_g1(&bytes)
}

#[test]
fun test_kdf() {
    use sui::bls12381::{scalar_from_u64, g2_generator, gt_generator, g2_mul, gt_mul};
    let r = scalar_from_u64(12345u64);
    let x = gt_mul(&r, &gt_generator());
    let nonce = g2_mul(&r, &g2_generator());
    let gid = hash_to_g1_with_dst(&vector[0]);
    let derived_key = kdf(&x, &nonce, &gid, @0x0, 42);
    let expected = x"89befdfd6aecdce1305ddbca891d1c29f0507cfd5225cd6b11e52e60f088ea87";
    assert!(derived_key == expected);
}