
# Get the current sync committee pubkeys from 'http://unstable.holesky.beacon-api.nimbus.team/eth/v1/beacon/light_client/updates?start_period=170&count=1'
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



def _serialize_uncompressed_g1(g1):
    x = int(g1[0]).to_bytes(48, byteorder="big")
    y = int(g1[1]).to_bytes(48, byteorder="big")
    return x + y

# Get the current sync committee pubkeys
url = 'http://unstable.holesky.beacon-api.nimbus.team/eth/v1/beacon/light_client/updates?start_period=170&count=1'
response = requests.get(url)
data = response.json()
sync_committee_pubkeys = data[0]['data']['next_sync_committee']['pubkeys']

compressed_pubkeys = [decode_hex(pubkey[2:]) for pubkey in sync_committee_pubkeys]

agg_pk = bls_pop._AggregatePKs(compressed_pubkeys)

print(agg_pk.hex())

env_file_path = os.path.join(os.path.dirname(__file__), '..', '..', '.env')

# # Writing the aggregated public key into the .env file
with open(env_file_path, 'a') as file:
    file.write(f"AGGREGATED_PUBLIC_KEY=0x{agg_pk.hex()}\n")
