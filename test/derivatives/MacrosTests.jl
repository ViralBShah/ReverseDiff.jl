module MacrosTests

using ReverseDiffPrototype, Base.Test
using ForwardDiff: Dual, partials

include("../utils.jl")

println("testing macros (@forward, @skip, etc.)...")
tic()

############################################################################################

tp = Tape()
x, a, b = rand(3)

############
# @forward #
############

f0(x) = 1. / (1. + exp(-x))
f0(a, b) = sqrt(a^2 + b^2)

RDP.@forward f1{T<:Real}(x::T) = 1. / (1. + exp(-x))
RDP.@forward f1{A,B<:Real}(a::A, b::B) = sqrt(a^2 + b^2)

RDP.@forward f2(x) = 1. / (1. + exp(-x))
RDP.@forward f2(a, b) = sqrt(a^2 + b^2)

RDP.@forward function f3{T<:Real}(x::T)
    return 1. / (1. + exp(-x))
end

RDP.@forward function f3{A,B<:Real}(a::A, b::B)
    return sqrt(a^2 + b^2)
end

RDP.@forward function f4(x)
    return 1. / (1. + exp(-x))
end

RDP.@forward function f4(a, b)
    return sqrt(a^2 + b^2)
end

function test_forward(f, x, tp)
    xt = track(x, tp)

    y = f(x)
    @test isempty(tp)

    yt = f(xt)
    @test yt == y
    dual = f(Dual(x, one(x)))
    @test length(tp) == 1
    node = first(tp)
    @test node.func === nothing
    @test node.inputs === xt
    @test node.outputs === yt
    @test node.cache === partials(dual)
    empty!(tp)
end

function test_forward(f, a, b, tp)
    at, bt = track(a, tp), track(b, tp)

    c = f(a, b)
    @test isempty(tp)

    tc = f(at, b)
    @test tc == c
    dual = f(Dual(a, one(a)), b)
    @test length(tp) == 1
    node = first(tp)
    @test node.func === nothing
    @test node.inputs === at
    @test node.outputs === tc
    @test node.cache === partials(dual)
    empty!(tp)

    tc = f(a, bt)
    @test tc == c
    dual = f(a, Dual(b, one(b)))
    @test length(tp) == 1
    node = first(tp)
    @test node.func === nothing
    @test node.inputs === bt
    @test node.outputs === tc
    @test node.cache === partials(dual)
    empty!(tp)

    tc = f(at, bt)
    @test tc == c
    dual = f(Dual(a, one(a), zero(a)), Dual(b, zero(b), one(b)))
    @test length(tp) == 1
    node = first(tp)
    @test node.func === nothing
    @test node.inputs === (at, bt)
    @test node.outputs === tc
    @test node.cache === partials(dual)
    empty!(tp)
end

for f in (RDP.@forward(f0), f1, f2, f3, f4)
    testprintln("@forward named functions", f)
    test_forward(f, x, tp)
    test_forward(f, a, b, tp)
end

RDP.@forward f5 = (x) -> 1. / (1. + exp(-x))
testprintln("@forward anonymous functions", f5)
test_forward(f5, x, tp)

RDP.@forward f6 = (a, b) -> sqrt(a^2 + b^2)
testprintln("@forward anonymous functions", f6)
test_forward(f6, a, b, tp)

#########
# @skip #
#########

g0 = f0

RDP.@skip g1{T<:Real}(x::T) = 1. / (1. + exp(-x))
RDP.@skip g1{A,B<:Real}(a::A, b::B) = sqrt(a^2 + b^2)

RDP.@skip g2(x) = 1. / (1. + exp(-x))
RDP.@skip g2(a, b) = sqrt(a^2 + b^2)

RDP.@skip function g3{T<:Real}(x::T)
    return 1. / (1. + exp(-x))
end

RDP.@skip function g3{A,B<:Real}(a::A, b::B)
    return sqrt(a^2 + b^2)
end

RDP.@skip function g4(x)
    return 1. / (1. + exp(-x))
end

RDP.@skip function g4(a, b)
    return sqrt(a^2 + b^2)
end

function test_skip(g, x, tp)
    xt = track(x, tp)

    y = g(x)
    @test isempty(tp)

    yt = g(xt)
    @test yt === y
    @test isempty(tp)
end

function test_skip(g, a, b, tp)
    at, bt = track(a, tp), track(b, tp)

    c = g(a, b)
    @test isempty(tp)

    tc = g(at, b)
    @test tc === c
    @test isempty(tp)

    tc = g(a, bt)
    @test tc === c
    @test isempty(tp)

    tc = g(at, bt)
    @test tc === c
    @test isempty(tp)
end

for g in (RDP.@skip(g0), g1, g2, g3, g4)
    testprintln("@skip named functions", g)
    test_skip(g, x, tp)
    test_skip(g, a, b, tp)
end

RDP.@skip g5 = (x) -> 1. / (1. + exp(-x))
testprintln("@skip anonymous functions", g5)
test_skip(g5, x, tp)

RDP.@skip g6 = (a, b) -> sqrt(a^2 + b^2)
testprintln("@skip anonymous functions", g6)
test_skip(g6, a, b, tp)

############################################################################################

println("done (took $(toq()) seconds)")

end # module