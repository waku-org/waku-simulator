import requests
import time
import json
import os
import base64
import argparse
import sys

def send_waku_msg(node_address, kbytes, pubsub_topic, content_topic):
    # TODO dirty trick .replace("=", "")
    base64_payload = (base64.b64encode(os.urandom(kbytes*1000)).decode('ascii')).replace("=", "")
    #print(base64_payload)
    print("size message kBytes", len(base64_payload) *(3/4)/1000, "KBytes")
    #pubsub_topic = "/waku/2/default-waku/proto"
    #content_topic = "xxx"
    data = {
        'jsonrpc': '2.0',
        'method': 'post_waku_v2_relay_v1_message',
        'id': 1,
        'params': [pubsub_topic, {"payload": base64_payload, "contentTopic": content_topic, "ephemeral": False}]
    }
    print('Waku RPC: %s from %s PubSubTopic: %s, ContentTopic: %s' % (data['method'], node_address, pubsub_topic, content_topic))
    s_time = time.time()
    #print(data)
    response = requests.post(node_address, data=json.dumps(data), headers={'content-type': 'application/json'})
    elapsed_ms = (time.time() - s_time) * 1000
    response_obj = response.json()
    print('Response from %s: %s [%.4f ms.]' % (node_address, response_obj, elapsed_ms))
    return response_obj

parser = argparse.ArgumentParser(description='')

# these flags are mutually exclusive, one or the other, never at once
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-sn', '--single-node', type=str, help='example: http://waku-simulator_nwaku_1:8545')
group.add_argument('-mn', '--multiple-nodes', type=str, help='example: http://waku-simulator_nwaku_[1..10]:8545')

# rest of araguments
parser.add_argument('-c', '--content-topic', type=str, help='content topic', default="my-ctopic")
parser.add_argument('-p', '--pubsub-topic', type=str, help='pubsub topic', default="/waku/2/default-waku/proto")
parser.add_argument('-s', '--msg-size-kbytes', type=int, help='message size in kBytes', default=10)
parser.add_argument('-d', '--delay-seconds', type=int, help='delay in second between messages', required=15)
args = parser.parse_args()

print(args)

if args.single_node != None:
  print("Injecting traffic to single node RPC:", args.single_node)

# this simply converts from http://url_[1..5]:port to
# [http://url_1:port
nodes = []
if args.multiple_nodes:
  range_nodes = args.multiple_nodes.split(":")[1].split("_")[2]
  node_placeholder = args.multiple_nodes.replace(range_nodes, "{placeholder}")
  clean_range = range_nodes.replace("[", "").replace("]", "")
  start = int(clean_range.split("..")[0])
  end = int(clean_range.split("..")[1])

  print("Injecting traffic to multiple nodes RPC") 
  for i in range(start, end+1):
    nodes.append(node_placeholder.replace("{placeholder}", str(i)))

print("Injecting traffic to multiple nodes RPC")
for node in nodes:
  print(node)

while True:
    # calls are blocking
    # limited by the time it takes the rpc to reply

    if args.single_node != None:
      send_waku_msg(args.single_node, args.msg_size_kbytes, args.pubsub_topic, args.content_topic)

    if args.multiple_nodes != None:
      for node in nodes:
        send_waku_msg(node, args.msg_size_kbytes, args.pubsub_topic, args.content_topic)

    print("sleeping: ", args.delay_seconds, " seconds")
    time.sleep(args.delay_seconds)