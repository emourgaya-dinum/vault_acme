
mkdir -p ./vault/data 

export OPENBAO_DEV_LISTEN_ADDRESS=0.0.0.0:8200
export OPENBAO_DEV_ROOT_TOKEN_ID="root"

 mkdir ./mysql-data

 docker-compose up -d # ou docker-compose up
 