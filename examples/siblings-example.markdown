# Curl siblings creation and listing example

---

All siblings for a particular bucket (Riak 2.0 default is `"allow_mult":true}` but worth illustrating.

```
curl -X PUT -H "Content-Type: application/json" -d '{"props":{"allow_mult":true}}' \
http://127.0.0.1:10018/types/default/buckets/sibling/props
```

---

Retrieve the bucket properties

```
curl http://127.0.0.1:10018/types/default/buckets/sibling/props | json_pp
```

---
Create multiple siblings for the given key

```
curl -d 'test1' -H "Content-Type:text/plain" http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
curl -d 'test2' -H "Content-Type:text/plain" http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
curl -d 'test3' -H "Content-Type:text/plain" http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
curl -d 'test4' -H "Content-Type:text/plain" http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
```
---
Try to fetch the value, we just receive etags, as siblings have been created

```
curl http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
```
---

We can view all the values, by setting the content-type that we will accept to 

```
curl -H "Accept:multipart/mixed" http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
```

---

A trick to retrieve each result individually, with it's associated "X-Riak-Vclock" which we can then supply in order to resolve the conflicting writes

```
curl -v http://127.0.0.1:10018/types/default/buckets/sibling/keys/1 |  awk '/Siblings/{next}{print $0}' | while read i; do curl -v "http://127.0.0.1:10018/types/default/buckets/sibling/keys/1?vtag=$i"; echo; done | less
```
---

Now we set a value for the object, specify a vector clock found in the multi-value returned by the previous example.

curl -d 'test4' -H "Content-Type:text/plain" \
-H"X-Riak-Vclock:<One of the Vclocks returned in the preceeding example>" \
http://127.0.0.1:10018/types/default/buckets/sibling/keys/1

---

Perform a GET, the siblings have been resolved, we just receive the value

curl http://127.0.0.1:10018/types/default/buckets/sibling/keys/1
>test4
