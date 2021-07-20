include("../methods.jl")
include("../include/exact_conductance_jump.jl")
include("../include/Optimal_LambdaCC.jl")
## Get graph
G = _read_final("fauci-email-tofrom-cc-5.json") |>
        G -> (G..., A = spones!(G.A - Diagonal(G.A))) |> # remove weights and diagonals
        G -> (G..., xy = readdlm("fauci-email-tofrom-cc-5-modularity.xy"))
## Use Exact modularity and group-based layout to make the vis easier...
drawgraph(G, size=(350,350))
## Exact conductance
cond_S, cond = exact_conductance(G.A)
## This really does take a while...
Clus, Lams, ncut_S = exact_normalized_cut(G.A)
## compute additional set statistics.
more_set_stats(A::SparseMatrixCSC, S) = begin
""" Augument set_stats with ncut, sparsity, expansion scores. """
        volA=sum(A)
        nS = eltype(S) == Int ? length(S) : sum(S)
        nA = size(A,1)
        set_stats(A,S,volA) |>
                v->(cond=v[4], ncut=v[1]/(sum(G.A)-v[2])+v[1]/(v[2]),
                    cut=v[1], vol=v[2], size=nS, volC = volA-v[2], edges=v[3],
                    sparsity=v[1]/nS + v[1]/(nA-nS),
                    expansion=v[1]/min(nS, nA-nS))
end

cond_S_vals = more_set_stats(G.A, cond_S)
ncut_S_vals = more_set_stats(G.A, ncut_S)
drawgraph(G, pointcolor=:none, label="", size=(350,350))
drawset!(G, S, label="Min Conductance", marker=:star,
  markersize=4, color=3, markerstrokecolor=3)
drawset!(G, ncut_S, label="Normalized Cut", marker=:square,
  markersize=2.5, color=2, markerstrokecolor=2)
showlabel!(G, "conrad", 7, :left, rotation=15)
showlabel!(G, "colucci", 7, :left, rotation=15)
showlabel!(G, "collins", 7, :left, rotation=15)
plot!(legend=:bottomleft, legendfontsize=9)
##
savefig("figures/cond-vs-ncut.pdf")
##
stcut_S = stcut(G, "collins", "conrad")
drawgraph(G, pointcolor=:none, label="", size=(350,350))
drawset!(G, stcut_S, label="Min Conductance", marker=:star,
  markersize=4, color=3, markerstrokecolor=3)
showlabel!(G, "conrad", 7, :left, rotation=15)
showlabel!(G, "collins", 7, :left, rotation=15)
plot!(legend=:bottomleft, legendfontsize=9)
##
savefig("figures/cond-vs-ncut-stcut.pdf")
##
stcut_S_vals = more_set_stats(G.A, stcut_S)
## get Fiedler set
spec_S_data = spectral_cut(G.A)
spec_S = spec_S_data.set
spec_S_vals = more_set_stats(G.A, spec_S)
## get the spectral ncut set just to check
sweepcut_ncuts = spec_S_data.sweepcut_profile.cut./spec_S_data.sweepcut_profile.volume + spec_S_data.sweepcut_profile.cut./(spec_S_data.sweepcut_profile.total_volume .- spec_S_data.sweepcut_profile.volume)
argmin(sweepcut_ncuts)
spec_S_ncut = spec_S_data.sweepcut_profile.p[argmin(sweepcut_ncuts):end]
##

##
drawgraph(G, pointcolor=:none, label="", size=(350,350))
drawset!(G, spec_S, label="Spectral Clustering", marker=:star,
  markersize=4, color=3, markerstrokecolor=3)
showlabel!(G, "conrad", 7, :left, rotation=15)
showlabel!(G, "collins", 7, :left, rotation=15)
plot!(legend=:bottomleft, legendfontsize=9)
##
savefig("figures/cond-vs-ncut-spectral.pdf")
##
drawgraph(G, pointcolor=:none, label="", size=(350,350))
drawset!(G, spec_S_ncut, label="Spectral Clustering (ncut)", marker=:star,
  markersize=4, color=3, markerstrokecolor=3)
showlabel!(G, "conrad", 7, :left, rotation=15)
showlabel!(G, "collins", 7, :left, rotation=15)
plot!(legend=:bottomleft, legendfontsize=9)
##
savefig("figures/cond-vs-ncut-spectral-ncut.pdf")
## write out the table
function _write_set_info_latex(label, vals)
  # set & size & cut & vol & $\phi$ & ncut \\
  println("$(label) & $(vals.size) & $(Int.(vals.cut)) & $(Int.(vals.vol)) & $(round(vals.cond,digits=5)) & $(round(vals.ncut,digits=5)) \\\\")
end
##
_write_set_info_latex("conductance", cond_S_vals)
_write_set_info_latex("normalized cut", ncut_S_vals)
_write_set_info_latex("Conrad-Collins cut", stcut_S_vals)
_write_set_info_latex("spectral cut", spec_S_vals)
