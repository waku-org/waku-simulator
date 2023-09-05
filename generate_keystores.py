import json
import copy
import os
import subprocess
# Opening JSON file
f = open('rlnKeystore.json')

# returns JSON object as
# a dictionary
data = json.load(f)

base_credentials = copy.deepcopy(data)
base_credentials["credentials"] = {}

#print(data["credentials"][0])

#config
NUM_KEYSTORES_TO_GENERATE = 2
BASE_FOLDER = "data"
assert len(data["credentials"]) > NUM_KEYSTORES_TO_GENERATE

import shutil
#if os.path.exists(BASE_FOLDER):
#    shutil.rmtree(BASE_FOLDER)
if not os.path.exists(BASE_FOLDER):
    os.mkdir(BASE_FOLDER, mode=0o777, dir_fd=None)
index = 0


for k,v in data["credentials"].items():
    new_cred = copy.deepcopy(base_credentials)
    new_cred["credentials"][k] = v
    #base_credentials["credentials"][0] = data["credentials"][i]
    print(base_credentials)
    new_dir = BASE_FOLDER + "/nwaku_" + str(index)
    if not os.path.exists(new_dir):
        os.mkdir(new_dir, mode=0o777, dir_fd=None)
    fname = new_dir+'/rlnKeystore_' + str(index) + ".json"
    with open(fname, 'w') as outfile:
        json.dump(new_cred, outfile, separators=(',', ':'))
        #json.dump(base_credentials, outfile)
    #os.chmod(fname, 0o777)

    import stat
    #os.chmod(fname, stat.S_IRWXO)
    #os.chmod(fname, stat.S_IRUSR | stat.S_IRGRP | stat.S_IROTH)
    # quick to make it work
    print(subprocess.run(['chmod', '777', fname]))
    print(subprocess.run(['chmod', '777', new_dir]))
    index += 1


f.close()
