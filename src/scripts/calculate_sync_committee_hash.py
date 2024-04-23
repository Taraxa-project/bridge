import os
import requests
from eth_utils import decode_hex
import hashlib
from typing import List

from eth2spec.utils.ssz.ssz_typing import (
     Container, Vector, Bytes48 )

PERIOD = 182 #UPDATE THIS
url = f'https://beacon-pr-2618.prnet.taraxa.io/eth/v1/beacon/light_client/updates?start_period={PERIOD}&count=1'

SYNC_COMMITTEE_SIZE = 512  # Example size, adjust as per your specs
BLSPUBLICKEY_LENGTH = 48  # Length of a BLS public key in bytes

class SyncCommittee(Container):
    pubkeys: Vector[Bytes48, SYNC_COMMITTEE_SIZE]
    aggregate_pubkey: Bytes48

def hash_tree_root(sync_committee: 'SyncCommittee') -> bytes:
    # Convert public keys into a Merkle tree and compute root
    pubkeys_leaves = []
    for pubkey in sync_committee.pubkeys:
        assert len(pubkey) == BLSPUBLICKEY_LENGTH, "!key"
        pubkeys_leaves.append(hashlib.sha256(pubkey + bytes(16)).digest())
    pubkeys_root = merkle_root(pubkeys_leaves)

    # Hash the aggregate public key
    assert len(sync_committee.aggregate_pubkey) == BLSPUBLICKEY_LENGTH, "!agg_key"
    aggregate_pubkey_root = hashlib.sha256(sync_committee.aggregate_pubkey + bytes(16)).digest()

    # Hash the nodes of the Merkle tree
    return hash_node(pubkeys_root, aggregate_pubkey_root)

def get_power_of_two_ceil(n):
    if n == 0:
        return 0
    n -= 1
    shift = 1
    while (n + 1) >> shift:
        shift <<= 1
    return 1 << shift

def merkle_root(leaves: list) -> bytes:
    len_leaves = len(leaves)
    if len_leaves == 0:
        return bytes(32)  # Return a zero-filled bytes32
    elif len_leaves == 1:
        return hash(leaves[0])
    elif len_leaves == 2:
        return hash_node(leaves[0], leaves[1])

    bottom_length = get_power_of_two_ceil(len_leaves)
    o = [bytes(32)] * (bottom_length * 2)  # Initialize with zero-filled bytes32

    # Fill the initial leaf positions
    for i in range(len_leaves):
        o[bottom_length + i] = leaves[i]

    # Construct the tree by calculating parent nodes
    for i in range(bottom_length - 1, 0, -1):
        o[i] = hash_node(o[i * 2], o[i * 2 + 1])

    return o[1]

def hash_node(left: bytes, right: bytes) -> bytes:
    return hashlib.sha256(left + right).digest()


response = requests.get(url)
data = response.json()
data = data[0]

sync_committee_pubkeys = data['data']['next_sync_committee']['pubkeys']
agg_pk = data['data']['next_sync_committee']['aggregate_pubkey']

sync_committee = SyncCommittee(pubkeys=[decode_hex(pubkey) for pubkey in sync_committee_pubkeys], aggregate_pubkey=decode_hex(agg_pk))

# Set path to .env file
env_file_path = os.path.join(os.getcwd(), '.env')  # Change as necessary

# Writing to the .env file
with open(env_file_path, 'a') as file:
    file.write(f"\nSLOT={data['data']['finalized_header']['beacon']['slot']}\n")
    file.write(f"PROPOSER_INDEX={data['data']['finalized_header']['beacon']['proposer_index']}\n")
    file.write(f"PARENT_ROOT={data['data']['finalized_header']['beacon']['parent_root']}\n")
    file.write(f"STATE_ROOT={data['data']['finalized_header']['beacon']['state_root']}\n")
    file.write(f"BODY_ROOT={data['data']['finalized_header']['beacon']['body_root']}\n")
    file.write(f"BLOCK_NUMBER={data['data']['finalized_header']['execution']['block_number']}\n")
    file.write(f"MERKLE_ROOT={data['data']['finalized_header']['execution']['state_root']}\n")
    file.write(f"SYNC_COMMITTEE_ROOT=0x{hash_tree_root(sync_committee).hex()}\n")
