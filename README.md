# VectorBackedLists

Double linked lists using Vectors as memory pool.

## Example

```julia
using VectorBackedLists

d = [1,2,3,4]
dl = list(d)

s = start(dl)
_, t = next(dl, s) # t points at 2
_, n = next(dl, t) # n points at 3
_, q = next(dl, n) # q points at 4

move_before!(dl, n, t)
@assert collect(dl) == [1,3,2,4]

insert_after!(dl, q, 4)
@assert collect(dl) == [1,3,2,4,4]

insert_after!(dl, t, 100)
@assert collect(dl) == [1,3,2,100,4,4]

for v in dl
    println(v)
end
```