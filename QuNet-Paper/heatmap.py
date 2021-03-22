# Preceeding from heatmap.jl (start there if you haven't already)

# Libraries
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
# This could be used for smoothing the heatmap out
# from scipy.stats import kde

# Import data
df = pd.read_csv("~/.julia/dev/QuNet/data/heatmap.csv")

# Extract data into x, y
e = df["Efficiency"].tolist()
f = df["Fidelity"].tolist()

# Create a heatmap of end-user data
fig, axes = plt.subplots()
nbins = 40
axes.hist2d(e, f, range=((0,1), (0.5, 1)), bins=nbins, cmap=plt.cm.hot)
axes.set_xlabel("Efficiency")
axes.set_ylabel("Fidelity")

# Collect data for the QKD contour plots
delta = 0.01
x = np.arange(0.0, 1.0, delta)
y = np.arange(0.5, 1.0, delta )
E, F = np.meshgrid(x, y)

# End to end failure rate of a 100 x 100 grid lattice with 50 competing user pairs
P0 = 0.201

# Average rate of transmission per user pair
R = (1-P0) * E

# QKD contour
Z = R * (1 - (F * np.log(1 - F)/np.log(2) + (1 - F) * np.log(F)/np.log(2)))

# Overlay the contour for Z = 1, 2, 3, ...
# CS = axes.contour(E, F, Z, levels = [1, 2, 3, 4, 5])
# axes.clabel(CS, inline=1, fontsize=10, fmt="%1.1f")
# plt.show()
plt.savefig("singleheat.pdf")
