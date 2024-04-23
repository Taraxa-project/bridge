
# Get the current sync committee pubkeys from 'https://beacon-pr-2618.prnet.taraxa.io/eth/v1/beacon/light_client/updates?start_period=177&count=1'
import os
import requests
from eth_utils import decode_hex

from eth2spec.utils.ssz.ssz_impl import hash_tree_root
from eth2spec.utils.ssz.ssz_typing import (
     Container, Vector, Bytes48 )

class SyncCommittee(Container):
    pubkeys: Vector[Bytes48, 512]
    aggregate_pubkey: Bytes48

PERIOD = 182
url = 'https://beacon-pr-2618.prnet.taraxa.io/eth/v1/beacon/light_client/updates?start_period='+str(PERIOD)+'&count=1'
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


compressed_pubkeys = [decode_hex(pubkey) for pubkey in sync_committee_pubkeys]
# get keys and pass them to new SyncCommittee object
sync_committee = SyncCommittee((compressed_pubkeys, decode_hex(agg_pk)))

env_file_path = os.path.join(os.path.dirname(__file__), '..', '..', '.env')

# # Writing the aggregated public key into the .env file
with open(env_file_path, 'a') as file:
    # write env variables for all from slot to agg_pk
    file.write(f"\nSLOT={slot}\n")
    file.write(f"PROPOSER_INDEX={proposer_index}\n")
    file.write(f"PARENT_ROOT={parent_root}\n")
    file.write(f"STATE_ROOT={state_root}\n")
    file.write(f"BODY_ROOT={body_root}\n")
    file.write(f"BLOCK_NUMBER={block_number}\n")
    file.write(f"MERKLE_ROOT={merkle_root}\n")
    file.write(f"SYNC_COMMITTEE_ROOT={hash_tree_root(sync_committee)}\n")
