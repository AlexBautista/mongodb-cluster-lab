sh.enableSharding("MyDatabase")
db.adminCommand( { shardCollection: "MyDatabase.MyCollection", key: { supplierId: "hashed" } } )
show dbs
exit