# Riak 2.0 Quickstart

^Who I am. Story. 

---

# Agenda

* 1:45 Setup Test VMs
* 2:00 Riak Overview
* 3:00 What’s New in 2.0
* Bucket Types, Strong Consistency, Data Types, Search, Security
* 4:40 Coding a Sample App
* 5:30 Wrapup QnA

^There will be time for questions after each section overview, and a final QnA at the end of the day. It’s an aggressive agenda. My goal is that your mind is melted by the end of this, but also energized with ideas. Coding a Sample App (use DTs, create partition: http://aphyr.com/posts/281-call-me-maybe-carly-rae-jepsen-and-the-perils-of-network-partitions ) 

---

# http://172.20.21.112/

---

# Port Forwarding

* Network settings (should be port 2201)
* ssh root@localhost -p 2201
* password: basho
* cd /riak/dev

---

# Start all Nodes

* $ /riak/dev/dev1/bin/riak start
* $ /riak/dev/dev2/bin/riak start
* $ /riak/dev/dev3/bin/riak start
* ## OR ##
* for d in `ls /riak/dev`; do /riak/dev/$d/bin/riak start; done
* for d in `ls /riak/dev`; do /riak/dev/$d/bin/riak ping; done

---

# Setup a Cluster

* cd /riak/dev
* ./dev2/bin/riak-admin cluster join dev1@127.0.0.1
* ./dev3/bin/riak-admin cluster join dev1@127.0.0.1
* ./dev1/bin/riak-admin cluster plan
* ./dev2/bin/riak-admin cluster commit
* ./dev1/bin/riak-admin member-status

---

# Riak Overview

* Key Value Datastore
* Distributed
* Fault tolerant
* Highly Available
* Critical Data
* Operational simplicity
* Open Source

^How does Riak provide all of these things? It’s the soul of Riak, and how it distributes data. Let’s start at the beginning. 

---

# 5 min Break

---

# New in Riak 2.0

* Bucket Types
* Strong Consistency
* Data Types
* Search
* Security
* Etc. (new AAE, new config, improvements, fixes)

^In this section I’ll have you follow along. This is the operations side of things. If you’re an operator, this is what you’ll see of 2.0. Once we’re through all of these things, we’ll toy around with these points from a developer point of view, and write Ruby code that connects to the server. 

---

# Bucket Types

---

# Why?

* Define total configurations prior to bucket creation and change them if you need to.
* More structured application for defining and managing bucket properties across groups of similar buckets.
* Better performance (plumtree, not gossip)

^Why should I use bucket types in Riak 2.0 over the original bucket properties? Performance: Less bucket configuration to gossip around the cluster. 

---

# When?

* Always

^When should you use bucket types in Riak 2.0? 

---

# Key Features

* Command line interface
* A higher level namespace than buckets
* Better performance (plumtree, not gossip)
* New defaults

---

# Command Line Exercise

* riak-admin bucket-type list
* riak-admin bucket-type status default
* riak-admin bucket-type create critical  '{"props":{"n_val":3}}'
* riak-admin bucket-type activate critical
* riak-admin bucket-type update critical  '{"props":{"pw":3, "pr":3}}'

^Creating a critical bucket-type and setting n_val to 5 and then pw & pr to 3. Follow along 

---

# Third Namespace

* %% The following two requests will be made to completely different keys, even though the bucket and key names are the same.
* {ok, Obj1} = riakc_pb_socket:get(Pid,{<<"type1">>,<<"my_bucket">>},<<"my_key">>),
* {ok, Obj2} = riakc_pb_socket:get(Pid,{<<"type2">>,<<"my_bucket">>},<<“my_key”>>).
* ## HTTP
* ## The following two requests will be made to completely different keys, even though the bucket and key names are the same.
* curl http://localhost:8098/types/type1/my_bucket/my_key
* curl http://localhost:8098/types/type2/my_bucket/my_key

^The example is in Erlang 

---

# Upgrade Support

* Existing buckets use default bucket type.
* default bucket type matches Riak 1.4.x defaults (including {allow_mult, false}).
* All newly defined bucket types use {allow_mult, true} unless explicitly set to false.

^This means that applications that have previously ignored conflict resolutions in certain buckets (or all buckets) can continue to do so. New applications, however, are encouraged to retain and resolve siblings with the appropriate application-side business logic. Allow_mult true is needed for CRDTs. 

---

# Downgrade Support

* Following an upgrade to version 2.0 or later, you can still downgrade the cluster to a pre-2.0 version if you have not created and activated a bucket type in the cluster.
* Once any bucket type has been created and activated, you can no longer downgrade the cluster to a pre-2.0 version.

---

# Using Bucket Types

* O1 = riakc_obj:new(<<"memes">>,
*                    <<"all_your_base">>,
*                    <<"all your base are belong to us">>,
*                    <<"text/plain">>),
* riakc_pb_socket:put(Pid, O1).
* O2 = riakc_obj:new({<<"critical">>, <<"memes">>},
*                     <<"doge">>,
*                     <<"such bucket, very perform">>,
*                     <<"text/plain">>),
* riakc_pb_socket:put(Pid, O2).

^You use them just like you’d use buckets without types, you just have to add the type name to any request. 

---

# Questions?

---

# Strong Consistency

^In versions 2.0 and later, Riak allows you to create buckets that provide strong consistency guarantees for the data stored within them, enabling you to use Riak as a CP system (consistent plus partition tolerant) for at least some of your data.  This option was added to complement Riak's standard eventually consistent, high availability mode. When data is stored in a bucket with strong consistency guarantees, a value is guaranteed readable by any node immediately after a successful write has occurred. 

---

# How do we CP?

^A single vnode is the leader in an ensemble which makes sure updates are consistent by leader election per key, using a form of the Paxos algorithm. Reads can end up being just a read of the leader. Writes can be made just to the leader then replicated to the others. Can handle a minority of replicating nodes failing, but not a majority. 

---

# strong_consistency = on

^Note: This will enable you to use strong consistency in Riak, but this setting will not apply to all of the data in your Riak cluster. Instead, strong consistency is applied only at the bucket level, using bucket types. 

---

# Rolling Update

* ## Set SC from off to on
* find /riak/dev -name riak.conf | xargs sed \
* -e "s/## strong_consistency = on/strong_consistency = on/" -i
* ## restart each node
* for d in `ls /riak/dev`; do /riak/dev/$d/bin/riak restart; done
* http://bit.ly/1vMY5Aa

^In production, if you want to activate search, you would do a rolling restart, where you take down each node, update the riak.conf file, and start it back up.
 

---

# Set as a Bucket Type

* riak-admin bucket-type create sc \
* '{"props":{"consistent":true}}'
* riak-admin bucket-type activate sc
* riak-admin bucket-type status sc

^Run this yourself. 
 

---

# SC Exercise

* curl -XPUT http://localhost:10018/types/sc/buckets/cats/keys/liono \
* -H'text/plain' \
* -d'Thundercats Ho!'
* /riak/dev/dev3/bin/riak stop
* /riak/dev/dev4/bin/riak stop
* # Try running the PUT again
* /riak/dev/dev3/bin/riak start
* /riak/dev/dev4/bin/riak start

^Run this yourself. Write a value. Take down two nodes. Try writing again. Try writing to a non-SC bucket: replace “sc" with “default” 

---

# Properties

* All PUTs to existing keys must pass in a vector clock.
* If the vector clock is stale the PUT will fail and a new GET is needed for the latest vector clock before retrying the PUT.
* No MDC support in Riak 2.0.

^Sad to say, no MDC support in 2.0 

---

# Data Types

---

# Data Types via Bucket Types

* riak-admin bucket-type list
* riak-admin bucket-type create maps \
*   '{"props":{"datatype":"map"}}'
* riak-admin bucket-type activate maps
* riak-admin bucket-type status maps

---

# Why?

* Easier to reason about datatypes
* Pre-defined convergent behavior
* Reduced traffic for small object deltas

^Riak used to support only opaque values. It still does, you can still store anything from JSON to images. 

---

# How?

* CRDTs (Conflict-free Replicated Data Types)
* CvRDT (Convergent) backend
* CmRDT (Commutative) frontend
* Think git, but magic

---

# Supported Types

* Counter
* Flag
* Set
* Map (counter, flag, set, map, register)

---

# Using Data Types is Different

* curl -XPUT http://localhost:10018/types/maps/buckets/people/keys/brown \
* -H'Content-Type:application/json' \
* -d'{"update":{"name":"Danny"}}'
* curl -XPUT http://localhost:10018/types/maps/buckets/people/keys/brown \
* -H'Content-Type:application/json' \
* -d'{"update":{"name":"Dan"}}'

---

# Search

^In my opinion, the best new feature in Riak 2.0. In fact, this feature is so amazing, we could spin it off into a stand alone project, and get $100M in funding just like ElasticSearch—not that I’m bitter. 

---

# Why?

* Improve data retrieval in Riak
* Easy to store data, not easy to query it
* MapReduce is resource intensive
* Solr
* Has excellent analyzer/language support
* ranking, faceting, highlighting, geo, etc
* Built on Lucene
* Basho isn’t a search company

^Basho Search v1 failed (we aren’t a search company) Why not just use ElasticSearch? Great question: AAE! Search keeps your data and your index in sync.   Insert objects like Riak, query like Solr. 

---

# search = on

^Just like strong consistency, using Search is just turning it on in every node. 

---

# Creating an Index

* curl -XPUT http://localhost:10018/search/index/people -H 'application/json' -d '{"schema":"_yz_default"}'
* curl http://localhost:10018/search/index/people

---

# Associating an Index

* riak-admin bucket-type create people \
* '{"props":{"search_index":"people"}}'
* riak-admin bucket-type activate people

^The index does not have to be the same as the bucket type, but I find it’s easy to keep track of the index name this way. 

---

# Inserting a Value

* curl -XPUT http://localhost:10018/types/people/buckets/attendees/keys/nsm \ -H'application/json' \ -d'{"name_s":"Eric Redmond",     "location_p":[53.3478,-6.2597]}'

^curl -XPUT http://localhost:10018/types/default/buckets/attendees/keys/nsm -H'application/json' -d'{"name_s":"Eric Redmond", "location_p":[53.3478,-6.2597]}' 

---

# Querying a Value

* curl -XPUT "http://localhost:8098/solr/people/select?wt=json&q=*:*" 

---

# Security

---

# Security On/Off

* $ riak-admin security
* $ riak-admin security status
* $ riak-admin security enable
* $ riak-admin security disable

^Enabling security will change the way your client libraries and your applications interact with Riak. Once security is enabled, all client connections must be encrypted and all permissions will be denied by default. Set up your users, groups and sources first with security disabled to not impact the service. 

---

# Terminology

* Authentication is the process of identifying a user.
* Authorization is verifying whether a user has access to perform the requested operation.
* Groups can have permissions assigned to them, but cannot be authenticated.
* Users can be authenticated and authorized; permissions (authorization) may be granted directly or via group membership.
* Sources are used to define authentication mechanisms. A user cannot be authenticated to Riak until a source is defined.

^If you notice, I spell “authorization” with a “Z”, and I call zed “Z”, get used to it. 

---

# Managing Users

* $ riak-admin security print-users
* $ riak-admin security add-user riakuser
* $ riak-admin security alter-user riakuser password=letitcrash
* $ riak-admin security alter-user riakuser location=dublin

^You can’t alter the username, but all other fields can be changed as well as metadata being assigned to users. 

---

# Managing Groups

* $ riak-admin security print-groups
* $ riak-admin security add-group admin
* $ riak-admin security alter-user riakuser groups=admin

---

# Managing Permissions

* $ riak-admin security grant <permissions> on any to all|{<user>|<group>[,...]}
* $ riak-admin security grant <permissions> on <bucket-type> to all|{<user>|<group>[,...]}
* $ riak-admin security grant <permissions> on <bucket-type> <bucket> to all|{<user>|<group>[,…]}
* $ riak-admin security revoke <permissions> on any from all|{<user>|<group>[,...]}
* $ riak-admin security revoke <permissions> on <bucket-type> from all|{<user>|<group>[,...]}
* $ riak-admin security revoke <permissions> on <bucket-type> <bucket> from all|{<user>|<group>[,...]}

^As you can see, there’s a lot of options for security, I recommend checking them out in the basho docs. You can grant and revoke at the “any”, bucket-type and bucket level. You can grant and revoke at the “all”, group and user level. 

---

# Managing Permissions

* $ riak-admin security grant riak_kv.get on any to admin
* $ riak-admin security grant search.query on index to admin
* $ riak-admin security grant search.query on schema to admin

---

# Supported Sources

* Trust
* Password
* Certificate
* PAM

^There’s more to security, and I’m going to leave that as an exercise to investigate in your own time. For now, it’s good to know that these are the sources supported by Riak security. Specify trusted CIDRs from which all clients will be authenticated by default. Riak and clients have same Root CA. 

---

# 15 min Break

---

# RTFM
(docs.basho.com)

^Visit docs.basho.com I know it might be strange to spend class time looking through online documentation, but Riak is a bit different. Namely, our docs are amazing, and nearly all questions you may have are in there somewhere.  

---

# Riak as Document Datastore

^Who’s heard of Mongo or Couch? 

---

# Riak as Ruby

* http://bit.ly/1polBLl
* Create index, bucket type, associate to bucket
* Connect ruby to cluster
* Insert values
* Search

---

# Questions and
(potential) Answers

---
