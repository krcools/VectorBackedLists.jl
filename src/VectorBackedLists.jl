module VectorBackedLists

export list, insert_after!, move_before!, prev, sublist, advance

export start, next, done

struct Node{I}
    value::I    # index into list data
    next::I     # index into nodes of the next node
    prev::I     # index into nodes of the previous node
end

struct VectorBackedList{T,S<:AbstractVector{T},I}
    data::S
    nodes::Vector{Node{I}}
    head::I
    tail::I
end

Base.eltype(::VectorBackedList{T}) where {T} = T
start(list::VectorBackedList) = list.nodes[list.head].next
next(list::VectorBackedList, state) = (list.data[list.nodes[state].value], list.nodes[state].next)
done(list::VectorBackedList, state) = state == list.tail
function Base.iterate(list::VectorBackedList, state=start(list))
    done(list, state) && return nothing
    return next(list, state)
end

"""
    advance(iterable, state) -> next_state

Advances the iteration state without producing the associated value. It holds that

    next(iterable, state)[2] == advance(iterable, state)
"""
advance(list::VectorBackedList, state) = list.nodes[state].next

"""
done(iterable) -> state

Produces an iterator state for which `done(iterable,state) == true`. Cf. to the
c++ end() api.
"""
done(list::VectorBackedList) = list.tail
Base.setindex!(list::VectorBackedList{T,S,I}, v::T, state::I) where {T,S,I} = (list.data[list.nodes[state].value] = v)
Base.getindex(list::VectorBackedList{T,S,I}, state::I) where {T,S,I} = list.data[list.nodes[state].value]

Base.IteratorSize(list::VectorBackedList) = Base.SizeUnknown()
# Base.length(sl::VectorBackedList) = (n = 0; for x in sl; n += 1; end; n)

function sublist(ls::VectorBackedList{T,S,I}, b, e) where {T,S,I}
    VectorBackedList{T,S,I}(
        ls.data,
        ls.nodes,
        ls.nodes[b].prev,
        e
    )
end

"""
    prev(list, state) -> item, prevstate

Returns the current item from `list` and sets the state to point to the previous
entry. It hold that

```
_, p = prev(list, s)
_, n = next(list, p)
n == s
```
"""
prev(list, state) = (list.data[list.nodes[state].value], list.nodes[state].prev)

"""
    list(data, [index_type=eltype(eachindex(data))])

Create a list from an indexable container. The list provided a view on the container,
so any mutations realised through calling the list API will be reflected in the
state of the underlying container.

If memory consumption is a priority, the iterator type can be forced to a smaller
sized integer. Be careful: it is possible that the data passed is longer than the
largest value representable for the iterator type. In this case, the list implementation
fails quietly and its behaviour will be undefined.
"""
function list(data, index_type=eltype(eachindex(data)))

    T = eltype(data)
    S = typeof(data)
    I = index_type
    n = length(data)

    nodes = Vector{Node{I}}(undef, n+2)
    nodes[1] = Node{I}(0,2,0)
    for i in 2:n+1; nodes[i] = Node{I}(i-1, i+1, i-1); end
    nodes[end] = Node{I}(0,0,n+1)
    VectorBackedList{T, S, I}(data, nodes, 1, n+2)
end

"""
    move_before(list, item, dest)

Move the node pointed to by iterator `item` in fron of iterator `dest`.
"""
function move_before!(list, I, T)

    @assert I != T
    nodes = list.nodes

    # step 1: remove n
    _, P = prev(list,I);
    _, N = next(list,I);
    p = nodes[P]
    n = nodes[N]
    # @assert P == p.idx
    # @assert N == n.idx

    #nodes[P] = Node(p.value, n.idx, p.prev, p.idx)
    nodes[P] = Node(p.value, N, p.prev)
    # nodes[N] = Node(n.value, n.next, p.idx, n.idx)
    nodes[N] = Node(n.value, n.next, P)

    # step 2: reintroduce n
    _, Q = prev(list, T)
    i = nodes[I]
    t = nodes[T]
    q = nodes[Q]
    # @assert Q == q.idx
    # @assert T == t.idx
    # @assert I == i.idx

    nodes[Q] = Node(q.value, I, q.prev)
    nodes[T] = Node(t.value, t.next, I)
    nodes[I] = Node(i.value, T, Q)
    nothing
end

"""
    insert_after!(list, dest, value)

Insert `value` in `list` after the value pointed to by iterator `dest`.
"""
function insert_after!(list::VectorBackedList, T, v)

    data = list.data
    nodes = list.nodes

    push!(data, v)

    _, N = next(list, T)
    t = nodes[T]
    n = nodes[N]

    I = length(nodes)+1
    push!(nodes, Node(length(data), N, T))

    nodes[T] = Node(t.value, I, t.prev)
    nodes[N] = Node(n.value, n.next, I)
    nothing
end


function insert_before!(list::VectorBackedList, T, v)

    data = list.data
    nodes = list.nodes

    push!(data, v)

    P = list.nodes[T].prev
    t = nodes[T]
    p = nodes[P]

    I = length(nodes)+1
    push!(nodes, Node(length(data), T, P))

    nodes[T] = Node(t.value, t.next, I)
    nodes[P] = Node(p.value, I, p.prev)
    nothing
end


Base.push!(list::VectorBackedList, v) = insert_before!(list, done(list), v)


end # module
