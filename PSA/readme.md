=========================================
Mongolab Sharded Cluster with Docker Compose
=========================================

## PSA Style (Primary - Secondary - Arbiter)

### Mongo Components

* Config Server (3 member replica set): `configsvr01`,`configsvr02`,`configsvr03`
* 3 Shards (each a 3 member `PSA` replica set):
	* `shard01-a`,`shard01-b` and 1 arbiter `shard01-x`
	* `shard02-a`,`shard02-b` and 1 arbiter `shard02-x`
	* `shard03-a`,`shard03-b` and 1 arbiter `shard03-x`
* 2 Routers (mongos): `router01`, `router02`

### Setup
- **Step 1: Start all of the containers**

```bash
docker-compose up -d
```

- **Step 2: Initialize the replica sets (config servers and shards) and routers**

```bash
docker-compose exec configsvr01 sh -c "mongo < /scripts/init-configserver.js"

docker-compose exec shard01-a sh -c "mongo < /scripts/init-shard01.js"
docker-compose exec shard02-a sh -c "mongo < /scripts/init-shard02.js"
docker-compose exec shard03-a sh -c "mongo < /scripts/init-shard03.js"
```

- **Step 3: Connect to the primary and add arbiters**
```bash
docker-compose exec shard01-a mongo --port 27017
rs.addArb("shard01-x:27017") // make sure that you are in primary before run this command
// or
docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.addArb(\""shard01-x:27017\"")' | mongo --port 27017"
```

```bash
docker-compose exec shard02-a mongo --port 27017
rs.addArb("shard02-x:27017") // make sure that you are in primary before run this command
// or
docker exec -it mongolab-shard-02-node-a bash -c "echo 'rs.addArb(\""shard02-x:27017\"")' | mongo --port 27017"
```

```bash
docker-compose exec shard03-a mongo --port 27017
rs.addArb("shard03-x:27017") // make sure that you are in primary before run this command
// or
docker exec -it mongolab-shard-03-node-a bash -c "echo 'rs.addArb(\""shard03-x:27017\"")' | mongo --port 27017"
```

- **Step 4: Initializing the router**
>Note: Wait a bit for the config server and shards to elect their primaries before initializing the router

```bash
docker-compose exec router01 sh -c "mongo < /scripts/init-router.js"
```

- **Step 5: Enable sharding and setup sharding-key**
```bash
docker-compose exec router01 mongo --port 27017

// Enable sharding for database `MyDatabase`
sh.enableSharding("MyDatabase")

// Setup shardingKey for collection `MyCollection`**
db.adminCommand( { shardCollection: "MyDatabase.MyCollection", key: { supplierId: "hashed" } } )

```

>Done! but before you start inserting data you should verify them first

### Verify

- **Verify the status of the sharded cluster**

```bash
docker-compose exec router01 mongo --port 27017
sh.status()
```

- **Verify status of replica set for each shard**
> You should see 1 PRIMARY, 1 SECONDARY and 1 ARBITER

```bash
docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
docker exec -it mongolab-shard-02-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
docker exec -it mongolab-shard-03-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
```

- **Check database status**
```bash
docker-compose exec router01 mongo --port 27017
use MyDatabase
db.stats()
db.MyCollection.getShardDistribution()
```

### More commands

```bash
docker exec -it mongolab-mongo-config-01 bash -c "echo 'rs.status()' | mongo --port 27017"


docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.help()' | mongo --port 27017"
docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.status()' | mongo --port 27017" 
docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.printReplicationInfo()' | mongo --port 27017" 
docker exec -it mongolab-shard-01-node-a bash -c "echo 'rs.printSlaveReplicationInfo()' | mongo --port 27017"
```

---

### Normal Startup
The cluster only has to be initialized on the first run. Subsequent startup can be achieved simply with `docker-compose up` or `docker-compose up -d`

### Resetting the Cluster
To remove all data and re-initialize the cluster, make sure the containers are stopped and then:

```bash
docker-compose rm
```

### Clean up docker-compose
```bash
docker-compose down -v --rmi all --remove-orphans
```

Execute the **First Run** instructions again.


