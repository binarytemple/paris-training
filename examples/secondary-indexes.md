footer: © Basho Technologies, 2014
slidenumbers: true

# Riak Secondary Indexing


![inline 90%](basho-horiz.png)

# 2014 - Bryan Hunt Basho CSE

---

# How do I use secondary indexes?

^ Secondary Indexes allow you to tag a Riak object with some index metadata, and later retrieve the object by querying the index, rather than the object's primary key.

---

### Some examples

---

### Storing

^ For example, let's say you want to store a user object, accessible by username, twitter handle, or email address. You might pick the username as the primary key, while indexing the twitter handle and email address. Below is a curl command to accomplish this through the HTTP interface of a local Riak node:

```
    curl -X POST \
    -H 'x-riak-index-twitter_bin: rustyio' \
    -H 'x-riak-index-email_bin: rusty@basho.com' \
    -d '...user data...' \
    http://localhost:8098/buckets/users/keys/rustyk
```

---

### Querying 

^ Previously, there was no simple way to access an object by anything other than the primary key, the username. The developer would be forced to "roll their own indexes." With Secondary Indexes enabled, however, you can easily retrieve the data by querying the user's twitter handle:

---

### Querying example 1

Query the twitter handle...

```
curl localhost:8098/buckets/users/index/twitter_bin/rustyio

# Response...
{"keys":["rustyk"]}

```
---

### Querying example 2

Or the user's email address:

```
# Query the email address...
curl localhost:8098/buckets/users/index/email_bin/rusty@basho.com

# Response...
{"keys":["rustyk"]}
```
---

### Rewriting indexes

^ You can change an object's indexes by simply writing the object again with the updated index information. For example, to add an index on Github handle:


--- 

### Rewriting indexes example
```
    curl -X POST \
    -H 'x-riak-index-twitter_bin: rustyio' \
    -H 'x-riak-index-email_bin: rusty@basho.com' \
    -H 'x-riak-index-github_bin: rustyio' \
    -d '...user data...' \
    http://localhost:8098/buckets/users/keys/rustyk
```

^ That's all there is to it, but that's enough to represent a variety of different relationships within Riak.

Above is an example of assigning an alternate key to an object. But
imagine that instead of a `twitter_bin` field, our object had an
`employer_bin` field that matched the primary key for an object in our
`employers` bucket. We can now look up users by their employer.

Or imagine a `role_bin` field that matched the primary key for an
object in our `security_roles` bucket. This allows us to look up all
users that are assigned to a specific security role in the system.

---

## Design Decisions

Secondary Indexes maintains Riak's distributed, scalable, and failure
tolerant nature by avoiding the need for a pre-defined schema, which
would be shared state. Indexes are declared on a per-object basis, and
the index type (binary or integer) is determined by the field's
suffix.

Indexing is real-time and atomic; the results show up in queries
immediately after the write operation completes, and all indexing
occurs on the [partition](http://wiki.basho.com/Riak-Glossary.html#Partition) where
the object lives, so the object and its indexes stay in sync. Indexes
can be stored and queried via the HTTP interface or the Protocol
Buffers interface. Additionally, index results can feed directly into
a Map/Reduce operation. And our Enterprise customers will be happy to
know that Secondary Indexing plays well with multi data center
replication.

---

Indexes are declared as metadata, rather than an object's value, in
order to preserve Riak's view that the value of your object is as an
opaque document. An object can have an unlimited number of index
fields of any size (dependent upon system resources, of course.) We
have stress tested with 1,000 index fields, though we expect most
applications won't need nearly that many. Indexes do contribute to the
base size of the object, and they also take up their own disk space,
but the overhead for each additional index entry is minimal: the
[vector clock](http://wiki.basho.com/Riak-Glossary.html#Vector-Clock)
information (and other metadata) is stored in the object, not in the
index entry. Additionally, the LevelDB backend (and, likely, most
index-capable backends) support prefix-compression, further shrinking
index size.

---

This initial release does have some important limitations. Only single
index queries are supported, and only for exact matches or range
queries. The result order is undefined, and pagination is not
supported. While this offers less in the way of ad-hoc querying than
other datastores, it is a solid 80% solution that allows us to focus
future energy where users and customers need it most. (Trust me, we
have many plans and prototypes of potential features. Building
something is easy, building the **right** thing is harder.)

---

## Behind The Scenes

What is happening behind the scenes? A lot, actually.

At *write time*, the system pulls the index fields from the incoming
object, parses and validates the fields, updates the object with the
newly parsed fields, and then continues with the write operation. The
replicas of the object are sent to
[virtual nodes](http://wiki.basho.com/Riak-Glossary.html#Vnode) where
the object and its indexes are persisted to disk.

At *query time*, the system first calculates what we call a "covering"
set of partitions. The system looks at how many replicas of our data
are stored and determines the minimum number of partitions that it
must examine to retrieve a full set of results, accounting for any
offline nodes. By default, Riak is configured to store 3 replicas of
all objects, so the system can generate a full result set if it reads
from one-third of the system's partitions, as long as it chooses the
right set of partitions. The query is then broadcast to the selected
partitions, which read the index data, generate a list of keys, and
send them back to the coordinating node.

Storing index data is very different from storing key/value data: in
general, any database that stores indexes on a disk would *prefer* to
be able to store the index in a contiguous block and in the desired
order--basically getting as near to the final result set as
possible. This minimizes disk movement and other work during a query,
and provides faster read operations. The challenge is that index
values rarely enter the system in the right order, so the database
must do some shuffling at write time. Most databases delay this
shuffling, they write to disk in a slightly sub-optimal format, then
go back and "fix things up" at a later point in time.

None of Riak's existing key/value-oriented backends were a good fit
for index data; they all focused on fast key/value access. During the
development of Secondary Indexes we explored other
options. Coincidentally, the Basho team had already begun work to
adapt LevelDB--a low-level storage library from Google--as a storage
engine for Riak KV. LevelDB stores data in a defined order, exactly
what Secondary Indexes needed, and it is actually versatile enough to
manage both the index data AND the object's value. Plus, it is very
RAM friendly. You can learn more about LevelDB from
[this page](http://code.google.com/p/leveldb/) on Google Code.


---

[[Secondary Indexes|Using Secondary Indexes]] allows an application to tag a Riak object with one or more field/value pairs. The object is indexed under these field/value pairs, and the application can later query the index to retrieve a list of matching keys.

## Requesting

---

### Exact Match

```bash
GET /buckets/mybucket/index/myindex_bin/value
```

---

### Range Query

```
GET /buckets/mybucket/index/myindex_bin/start/end
```

{{#1.4.0+}}

---

#### Range query with terms
To see the index values matched by the range, use `return_terms=true`.

```
GET /buckets/mybucket/index/myindex_bin/start/end?return_terms=true
```

---

### Pagination
Add the parameter `max_results` for pagination. This will limit the results and provide for the next request a `continuation` value.

```
GET /buckets/mybucket/index/myindex_bin/start/end?return_terms=true&max_results=500
GET /buckets/mybucket/index/myindex_bin/start/end?return_terms=true&max_results=500&continuation=g2gCbQAAAAdyaXBqYWtlbQAAABIzNDkyMjA2ODcwNTcxMjk0NzM=
```

---

### Streaming
```
GET /buckets/mybucket/index/myindex_bin/start/end?stream=true
```

---

## Response

Normal status codes:

+ `200 OK`

Typical error codes:

+ `400 Bad Request` - if the index name or index value is invalid.
+ `500 Internal Server Error` - if there was an error in processing a map or reduce function, or if indexing is not supported by the system.
+ `503 Service Unavailable` - if the job timed out before it could complete

---


## Example

```
$ curl -v http://localhost:8098/buckets/mybucket/index/field1_bin/val1
* About to connect() to localhost port 8098 (#0)
*   Trying 127.0.0.1... connected
* Connected to localhost (127.0.0.1) port 8098 (#0)
> GET /buckets/mybucket/index/field1_bin/val1 HTTP/1.1
> User-Agent: curl/7.19.7 (universal-apple-darwin10.0) libcurl/7.19.7 OpenSSL/0.9.8r zlib/1.2.3
> Host: localhost:8098
> Accept: */*
>
< HTTP/1.1 200 OK
< Vary: Accept-Encoding
< Server: MochiWeb/1.1 WebMachine/1.9.0 (participate in the frantic)
< Date: Fri, 30 Sep 2011 15:24:35 GMT
< Content-Type: application/json
< Content-Length: 19
<
* Connection #0 to host localhost left intact
* Closing connection #0
{"keys":["mykey1"]}%
```
---
