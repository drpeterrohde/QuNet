<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

# Contents

* Table of contents
{:toc}

# About

The paper _"QuNet: Cost vector analysis & multi-path entanglement routing in quantum networks"_ (Leone, Miller, Singh, Langford & Rohde, 2021) presents the theory, design and initial results for QuNet.

Developers:
+ Hudson Leone ([leoneht0@gmail.com](mailto:leoneht0@gmail.com))
+ Nathaniel Miller
+ Deepesh Singh
+ Nathan Langford
+ Peter Rohde ([dr.rohde@gmail.com](mailto:dr.rohde@gmail.com), [www.peterrohde.org](https://www.peterrohde.org))

# Goal

QuNet is a highly-scalable, multi-user quantum network simulator and benchmarking tool implemented in Julia. It relies on efficient algorithms for performing multi-user routing and congestion avoidance using quantum memories. QuNet focusses on the specific task of distributing entangled Bell pairs,
<p align="center">
$$ |\Psi^+\rangle = \frac{1}{\sqrt{2}}(|00\rangle + |11\rangle). $$
</p>
These can subsequently be employed in state teleportation protocols to transmit arbitrary quantum states, or be applied to quantum key distribution, distributed quantum computing, or other entanglement-based quantum protocols.

QuNet uses a _cost vector_ methodology. Rather than track quantum states themselves, we track their associated _costs_ as they traverse the network. Costs are arbitrary properties that accumulate additively as qubits traverse networks. We can express physical degradation such as loss, dephasing or depolarising processes in this form, and also non-physical costs such as monetary ones. Tracking the accumulation of costs acting on Bell pairs is equivalent to directly tracking the states themselves.

# Multi-path routing

Classical networks rely on path-finding algorithms (e.g shortest path a la Dijkstra) for optimal packet routing. Quantum networks can employ multi-path routing, whereby multiple independently routed Bell pairs are purified into one of higher fidelity.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101952-634a0d00-9f8b-11eb-986e-2bb964d8273b.jpeg" width="50%"></p>
<!--- ![1F8AF4E2-0408-45B0-98B9-9ABA8FD10FB1](https://user-images.githubusercontent.com/4382522/115101952-634a0d00-9f8b-11eb-986e-2bb964d8273b.jpeg) --->

# Entanglement swapping & purification

Primitive operations in quantum networks include entanglement swapping (for extending entanglement links), and entanglement purification (for boosting fidelity).

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101972-82489f00-9f8b-11eb-8e5d-62bb39d81e74.jpeg" width="30%" align="middle"></p>
<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101973-84126280-9f8b-11eb-95d1-c6e2d43ef390.jpeg" width="50%" align="middle"></p>

<!---
![8874AFC3-5CCE-4C02-B13C-99990B60679B](https://user-images.githubusercontent.com/4382522/115101972-82489f00-9f8b-11eb-8e5d-62bb39d81e74.jpeg)
![3022BE3F-72E4-45DD-A907-AC4046BCF8B2](https://user-images.githubusercontent.com/4382522/115101973-84126280-9f8b-11eb-95d1-c6e2d43ef390.jpeg)
--->

# Graph reduction

These primitives provide simple substitution rules for graph reduction.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101982-98565f80-9f8b-11eb-9a2f-a737a99c37ae.jpeg" width="50%" align="middle"></p>
<!--- ![B26B4EEC-96C4-4F6D-A762-A19D86C20823](https://user-images.githubusercontent.com/4382522/115101982-98565f80-9f8b-11eb-9a2f-a737a99c37ae.jpeg) --->

# Network abstraction

# Space-based networks

Here Alice & Bob have the option of communicating via:
+ A static ground-based fibre link.
+ A LEO satellite passing overhead through atmospheric free-space channels, which dynamically update.
+ Exploiting both and purifying them together (multi-path routing).

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101996-bae87880-9f8b-11eb-8f99-e06c1c65f8c1.jpeg" width="50%" align="middle"></p>
<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115101998-bcb23c00-9f8b-11eb-853c-487708e3cbac.jpeg" width="40%" align="middle"></p>

<!---
![04AABAD5-8CB2-4F67-BED7-0E28AE4CD71F](https://user-images.githubusercontent.com/4382522/115101996-bae87880-9f8b-11eb-8f99-e06c1c65f8c1.jpeg)
![6F973A32-33B6-4A3E-B92C-0D8CE9165B96](https://user-images.githubusercontent.com/4382522/115101998-bcb23c00-9f8b-11eb-853c-487708e3cbac.jpeg)
--->

# Code example

This is the QuNet code in Julia that creates that network. Julia modules can be called from Python or run in Jupyter notebooks too. You can learn more about the Julia language at [www.julialang.org](https://www.julialang.org).

<!--- ![F8B2F2BD-59E6-4FDE-8A14-183D136A5E0A](https://user-images.githubusercontent.com/4382522/115102036-ea978080-9f8b-11eb-872f-143fb3e438f3.jpeg) --->

```julia
using QuNet

Q = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
S = PlanSatNode("S")

B.location = Coords(500,0,0)
S.location = Coords(-2000,0,1000)
S.velocity = Velocity(1000,0)

AB = BasicChannel(A, B, exp_cost=true)
AS = AirChannel(A, S)
SB = AirChannel(S, B)

for i in [A, S, AB, AS, SB]
    add(Q, i)
end
```

# Temporal routing & quantum memories

We accommodate for quantum memories by treating them as temporal channels between the respective nodes of identical copies of the underlying graph, where each layer represents the network at a particular point in time.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102057-06028b80-9f8c-11eb-9f8b-76c8c58d38f5.jpeg" width="100%" align="middle"></p>
<!--- ![FE76132D-706C-488B-A6C8-B6B1536283BA](https://user-images.githubusercontent.com/4382522/115102057-06028b80-9f8c-11eb-9f8b-76c8c58d38f5.jpeg) --->

The incrementally weighted asynchronous nodes guide the routing algorithm to preference earlier times, thereby temporally compressing multi-user routing, and providing a temporal routing queue.

The compression ratio is the ratio between routing time with and without memories. Here we show the temporal compression ratio of our algorithm against increasing network congestion.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102085-2af6fe80-9f8c-11eb-9cc9-a3a51beaddf5.jpeg" width="50%" align="middle"></p>
<!--- ![205A8E5E-4ECA-4E30-83E7-48444F178BB0](https://user-images.githubusercontent.com/4382522/115102085-2af6fe80-9f8c-11eb-9cc9-a3a51beaddf5.jpeg) --->

Here’s a multi-user network with 3 users (colour coded) and multi-path routing (maximum 3 paths per user). The stacked layers represent time.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102120-5679e900-9f8c-11eb-9f3c-284a61354520.jpeg" width="50%" align="middle"></p>
<!--- ![BFFD97D5-66CD-4880-A2F0-A1CA11F710EA](https://user-images.githubusercontent.com/4382522/115102120-5679e900-9f8c-11eb-9f3c-284a61354520.jpeg) --->

# Efficient multi-path routing

Our greedy multi-path routing algorithm allows multi-user routing with congestion mitigation via quantum memories, with algorithmic efficiency 
$$ O(M^3V^2) $$, for _M_ user-pairs on a _V_-vertex graph, and is therefore highly scalable and efficient in both users and network size.

Here we consider a grid network with edge percolations, showing the likelihood of users utilising different path numbers as the network becomes increasingly disconnected.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102139-73aeb780-9f8c-11eb-80ef-f3a620479995.jpeg" width="50%" align="middle"></p>
<!--- ![D703EE9D-3CEB-44AC-9F38-AB00DED24637](https://user-images.githubusercontent.com/4382522/115102139-73aeb780-9f8c-11eb-80ef-f3a620479995.jpeg) --->

# Application to quantum key distribution

This heat map shows the fidelity/efficiency trade off for random user pairs on a square lattice network. The distinct heat curves correspond to different numbers of paths utilised. Superimposed contours show achievable per-user E91 QKD secret key rates for the network.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102157-87f2b480-9f8c-11eb-993b-977575973893.jpeg" width="50%" align="middle"></p>
<!--- ![A324DFFD-5CFD-4461-8334-E2DD087A2784](https://user-images.githubusercontent.com/4382522/115102157-87f2b480-9f8c-11eb-993b-977575973893.jpeg) --->

# Application to distributed quantum computing

Our next stage of research is applying QuNet to distributed quantum computing. Entanglement links can be used to fuse together geographically separated graph states, facilitating distributed quantum computation exponentially more powerful than the sum of the parts.

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/115102168-9f31a200-9f8c-11eb-8e4a-7942752468fe.jpeg" width="60%" align="middle"></p>
<!--- ![849B6215-EF77-4E3B-89DE-7E09E935B609](https://user-images.githubusercontent.com/4382522/115102168-9f31a200-9f8c-11eb-8e4a-7942752468fe.jpeg) --->

Consider a distributed computer with N nodes, each with n bits/qubits, and a scaling function that indicates classical-equivalent compute power (classically this is linear, for quantum computers super-linear). The computational gain achieved by unifying remote devices is,

<p align="center">
$$ \lambda = \frac{f_\mathrm{sc}(Nn)}{N\cdot f_\mathrm{sc}(n)}. $$
</p>
<!--- ![31684FB9-FAB0-4C00-A44C-3A4BB5CBB809](https://user-images.githubusercontent.com/4382522/115102197-ba9cad00-9f8c-11eb-97b6-2adc7d92769e.jpeg) --->

Through unification of remote computational assets:
+ Classical computers, $$ \lambda=1 $$. There is no computational enhancement.
+ Quantum computers $$ \lambda>1 $$, in the best case $$ \lambda=\mathrm{exp}(N) $$. We achieve exponential computational enhancement.

# The vision, the book

Our vision for the quantum internet is presented in the upcoming book [“The Quantum Internet”](https://cup.org/2Q7UpM4) published by Cambridge University Press.

# Acknowledgements

We thank Darcy Morgan, Alexis Shaw, Marika Kieferova, Zixin Huang, Louis Tessler, Yuval Sanders, Jasminder Sidhu, Simon Devitt & Jon Dowling for conversation (both helpful, unhelpful, meaningless, derogatory, and diatribe). We also thank the developers of [JuliaGraphs](https://juliagraphs.org), which QuNet makes heavy use of.
