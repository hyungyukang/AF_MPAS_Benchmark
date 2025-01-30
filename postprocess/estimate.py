#---------------------------------------------------------------------------------
# A Python script to estimate the number of nodes required to complete the
# simulation within 40 min.
#
# Note: After obtatining the runtime for both test cases, the number of nodes
#       (cores) required for an incresing number of windows (i.e., regionally
#       refined regions) can be estimated under a linear scaling assumption.
#---------------------------------------------------------------------------------
import os

# Runtime (time integration) from log.ocean.0000.out (or log.ocean.00000.out)

# - Runtime of VR_20km-4km_N01_D700 (<= 2400 s)
refRuntimeVR = 2399.776

# - Runtime of QU_20km
refRuntimeQU = 2076.7826

# Number of nodes used
nNodeUsed = 64

# Number of cores per node
nCoresPerNode = 128


#---------------------------------------------------------------------------------
# Estimate #Nodes completing simulations within 40 min
#   for increasing number of windows
# - Linear scaling is assumed.
#---------------------------------------------------------------------------------

# Number of windows (refinement regions) you want to estimate
nWindows = 10

runtimeDiff = refRuntimeVR - refRuntimeQU

print("--------------------------------------------------------------------")
print("Runtime measured using",nNodeUsed,"nodes (",nNodeUsed*nCoresPerNode,"cores )")
print(" - VR20km-1km_N01_D700 =",refRuntimeVR,"s")
print(" - QU20km              =",refRuntimeQU,"s")
print("--------------------------------------------------------------------")
print("Estimated requirements to complete 48 h forecast within 40 minutes:")
print(" ")
for i in range(nWindows):
    runtimeScaler = refRuntimeVR/2400.0
    runtimeWithWindows = refRuntimeQU * runtimeScaler + (i+1)*runtimeDiff
    nCoresEstimated = (nNodeUsed * nCoresPerNode) * runtimeWithWindows / refRuntimeVR
    nNodesEstimated = round(nCoresEstimated / nCoresPerNode)
    print(nNodesEstimated,"nodes (", nNodesEstimated*nCoresPerNode,
          "cores ) for",i+1,"windows.")
print("--------------------------------------------------------------------")
