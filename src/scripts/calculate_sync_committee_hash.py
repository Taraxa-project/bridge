
# Get the current sync committee pubkeys from 'https://beacon-pr-2618.prnet.taraxa.io/eth/v1/beacon/light_client/updates?start_period=177&count=1'
import os
import requests
from py_ecc.bls import G2ProofOfPossession as bls_pop
from eth_utils import decode_hex
from typing import Tuple

def get_flags(z: int) -> Tuple[bool, bool, bool]:
    c_flag = bool((z >> 383) & 1)  # The most significant bit.
    b_flag = bool((z >> 382) & 1)  # The second-most significant bit.
    a_flag = bool((z >> 381) & 1)  # The third-most significant bit.
    return c_flag, b_flag, a_flag

# Get the current sync committee pubkeys
url = 'https://beacon-pr-2618.prnet.taraxa.io/eth/v1/beacon/light_client/updates?start_period=180&count=1'
response = requests.get(url)
data = response.json()

slot = data[0]['data']['finalized_header']['beacon']['slot']
proposer_index = data[0]['data']['finalized_header']['beacon']['proposer_index']
parent_root = data[0]['data']['finalized_header']['beacon']['parent_root']
state_root = data[0]['data']['finalized_header']['beacon']['state_root']
body_root = data[0]['data']['finalized_header']['beacon']['body_root']
block_number = data[0]['data']['finalized_header']['execution']['block_number']
merkle_root = data[0]['data']['finalized_header']['execution']['state_root']
sync_committee_pubkeys = data[0]['data']['next_sync_committee']['pubkeys']
agg_pk = data[0]['data']['next_sync_committee']['aggregate_pubkey']


compressed_pubkeys = [decode_hex(pubkey[2:]) for pubkey in sync_committee_pubkeys]


env_file_path = os.path.join(os.path.dirname(__file__), '..', '..', '.env')

# # Writing the aggregated public key into the .env file
with open(env_file_path, 'a') as file:
    # write env variables for all from slot to agg_pk
    file.write(f"SLOT={slot}\n")
    file.write(f"PROPOSER_INDEX={proposer_index}\n")
    file.write(f"PARENT_ROOT=0x{parent_root}\n")
    file.write(f"STATE_ROOT=0x{state_root}\n")
    file.write(f"BODY_ROOT=0x{body_root}\n")
    file.write(f"BLOCK_NUMBER={block_number}\n")
    file.write(f"MERKLE_ROOT=0x{merkle_root}\n")
    for i, pubkey in enumerate(compressed_pubkeys):
        file.write(f"SYNC_COMMITTEE_PUBKEY_{i}=0x{pubkey.hex()}\n")
    file.write(f"\nAGGREGATED_PUBLIC_KEY=0x{agg_pk}\n")
