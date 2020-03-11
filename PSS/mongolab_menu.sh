#!/bin/bash -       
#title           :mongo_menu.sh
#description     :This script will make an installation and setup of the Mongo Lab Cluster.
#author		 :Alejandro Bautista
#date            :2020 09 03
#version         :0.1    
#usage		 :bash mongo_menu.sh
#notes           :-
#bash_version    :-
#==============================================================================


#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

# Continued from above example
#echo -e "I ${RED}love${NC} Color!"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

while true; do

    title="MongoLab Setup"
    prompt="Pick an option:"
    options=("Initialize MongoDB Cluster" 
        "Verify the Cluster status (router01)"
        "Verify Docker containers"
        "Start Cluster"
        "Stop Cluster"
        "Shutdown and remove cluster (WARNING:this will remove all containers!)"
        "Prune All Docker files (WARNING:this will remove all containers,images,networks and volumes!)"
        "Update MongoDB Lab Cluster Code"
        "Invite Alejandro a Cofee! (best option)")

    echo -e "${GREEN} $title ${NC}"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do 

        case "$REPLY" in

        1 ) echo "You picked $opt which is option $REPLY"
            echo -e "${CYAN} [TASK] STARTING UP THE CLUSTER... ${NC}"
            docker-compose up -d
            echo -e "${CYAN} [TASK] INITIATING CONFIG SERVER... ${NC}"
            docker-compose exec configsvr01 sh -c "mongo < /scripts/init-configserver.js"
            echo -e "${CYAN} [TASK] INITIATING SHARDING... ${NC}"
            docker-compose exec shard01-a sh -c "mongo < /scripts/init-shard01.js"
            docker-compose exec shard02-a sh -c "mongo < /scripts/init-shard02.js"
            docker-compose exec shard03-a sh -c "mongo < /scripts/init-shard03.js"
            echo -e "${CYAN} [TASK] WAITING 10S TO INITIATE THE ROUTER... ${NC}"
            sleep 10s            
            docker-compose exec router01 sh -c "mongo < /scripts/init-router.js"
            echo -e "${CYAN} [TASK] ENABLE SHARDING ON THE ROUTER 01... ${NC}"
            #docker-compose exec router01 mongo --port 27017
            docker-compose exec router01 sh -c "mongo < /scripts/enable-sharding.js"
            echo -e "${CYAN} [TASK] STARTING UP MONGOEXPRESS CONTAINER... ${NC}"
            docker run --name mongo-express-gui -d --network pss_default -e ME_CONFIG_MONGODB_SERVER=mongolab-mongo-config-01,mongolab-mongo-config-02,mongolab-mongo-config-03 -p 8081:8081 mongo-express
    
            break;;
        2 ) echo "You picked $opt which is option $REPLY"
            
            #docker-compose exec router01 mongo --port 27017
            echo -e "${CYAN} [TASK] CHECKING SHARD STATUS ON ROUTER 01... ${NC}"
            docker-compose exec router01 sh -c "mongo < /scripts/shard-status.js"
            echo -e "${CYAN} [TASK] CHECKING REPLICA SET STATUS ON EACH SHARD... ${NC}"
            docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
            docker exec -it mongolab-shard-02-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
            docker exec -it mongolab-shard-03-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
            echo -e "${CYAN} [TASK] CHECKING SHARD DISTRIBUTION... ${NC}"
            #docker-compose exec router01 mongo --port 27017
            docker-compose exec router01 sh -c "mongo < /scripts/shard-distribution.js"
        
            break;;    

        3 ) echo "You picked $opt which is option: $REPLY"
            
            echo -e "${CYAN} [TASK] CHECKING MONGO LAB DOCKER CONTAINERS... ${NC}"
            docker container ls --size --filter name=mongo* 
                       
        
            break;;       
        4 ) echo "You picked $opt which is option: $REPLY"
            
            echo -e "${CYAN} [TASK] STARTING MONGO LAB CLUSTER AND MONGO EXPRESS... ${NC}"
            docker-compose up -d
            docker container restart mongo-express-gui                       
        
            break;;   
        5 ) echo "You picked $opt which is option $REPLY"
            
            echo -e "${CYAN} [TASK] STOPPING MONGO LAB CLUSTER AND MONGO EXPRESS... ${NC}"
            docker stop mongo-express-gui        
            docker-compose down
        
            break;;       
        6 ) echo "You picked $opt which is option $REPLY"
            
            echo -e "${CYAN} [TASK] REMOVING MONGO LAB CLUSTER AND MONGO EXPRESS CONTAINERS... ${NC}"

            docker container stop $(docker container ls -aq | grep mongolab)
            docker stop mongo-express-gui
            docker rm mongo-express-gui
            docker container rm  mongo-express-gui
            docker-compose rm
            docker-compose down -v --rmi all --remove-orphans
        
            break;;

        7 ) echo "You picked $opt which is option $REPLY"
            
            echo -e "${CYAN} [TASK] DOCKER SYSTEM PRUNE... ${NC}"
            docker system prune -a --volumes   

            break;;
        8 ) echo "You picked $opt which is option $REPLY"
            
            echo -e "${CYAN}[TASK] Pulling newest version...${NC}"
            git pull
            
            break;;
        
        9 ) echo "You picked $opt which is option $REPLY"
            
            echo -e "${CYAN} Thank you, that is the best option! :) ${NC}"
            
            break;;
        $(( ${#options[@]}+1 )) ) echo -e "${YELLOW}Goodbye!${NC}"; exit;;
        *) echo -e "${RED}Invalid option. Try another one.${NC}";continue;;

        esac
    done

    echo -e "${YELLOW} Are we done? ${NC}"
   
    select opt in "Yes" "No"; do
        case $REPLY in
            1) break 2 ;;
            2) break ;;
            *) echo -e "${RED}Invalid option! 1=Yes 2=No ${NC} " >&2
        esac
    done

done