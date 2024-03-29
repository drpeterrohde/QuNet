using QuNet
using Statistics

grid_size = 100
num_pairs = 50
num_trials = 100
max_paths = 4

failure_counts = []
for i in 1:num_trials
    println("num_trial $i")
    edge_costs = Dict("loss"=>0.05, "Z"=>0.05)
    net = GridNetwork(grid_size, grid_size, edge_costs=edge_costs)
    user_pairs = QuNet.make_user_pairs(net, 50)
    pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(net, QuNet.purify, user_pairs, 4)
    push!(failure_counts, pathuse_count[1])
end
println(mean(failure_counts./num_pairs))
println(failure_counts)


# # Set up a Python backend before importing PyPlot
# using PyCall
# # Specify user GUI from options (:tk, :gtk3, :gtk, :qt5, :qt4, :qt, or :wx)
# # pygui(:qt)
# using PyPlot
#
# # # Test PyPlot
# # # use x = linspace(0,2*pi,1000) in Julia 0.6
# # x = range(0; stop=2*pi, length=1000); y = sin.(3 * x + 4 * cos.(2 * x));
# # plot(x, y, color="red", linewidth=2.0, linestyle="--")
# # title("A sinusoidally modulated sinusoid")
# # # Display figure with Julia backend
# # display(gcf())
# # # Save as a Pdf
# # savefig("sinusoid_test.pdf")
# # #show()
#
# # Try heatmap
# # Install numpy
# using PyCall
# np = pyimport("numpy")
# kde = pyimport("scipy.stats.kde")
# data = np.random.multivariate_normal([0, 0], [[1, 0.5], [0.5, 3]], 200)
# Tdata = transpose(data)
# x = Tdata[1, :]
# y = Tdata[2, :]
#
# # # Evaluate a gaussian kde on a regular grid of nbins x nbins over data extents
# # k = kde.gaussian_kde(Tdata)
# # xi, yi = np.mgrid[minimum(x):maximum(x):nbins*1j, minimum(y):maximum(y):nbins*1j]
# # zi = k(np.vstack([xi.flatten(), yi.flatten()]))
#
# fig, axs = plt.subplots(ncols=2, nrows=1, figsize=(21, 5))
# # Everything starts with a Scatterplot
# axs[0].set_title('Scatterplot')
# axs[0].plot(x, y, 'ko')
#
# # # plot a density
# # axes[1].set_title('Calculate Gaussian KDE')
# # axes[1].pcolormesh(xi, yi, zi.reshape(xi.shape), shading='auto', cmap=plt.cm.BuGn_r)
# #
# display(gcf())
