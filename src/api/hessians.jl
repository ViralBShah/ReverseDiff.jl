##################################################
# Hessian of `f(::AbstractArray)::AbstractArray` #
##################################################

# hessian #
#---------#

function hessian(f, input::AbstractArray, cfg::HessianConfig = HessianConfig(input))
    ∇f = x -> gradient(f, x, cfg.gradient_config)
    return jacobian(∇f, input, cfg.jacobian_config)
end

# hessian! #
#----------#

function hessian!(result, f, input::AbstractArray, cfg::HessianConfig = HessianConfig(input))
    ∇f = x -> gradient(f, x, cfg.gradient_config)
    jacobian!(result, ∇f, input, cfg.jacobian_config)
    return result
end

function hessian!(result::DiffResult, f, input::AbstractArray,
                  cfg::HessianConfig = HessianConfig(result, input))
    ∇f! = (y, x) -> begin
        gradient_result = DiffResult(zero(eltype(y)), y)
        gradient!(gradient_result, f, x, cfg.gradient_config)
        DiffBase.value!(result, value(DiffBase.value(gradient_result)))
        return y
    end
    jacobian!(DiffBase.hessian(result), ∇f!,
              DiffBase.gradient(result), input,
              cfg.jacobian_config)
    return result
end

############################
# Executing HessianRecords #
############################

function hessian!(rec::HessianRecord, input::AbstractArray)
    result = construct_result(rec.output, rec.input)
    hessian!(result, rec, input)
    return result
end

function hessian!(result::AbstractArray, rec::HessianRecord, input::AbstractArray)
    jrec = _JacobianRecord(rec.func, rec.input, rec.output, rec.tape)
    jacobian!(result, jrec, input)
    return result
end

function hessian!(result::DiffResult, rec::HessianRecord, input::AbstractArray)
    jrec = _JacobianRecord(rec.func, rec.input, rec.output, rec.tape)
    jacobian!(DiffResult(DiffBase.gradient(result), DiffBase.hessian(result)), jrec, input)
    DiffBase.value!(result, rec.func(input))
    return result
end

######################
# Hessian API Errors #
######################

const HESS_MULTI_ARG_ERR_MSG = "Taking the Hessian of a function with multiple arguments is not yet supported"

hessian(f, xs::Tuple, ::HessianConfig) = error(HESS_MULTI_ARG_ERR_MSG)
hessian(f, xs::Tuple) = error(HESS_MULTI_ARG_ERR_MSG)
hessian!(outs::Tuple, f, xs::Tuple, ::HessianConfig) = error(HESS_MULTI_ARG_ERR_MSG)
hessian!(outs::Tuple, f, xs::Tuple) = error(HESS_MULTI_ARG_ERR_MSG)
