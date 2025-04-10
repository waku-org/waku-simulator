import requests
import time
import datetime
import os
import base64
import urllib.parse
import requests
import argparse
import re

def send_waku_msg(node_address, kbytes, pubsub_topic, content_topic):
    # TODO dirty trick .replace("=", "")
    base64_payload = (base64.b64encode(os.urandom(kbytes*1000)).decode('ascii')).replace("=", "")
    print("size message kBytes", len(base64_payload) *(3/4)/1000, "KBytes")
    body = {
        "payload": base64_payload,
        "contentTopic": content_topic,
        "version": 1,  # You can adjust the version as needed
        #"timestamp": int(time.time())
    }

    encoded_pubsub_topic = urllib.parse.quote(pubsub_topic, safe='')

    url = f"{node_address}/relay/v1/messages/{encoded_pubsub_topic}"
    headers = {'content-type': 'application/json'}

    readable_time = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    print('[%s] Waku REST API: %s PubSubTopic: %s, ContentTopic: %s' % (readable_time, url, pubsub_topic, content_topic))
    s_time = time.time()
    
    response = None
    readable_time = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    try:
      print('[%s] Sending request' % readable_time)
      response = requests.post(url, json=body, headers=headers)
    except Exception as e:
      print(f"Error sending request: {e}")

    if(response != None):
      elapsed_ms = (time.time() - s_time) * 1000
      readable_time = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
      print('[%s] Response from %s: status:%s content:%s [%.4f ms.]' % (readable_time, node_address, \
        response.status_code, response.text, elapsed_ms))

parser = argparse.ArgumentParser(description='')

# these flags are mutually exclusive, one or the other, never at once
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-sn', '--single-node', type=str, help='example: http://waku-simulator-nwaku-1:8645')
group.add_argument('-mn', '--multiple-nodes', type=str, help='example: http://waku-simulator-nwaku-[1..10]:8645')

# rest of araguments
parser.add_argument('-c', '--content-topic', type=str, help='content topic', default="my-ctopic")
parser.add_argument('-p', '--pubsub-topic', type=str, help='pubsub topic', default="/waku/2/rs/66/0")
parser.add_argument('-s', '--msg-size-kbytes', type=int, help='message size in kBytes', default=10)
parser.add_argument('-d', '--delay-seconds', type=int, help='delay in second between messages', required=15)
args = parser.parse_args()

print(args)

if args.single_node != None:
  print("Injecting traffic to single node REST API:", args.single_node)

# this simply converts from http://url_[1..5]:port to
# [http://url_1:port or from http://url-[1..5]:port to
# [http://url-1:port
nodes = []
if args.multiple_nodes:
  start, end = (int(x) for x in re.search(r"\[(\d+)\.\.(\d+)\]", args.multiple_nodes).groups()) 
 
  if start is None or end is None:
      print("Could not parse range of multiple_nodes argument")
      exit

  print("Injecting traffic to multiple nodes REST APIs") 
  for i in range(end, start - 1, -1): 
    nodes.append(re.sub(r"\[\d+\.\.\d+\]", str(i), args.multiple_nodes))

for node in nodes:
  print(node)

while True:
    # calls are blocking
    # limited by the time it takes the REST API to reply

    if args.single_node != None:
      send_waku_msg(args.single_node, args.msg_size_kbytes, args.pubsub_topic, args.content_topic)

    if args.multiple_nodes != None:
      for node in nodes:
        send_waku_msg(node, args.msg_size_kbytes, args.pubsub_topic, args.content_topic)

    readable_time = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    print('[%s] sleeping: %s seconds' % (readable_time, args.delay_seconds))
    time.sleep(args.delay_seconds)