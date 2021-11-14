#!/bin/sh

#
# Copyright 2019-2020 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e # Any command which returns non-zero exit code will cause this shell script to exit immediately
set -x # Activate debugging to show execution details: all commands will be printed before execution

containerName=${1:-projector-idea-c}
ideUrl=${2:-https://download.jetbrains.com/idea/ideaIU-2021.1.3.tar.gz}
jdkUrl=${3:-https://big.guiren21.com/201704/tools/jdk-linux-x64.tar.gz}
goUrl=${4:-https://dl.google.com/go/go1.17.3.linux-amd64.tar.gz}
projectorUrl=${5:-https://github.com/JetBrains/projector-server/releases/download/v1.5.0/projector-server-v1.5.0.zip}

# build container:
docker build -t "$containerName"  --build-arg "ideUrl=$ideUrl"  --build-arg "jdkUrl=$jdkUrl"   --build-arg "goUrl=$goUrl"   \
  --build-arg "projectorUrl=$projectorUrl" -f Dockerfile ..
