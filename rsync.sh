#!/bin/bash

rsync \
-e 'ssh -p 60000' \
-avr \
--delete \
--delete-during \
--files-from="./rsync_files.txt" \
./ \
prejoy@127.0.0.1:/home/prejoy/MySites/prejoy.github.io/
