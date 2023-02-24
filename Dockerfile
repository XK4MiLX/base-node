FROM golang:1.19 as op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV COMMIT=3c3e1a88b234a68bcd59be0c123d9f3cc152a91e
RUN git init && \
    git remote add origin $REPO && \
    git fetch --depth=1 origin $COMMIT && \
    git reset --hard FETCH_HEAD

RUN cd op-node && \
    make op-node


FROM golang:1.19 as geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth.git
ENV COMMIT=0678a130d7908b64aea596320099d30463119169
RUN git init && \
    git remote add origin $REPO && \
    git fetch --depth=1 origin $COMMIT && \
    git reset --hard FETCH_HEAD

RUN go run build/ci.go install -static ./cmd/geth


FROM golang:1.19

ENV OP_GETH_GENESIS_FILE_PATH=goerli/genesis-l2.json
ENV OP_GETH_SEQUENCER_HTTP=https://goerli.base.org
ENV OP_NODE_L2_ENGINE_AUTH=/tmp/engine-auth-jwt
ENV OP_NODE_L2_ENGINE_AUTH_RAW=688f5d737bad920bdfb2fc2f488d6b6209eebda1dae949a8de91398d932c517a # for localdev only

ENV OP_NODE_L1_ETH_RPC=${NODE_ETH_RPC:-https://goerli.infura.io/v3/4bf416a021df4c2bbb25e8dc82296836} # replace with your L1 node RPC URL
ENV OP_NODE_L2_ENGINE_AUTH=/tmp/engine-auth-jwt
ENV OP_NODE_L2_ENGINE_AUTH_RAW=688f5d737bad920bdfb2fc2f488d6b6209eebda1dae949a8de91398d932c517a # for localdev only
ENV OP_NODE_L2_ENGINE_RPC=http://${NODE_L2_RPC:-geth}:8551
ENV OP_NODE_LOG_LEVEL=info
ENV OP_NODE_METRICS_ADDR=0.0.0.0
ENV OP_NODE_METRICS_ENABLED=true
ENV OP_NODE_METRICS_PORT=7300
ENV OP_NODE_P2P_AGENT=base
ENV OP_NODE_P2P_BOOTNODES=enr:-J64QBbwPjPLZ6IOOToOLsSjtFUjjzN66qmBZdUexpO32Klrc458Q24kbty2PdRaLacHM5z-cZQr8mjeQu3pik6jPSOGAYYFIqBfgmlkgnY0gmlwhDaRWFWHb3BzdGFja4SzlAUAiXNlY3AyNTZrMaECmeSnJh7zjKrDSPoNMGXoopeDF4hhpj5I0OsQUUt4u8uDdGNwgiQGg3VkcIIkBg,enr:-J64QAlTCDa188Hl1OGv5_2Kj2nWCsvxMVc_rEnLtw7RPFbOfqUOV6khXT_PH6cC603I2ynY31rSQ8sI9gLeJbfFGaWGAYYFIrpdgmlkgnY0gmlwhANWgzCHb3BzdGFja4SzlAUAiXNlY3AyNTZrMaECkySjcg-2v0uWAsFsZZu43qNHppGr2D5F913Qqs5jDCGDdGNwgiQGg3VkcIIkBg
ENV OP_NODE_P2P_LISTEN_IP=0.0.0.0
ENV OP_NODE_P2P_LISTEN_TCP_PORT=9222
ENV OP_NODE_P2P_LISTEN_UDP_PORT=9222
ENV OP_NODE_ROLLUP_CONFIG=goerli/rollup.json
ENV OP_NODE_RPC_ADDR=0.0.0.0
ENV OP_NODE_RPC_PORT=8545
ENV OP_NODE_SNAPSHOT_LOG=/tmp/op-node-snapshot-log
ENV OP_NODE_VERIFIER_L1_CONFS=0

RUN apt-get update && \
    apt-get install -y jq curl

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=geth /app/build/bin/geth ./
COPY . .
