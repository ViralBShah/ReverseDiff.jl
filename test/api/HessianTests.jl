module HessianTests

using DiffBase, ForwardDiff, ReverseDiff, Base.Test

include(joinpath(dirname(@__FILE__), "../utils.jl"))

println("testing hessian/hessian!...")
tic()

############################################################################################

function test_unary_hessian(f, x)
    test = DiffBase.HessianResult(x)
    ForwardDiff.hessian!(test, f, x, ForwardDiff.HessianConfig{1}(test, x))

    # without HessianConfig

    @test_approx_eq_eps ReverseDiff.hessian(f, x) DiffBase.hessian(test) EPS

    out = similar(DiffBase.hessian(test))
    ReverseDiff.hessian!(out, f, x)
    @test_approx_eq_eps out DiffBase.hessian(test) EPS

    result = DiffBase.HessianResult(x)
    ReverseDiff.hessian!(result, f, x)
    @test_approx_eq_eps DiffBase.value(result) DiffBase.value(test) EPS
    @test_approx_eq_eps DiffBase.gradient(result) DiffBase.gradient(test) EPS
    @test_approx_eq_eps DiffBase.hessian(result) DiffBase.hessian(test) EPS

    # with HessianConfig

    cfg = ReverseDiff.HessianConfig(x)

    @test_approx_eq_eps ReverseDiff.hessian(f, x, cfg) DiffBase.hessian(test) EPS

    out = similar(DiffBase.hessian(test))
    ReverseDiff.hessian!(out, f, x, cfg)
    @test_approx_eq_eps out DiffBase.hessian(test) EPS

    result = DiffBase.HessianResult(x)
    cfg = ReverseDiff.HessianConfig(result, x)
    ReverseDiff.hessian!(result, f, x, cfg)
    @test_approx_eq_eps DiffBase.value(result) DiffBase.value(test) EPS
    @test_approx_eq_eps DiffBase.gradient(result) DiffBase.gradient(test) EPS
    @test_approx_eq_eps DiffBase.hessian(result) DiffBase.hessian(test) EPS

    # with HessianRecord

    r = ReverseDiff.HessianRecord(f, rand(size(x)))

    @test_approx_eq_eps ReverseDiff.hessian!(r, x) DiffBase.hessian(test) EPS

    out = similar(DiffBase.hessian(test))
    ReverseDiff.hessian!(out, r, x)
    @test_approx_eq_eps out DiffBase.hessian(test) EPS

    result = DiffBase.HessianResult(x)
    ReverseDiff.hessian!(result, r, x)
    @test_approx_eq_eps DiffBase.value(result) DiffBase.value(test) EPS
    @test_approx_eq_eps DiffBase.gradient(result) DiffBase.gradient(test) EPS
    @test_approx_eq_eps DiffBase.hessian(result) DiffBase.hessian(test) EPS
end

for f in DiffBase.MATRIX_TO_NUMBER_FUNCS
    testprintln("MATRIX_TO_NUMBER_FUNCS", f)
    test_unary_hessian(f, rand(5, 5))
end

for f in DiffBase.VECTOR_TO_NUMBER_FUNCS
    testprintln("VECTOR_TO_NUMBER_FUNCS", f)
    test_unary_hessian(f, rand(5))
end

############################################################################################

println("done (took $(toq()) seconds)")

end # module
