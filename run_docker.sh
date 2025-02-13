
mkdir -p ./vault/data 

export OPENBAO_DEV_LISTEN_ADDRESS=0.0.0.0:8200
export OPENBAO_DEV_ROOT_TOKEN_ID="root"

 mkdir ./mysql-data

docker-compose up -d
docker logs openbao 2>/dev/null|grep "Root Token"
docker logs openbao 2>/dev/null|grep "Unseal Key" 
